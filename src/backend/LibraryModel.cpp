#include "LibraryModel.h"

LibraryModel::LibraryModel(TrackDatabase *db, QObject *parent)
    : QAbstractListModel(parent), m_db(db) {}

int LibraryModel::rowCount(const QModelIndex &) const { return m_data.size(); }

QHash<int,QByteArray> LibraryModel::roleNames() const {
    return {
        {IdRole,         "trackId"},
        {PathRole,       "path"},
        {TitleRole,      "title"},
        {ArtistRole,     "artist"},
        {AlbumRole,      "album"},
        {GenreRole,      "genre"},
        {ComposerRole,   "composer"},
        {YearRole,       "year"},
        {DurationRole,   "duration"},
        {BitrateRole,    "bitrate"},
        {SampleRateRole, "sampleRate"},
        {CodecRole,      "codec"},
        {ArtworkRole,    "artwork"},
        {HasArtworkRole, "hasArtwork"},
        {PlayCountRole,  "playCount"},
        {RatingRole,     "rating"},
        {LastPlayedRole, "lastPlayed"},
    };
}

QVariant LibraryModel::data(const QModelIndex &idx, int role) const {
    if (!idx.isValid() || idx.row() >= m_data.size()) return {};
    const QVariantMap &t = m_data.at(idx.row()).toMap();
    switch (role) {
        case IdRole:         return t["id"];
        case PathRole:       return t["path"];
        case TitleRole:      return t["title"];
        case ArtistRole:     return t["artist"];
        case AlbumRole:      return t["album"];
        case GenreRole:      return t["genre"];
        case ComposerRole:   return t["composer"];
        case YearRole:       return t["year"];
        case DurationRole:   return t["duration"];
        case BitrateRole:    return t["bitrate"];
        case SampleRateRole: return t["sampleRate"];
        case CodecRole:      return t["codec"];
        case ArtworkRole:    return {};
        case HasArtworkRole: return t["hasArtwork"].toBool();
        case PlayCountRole:  return t["playCount"];
        case RatingRole:     return t["rating"];
        case LastPlayedRole: return t["lastPlayed"];
        default:             return {};
    }
}

void LibraryModel::doReload() {
    beginResetModel();
    m_data = m_db->allTracks(m_textFilter, m_artistFilter, m_albumFilter,
                              m_favsOnly, m_sortCol, m_sortAsc);
    endResetModel();
    emit countChanged();
}

void LibraryModel::reload()                      { doReload(); }
void LibraryModel::setFilter(const QString &f)   { m_textFilter = f;   doReload(); }
void LibraryModel::setArtistFilter(const QString &a) { m_artistFilter = a; doReload(); }
void LibraryModel::setAlbumFilter(const QString &a)  { m_albumFilter  = a; doReload(); }
void LibraryModel::setFavoritesOnly(bool on)     { m_favsOnly = on; doReload(); }
void LibraryModel::setSort(const QString &col, bool asc) { m_sortCol = col; m_sortAsc = asc; doReload(); }

void LibraryModel::clearFilters() {
    m_textFilter.clear();
    m_artistFilter.clear();
    m_albumFilter.clear();
    m_favsOnly = false;
    doReload();
}

void LibraryModel::updatePlayCount(int trackId, int newCount) {
    for (int i = 0; i < m_data.size(); ++i) {
        QVariantMap t = m_data.at(i).toMap();
        if (t["id"].toInt() == trackId) {
            t["playCount"] = newCount;
            m_data[i] = t;
            QModelIndex idx = index(i);
            emit dataChanged(idx, idx, {PlayCountRole});
            return;
        }
    }
}

QVariantList LibraryModel::snapshot() const { return m_data; }
