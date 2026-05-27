#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>

class PlaylistManager : public QObject {
    Q_OBJECT
public:
    explicit PlaylistManager(QObject *parent = nullptr);

    void setDatabase(const QSqlDatabase &db);

    Q_INVOKABLE QVariantList allPlaylists();
    Q_INVOKABLE int  createPlaylist(const QString &name);
    Q_INVOKABLE bool renamePlaylist(int id, const QString &name);
    Q_INVOKABLE bool deletePlaylist(int id);
    Q_INVOKABLE bool addTrack(int playlistId, int trackId);
    Q_INVOKABLE bool removeTrack(int playlistId, int trackId);
    Q_INVOKABLE QVariantList playlistTracks(int playlistId);
    Q_INVOKABLE bool moveTrack(int playlistId, int fromPos, int toPos);
    Q_INVOKABLE int  trackCount(int playlistId);

signals:
    void playlistsChanged();
    void playlistTracksChanged(int playlistId);

private:
    QSqlDatabase m_db;
};
