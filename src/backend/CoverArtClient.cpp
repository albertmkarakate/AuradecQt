#include "CoverArtClient.h"
#include <QNetworkReply>
#include <QImage>
#include <QBuffer>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

CoverArtClient::CoverArtClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

void CoverArtClient::fetchByMbid(const QString &releaseMbid)
{
    if (releaseMbid.isEmpty()) {
        emit fetchError("No MusicBrainz release ID provided");
        return;
    }

    // Try the 500px-wide variant first — falls back to full size if unavailable
    QString url = QStringLiteral("https://coverartarchive.org/release/%1/front-500")
                      .arg(releaseMbid);
    doFetch(url);
}

void CoverArtClient::fetchByAlbum(const QString &artist, const QString &album)
{
    if (artist.isEmpty() || album.isEmpty()) {
        emit fetchError("Artist and album name required");
        return;
    }

    // Deezer search: /search/album?q=artist album
    QString query = artist + QStringLiteral(" ") + album;
    QUrl url(QStringLiteral("https://api.deezer.com/search/album?q=%1")
                 .arg(QString::fromUtf8(QUrl::toPercentEncoding(query))));

    QNetworkRequest req{url};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit fetchError(QStringLiteral("Deezer search failed: %1")
                                .arg(reply->errorString()));
            return;
        }
        processDeezerReply(reply->readAll());
    });
}

void CoverArtClient::doFetch(const QString &url)
{
    QNetworkRequest req{QUrl(url)};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    // Cover Art Archive may redirect; QNetworkAccessManager follows by default
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::SameOriginRedirectPolicy);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            // If the 500px variant failed, try the full-size image
            QString origUrl = reply->request().url().toString();
            if (origUrl.contains(QLatin1String("front-500"))) {
                QString fullUrl = origUrl.replace(QLatin1String("front-500"),
                                                  QLatin1String("front"));
                auto *retryReply = m_nam->get(QNetworkRequest(QUrl(fullUrl)));
                connect(retryReply, &QNetworkReply::finished, this,
                        [this, retryReply]() {
                    retryReply->deleteLater();
                    if (retryReply->error() != QNetworkReply::NoError) {
                        emit fetchError(QStringLiteral("Cover art not found for this release"));
                        return;
                    }
                    processImageData(retryReply->readAll());
                });
                return;
            }

            emit fetchError(QStringLiteral("Cover Art Archive error: %1")
                                .arg(reply->errorString()));
            return;
        }

        processImageData(reply->readAll());
    });
}

void CoverArtClient::processDeezerReply(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        emit fetchError(QStringLiteral("Failed to parse Deezer response"));
        return;
    }

    QJsonObject obj = doc.object();
    QJsonArray results = obj.value(QStringLiteral("data")).toArray();
    if (results.isEmpty()) {
        emit fetchError(QStringLiteral("No album art found on Deezer"));
        return;
    }

    // Take the best match: first result with cover_big
    QString coverUrl;
    for (const QJsonValue &v : results) {
        QJsonObject album = v.toObject();
        coverUrl = album.value(QStringLiteral("cover_big")).toString();
        if (!coverUrl.isEmpty())
            break;
    }

    if (coverUrl.isEmpty()) {
        emit fetchError(QStringLiteral("Deezer result has no cover art URL"));
        return;
    }

    // Fetch the actual image from Deezer's CDN
    QNetworkRequest req{QUrl(coverUrl)};
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit fetchError(QStringLiteral("Failed to download Deezer cover art"));
            return;
        }
        processImageData(reply->readAll());
    });
}

void CoverArtClient::processImageData(const QByteArray &data)
{
    QImage img;
    if (!img.loadFromData(data)) {
        emit fetchError("Failed to decode cover art image");
        return;
    }

    // Scale down if very large (keep under 800px for QML display)
    if (img.width() > 800 || img.height() > 800) {
        img = img.scaled(800, 800, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    img.save(&buffer, "JPEG");
    buffer.close();

    QString dataUrl = QStringLiteral("data:image/jpeg;base64,")
                      + QString::fromLatin1(bytes.toBase64());
    emit coverArtReady(dataUrl);
}
