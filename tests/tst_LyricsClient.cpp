#include <QtTest>
#include <QSignalSpy>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QBuffer>

#include "../src/backend/LyricsClient.h"

// ── Fake network reply ──────────────────────────────────────────────────────

class FakeReply : public QNetworkReply {
    Q_OBJECT
public:
    FakeReply(QObject *parent, const QByteArray &data, int httpStatus = 200)
        : QNetworkReply(parent), m_data(data)
    {
        setAttribute(QNetworkRequest::HttpStatusCodeAttribute, httpStatus);
        if (httpStatus >= 400) {
            setError(QNetworkReply::ContentNotFoundError, "Not found");
        }
        open(QIODevice::ReadOnly);
        QMetaObject::invokeMethod(this, "emitFinished", Qt::QueuedConnection);
    }
    void abort() override {}
    qint64 bytesAvailable() const override { return m_data.size() - m_pos; }
protected:
    qint64 readData(char *data, qint64 maxSize) override {
        qint64 n = qMin(maxSize, (qint64)(m_data.size() - m_pos));
        if (n <= 0) return 0;
        memcpy(data, m_data.constData() + m_pos, n);
        m_pos += n;
        return n;
    }
private slots:
    void emitFinished() { emit finished(); }
private:
    QByteArray m_data;
    int        m_pos = 0;
};

// ── Fake NAM — returns preset response for next request ─────────────────────

class FakeNam : public QNetworkAccessManager {
    Q_OBJECT
public:
    explicit FakeNam(QObject *parent = nullptr) : QNetworkAccessManager(parent) {}
    void setNextResponse(const QByteArray &data, int status = 200) {
        m_nextData   = data;
        m_nextStatus = status;
        m_callCount  = 0;
    }
    int callCount() const { return m_callCount; }
    QUrl lastUrl() const  { return m_lastUrl; }
protected:
    QNetworkReply *createRequest(Operation, const QNetworkRequest &req, QIODevice *) override {
        ++m_callCount;
        m_lastUrl = req.url();
        return new FakeReply(this, m_nextData, m_nextStatus);
    }
private:
    QByteArray m_nextData;
    int        m_nextStatus = 200;
    int        m_callCount  = 0;
    QUrl       m_lastUrl;
};

// ── Test class ──────────────────────────────────────────────────────────────

class tst_LyricsClient : public QObject {
    Q_OBJECT

private:
    LyricsClient *m_client = nullptr;
    FakeNam      *m_nam    = nullptr;

private slots:
    void init() {
        m_client = new LyricsClient(this);
        m_nam    = new FakeNam(this);
        m_client->setNetworkManager(m_nam);
    }

    void cleanup() {
        delete m_client; m_client = nullptr;
        // m_nam deleted via parent chain above
    }

    // ── Initial state ────────────────────────────────────────────────────────

    void test_initialState() {
        QVERIFY(!m_client->busy());
        QCOMPARE(m_client->statusText(), QString());
        QVERIFY(!m_client->spotifyConfigured());
    }

    // ── setSpotifyToken ──────────────────────────────────────────────────────

    void test_setSpotifyToken_setsConfigured() {
        QSignalSpy spy(m_client, &LyricsClient::spotifyConfiguredChanged);
        m_client->setSpotifyToken("fake-sp-dc-token");
        QCOMPARE(spy.count(), 1);
        QVERIFY(m_client->spotifyConfigured());
    }

    void test_setSpotifyToken_clearUnconfigures() {
        m_client->setSpotifyToken("fake-sp-dc-token");
        QSignalSpy spy(m_client, &LyricsClient::spotifyConfiguredChanged);
        m_client->setSpotifyToken("");
        QCOMPARE(spy.count(), 1);
        QVERIFY(!m_client->spotifyConfigured());
    }

    void test_setSpotifyToken_noDuplicateSignal() {
        m_client->setSpotifyToken("tok");
        QSignalSpy spy(m_client, &LyricsClient::spotifyConfiguredChanged);
        m_client->setSpotifyToken("tok");  // same value — no signal
        QCOMPARE(spy.count(), 0);
    }

    // ── cancelFetch ──────────────────────────────────────────────────────────

    void test_cancelWhenIdle_doesNotCrash() {
        m_client->cancelFetch();
        QVERIFY(!m_client->busy());
    }

    void test_cancelAfterFetch_clearsBusy() {
        QByteArray json = R"({"plainLyrics":"","syncedLyrics":"","instrumental":false})";
        m_nam->setNextResponse(json);

        m_client->fetchLyrics("Artist", "Title");
        QVERIFY(m_client->busy());

        m_client->cancelFetch();
        QVERIFY(!m_client->busy());
    }

    // ── fetchLyrics error paths ──────────────────────────────────────────────

    void test_fetchLyrics_emptyArtistTitle_emitsError() {
        // Empty artist+title: no network call, immediate error
        m_nam->setNextResponse(QByteArray());

        QSignalSpy errSpy(m_client, &LyricsClient::fetchError);
        m_client->fetchLyrics("", "");
        QCOMPARE(m_nam->callCount(), 0);
        QCOMPARE(errSpy.count(), 1);
    }

    void test_fetchLyrics_networkError_triesFallback() {
        // First call: LRCLIB fails (404), second: OVH fails (404), no Spotify
        m_nam->setNextResponse(QByteArray(), 404);

        QSignalSpy errSpy(m_client, &LyricsClient::fetchError);
        m_client->fetchLyrics("Artist", "Song");

        // Two network calls (LRCLIB → OVH), then error
        QTRY_COMPARE_WITH_TIMEOUT(errSpy.count(), 1, 3000);
        QVERIFY(errSpy.at(0).at(0).toString().contains("exhaust", Qt::CaseInsensitive)
             || errSpy.at(0).at(0).toString().contains("source", Qt::CaseInsensitive));
    }

    // ── LRCLIB response parsing ───────────────────────────────────────────────

    void test_lrclibSuccess_emitsLyricsReady() {
        QByteArray json = R"({
            "plainLyrics": "Hello world\nSecond line",
            "syncedLyrics": "[00:01.00]Hello world\n[00:03.50]Second line",
            "instrumental": false
        })";
        m_nam->setNextResponse(json);

        QSignalSpy readySpy(m_client, &LyricsClient::lyricsReady);
        m_client->fetchLyrics("Artist", "Song");

        QTRY_COMPARE_WITH_TIMEOUT(readySpy.count(), 1, 3000);
        QCOMPARE(readySpy.at(0).at(0).toString(), QStringLiteral("Hello world\nSecond line"));
        QCOMPARE(readySpy.at(0).at(2).toString(), QStringLiteral("LRCLIB"));
        QVERIFY(!m_client->busy());
    }

    void test_lrclibInstrumental_emitsEmptyLyrics() {
        QByteArray json = R"({"instrumental": true})";
        m_nam->setNextResponse(json);

        QSignalSpy readySpy(m_client, &LyricsClient::lyricsReady);
        m_client->fetchLyrics("Artist", "Song");

        QTRY_COMPARE_WITH_TIMEOUT(readySpy.count(), 1, 3000);
        QCOMPARE(readySpy.at(0).at(0).toString(), QString());
        QCOMPARE(readySpy.at(0).at(2).toString(), QStringLiteral("LRCLIB"));
    }

    void test_lrclibEmptyLyrics_fallsThrough() {
        // LRCLIB returns empty lyrics → should try next source (OVH fails)
        QByteArray json = R"({"plainLyrics": "", "syncedLyrics": "", "instrumental": false})";
        m_nam->setNextResponse(json);

        QSignalSpy errSpy(m_client, &LyricsClient::fetchError);
        m_client->fetchLyrics("Artist", "Song");

        // Ends in error (OVH also gets empty JSON)
        QTRY_COMPARE_WITH_TIMEOUT(errSpy.count(), 1, 3000);
        QVERIFY(m_nam->callCount() >= 2);
    }

    void test_lrclibBadJson_fallsThrough() {
        m_nam->setNextResponse(QByteArray("not json at all"));

        QSignalSpy errSpy(m_client, &LyricsClient::fetchError);
        m_client->fetchLyrics("Artist", "Song");

        QTRY_COMPARE_WITH_TIMEOUT(errSpy.count(), 1, 3000);
        QVERIFY(m_nam->callCount() >= 2);
    }

    // ── lyrics.ovh parsing ───────────────────────────────────────────────────

    void test_ovhSuccess_emitsLyricsReady() {
        // First call (LRCLIB): empty lyrics to fall through
        // Second call (OVH): success
        // We can't easily differentiate per-call. Instead: send LRCLIB empty,
        // then update next response before OVH fires. But FakeNam only stores one.
        // Simplest: make LRCLIB return 404 so it fails, OVH returns valid JSON.

        // Set up OVH response as the single fake response.
        // LRCLIB gets 404 first (but we've already set the response);
        // after LRCLIB fails, tryNextSource triggers OVH with same fake NAM.
        // The FakeNam always returns whatever m_nextData is, so we need both to
        // return OVH JSON. LRCLIB 404 triggers network error path, not JSON parse,
        // so we can set status to 200 + OVH JSON and let LRCLIB parse it (will get
        // "lyrics" field from it which is missing → falls to tryNextSource).

        // Better approach: Two separate FakeNams queued is complex. Instead just
        // verify OVH JSON is parsed correctly via a direct processOvhReply path.
        // Since processOvhReply is private, trigger it by making LRCLIB return
        // invalid JSON (falls through to OVH) and OVH return valid JSON.

        // The FakeNam returns the SAME response to all calls.
        // LRCLIB will get OVH JSON (no plainLyrics/syncedLyrics fields) → empty → fallthrough
        // OVH will get OVH JSON (has "lyrics" field) → success.

        QByteArray ovhJson = R"({"lyrics": "Line one\nLine two"})";
        m_nam->setNextResponse(ovhJson);

        QSignalSpy readySpy(m_client, &LyricsClient::lyricsReady);
        m_client->fetchLyrics("Artist", "Song");

        QTRY_COMPARE_WITH_TIMEOUT(readySpy.count(), 1, 3000);
        QCOMPARE(readySpy.at(0).at(0).toString(), QStringLiteral("Line one\nLine two"));
        QCOMPARE(readySpy.at(0).at(2).toString(), QStringLiteral("lyrics.ovh"));
    }

    // ── busy signal ──────────────────────────────────────────────────────────

    void test_busyTransitions() {
        QByteArray json = R"({"plainLyrics":"A","syncedLyrics":"","instrumental":false})";
        m_nam->setNextResponse(json);

        QSignalSpy spy(m_client, &LyricsClient::busyChanged);
        m_client->fetchLyrics("A", "B");

        QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 2, 3000);  // true → false
        QVERIFY(!m_client->busy());
    }
};

QTEST_MAIN(tst_LyricsClient)
#include "tst_LyricsClient.moc"
