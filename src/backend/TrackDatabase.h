#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QVariantMap>
#include <QVariantList>

class TrackDatabase : public QObject {
    Q_OBJECT
public:
    explicit TrackDatabase(QObject *parent = nullptr);
    ~TrackDatabase();

    bool open();
    void close();

    bool upsertTrack(const QVariantMap &track);
    QVariantList allTracks(const QString &textFilter = {},
                           const QString &artistFilter = {},
                           const QString &albumFilter = {},
                           bool favsOnly = false,
                           const QString &sortCol = "artist",
                           bool sortAsc = true);
    QVariantList allArtists();
    QVariantList allAlbums();
    Q_INVOKABLE bool updateTrack(int id, const QVariantMap &fields);
    Q_INVOKABLE bool deleteTrack(int id);
    Q_INVOKABLE void incrementPlayCount(int id);
    Q_INVOKABLE QVariantMap trackById(int id);
    Q_INVOKABLE QVariantMap codecStats();
    Q_INVOKABLE void toggleFavorite(int id);
    Q_INVOKABLE bool isFavorite(int id);
    Q_INVOKABLE bool saveArtwork(int trackId, const QString &base64DataUrl);
    Q_INVOKABLE bool writeFileTags(int trackId);
    Q_INVOKABLE QString databasePath() const { return m_dbPath; }
    QSqlDatabase database() const { return m_db; }
    Q_INVOKABLE QByteArray artworkBlob(int trackId);

    // Artist metadata
    Q_INVOKABLE QVariantMap artistInfo(const QString &name);
    Q_INVOKABLE bool updateArtistInfo(const QString &name, const QVariantMap &data);
    Q_INVOKABLE QVariantList allArtistsWithInfo();
    Q_INVOKABLE int artistCount();

signals:
    void playCountChanged(int trackId, int newCount);

private:
    void createSchema();
    QSqlDatabase m_db;
    QString      m_dbPath;
};
