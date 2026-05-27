#include <QtTest>
#include <QTemporaryDir>
#include <QStandardPaths>

// Point the database at a temp dir so tests don't touch the real library
#include "../src/backend/TrackDatabase.h"

class tst_TrackDatabase : public QObject {
    Q_OBJECT

private:
    QTemporaryDir m_dir;
    TrackDatabase *m_db = nullptr;

    QVariantMap makeTrack(const QString &path,
                          const QString &title  = "Test Track",
                          const QString &artist = "Test Artist",
                          const QString &album  = "Test Album",
                          int year = 2024) {
        QVariantMap t;
        t["path"]   = path;
        t["title"]  = title;
        t["artist"] = artist;
        t["album"]  = album;
        t["year"]   = year;
        t["codec"]  = "FLAC";
        t["addedAt"] = (qint64)QDateTime::currentSecsSinceEpoch();
        return t;
    }

private slots:
    void initTestCase() {
        QVERIFY(m_dir.isValid());
        // Override the app data dir so TrackDatabase writes to temp location
        QStandardPaths::setTestModeEnabled(true);
        m_db = new TrackDatabase(this);
        QVERIFY(m_db->open());
    }

    void cleanupTestCase() {
        delete m_db;
        m_db = nullptr;
        QStandardPaths::setTestModeEnabled(false);
    }

    void test_upsertAndRetrieve() {
        QVariantMap t = makeTrack("/music/test1.flac", "Hello World", "Artist A", "Album X", 2020);
        QVERIFY(m_db->upsertTrack(t));

        QVariantMap r = m_db->trackById(-1); // invalid id — should be empty
        QVERIFY(r.isEmpty());

        QVariantList all = m_db->allTracks();
        QVERIFY(!all.isEmpty());
        QVariantMap first = all.first().toMap();
        QCOMPARE(first["title"].toString(),  QStringLiteral("Hello World"));
        QCOMPARE(first["artist"].toString(), QStringLiteral("Artist A"));
        QCOMPARE(first["year"].toInt(),      2020);
    }

    void test_upsertIsDeduplicated() {
        // Insert same path twice — count should not increase
        QVariantMap t = makeTrack("/music/dedup.flac", "Track A", "Artist B", "Album Y");
        QVERIFY(m_db->upsertTrack(t));
        int countBefore = m_db->allTracks().size();

        // Upsert again with updated title
        t["title"] = "Track A Updated";
        QVERIFY(m_db->upsertTrack(t));
        int countAfter = m_db->allTracks().size();

        QCOMPARE(countAfter, countBefore); // no duplicate

        // Find the track — should have updated title
        QVariantList all = m_db->allTracks();
        bool found = false;
        for (const QVariant &v : all) {
            QVariantMap m = v.toMap();
            if (m["path"].toString() == "/music/dedup.flac") {
                QCOMPARE(m["title"].toString(), QStringLiteral("Track A Updated"));
                found = true;
                break;
            }
        }
        QVERIFY(found);
    }

    void test_updateTrack() {
        QVariantMap t = makeTrack("/music/update_test.flac", "Original", "Artist C", "Album Z");
        QVERIFY(m_db->upsertTrack(t));

        // Find its id
        int id = -1;
        for (const QVariant &v : m_db->allTracks()) {
            QVariantMap m = v.toMap();
            if (m["path"].toString() == "/music/update_test.flac") {
                id = m["id"].toInt();
                break;
            }
        }
        QVERIFY(id > 0);

        QVariantMap fields;
        fields["title"]  = "Updated Title";
        fields["genre"]  = "Jazz";
        QVERIFY(m_db->updateTrack(id, fields));

        QVariantMap r = m_db->trackById(id);
        QCOMPARE(r["title"].toString(), QStringLiteral("Updated Title"));
        QCOMPARE(r["genre"].toString(), QStringLiteral("Jazz"));
    }

    void test_toggleFavorite() {
        QVariantMap t = makeTrack("/music/fav_test.flac", "Fav Track", "Artist D", "Album W");
        QVERIFY(m_db->upsertTrack(t));

        int id = -1;
        for (const QVariant &v : m_db->allTracks()) {
            QVariantMap m = v.toMap();
            if (m["path"].toString() == "/music/fav_test.flac") {
                id = m["id"].toInt();
                break;
            }
        }
        QVERIFY(id > 0);

        QVERIFY(!m_db->isFavorite(id));
        m_db->toggleFavorite(id);
        QVERIFY(m_db->isFavorite(id));
        m_db->toggleFavorite(id);
        QVERIFY(!m_db->isFavorite(id));
    }

    void test_incrementPlayCount() {
        QVariantMap t = makeTrack("/music/play_test.flac", "Play Track", "Artist E", "Album V");
        QVERIFY(m_db->upsertTrack(t));

        int id = -1;
        for (const QVariant &v : m_db->allTracks()) {
            QVariantMap m = v.toMap();
            if (m["path"].toString() == "/music/play_test.flac") {
                id = m["id"].toInt();
                break;
            }
        }
        QVERIFY(id > 0);

        int initial = m_db->trackById(id)["playCount"].toInt();

        QSignalSpy spy(m_db, &TrackDatabase::playCountChanged);
        m_db->incrementPlayCount(id);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toInt(), id);
        QCOMPARE(spy.at(0).at(1).toInt(), initial + 1);

        m_db->incrementPlayCount(id);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(spy.at(1).at(1).toInt(), initial + 2);
    }

    void test_deleteTrack() {
        QVariantMap t = makeTrack("/music/delete_test.flac", "Delete Track", "Artist F", "Album U");
        QVERIFY(m_db->upsertTrack(t));

        int id = -1;
        for (const QVariant &v : m_db->allTracks()) {
            QVariantMap m = v.toMap();
            if (m["path"].toString() == "/music/delete_test.flac") {
                id = m["id"].toInt();
                break;
            }
        }
        QVERIFY(id > 0);

        QVERIFY(m_db->deleteTrack(id));
        QVERIFY(m_db->trackById(id).isEmpty());

        // deleteTrack on already-deleted id should return false
        QVERIFY(!m_db->deleteTrack(id));
    }

    void test_codecStats() {
        QVariantMap t1 = makeTrack("/music/codec1.flac"); t1["codec"] = "FLAC";
        QVariantMap t2 = makeTrack("/music/codec2.mp3");  t2["codec"] = "MP3";
        QVariantMap t3 = makeTrack("/music/codec3.mp3");  t3["codec"] = "MP3";
        m_db->upsertTrack(t1);
        m_db->upsertTrack(t2);
        m_db->upsertTrack(t3);

        QVariantMap stats = m_db->codecStats();
        QVERIFY(stats.contains("mp3"));
        QVERIFY(stats["mp3"].toInt() >= 2);
    }

    void test_allTracksTextFilter() {
        QVariantMap t = makeTrack("/music/filter_test.flac", "Unique XYZ Title", "Filter Artist", "Filter Album");
        QVERIFY(m_db->upsertTrack(t));

        QVariantList results = m_db->allTracks("Unique XYZ");
        QVERIFY(!results.isEmpty());
        bool found = false;
        for (const QVariant &v : results) {
            if (v.toMap()["title"].toString().contains("Unique XYZ")) { found = true; break; }
        }
        QVERIFY(found);

        QVariantList noResults = m_db->allTracks("ZZZNOMATCH999");
        QVERIFY(noResults.isEmpty());
    }
};

QTEST_MAIN(tst_TrackDatabase)
#include "tst_TrackDatabase.moc"
