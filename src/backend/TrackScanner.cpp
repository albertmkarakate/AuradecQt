#include "TrackScanner.h"
#include "TrackDatabase.h"
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QThread>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QtConcurrent/QtConcurrent>
#include <QVariantMap>
#include <QDateTime>
#include <QFileDialog>
#include <QSettings>
#include <QFile>
#include <QDebug>

#ifdef HAVE_TAGLIB
#include <taglib/fileref.h>
#include <taglib/tag.h>
#include <taglib/tpropertymap.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <taglib/flacfile.h>
#include <taglib/vorbisfile.h>
#include <taglib/opusfile.h>
#include <taglib/aifffile.h>
#include <taglib/wavfile.h>
#include <taglib/mp4file.h>
#include <taglib/mp4tag.h>
#include <taglib/mp4coverart.h>
#include <taglib/xiphcomment.h>
#endif

static const QStringList kAudioExts = {
    "mp3","flac","ogg","opus","m4a","aac","wav","aiff","wv","ape","wma","alac"
};

TrackScanner::TrackScanner(TrackDatabase *db, QObject *parent)
    : QObject(parent), m_db(db) {}

void TrackScanner::cancel() { m_cancel.storeRelaxed(1); }

QStringList TrackScanner::loadFolders() {
    QSettings s("Auradec", "Auradec");
    QStringList folders = s.value("musicDirs").toStringList();
    if (folders.isEmpty()) {
        QString legacy = s.value("lastMusicDir").toString();
        if (!legacy.isEmpty()) {
            folders << legacy;
            s.setValue("musicDirs", folders);
        }
    }
    return folders;
}

void TrackScanner::saveFolders(const QStringList &folders) {
    QSettings s("Auradec", "Auradec");
    s.setValue("musicDirs", folders);
}

QStringList TrackScanner::scanFolders() const {
    return loadFolders();
}

void TrackScanner::removeFolder(const QString &path) {
    QStringList folders = loadFolders();
    folders.removeAll(path);
    saveFolders(folders);
    emit foldersChanged();
}

void TrackScanner::pickAndScan() {
    QStringList folders = loadFolders();
    QString startDir = folders.isEmpty() ? QDir::homePath() : folders.last();
    QString dir = QFileDialog::getExistingDirectory(
        nullptr,
        "Choose Music Folder",
        startDir,
        QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks
    );
    if (!dir.isEmpty()) {
        if (!folders.contains(dir)) {
            folders << dir;
            saveFolders(folders);
            emit foldersChanged();
        }
        scanDirectory(dir);
    }
}

void TrackScanner::rescanAll() {
    QStringList folders = loadFolders();
    for (const QString &dir : folders) {
        if (QDir(dir).exists())
            scanDirectory(dir);
    }
}

QStringList TrackScanner::collectFiles(const QString &dir) {
    QStringList files;
    QDirIterator it(dir, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString p = it.next();
        if (kAudioExts.contains(QFileInfo(p).suffix().toLower()))
            files << p;
    }
    return files;
}

#ifdef HAVE_TAGLIB
static QByteArray extractArtwork(const QString &path) {
    TagLib::FileRef fr(path.toLocal8Bit().constData());
    if (fr.isNull()) return {};

    // MP3 — ID3v2 APIC frame
    if (auto *f = dynamic_cast<TagLib::MPEG::File*>(fr.file())) {
        if (f->ID3v2Tag()) {
            auto frames = f->ID3v2Tag()->frameListMap()["APIC"];
            if (!frames.isEmpty()) {
                auto *pic = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frames.front());
                if (pic) return QByteArray(pic->picture().data(), pic->picture().size());
            }
        }
    }
    // FLAC — picture list
    else if (auto *f = dynamic_cast<TagLib::FLAC::File*>(fr.file())) {
        if (!f->pictureList().isEmpty())
            return QByteArray(f->pictureList().front()->data().data(),
                              f->pictureList().front()->data().size());
    }
    // M4A / AAC / ALAC — MP4 covr atom
    else if (auto *f = dynamic_cast<TagLib::MP4::File*>(fr.file())) {
        if (f->tag()) {
            const auto &items = f->tag()->itemMap();
            if (items.contains("covr")) {
                auto covers = items["covr"].toCoverArtList();
                if (!covers.isEmpty())
                    return QByteArray(covers.front().data().data(), covers.front().data().size());
            }
        }
    }
    // OGG Vorbis / Opus — METADATA_BLOCK_PICTURE in Xiph comment
    else if (auto *f = dynamic_cast<TagLib::Ogg::Vorbis::File*>(fr.file())) {
        if (f->tag() && !f->tag()->pictureList().isEmpty())
            return QByteArray(f->tag()->pictureList().front()->data().data(),
                              f->tag()->pictureList().front()->data().size());
    }
    else if (auto *f = dynamic_cast<TagLib::Ogg::Opus::File*>(fr.file())) {
        if (f->tag() && !f->tag()->pictureList().isEmpty())
            return QByteArray(f->tag()->pictureList().front()->data().data(),
                              f->tag()->pictureList().front()->data().size());
    }
    return {};
}

static QByteArray folderArtwork(const QString &trackPath) {
    static const QStringList kNames = {
        "cover.jpg","cover.jpeg","cover.png",
        "folder.jpg","folder.jpeg","folder.png",
        "front.jpg","front.jpeg","front.png",
        "artwork.jpg","artwork.jpeg","artwork.png",
        "albumart.jpg","albumart.png"
    };
    QDir dir = QFileInfo(trackPath).dir();
    for (const QString &name : kNames) {
        QString p = dir.filePath(name);
        if (QFile::exists(p)) {
            QFile f(p);
            if (f.open(QIODevice::ReadOnly))
                return f.readAll();
        }
    }
    return {};
}
#endif

void TrackScanner::scanDirectory(const QString &path) {
    m_cancel.storeRelaxed(0);
    QString dbPath = m_db->databasePath();
    QtConcurrent::run([this, path, dbPath]() {
        // Per-thread DB connection — QSqlDatabase is not thread-safe to share
        QString connName = QStringLiteral("auradec_scan_%1")
                           .arg((quintptr)QThread::currentThreadId(), 0, 16);
        {
            QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connName);
            db.setDatabaseName(dbPath);
            if (!db.open()) {
                emit scanComplete(0);
                QSqlDatabase::removeDatabase(connName);
                return;
            }
            QSqlQuery pragma(db);
            pragma.exec("PRAGMA journal_mode=WAL");
            pragma.exec("PRAGMA synchronous=NORMAL");

            QStringList files = collectFiles(path);
            int total = files.size();
            int added = 0;

            for (int i = 0; i < total; ++i) {
                if (m_cancel.loadRelaxed()) break;

                const QString &fp = files[i];
                QVariantMap t;
                t["path"] = fp;

                QFileInfo fi(fp);
                t["codec"] = fi.suffix().toUpper();

#ifdef HAVE_TAGLIB
                TagLib::FileRef fr(fp.toLocal8Bit().constData());
                if (!fr.isNull() && fr.tag()) {
                    auto *tag = fr.tag();
                    t["title"]  = QString::fromStdWString(tag->title().toWString());
                    t["artist"] = QString::fromStdWString(tag->artist().toWString());
                    t["album"]  = QString::fromStdWString(tag->album().toWString());
                    t["genre"]  = QString::fromStdWString(tag->genre().toWString());
                    t["year"]   = (int)tag->year();
                }
                if (!fr.isNull() && fr.audioProperties()) {
                    auto *ap = fr.audioProperties();
                    t["duration"]   = ap->lengthInMilliseconds();
                    t["bitrate"]    = ap->bitrate();
                    t["sampleRate"] = ap->sampleRate();
                }
                QByteArray art = extractArtwork(fp);
                if (art.isEmpty()) art = folderArtwork(fp);
                if (!art.isEmpty()) t["artwork"] = art;
#endif
                if (t.value("title").toString().isEmpty())
                    t["title"] = fi.baseName();

                // Upsert inline using per-thread connection
                QSqlQuery q(db);
                q.prepare(R"(
                    INSERT INTO tracks (path,title,artist,album,genre,year,
                        duration,bitrate,sampleRate,codec,artwork,addedAt)
                    VALUES (:path,:title,:artist,:album,:genre,:year,
                        :duration,:bitrate,:sampleRate,:codec,:artwork,:addedAt)
                    ON CONFLICT(path) DO UPDATE SET
                        title=excluded.title, artist=excluded.artist,
                        album=excluded.album, genre=excluded.genre,
                        year=excluded.year, duration=excluded.duration,
                        bitrate=excluded.bitrate, sampleRate=excluded.sampleRate,
                        codec=excluded.codec,
                        artwork=COALESCE(excluded.artwork, tracks.artwork)
                )");
                q.bindValue(":path",       t["path"]);
                q.bindValue(":title",      t["title"]);
                q.bindValue(":artist",     t.value("artist"));
                q.bindValue(":album",      t.value("album"));
                q.bindValue(":genre",      t.value("genre"));
                q.bindValue(":year",       t.value("year"));
                q.bindValue(":duration",   t.value("duration"));
                q.bindValue(":bitrate",    t.value("bitrate"));
                q.bindValue(":sampleRate", t.value("sampleRate"));
                q.bindValue(":codec",      t.value("codec"));
                q.bindValue(":artwork",    t.value("artwork"));
                q.bindValue(":addedAt",    QDateTime::currentSecsSinceEpoch());
                if (q.exec()) ++added;

                if (i % 20 == 0)
                    emit scanProgress(i + 1, total);
            }

            emit scanProgress(total, total);
            db.close();
            emit scanComplete(added);
        }
        QSqlDatabase::removeDatabase(connName);
    });
}
