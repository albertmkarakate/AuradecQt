#include <QtTest>
#include <QStandardPaths>
#include <QTemporaryDir>
#include "../src/backend/TrackDatabase.h"
#include "../src/backend/LibraryModel.h"

class tst_LibraryModel : public QObject {
    Q_OBJECT

private:
    QTemporaryDir  m_dir;
    TrackDatabase *m_db    = nullptr;
    LibraryModel  *m_model = nullptr;

    void insert(const QString &path, const QString &title,
                const QString &artist, const QString &album, int year = 2020) {
        QVariantMap t;
        t["path"]   = path;
        t["title"]  = title;
        t["artist"] = artist;
        t["album"]  = album;
        t["year"]   = year;
        t["codec"]  = "FLAC";
        t["addedAt"] = (qint64)QDateTime::currentSecsSinceEpoch();
        m_db->upsertTrack(t);
    }

private slots:
    void initTestCase() {
        QVERIFY(m_dir.isValid());
        QStandardPaths::setTestModeEnabled(true);
        m_db = new TrackDatabase(this);
        QVERIFY(m_db->open());
        m_model = new LibraryModel(m_db, this);

        insert("/m/a.flac", "Alpha",   "Zebra",  "Zoo",    2018);
        insert("/m/b.flac", "Beta",    "Apple",  "Barn",   2020);
        insert("/m/c.flac", "Gamma",   "Apple",  "Barn",   2022);
        insert("/m/d.flac", "Delta",   "Mango",  "Market", 2015);
        m_model->doReload();
    }

    void cleanupTestCase() {
        delete m_model;
        delete m_db;
        QStandardPaths::setTestModeEnabled(false);
    }

    void test_initialCount() {
        QVERIFY(m_model->rowCount() >= 4);
    }

    void test_textFilter() {
        m_model->setFilter("Alpha");
        QCOMPARE(m_model->rowCount(), 1);
        QCOMPARE(m_model->data(m_model->index(0), LibraryModel::TitleRole).toString(),
                 QStringLiteral("Alpha"));
        m_model->clearFilters();
    }

    void test_artistFilter() {
        m_model->setArtistFilter("Apple");
        QVERIFY(m_model->rowCount() >= 2);
        for (int i = 0; i < m_model->rowCount(); ++i) {
            QCOMPARE(m_model->data(m_model->index(i), LibraryModel::ArtistRole).toString(),
                     QStringLiteral("Apple"));
        }
        m_model->clearFilters();
    }

    void test_albumFilter() {
        m_model->setAlbumFilter("Barn");
        QVERIFY(m_model->rowCount() >= 2);
        for (int i = 0; i < m_model->rowCount(); ++i) {
            QCOMPARE(m_model->data(m_model->index(i), LibraryModel::AlbumRole).toString(),
                     QStringLiteral("Barn"));
        }
        m_model->clearFilters();
    }

    void test_clearFilters() {
        m_model->setFilter("Alpha");
        QCOMPARE(m_model->rowCount(), 1);
        m_model->clearFilters();
        QVERIFY(m_model->rowCount() >= 4);
    }

    void test_sortByTitle() {
        m_model->setSort("title", true);
        QString prev;
        for (int i = 0; i < m_model->rowCount(); ++i) {
            QString cur = m_model->data(m_model->index(i), LibraryModel::TitleRole).toString();
            if (!prev.isEmpty()) QVERIFY(cur >= prev);
            prev = cur;
        }
        m_model->clearFilters();
    }

    void test_sortByYear_desc() {
        m_model->setSort("year", false);
        int prev = INT_MAX;
        for (int i = 0; i < m_model->rowCount(); ++i) {
            int cur = m_model->data(m_model->index(i), LibraryModel::YearRole).toInt();
            QVERIFY(cur <= prev);
            prev = cur;
        }
        m_model->clearFilters();
    }

    void test_snapshot() {
        QVariantList snap = m_model->snapshot();
        QCOMPARE(snap.size(), m_model->rowCount());
    }

    void test_updatePlayCountSignal() {
        QVariantList snap = m_model->snapshot();
        QVERIFY(!snap.isEmpty());
        int trackId = snap.first().toMap()["id"].toInt();
        QVERIFY(trackId > 0);

        QSignalSpy spy(m_model, &LibraryModel::dataChanged);
        m_model->updatePlayCount(trackId, 42);
        QCOMPARE(spy.count(), 1);

        // Verify the model returns the updated count
        bool found = false;
        for (int i = 0; i < m_model->rowCount(); ++i) {
            if (m_model->data(m_model->index(i), LibraryModel::IdRole).toInt() == trackId) {
                QCOMPARE(m_model->data(m_model->index(i), LibraryModel::PlayCountRole).toInt(), 42);
                found = true;
                break;
            }
        }
        QVERIFY(found);
    }
};

QTEST_MAIN(tst_LibraryModel)
#include "tst_LibraryModel.moc"
