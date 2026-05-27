#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDateTime>

class LyricsClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(bool spotifyConfigured READ spotifyConfigured NOTIFY spotifyConfiguredChanged)
public:
    explicit LyricsClient(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString statusText() const { return m_statusText; }
    bool spotifyConfigured() const { return !m_spDc.isEmpty(); }

    /// Start fetching lyrics from available sources (LRCLIB → lyrics.ovh → Spotify).
    /// @param duration  Track duration in seconds (used by LRCLIB for better matching).
    Q_INVOKABLE void fetchLyrics(const QString &artist, const QString &title, int duration = 0);
    Q_INVOKABLE void cancelFetch();

    /// Set the Spotify sp_dc cookie value for Spotify lyrics access.
    /// Pass empty string to clear.
    Q_INVOKABLE void setSpotifyToken(const QString &spDc);

    // For testing only — replace the internal QNetworkAccessManager
    void setNetworkManager(QNetworkAccessManager *nam);

signals:
    void lyricsReady(const QString &plainLyrics, const QString &syncedLyrics, const QString &source);
    void fetchError(const QString &message);
    void busyChanged();
    void statusTextChanged();
    void spotifyConfiguredChanged();

private:
    enum Source { LRCLIB = 0, LyricsOvh, Spotify, SourceCount };

    void setBusy(bool b);
    void setStatusText(const QString &text);
    void tryNextSource();
    void doFetch(const QUrl &url, Source src);
    void processLRCLIBReply(const QByteArray &data);
    void processOvhReply(const QByteArray &data);

    // Spotify sub-workflow
    void startSpotifyTokenFetch();
    void startSpotifySearch();
    void startSpotifyLyricsFetch();

    QNetworkAccessManager *m_nam;
    QNetworkReply *m_reply = nullptr;
    Source m_currentSource = LRCLIB;
    QString m_artist;
    QString m_title;
    int m_duration = 0;
    bool m_busy = false;
    QString m_statusText;

    // Spotify state
    QString m_spDc;
    QString m_spotifyAccessToken;
    qint64  m_tokenExpiryMs = 0;   // epoch ms when token expires
    QString m_spotifyTrackId;
};
