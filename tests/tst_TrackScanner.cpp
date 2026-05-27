#include <QtTest>
#include <QTemporaryDir>
#include <QStandardPaths>
#include <QSignalSpy>
#include <QFile>

#include "../src/backend/TrackDatabase.h"
#include "../src/backend/TrackScanner.h"

class tst_TrackScanner : public QObject {
    Q_OBJECT

private:
    QTemporaryDir  m_tempDir;
    TrackDatabase *m_db      = nullptr;
    TrackScanner  *m_scanner = nullptr;

    QString makeFile(const QString &name, const QByteArray &content = "FAKEFAKE") {
        QString p = m_tempDir.filePath(name);
        QFile f(p);
        f.open(QIODevice::WriteOnly);
        f.write(content);
        f.close();
        return p;
    }

private slots:
    void initTestCase() {
        QVERIFY(m_tempDir.isValid());
        QStandardPaths::setTestModeEnabled(true);
        m_db = new TrackDatabase(this);
        QVERIFY(m_db->open());
        m_scanner = new TrackScanner(m_db, this);
        QVERIFY(m_scanner);

        // Start with a clean folder list in test mode
        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList());
    }

    void cleanupTestCase() {
        delete m_scanner; m_scanner = nullptr;
        delete m_db;      m_db      = nullptr;
        QStandardPaths::setTestModeEnabled(false);
    }

    // ── Folder management ───────────────────────────────────────────────────

    void test_initialFoldersEmpty() {
        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList());
        QVERIFY(m_scanner->scanFolders().isEmpty());
    }

    void test_removeFolderDoesNothing_whenNotPresent() {
        // Should not crash or change anything
        m_scanner->removeFolder("/nonexistent/path");
        QVERIFY(true);
    }

    void test_removeFolderEmitsSignal() {
        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList() << m_tempDir.path());

        QSignalSpy spy(m_scanner, &TrackScanner::foldersChanged);
        m_scanner->removeFolder(m_tempDir.path());
        QCOMPARE(spy.count(), 1);
        QVERIFY(m_scanner->scanFolders().isEmpty());
    }

    void test_removeFolderOnlyRemovesTarget() {
        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList() << "/music/a" << "/music/b" << "/music/c");

        m_scanner->removeFolder("/music/b");

        QStringList remaining = m_scanner->scanFolders();
        QVERIFY(!remaining.contains("/music/b"));
        QVERIFY(remaining.contains("/music/a"));
        QVERIFY(remaining.contains("/music/c"));

        // Restore
        s.setValue("musicDirs", QStringList());
    }

    // ── Scan ────────────────────────────────────────────────────────────────

    void test_rescanAllDoesNotCrashWithNoFolders() {
        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList());
        m_scanner->rescanAll();   // fire-and-forget; must not crash or hang
        QVERIFY(true);
    }

    void test_scanDirectoryEmitsSignals() {
        // Create a few fake audio files (extension only — no TAGLIB needed)
        makeFile("track1.flac");
        makeFile("track2.mp3");
        makeFile("not_audio.txt");

        QSignalSpy progress(m_scanner, &TrackScanner::scanProgress);
        QSignalSpy complete(m_scanner, &TrackScanner::scanComplete);

        m_scanner->scanDirectory(m_tempDir.path());

        QTRY_COMPARE_WITH_TIMEOUT(complete.count(), 1, 5000);
        QVERIFY(!progress.isEmpty());

        // Last progress signal: done == total
        QList<QVariant> last = progress.last();
        QCOMPARE(last[0].toInt(), last[1].toInt());
    }

    void test_scanDirectoryAddsTracksToDB() {
        // Fresh temp dir with known files
        QTemporaryDir d;
        QVERIFY(d.isValid());
        QFile f1(d.filePath("alpha.flac")); f1.open(QIODevice::WriteOnly); f1.write("X"); f1.close();
        QFile f2(d.filePath("beta.ogg"));  f2.open(QIODevice::WriteOnly); f2.write("X"); f2.close();

        int before = m_db->allTracks().size();

        QSignalSpy complete(m_scanner, &TrackScanner::scanComplete);
        m_scanner->scanDirectory(d.path());
        QTRY_COMPARE_WITH_TIMEOUT(complete.count(), 1, 5000);

        int after = m_db->allTracks().size();
        QVERIFY(after >= before + 2);
    }

    void test_scanDirectoryIgnoresNonAudioFiles() {
        QTemporaryDir d;
        QVERIFY(d.isValid());
        QFile f1(d.filePath("readme.txt")); f1.open(QIODevice::WriteOnly); f1.write("X"); f1.close();
        QFile f2(d.filePath("image.jpg"));  f2.open(QIODevice::WriteOnly); f2.write("X"); f2.close();
        QFile f3(d.filePath("song.mp3"));   f3.open(QIODevice::WriteOnly); f3.write("X"); f3.close();

        int before = m_db->allTracks().size();
        QSignalSpy complete(m_scanner, &TrackScanner::scanComplete);
        m_scanner->scanDirectory(d.path());
        QTRY_COMPARE_WITH_TIMEOUT(complete.count(), 1, 5000);

        // Only .mp3 should be added (txt and jpg skipped)
        int after = m_db->allTracks().size();
        QVERIFY(after == before + 1);
    }

    void test_rescanAllScansStoredFolders() {
        QTemporaryDir d;
        QVERIFY(d.isValid());
        QFile f(d.filePath("rescan.flac")); f.open(QIODevice::WriteOnly); f.write("X"); f.close();

        QSettings s("Auradec", "Auradec");
        s.setValue("musicDirs", QStringList() << d.path());

        int before = m_db->allTracks().size();
        QSignalSpy complete(m_scanner, &TrackScanner::scanComplete);
        m_scanner->rescanAll();
        QTRY_COMPARE_WITH_TIMEOUT(complete.count(), 1, 5000);

        QVERIFY(m_db->allTracks().size() > before);

        s.setValue("musicDirs", QStringList());
    }
};

QTEST_MAIN(tst_TrackScanner)
#include "tst_TrackScanner.moc"
