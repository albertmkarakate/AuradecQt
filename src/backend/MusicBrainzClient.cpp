#include "MusicBrainzClient.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QDebug>

MusicBrainzClient::MusicBrainzClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_rateLimit(new QTimer(this))
{
    m_rateLimit->setSingleShot(true);
    m_rateLimit->setInterval(1200); // MusicBrainz requires 1 req/sec — use 1.2s margin
    connect(m_rateLimit, &QTimer::timeout, this, [this]() {
        if (m_pending) {
            doSearch(m_pendingTitle, m_pendingArtist, m_pendingAlbum);
            m_pending = false;
        }
    });
}

void MusicBrainzClient::search(const QString &title,
                                const QString &artist,
                                const QString &album)
{
    if (m_rateLimit->isActive()) {
        // Queue the search for after the rate limit
        m_pending = true;
        m_pendingTitle = title;
        m_pendingArtist = artist;
        m_pendingAlbum = album;
        return;
    }
    doSearch(title, artist, album);
}

void MusicBrainzClient::doSearch(const QString &title,
                                  const QString &artist,
                                  const QString &album)
{
    // Build query parts
    QStringList queryParts;
    if (!title.isEmpty())
        queryParts << QStringLiteral("recording:%1").arg(title);
    if (!artist.isEmpty())
        queryParts << QStringLiteral("artist:%1").arg(artist);
    if (!album.isEmpty())
        queryParts << QStringLiteral("release:%1").arg(album);

    if (queryParts.isEmpty()) {
        emit searchError("No search terms provided");
        return;
    }

    QUrl url(QStringLiteral("https://musicbrainz.org/ws/2/recording/"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("query"), queryParts.join(QStringLiteral(" AND ")));
    query.addQueryItem(QStringLiteral("fmt"), QStringLiteral("json"));
    query.addQueryItem(QStringLiteral("limit"), QStringLiteral("10"));
    url.setQuery(query);

    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    req.setRawHeader("Accept", "application/json");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, &MusicBrainzClient::onSearchFinished);

    // Start rate-limit timer
    m_rateLimit->start();
}

void MusicBrainzClient::onSearchFinished() {
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        emit searchError(QStringLiteral("MusicBrainz error: %1").arg(reply->errorString()));
        return;
    }

    QByteArray data = reply->readAll();
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError) {
        emit searchError(QStringLiteral("Parse error: %1").arg(err.errorString()));
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray recordings = root.value("recordings").toArray();

    if (recordings.isEmpty()) {
        emit searchError("No matches found — try adjusting the search fields.");
        return;
    }

    QVariantList results;
    for (const QJsonValue &val : recordings) {
        QJsonObject rec = val.toObject();
        QVariantMap m;

        m["mbid"]  = rec.value("id").toString();
        m["title"] = rec.value("title").toString();
        m["score"] = rec.value("score").toInt();

        // Artist from artist-credit
        QJsonArray credits = rec.value("artist-credit").toArray();
        if (!credits.isEmpty()) {
            QJsonObject first = credits.first().toObject();
            m["artist"] = first.value("name").toString();
        }

        // Album from first release
        QJsonArray releases = rec.value("releases").toArray();
        if (!releases.isEmpty()) {
            QJsonObject rel = releases.first().toObject();
            m["album"] = rel.value("title").toString();
            QString date = rel.value("date").toString();
            if (!date.isEmpty())
                m["year"] = date.left(4).toInt();
            m["releaseMbid"] = rel.value("id").toString();
        }

        // Genre from first tag
        QJsonArray tags = rec.value("tags").toArray();
        if (!tags.isEmpty()) {
            QJsonObject firstTag = tags.first().toObject();
            m["genre"] = firstTag.value("name").toString();
        }

        results.append(m);
    }

    emit resultsReady(results);
}
