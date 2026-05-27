#include "AlbumModel.h"

AlbumModel::AlbumModel(TrackDatabase *db, QObject *parent)
    : QAbstractListModel(parent), m_db(db) {}

int AlbumModel::rowCount(const QModelIndex &) const { return m_data.size(); }

QHash<int,QByteArray> AlbumModel::roleNames() const {
    return {
        {NameRole,    "name"},
        {ArtistRole,  "artist"},
        {YearRole,    "year"},
        {CountRole,   "count"},
        {CoverIdRole, "coverId"},
    };
}

QVariant AlbumModel::data(const QModelIndex &idx, int role) const {
    if (!idx.isValid() || idx.row() >= m_data.size()) return {};
    const QVariantMap &m = m_data.at(idx.row()).toMap();
    switch (role) {
        case NameRole:    return m["name"];
        case ArtistRole:  return m["artist"];
        case YearRole:    return m["year"];
        case CountRole:   return m["count"];
        case CoverIdRole: return m["coverId"];
        default:          return {};
    }
}

void AlbumModel::reload() {
    beginResetModel();
    m_data = m_db->allAlbums();
    endResetModel();
    emit countChanged();
}
