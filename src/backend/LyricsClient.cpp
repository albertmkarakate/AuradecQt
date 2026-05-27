#include "LyricsClient.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

// API endpoints
static const QString LRCLIB_API = QStringLiteral("https://lrclib.net/api/get");
static const QString LYRICS_OVH_API = QStringLiteral("https://api.lyrics.ovh/v1");

LyricsClient::LyricsClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

void LyricsClient::setBusy(bool b)
{
    if (m_busy == b) return;
    m_busy = b;
    emit busyChanged();
}

void LyricsClient::setStatusText(const QString &text)
{
    if (m_statusText == text) return;
    m_statusText = text;
    emit statusTextChanged();
}

void LyricsClient::fetchLyrics(const QString &artist, const QString &title, int duration)
{
    cancelFetch();
    m_artist = artist.trimmed();
    m_title = title.trimmed();
    m_duration = duration;
    m_currentSource = LRCLIB;
    setStatusText(QStringLiteral("Fetching lyrics…"));
    setBusy(true);
    tryNextSource();
}

void LyricsClient::setNetworkManager(QNetworkAccessManager *nam)
{
    if (m_reply) { m_reply->abort(); m_reply->deleteLater(); m_reply = nullptr; }
    m_nam->deleteLater();
    m_nam = nam;
}

void LyricsClient::setSpotifyToken(const QString &spDc)
{
    if (m_spDc == spDc) return;
    m_spDc = spDc;
    if (m_spDc.isEmpty()) {
        m_spotifyAccessToken.clear();
        m_tokenExpiryMs = 0;
    }
    emit spotifyConfiguredChanged();
}

void LyricsClient::cancelFetch()
{
    setStatusText(QString());
    setBusy(false);
    if (m_reply) {
        auto *reply = m_reply;
        m_reply = nullptr;
        reply->abort();
        reply->deleteLater();
    }
    m_spotifyTrackId.clear();
}

void LyricsClient::tryNextSource()
{
    if (m_reply) {
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    if (m_artist.isEmpty() || m_title.isEmpty()) {
        setStatusText(QStringLiteral("Artist and title required"));
        setBusy(false);
        emit fetchError("Artist and title required");
        return;
    }

    switch (m_currentSource) {
    case LRCLIB: {
        // LRCLIB: GET /api/get?artist_name=X&track_name=X&duration=N
        QUrl url(LRCLIB_API);
        QUrlQuery q;
        q.addQueryItem(QStringLiteral("artist_name"), m_artist);
        q.addQueryItem(QStringLiteral("track_name"), m_title);
        if (m_duration > 0)
            q.addQueryItem(QStringLiteral("duration"), QString::number(m_duration));
        url.setQuery(q);
        doFetch(url, LRCLIB);
        break;
    }
    case LyricsOvh: {
        // lyrics.ovh: GET /v1/{artist}/{title}
        QUrl url(LYRICS_OVH_API + "/"
                 + QUrl::toPercentEncoding(m_artist) + "/"
                 + QUrl::toPercentEncoding(m_title));
        doFetch(url, LyricsOvh);
        break;
    }
    case Spotify: {
        if (m_spDc.isEmpty()) {
            // No token configured — skip silently
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        // Check if we already have a valid access token
        if (!m_spotifyAccessToken.isEmpty() &&
            QDateTime::currentMSecsSinceEpoch() < m_tokenExpiryMs - 60000) {
            // Token still valid (with 60s buffer) — search directly
            startSpotifySearch();
        } else {
            startSpotifyTokenFetch();
        }
        break;
    }
    default: {
        setStatusText(QStringLiteral("No lyrics source available"));
        emit fetchError(QStringLiteral("No lyrics source available"));
        break;
    }
    }
}

void LyricsClient::doFetch(const QUrl &url, Source src)
{
    m_currentSource = src;

    QNetworkRequest req{url};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        auto *reply = qobject_cast<QNetworkReply*>(sender());
        if (!reply) return;
        if (m_reply == reply) m_reply = nullptr;
        reply->deleteLater();
        if (!m_busy) return; // cancelled

        if (reply->error() != QNetworkReply::NoError) {
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            if (m_currentSource >= SourceCount) {
                setStatusText(QStringLiteral("Could not fetch lyrics"));
                setBusy(false);
                emit fetchError(QStringLiteral("All lyrics sources exhausted"));
                return;
            }
            setStatusText(QStringLiteral("Source unavailable, trying fallback…"));
            tryNextSource();
            return;
        }

        const QByteArray data = reply->readAll();

        switch (m_currentSource) {
        case LRCLIB:  processLRCLIBReply(data); break;
        case LyricsOvh: processOvhReply(data);  break;
        default:      setStatusText(QStringLiteral("Unknown source")); setBusy(false); emit fetchError(QStringLiteral("Unknown source")); break;
        }
    });
}

void LyricsClient::processLRCLIBReply(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
        tryNextSource();
        return;
    }

    QJsonObject obj = doc.object();

    // Check if instrumental
    if (obj.value(QStringLiteral("instrumental")).toBool()) {
        setStatusText(QStringLiteral("Instrumental track"));
        setBusy(false);
        emit lyricsReady(QString(), QString(), QStringLiteral("LRCLIB"));
        return;
    }

    QString plain = obj.value(QStringLiteral("plainLyrics")).toString().trimmed();
    QString synced = obj.value(QStringLiteral("syncedLyrics")).toString().trimmed();

    if (plain.isEmpty() && synced.isEmpty()) {
        setStatusText(QStringLiteral("No lyrics found via LRCLIB"));
        m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
        tryNextSource();
        return;
    }

    setStatusText(QString());
    setBusy(false);
    emit lyricsReady(plain, synced, QStringLiteral("LRCLIB"));
}

void LyricsClient::processOvhReply(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        setStatusText(QStringLiteral("Could not parse lyrics.ovh response"));
        setBusy(false);
        emit fetchError(QStringLiteral("Could not parse lyrics.ovh response"));
        return;
    }

    QJsonObject obj = doc.object();
    QString lyrics = obj.value(QStringLiteral("lyrics")).toString().trimmed();
    if (lyrics.isEmpty()) {
        setStatusText(QStringLiteral("No lyrics found via lyrics.ovh"));
        setBusy(false);
        emit fetchError(QStringLiteral("No lyrics found"));
        return;
    }

    setStatusText(QString());
    setBusy(false);
    emit lyricsReady(lyrics, QString(), QStringLiteral("lyrics.ovh"));
}

// ---------------------------------------------------------------------------
// Spotify lyrics sub-workflow (3 chained requests)
// ---------------------------------------------------------------------------

static const QString SPOTIFY_TOKEN_URL =
    QStringLiteral("https://open.spotify.com/get_access_token?reason=transport&productType=web_player");
static const QString SPOTIFY_API_SEARCH =
    QStringLiteral("https://api.spotify.com/v1/search");
static const QString SPOTIFY_COLOR_LYRICS =
    QStringLiteral("https://spclient.wg.spotify.com/color-lyrics/v2/track");

void LyricsClient::startSpotifyTokenFetch()
{
    setStatusText(QStringLiteral("Getting Spotify access token…"));

    QNetworkRequest req{QUrl(SPOTIFY_TOKEN_URL)};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    req.setRawHeader("Cookie", QStringLiteral("sp_dc=%1").arg(m_spDc).toUtf8());
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (!m_reply) return;
        m_reply->deleteLater();
        auto *reply = m_reply;
        m_reply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            reply->deleteLater();
            setStatusText(QStringLiteral("Spotify token fetch failed"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            if (m_currentSource >= SourceCount) {
                setBusy(false);
                emit fetchError(QStringLiteral("All lyrics sources exhausted"));
            } else {
                tryNextSource();
            }
            return;
        }

        QByteArray data = reply->readAll();
        reply->deleteLater();

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(data, &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            setStatusText(QStringLiteral("Could not parse Spotify token response"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        QJsonObject obj = doc.object();
        m_spotifyAccessToken = obj.value(QStringLiteral("accessToken")).toString();
        m_tokenExpiryMs = static_cast<qint64>(
            obj.value(QStringLiteral("accessTokenExpirationTimestampMs")).toDouble());

        if (m_spotifyAccessToken.isEmpty()) {
            setStatusText(QStringLiteral("Empty Spotify access token"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        setStatusText(QStringLiteral("Spotify token obtained, searching track…"));
        startSpotifySearch();
    });
}

void LyricsClient::startSpotifySearch()
{
    QString query = QStringLiteral("%1 %2").arg(m_artist, m_title);
    QUrl url(SPOTIFY_API_SEARCH);
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("q"), query);
    q.addQueryItem(QStringLiteral("type"), QStringLiteral("track"));
    q.addQueryItem(QStringLiteral("limit"), QStringLiteral("3"));
    url.setQuery(q);

    QNetworkRequest req{url};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    req.setRawHeader("Authorization",
                     QStringLiteral("Bearer %1").arg(m_spotifyAccessToken).toUtf8());
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (!m_reply) return;
        m_reply->deleteLater();
        auto *reply = m_reply;
        m_reply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            reply->deleteLater();
            setStatusText(QStringLiteral("Spotify search failed"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            if (m_currentSource >= SourceCount) {
                setBusy(false);
                emit fetchError(QStringLiteral("All lyrics sources exhausted"));
            } else {
                tryNextSource();
            }
            return;
        }

        QByteArray data = reply->readAll();
        reply->deleteLater();

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(data, &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            setStatusText(QStringLiteral("Could not parse Spotify search response"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        QJsonObject obj = doc.object();
        QJsonArray tracks = obj.value(QStringLiteral("tracks")).toObject()
                                .value(QStringLiteral("items")).toArray();

        if (tracks.isEmpty()) {
            setStatusText(QStringLiteral("Track not found on Spotify"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        m_spotifyTrackId = tracks.first().toObject()
                               .value(QStringLiteral("id")).toString();

        if (m_spotifyTrackId.isEmpty()) {
            setStatusText(QStringLiteral("Spotify track has no ID"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        setStatusText(QStringLiteral("Spotify track found, fetching lyrics…"));
        startSpotifyLyricsFetch();
    });
}

void LyricsClient::startSpotifyLyricsFetch()
{
    QUrl url(QStringLiteral("%1/%2?format=json").arg(SPOTIFY_COLOR_LYRICS, m_spotifyTrackId));

    QNetworkRequest req{url};
    req.setRawHeader("User-Agent", "Auradec/1.0 (music-player) Qt/" QT_VERSION_STR);
    req.setRawHeader("Authorization",
                     QStringLiteral("Bearer %1").arg(m_spotifyAccessToken).toUtf8());
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (!m_reply) return;
        m_reply->deleteLater();
        auto *reply = m_reply;
        m_reply = nullptr;
        m_spotifyTrackId.clear();

        if (reply->error() != QNetworkReply::NoError) {
            reply->deleteLater();
            setStatusText(QStringLiteral("Spotify lyrics fetch failed"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            if (m_currentSource >= SourceCount) {
                setBusy(false);
                emit fetchError(QStringLiteral("All lyrics sources exhausted"));
            } else {
                tryNextSource();
            }
            return;
        }

        QByteArray data = reply->readAll();
        reply->deleteLater();

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(data, &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            setStatusText(QStringLiteral("Could not parse Spotify lyrics response"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        QJsonObject obj = doc.object();
        QJsonObject lyrics = obj.value(QStringLiteral("lyrics")).toObject();
        QJsonArray lines = lyrics.value(QStringLiteral("lines")).toArray();

        if (lines.isEmpty()) {
            setStatusText(QStringLiteral("No lyrics found on Spotify"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        // Build synced LRC and plain text
        QStringList syncedLines;
        QStringList plainLines;
        for (const QJsonValue &v : lines) {
            QJsonObject line = v.toObject();
            QString words = line.value(QStringLiteral("words")).toString();
            if (words.trimmed().isEmpty()) continue;

            // Spotify startTimeMs is a string or number
            double startMs = line.value(QStringLiteral("startTimeMs")).toString().toDouble();
            int minutes = static_cast<int>(startMs) / 60000;
            int seconds = (static_cast<int>(startMs) / 1000) % 60;
            int centiseconds = (static_cast<int>(startMs) % 1000) / 10;

            syncedLines.append(QStringLiteral("[%1:%2.%3]%4")
                                   .arg(minutes, 2, 10, QLatin1Char('0'))
                                   .arg(seconds, 2, 10, QLatin1Char('0'))
                                   .arg(centiseconds, 2, 10, QLatin1Char('0'))
                                   .arg(words));
            plainLines.append(words);
        }

        if (syncedLines.isEmpty()) {
            setStatusText(QStringLiteral("No lyrics found on Spotify"));
            m_currentSource = static_cast<Source>(static_cast<int>(m_currentSource) + 1);
            tryNextSource();
            return;
        }

        setStatusText(QString());
        setBusy(false);
        emit lyricsReady(plainLines.join(QStringLiteral("\n")),
                         syncedLines.join(QStringLiteral("\n")),
                         QStringLiteral("Spotify"));
    });
}
