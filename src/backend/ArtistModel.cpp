#include "ArtistModel.h"

ArtistModel::ArtistModel(TrackDatabase *db, QObject *parent)
    : QAbstractListModel(parent), m_db(db) {}

int ArtistModel::rowCount(const QModelIndex &) const { return m_data.size(); }

QHash<int,QByteArray> ArtistModel::roleNames() const {
    return {{NameRole,"name"},{CountRole,"count"},{ImageUrlRole,"imageUrl"}};
}

QVariant ArtistModel::data(const QModelIndex &idx, int role) const {
    if (!idx.isValid() || idx.row() >= m_data.size()) return {};
    const QVariantMap &m = m_data.at(idx.row()).toMap();
    if (role == NameRole)     return m["name"];
    if (role == ImageUrlRole) return m["lastfmImageUrl"];
    return m["trackCount"];
}

void ArtistModel::reload() {
    beginResetModel();
    m_data = m_db->allArtistsWithInfo();
    endResetModel();
    emit countChanged();
}
