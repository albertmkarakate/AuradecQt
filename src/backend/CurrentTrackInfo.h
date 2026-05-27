#pragma once
#include <QObject>
#include <QVariantMap>

class CurrentTrackInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(int     id         READ id         NOTIFY changed)
    Q_PROPERTY(QString title      READ title      NOTIFY changed)
    Q_PROPERTY(QString artist     READ artist     NOTIFY changed)
    Q_PROPERTY(QString album      READ album      NOTIFY changed)
    Q_PROPERTY(QString codec      READ codec      NOTIFY changed)
    Q_PROPERTY(int     bitrate    READ bitrate    NOTIFY changed)
    Q_PROPERTY(int     sampleRate READ sampleRate NOTIFY changed)
    Q_PROPERTY(bool    hasArtwork READ hasArtwork NOTIFY changed)
    Q_PROPERTY(int     year       READ year       NOTIFY changed)
    Q_PROPERTY(QString genre      READ genre      NOTIFY changed)
    Q_PROPERTY(int     playCount    READ playCount    NOTIFY changed)
    Q_PROPERTY(QString composer     READ composer     NOTIFY changed)
    Q_PROPERTY(int     rating       READ rating       NOTIFY changed)
    Q_PROPERTY(QString lyrics       READ lyrics       NOTIFY lyricsChanged)
    Q_PROPERTY(QString syncedLyrics READ syncedLyrics NOTIFY lyricsChanged)

public:
    explicit CurrentTrackInfo(QObject *parent = nullptr);

    int     id()         const { return m_id; }
    QString title()      const { return m_title; }
    QString artist()     const { return m_artist; }
    QString album()      const { return m_album; }
    QString codec()      const { return m_codec; }
    int     bitrate()    const { return m_bitrate; }
    int     sampleRate() const { return m_sampleRate; }
    bool    hasArtwork() const { return m_hasArtwork; }
    int     year()       const { return m_year; }
    QString genre()      const { return m_genre; }
    int     playCount()  const { return m_playCount; }
    QString composer()   const { return m_composer; }
    int     rating()     const { return m_rating; }
    QString lyrics()      const { return m_lyrics; }
    QString syncedLyrics() const { return m_syncedLyrics; }

public slots:
    Q_INVOKABLE void setTrack(const QVariantMap &track);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void setLyrics(const QString &plain, const QString &synced);
    Q_INVOKABLE void clearLyrics();

signals:
    void changed();
    void lyricsChanged();

private:
    int     m_id         = -1;
    QString m_title;
    QString m_artist;
    QString m_album;
    QString m_codec;
    int     m_bitrate    = 0;
    int     m_sampleRate = 0;
    bool    m_hasArtwork = false;
    int     m_year       = 0;
    QString m_genre;
    int     m_playCount  = 0;
    QString m_composer;
    int     m_rating     = 0;
    QString m_lyrics;
    QString m_syncedLyrics;
};
