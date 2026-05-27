#include "TrackDatabase.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

#ifdef HAVE_TAGLIB
#include <taglib/fileref.h>
#include <taglib/tag.h>
#endif

TrackDatabase::TrackDatabase(QObject *parent) : QObject(parent) {}
TrackDatabase::~TrackDatabase() { close(); }

bool TrackDatabase::open() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_dbPath = dataDir + "/library.db";

    m_db = QSqlDatabase::addDatabase("QSQLITE", "auradec");
    m_db.setDatabaseName(m_dbPath);

    if (!m_db.open()) {
        qWarning() << "DB open failed:" << m_db.lastError().text();
        return false;
    }

    QSqlQuery pragma(m_db);
    pragma.exec("PRAGMA journal_mode=WAL");
    pragma.exec("PRAGMA synchronous=NORMAL");
    pragma.exec("PRAGMA cache_size=4000");

    createSchema();
    return true;
}

void TrackDatabase::close() {
    if (m_db.isOpen()) m_db.close();
}

void TrackDatabase::createSchema() {
    QSqlQuery q(m_db);
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS tracks (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            path       TEXT UNIQUE NOT NULL,
            title      TEXT,
            artist     TEXT,
            album      TEXT,
            genre      TEXT,
            composer   TEXT,
            year       INTEGER,
            duration   INTEGER,
            bitrate    INTEGER,
            sampleRate INTEGER,
            codec      TEXT,
            artwork    BLOB,
            lyrics     TEXT,
            playCount  INTEGER DEFAULT 0,
            rating     INTEGER,
            lastPlayed INTEGER,
            addedAt    INTEGER
        )
    )");
    QSqlQuery migrate(m_db);
    migrate.exec("ALTER TABLE tracks ADD COLUMN lyrics TEXT");
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS artists (
            name              TEXT PRIMARY KEY,
            bio               TEXT,
            bioSummary        TEXT,
            artwork           BLOB,
            lastfmImageUrl    TEXT,
            mbid              TEXT,
            tags              TEXT,
            similarArtists    TEXT,
            listeners         TEXT,
            templates         TEXT,
            customFields      TEXT,
            aliases           TEXT,
            awards            TEXT,
            topChartTracks    TEXT,
            bioUpdateSchedule TEXT,
            lastBioUpdate     INTEGER,
            lastLastfmSync    INTEGER
        )
    )");
    if (q.lastError().isValid())
        qWarning() << "Artists schema error:" << q.lastError().text();

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlists (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            name      TEXT NOT NULL,
            createdAt INTEGER
        )
    )");
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
            track_id    INTEGER NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
            position    INTEGER NOT NULL DEFAULT 0,
            UNIQUE(playlist_id, track_id)
        )
    )");
    q.exec("PRAGMA foreign_keys = ON");
}

bool TrackDatabase::upsertTrack(const QVariantMap &t) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO tracks (path, title, artist, album, genre, composer, year,
            duration, bitrate, sampleRate, codec, artwork, addedAt)
        VALUES (:path,:title,:artist,:album,:genre,:composer,:year,
            :duration,:bitrate,:sampleRate,:codec,:artwork,:addedAt)
        ON CONFLICT(path) DO UPDATE SET
            title=excluded.title, artist=excluded.artist,
            album=excluded.album, genre=excluded.genre,
            composer=excluded.composer, year=excluded.year,
            duration=excluded.duration, bitrate=excluded.bitrate,
            sampleRate=excluded.sampleRate, codec=excluded.codec,
            artwork=COALESCE(excluded.artwork, tracks.artwork)
    )");
    q.bindValue(":path",       t.value("path"));
    q.bindValue(":title",      t.value("title"));
    q.bindValue(":artist",     t.value("artist"));
    q.bindValue(":album",      t.value("album"));
    q.bindValue(":genre",      t.value("genre"));
    q.bindValue(":composer",   t.value("composer"));
    q.bindValue(":year",       t.value("year"));
    q.bindValue(":duration",   t.value("duration"));
    q.bindValue(":bitrate",    t.value("bitrate"));
    q.bindValue(":sampleRate", t.value("sampleRate"));
    q.bindValue(":codec",      t.value("codec"));
    q.bindValue(":artwork",    t.value("artwork"));
    q.bindValue(":addedAt",    QDateTime::currentSecsSinceEpoch());
    if (!q.exec()) {
        qWarning() << "Upsert failed:" << q.lastError().text();
        return false;
    }
    return true;
}

static QVariantMap rowToMap(QSqlQuery &q) {
    QVariantMap m;
    m["id"]         = q.value("id");
    m["path"]       = q.value("path");
    m["title"]      = q.value("title");
    m["artist"]     = q.value("artist");
    m["album"]      = q.value("album");
    m["genre"]      = q.value("genre");
    m["composer"]   = q.value("composer");
    m["year"]       = q.value("year");
    m["duration"]   = q.value("duration");
    m["bitrate"]    = q.value("bitrate");
    m["sampleRate"] = q.value("sampleRate");
    m["codec"]      = q.value("codec");
    m["artwork"]    = q.value("artwork");
    m["lyrics"]     = q.value("lyrics");
    m["playCount"]  = q.value("playCount");
    m["rating"]     = q.value("rating");
    m["lastPlayed"] = q.value("lastPlayed");
    return m;
}

QVariantList TrackDatabase::allTracks(const QString &textFilter,
                                      const QString &artistFilter,
                                      const QString &albumFilter,
                                      bool favsOnly,
                                      const QString &sortCol,
                                      bool sortAsc)
{
    static const QString kCols =
        "id, path, title, artist, album, genre, composer, year, duration, bitrate, sampleRate, codec, playCount, rating, lastPlayed, (artwork IS NOT NULL) as hasArtwork, lyrics";
    QStringList where;
    if (!textFilter.isEmpty())   where << "(title LIKE :tf OR artist LIKE :tf OR album LIKE :tf)";
    if (!artistFilter.isEmpty()) where << "artist = :af";
    if (!albumFilter.isEmpty())  where << "album  = :albf";
    if (favsOnly)                where << "rating = 5";
    static const QStringList kAllowedCols = {"title","artist","album","year","duration","bitrate","playCount","lastPlayed","addedAt"};
    QString col = kAllowedCols.contains(sortCol) ? sortCol : "artist";
    QString order = QString("%1 %2").arg(col, sortAsc ? "ASC" : "DESC");
    if (col != "title") order += ", title ASC";

    QString sql = "SELECT " + kCols + " FROM tracks";
    if (!where.isEmpty()) sql += " WHERE " + where.join(" AND ");
    sql += " ORDER BY " + order;

    QSqlQuery q(m_db);
    q.prepare(sql);
    if (!textFilter.isEmpty())   q.bindValue(":tf",   "%" + textFilter + "%");
    if (!artistFilter.isEmpty()) q.bindValue(":af",   artistFilter);
    if (!albumFilter.isEmpty())  q.bindValue(":albf", albumFilter);
    q.exec();

    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["id"]         = q.value("id");
        m["path"]       = q.value("path");
        m["title"]      = q.value("title");
        m["artist"]     = q.value("artist");
        m["album"]      = q.value("album");
        m["genre"]      = q.value("genre");
        m["composer"]   = q.value("composer");
        m["year"]       = q.value("year");
        m["duration"]   = q.value("duration");
        m["bitrate"]    = q.value("bitrate");
        m["sampleRate"] = q.value("sampleRate");
        m["codec"]      = q.value("codec");
        m["playCount"]  = q.value("playCount");
        m["rating"]     = q.value("rating");
        m["lastPlayed"] = q.value("lastPlayed");
        m["hasArtwork"] = q.value("hasArtwork").toBool();
        m["lyrics"]     = q.value("lyrics");
        list.append(m);
    }
    return list;
}

QVariantList TrackDatabase::allArtists() {
    QSqlQuery q(m_db);
    q.exec("SELECT DISTINCT artist, COUNT(*) as cnt FROM tracks WHERE artist != '' GROUP BY artist ORDER BY artist");
    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["name"]  = q.value(0);
        m["count"] = q.value(1);
        list.append(m);
    }
    return list;
}

QVariantList TrackDatabase::allAlbums() {
    QSqlQuery q(m_db);
    q.exec(R"(
        SELECT album, artist, year, COUNT(*) as cnt,
          (SELECT id FROM tracks t2 WHERE t2.album=tracks.album
           AND t2.artwork IS NOT NULL LIMIT 1) as coverId
        FROM tracks WHERE album != '' GROUP BY album ORDER BY album
    )");
    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["name"]    = q.value("album");
        m["artist"]  = q.value("artist");
        m["year"]    = q.value("year");
        m["count"]   = q.value("cnt");
        m["coverId"] = q.value("coverId");
        list.append(m);
    }
    return list;
}

bool TrackDatabase::updateTrack(int id, const QVariantMap &fields) {
    if (fields.isEmpty()) return false;
    static const QSet<QString> kAllowed = {
        "title","artist","album","genre","composer","year",
        "duration","bitrate","sampleRate","codec","lyrics",
        "rating","playCount","lastPlayed","artwork"
    };
    QStringList sets;
    QVariantMap safe;
    for (auto it = fields.constBegin(); it != fields.constEnd(); ++it) {
        if (!kAllowed.contains(it.key())) continue;
        sets << (it.key() + "=:" + it.key());
        safe.insert(it.key(), it.value());
    }
    if (sets.isEmpty()) return false;
    QSqlQuery q(m_db);
    q.prepare("UPDATE tracks SET " + sets.join(",") + " WHERE id=:id");
    for (auto it = safe.constBegin(); it != safe.constEnd(); ++it)
        q.bindValue(":" + it.key(), it.value());
    q.bindValue(":id", id);
    return q.exec();
}

bool TrackDatabase::deleteTrack(int id) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM tracks WHERE id=:id");
    q.bindValue(":id", id);
    return q.exec() && q.numRowsAffected() > 0;
}

void TrackDatabase::incrementPlayCount(int id) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE tracks SET playCount=playCount+1, lastPlayed=:ts WHERE id=:id");
    q.bindValue(":ts", QDateTime::currentSecsSinceEpoch());
    q.bindValue(":id", id);
    q.exec();
    QSqlQuery r(m_db);
    r.prepare("SELECT playCount FROM tracks WHERE id=:id");
    r.bindValue(":id", id);
    if (r.exec() && r.next())
        emit playCountChanged(id, r.value(0).toInt());
}

void TrackDatabase::toggleFavorite(int id) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE tracks SET rating = CASE WHEN rating=5 THEN 0 ELSE 5 END WHERE id=:id");
    q.bindValue(":id", id);
    q.exec();
}

bool TrackDatabase::saveArtwork(int trackId, const QString &base64DataUrl)
{
    int comma = base64DataUrl.indexOf(',');
    if (comma < 0) return false;
    QString b64 = base64DataUrl.mid(comma + 1);
    QByteArray bytes = QByteArray::fromBase64(b64.toLatin1());
    if (bytes.isEmpty()) return false;

    QSqlQuery q(m_db);
    q.prepare("UPDATE tracks SET artwork=:artwork WHERE id=:id");
    q.bindValue(":artwork", bytes);
    q.bindValue(":id", trackId);
    if (!q.exec()) {
        qWarning() << "saveArtwork failed:" << q.lastError().text();
        return false;
    }
    return true;
}

bool TrackDatabase::writeFileTags(int trackId) {
#ifdef HAVE_TAGLIB
    QVariantMap t = trackById(trackId);
    if (t.isEmpty()) return false;

    QString path = t["path"].toString();
    TagLib::FileRef fr(path.toLocal8Bit().constData(), true, TagLib::AudioProperties::Fast);
    if (fr.isNull() || !fr.tag()) return false;

    auto *tag = fr.tag();
    tag->setTitle(t["title"].toString().toStdWString());
    tag->setArtist(t["artist"].toString().toStdWString());
    tag->setAlbum(t["album"].toString().toStdWString());
    tag->setGenre(t["genre"].toString().toStdWString());
    int y = t["year"].toInt();
    if (y > 0) tag->setYear(static_cast<unsigned int>(y));

    return fr.save();
#else
    Q_UNUSED(trackId)
    return false;
#endif
}

bool TrackDatabase::isFavorite(int id) {
    QSqlQuery q(m_db);
    q.prepare("SELECT rating FROM tracks WHERE id=:id");
    q.bindValue(":id", id);
    q.exec();
    return q.next() && q.value(0).toInt() == 5;
}

QVariantMap TrackDatabase::codecStats() {
    QSqlQuery q(m_db);
    q.exec("SELECT LOWER(codec) as c, COUNT(*) as cnt FROM tracks GROUP BY LOWER(codec) ORDER BY cnt DESC");
    QVariantMap result;
    while (q.next())
        result[q.value("c").toString()] = q.value("cnt");
    return result;
}

QVariantMap TrackDatabase::trackById(int id) {
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM tracks WHERE id=:id");
    q.bindValue(":id", id);
    q.exec();
    if (q.next()) return rowToMap(q);
    return {};
}

QVariantMap TrackDatabase::artistInfo(const QString &name) {
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM artists WHERE name=:name");
    q.bindValue(":name", name);
    q.exec();
    if (!q.next()) return {};
    QVariantMap m;
    m["name"]             = q.value("name");
    m["bio"]              = q.value("bio");
    m["bioSummary"]       = q.value("bioSummary");
    m["artwork"]          = q.value("artwork");
    m["lastfmImageUrl"]   = q.value("lastfmImageUrl");
    m["mbid"]             = q.value("mbid");
    m["listeners"]        = q.value("listeners");
    m["bioUpdateSchedule"] = q.value("bioUpdateSchedule");
    m["lastBioUpdate"]    = q.value("lastBioUpdate");
    m["lastLastfmSync"]   = q.value("lastLastfmSync");
    auto parseJsonArr = [](const QVariant &v) -> QVariantList {
        if (v.isNull() || v.toString().isEmpty()) return {};
        QJsonDocument doc = QJsonDocument::fromJson(v.toString().toUtf8());
        return doc.isArray() ? doc.array().toVariantList() : QVariantList();
    };
    auto parseJsonObj = [](const QVariant &v) -> QVariantMap {
        if (v.isNull() || v.toString().isEmpty()) return {};
        QJsonDocument doc = QJsonDocument::fromJson(v.toString().toUtf8());
        return doc.isObject() ? doc.object().toVariantMap() : QVariantMap();
    };
    m["tags"]            = parseJsonArr(q.value("tags"));
    m["similarArtists"]  = parseJsonArr(q.value("similarArtists"));
    m["templates"]       = parseJsonArr(q.value("templates"));
    m["aliases"]         = parseJsonArr(q.value("aliases"));
    m["awards"]          = parseJsonArr(q.value("awards"));
    m["topChartTracks"]  = parseJsonArr(q.value("topChartTracks"));
    m["customFields"]    = parseJsonObj(q.value("customFields"));
    return m;
}

bool TrackDatabase::updateArtistInfo(const QString &name, const QVariantMap &data) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO artists (name, bio, bioSummary, artwork, lastfmImageUrl, mbid,
            tags, similarArtists, listeners, templates, customFields, aliases,
            awards, topChartTracks, bioUpdateSchedule, lastBioUpdate, lastLastfmSync)
        VALUES (:name, :bio, :bioSummary, :artwork, :lastfmImageUrl, :mbid,
            :tags, :similarArtists, :listeners, :templates, :customFields, :aliases,
            :awards, :topChartTracks, :bioUpdateSchedule, :lastBioUpdate, :lastLastfmSync)
        ON CONFLICT(name) DO UPDATE SET
            bio=excluded.bio, bioSummary=excluded.bioSummary,
            artwork=COALESCE(excluded.artwork, artists.artwork),
            lastfmImageUrl=excluded.lastfmImageUrl, mbid=excluded.mbid,
            tags=excluded.tags, similarArtists=excluded.similarArtists,
            listeners=excluded.listeners, templates=excluded.templates,
            customFields=excluded.customFields, aliases=excluded.aliases,
            awards=excluded.awards, topChartTracks=excluded.topChartTracks,
            bioUpdateSchedule=excluded.bioUpdateSchedule,
            lastBioUpdate=excluded.lastBioUpdate,
            lastLastfmSync=excluded.lastLastfmSync
    )");
    auto toJsonStr = [](const QVariant &v) -> QString {
        if (v.isNull()) return {};
        if (v.typeId() == QMetaType::QString) return v.toString();
        return QString::fromUtf8(QJsonDocument::fromVariant(v).toJson(QJsonDocument::Compact));
    };

    q.bindValue(":name",             name);
    q.bindValue(":bio",              data.value("bio"));
    q.bindValue(":bioSummary",       data.value("bioSummary"));
    q.bindValue(":artwork",          data.value("artwork"));
    q.bindValue(":lastfmImageUrl",   data.value("lastfmImageUrl"));
    q.bindValue(":mbid",             data.value("mbid"));
    q.bindValue(":tags",             toJsonStr(data.value("tags")));
    q.bindValue(":similarArtists",   toJsonStr(data.value("similarArtists")));
    q.bindValue(":listeners",        data.value("listeners"));
    q.bindValue(":templates",        toJsonStr(data.value("templates")));
    q.bindValue(":customFields",     toJsonStr(data.value("customFields")));
    q.bindValue(":aliases",          toJsonStr(data.value("aliases")));
    q.bindValue(":awards",           toJsonStr(data.value("awards")));
    q.bindValue(":topChartTracks",   toJsonStr(data.value("topChartTracks")));
    q.bindValue(":bioUpdateSchedule", data.value("bioUpdateSchedule"));
    q.bindValue(":lastBioUpdate",    data.value("lastBioUpdate").toLongLong());
    q.bindValue(":lastLastfmSync",   data.value("lastLastfmSync").toLongLong());

    if (!q.exec()) {
        qWarning() << "Artist upsert failed:" << q.lastError().text();
        return false;
    }
    return true;
}

QVariantList TrackDatabase::allArtistsWithInfo() {
    QSqlQuery q(m_db);
    q.exec(R"(
        SELECT a.name, a.bio, a.lastfmImageUrl, a.mbid,
               COALESCE((SELECT COUNT(*) FROM tracks t WHERE t.artist = a.name), 0) as trackCount
        FROM artists a ORDER BY a.name
    )");
    QVariantList list;
    while (q.next()) {
        QVariantMap m;
        m["name"]           = q.value("name");
        m["bio"]            = q.value("bio");
        m["lastfmImageUrl"] = q.value("lastfmImageUrl");
        m["mbid"]           = q.value("mbid");
        m["trackCount"]     = q.value("trackCount");
        list.append(m);
    }
    return list;
}

int TrackDatabase::artistCount() {
    QSqlQuery q(m_db);
    q.exec("SELECT COUNT(*) FROM artists");
    return q.next() ? q.value(0).toInt() : 0;
}

QByteArray TrackDatabase::artworkBlob(int trackId) {
    QSqlQuery q(m_db);
    q.prepare("SELECT artwork FROM tracks WHERE id=:id");
    q.bindValue(":id", trackId);
    return (q.exec() && q.next()) ? q.value(0).toByteArray() : QByteArray();
}
