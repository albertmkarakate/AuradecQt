#pragma once
#include <QAbstractListModel>
#include <QVariantList>
#include "TrackDatabase.h"

class LibraryModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        PathRole, TitleRole, ArtistRole, AlbumRole, GenreRole,
        ComposerRole, YearRole, DurationRole, BitrateRole,
        SampleRateRole, CodecRole, ArtworkRole, HasArtworkRole,
        PlayCountRole, RatingRole, LastPlayedRole
    };

    explicit LibraryModel(TrackDatabase *db, QObject *parent = nullptr);

    int rowCount(const QModelIndex & = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int,QByteArray> roleNames() const override;

    Q_INVOKABLE QVariantList snapshot() const;

public slots:
    void reload();
    Q_INVOKABLE void doReload();
    void updatePlayCount(int trackId, int newCount);
    void setFilter(const QString &filter);
    void setArtistFilter(const QString &artist);
    void setAlbumFilter(const QString &album);
    void clearFilters();
    void setSort(const QString &col, bool ascending = true);
    void setFavoritesOnly(bool on);

signals:
    void countChanged();

private:
    TrackDatabase  *m_db;
    QVariantList    m_data;
    QString         m_textFilter;
    QString         m_artistFilter;
    QString         m_albumFilter;
    QString         m_sortCol    { "artist" };
    bool            m_sortAsc    { true };
    bool            m_favsOnly   { false };

};
