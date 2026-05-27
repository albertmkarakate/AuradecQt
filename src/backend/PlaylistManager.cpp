#include "PlaylistManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>

PlaylistManager::PlaylistManager(QObject *parent) : QObject(parent) {}

void PlaylistManager::setDatabase(const QSqlDatabase &db) {
    m_db = db;
}

QVariantList PlaylistManager::allPlaylists() {
    QSqlQuery q(m_db);
    q.exec(R"(
        SELECT p.id, p.name, p.createdAt,
               COUNT(pt.track_id) as trackCount
        FROM playlists p
        LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
        GROUP BY p.id ORDER BY p.name COLLATE NOCASE
    )");
    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["id"]         = q.value("id");
        m["name"]       = q.value("name");
        m["createdAt"]  = q.value("createdAt");
        m["trackCount"] = q.value("trackCount");
        list.append(m);
    }
    return list;
}

int PlaylistManager::createPlaylist(const QString &name) {
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO playlists (name, createdAt) VALUES (:name, :ts)");
    q.bindValue(":name", name.trimmed());
    q.bindValue(":ts", QDateTime::currentSecsSinceEpoch());
    if (!q.exec()) {
        qWarning() << "createPlaylist failed:" << q.lastError().text();
        return -1;
    }
    int id = q.lastInsertId().toInt();
    emit playlistsChanged();
    return id;
}

bool PlaylistManager::renamePlaylist(int id, const QString &name) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE playlists SET name=:name WHERE id=:id");
    q.bindValue(":name", name.trimmed());
    q.bindValue(":id", id);
    bool ok = q.exec() && q.numRowsAffected() > 0;
    if (ok) emit playlistsChanged();
    return ok;
}

bool PlaylistManager::deletePlaylist(int id) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM playlists WHERE id=:id");
    q.bindValue(":id", id);
    bool ok = q.exec() && q.numRowsAffected() > 0;
    if (ok) emit playlistsChanged();
    return ok;
}

bool PlaylistManager::addTrack(int playlistId, int trackId) {
    QSqlQuery pos(m_db);
    pos.prepare("SELECT COALESCE(MAX(position), -1) + 1 FROM playlist_tracks WHERE playlist_id=:pid");
    pos.bindValue(":pid", playlistId);
    pos.exec();
    int nextPos = pos.next() ? pos.value(0).toInt() : 0;

    QSqlQuery q(m_db);
    q.prepare("INSERT OR IGNORE INTO playlist_tracks (playlist_id, track_id, position) VALUES (:pid, :tid, :pos)");
    q.bindValue(":pid", playlistId);
    q.bindValue(":tid", trackId);
    q.bindValue(":pos", nextPos);
    bool ok = q.exec() && q.numRowsAffected() > 0;
    if (ok) { emit playlistsChanged(); emit playlistTracksChanged(playlistId); }
    return ok;
}

bool PlaylistManager::removeTrack(int playlistId, int trackId) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM playlist_tracks WHERE playlist_id=:pid AND track_id=:tid");
    q.bindValue(":pid", playlistId);
    q.bindValue(":tid", trackId);
    bool ok = q.exec() && q.numRowsAffected() > 0;
    if (ok) { emit playlistsChanged(); emit playlistTracksChanged(playlistId); }
    return ok;
}

QVariantList PlaylistManager::playlistTracks(int playlistId) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT t.id, t.path, t.title, t.artist, t.album, t.duration,
               t.year, t.genre, t.codec, t.playCount, t.rating,
               pt.position
        FROM playlist_tracks pt
        JOIN tracks t ON t.id = pt.track_id
        WHERE pt.playlist_id = :pid
        ORDER BY pt.position
    )");
    q.bindValue(":pid", playlistId);
    q.exec();
    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["id"]        = q.value("id");
        m["path"]      = q.value("path");
        m["title"]     = q.value("title");
        m["artist"]    = q.value("artist");
        m["album"]     = q.value("album");
        m["duration"]  = q.value("duration");
        m["year"]      = q.value("year");
        m["genre"]     = q.value("genre");
        m["codec"]     = q.value("codec");
        m["playCount"] = q.value("playCount");
        m["rating"]    = q.value("rating");
        m["position"]  = q.value("position");
        list.append(m);
    }
    return list;
}

bool PlaylistManager::moveTrack(int playlistId, int fromPos, int toPos) {
    if (fromPos == toPos) return false;
    QSqlQuery q(m_db);
    // Move the row to a temporary sentinel position to avoid UNIQUE conflicts
    q.prepare("UPDATE playlist_tracks SET position=-1 "
              "WHERE playlist_id=:pid AND position=:from");
    q.bindValue(":pid", playlistId);
    q.bindValue(":from", fromPos);
    if (!q.exec()) return false;

    if (fromPos < toPos) {
        // Moving forward: shift intervening rows down
        q.prepare("UPDATE playlist_tracks SET position=position-1 "
                  "WHERE playlist_id=:pid AND position BETWEEN :lo AND :hi");
        q.bindValue(":pid", playlistId);
        q.bindValue(":lo", fromPos + 1);
        q.bindValue(":hi", toPos);
    } else {
        // Moving backward: shift intervening rows up
        q.prepare("UPDATE playlist_tracks SET position=position+1 "
                  "WHERE playlist_id=:pid AND position BETWEEN :lo AND :hi");
        q.bindValue(":pid", playlistId);
        q.bindValue(":lo", toPos);
        q.bindValue(":hi", fromPos - 1);
    }
    q.exec();

    q.prepare("UPDATE playlist_tracks SET position=:to "
              "WHERE playlist_id=:pid AND position=-1");
    q.bindValue(":pid", playlistId);
    q.bindValue(":to", toPos);
    bool ok = q.exec();
    if (ok) emit playlistTracksChanged(playlistId);
    return ok;
}

int PlaylistManager::trackCount(int playlistId) {
    QSqlQuery q(m_db);
    q.prepare("SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id=:pid");
    q.bindValue(":pid", playlistId);
    q.exec();
    return q.next() ? q.value(0).toInt() : 0;
}
