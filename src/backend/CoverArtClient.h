#pragma once
#include <QObject>
#include <QNetworkAccessManager>

class CoverArtClient : public QObject {
    Q_OBJECT
public:
    explicit CoverArtClient(QObject *parent = nullptr);

    /// Fetch cover art by MusicBrainz release MBID.
    /// Emits coverArtReady() with a base64 data URL, or fetchError().
    Q_INVOKABLE void fetchByMbid(const QString &releaseMbid);

    /// Fetch cover art by artist + album name (Deezer API fallback).
    /// Emits coverArtReady() with a base64 data URL, or fetchError().
    Q_INVOKABLE void fetchByAlbum(const QString &artist, const QString &album);

signals:
    void coverArtReady(const QString &dataUrl);
    void fetchError(const QString &message);

private:
    QNetworkAccessManager *m_nam;
    void doFetch(const QString &url);
    void processImageData(const QByteArray &data);
    void processDeezerReply(const QByteArray &data);
};
