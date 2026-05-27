#include "CurrentTrackInfo.h"
#include <QJsonDocument>
#include <QJsonObject>

CurrentTrackInfo::CurrentTrackInfo(QObject *parent) : QObject(parent) {}

void CurrentTrackInfo::setTrack(const QVariantMap &t) {
    m_id         = t.value("id", -1).toInt();
    m_title      = t.value("title").toString();
    m_artist     = t.value("artist").toString();
    m_album      = t.value("album").toString();
    m_codec      = t.value("codec").toString();
    m_bitrate    = t.value("bitrate", 0).toInt();
    m_sampleRate = t.value("sampleRate", 0).toInt();
    if (t.contains("hasArtwork"))
        m_hasArtwork = t.value("hasArtwork").toBool();
    else
        m_hasArtwork = !t.value("artwork").toByteArray().isEmpty();
    m_year       = t.value("year", 0).toInt();
    m_genre      = t.value("genre").toString();
    m_playCount  = t.value("playCount", 0).toInt();

    // Load lyrics from DB cache (JSON {"plain":"...","synced":"..."} or plain text)
    QString dbLyrics = t.value("lyrics").toString();
    if (!dbLyrics.isEmpty()) {
        if (dbLyrics.startsWith('{')) {
            QJsonDocument doc = QJsonDocument::fromJson(dbLyrics.toUtf8());
            if (doc.isObject()) {
                m_lyrics       = doc.object().value("plain").toString();
                m_syncedLyrics = doc.object().value("synced").toString();
            } else {
                m_lyrics = dbLyrics;
                m_syncedLyrics.clear();
            }
        } else {
            m_lyrics = dbLyrics;
            m_syncedLyrics.clear();
        }
    } else {
        m_lyrics.clear();
        m_syncedLyrics.clear();
    }

    emit lyricsChanged();
    emit changed();
}

void CurrentTrackInfo::setLyrics(const QString &plain, const QString &synced) {
    m_lyrics = plain;
    m_syncedLyrics = synced;
    emit lyricsChanged();
}

void CurrentTrackInfo::clearLyrics() {
    m_lyrics.clear();
    m_syncedLyrics.clear();
    emit lyricsChanged();
}

void CurrentTrackInfo::clear() {
    m_id = -1; m_title.clear(); m_artist.clear(); m_album.clear();
    m_codec.clear(); m_bitrate = 0; m_sampleRate = 0; m_hasArtwork = false;
    m_year = 0; m_genre.clear(); m_playCount = 0;
    m_lyrics.clear(); m_syncedLyrics.clear();
    emit changed();
    emit lyricsChanged();
}
