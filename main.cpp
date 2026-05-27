#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QFontDatabase>
#include <QQuickStyle>
#include <QDebug>
#include <cstdio>

static void msgHandler(QtMsgType, const QMessageLogContext &, const QString &msg) {
    fprintf(stderr, "QT: %s\n", msg.toLocal8Bit().constData());
    fflush(stderr);
}

#include "src/backend/AudioEngine.h"
#include "src/backend/TrackDatabase.h"
#include "src/backend/TrackScanner.h"
#include "src/backend/LibraryModel.h"
#include "src/backend/ArtistModel.h"
#include "src/backend/AlbumModel.h"
#include "src/backend/ArtworkProvider.h"
#include "src/backend/CurrentTrackInfo.h"
#include "src/backend/MusicBrainzClient.h"
#include "src/backend/CoverArtClient.h"
#include "src/backend/LyricsClient.h"
#include "src/backend/GeminiClient.h"
#include "src/backend/PlaylistManager.h"

int main(int argc, char *argv[]) {
    qInstallMessageHandler(msgHandler);
    QApplication app(argc, argv);
    app.setApplicationName("Auradec");
    app.setOrganizationName("Auradec");

    QQuickStyle::setStyle("Basic");

    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/Syne-Bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/Syne-ExtraBold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/Barlow-Light.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/Barlow-Regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/Barlow-Medium.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/JetBrainsMono-Regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/assets/fonts/JetBrainsMono-Medium.ttf");

    fprintf(stderr, "[1] opening db\n"); fflush(stderr);
    auto *db = new TrackDatabase(&app);
    if (!db->open()) { fprintf(stderr, "DB open failed\n"); return 1; }

    fprintf(stderr, "[2] creating backend objects\n"); fflush(stderr);
    auto *audioEngine  = new AudioEngine(&app);
    auto *scanner      = new TrackScanner(db, &app);
    auto *library      = new LibraryModel(db, &app);
    auto *artists      = new ArtistModel(db, &app);
    auto *albums       = new AlbumModel(db, &app);
    auto *currentTrack = new CurrentTrackInfo(&app);
    auto *mbClient     = new MusicBrainzClient(&app);
    auto *coverArt     = new CoverArtClient(&app);
    auto *lyricsClient = new LyricsClient(&app);
    auto *geminiClient   = new GeminiClient(&app);
    auto *playlistMgr    = new PlaylistManager(&app);
    playlistMgr->setDatabase(db->database());

    library->reload();
    artists->reload();
    albums->reload();
    scanner->rescanAll();

    QObject::connect(scanner, &TrackScanner::scanComplete, library, [library](int){ library->reload(); });
    QObject::connect(scanner, &TrackScanner::scanComplete, artists, [artists](int){ artists->reload(); });
    QObject::connect(scanner, &TrackScanner::scanComplete, albums,  [albums](int){ albums->reload(); });
    QObject::connect(db, &TrackDatabase::playCountChanged, library, &LibraryModel::updatePlayCount);

    fprintf(stderr, "[3] creating QML engine\n"); fflush(stderr);
    QQmlApplicationEngine qml;
    qml.addImageProvider("artwork", new ArtworkProvider(db));
    qml.addImportPath(QStringLiteral("qrc:/"));

    // Print all QML warnings
    QObject::connect(&qml, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        for (const auto &w : warnings)
            qCritical() << "QML:" << w.toString();
    });

    qml.rootContext()->setContextProperty("audioEngine",   audioEngine);
    qml.rootContext()->setContextProperty("trackScanner",  scanner);
    qml.rootContext()->setContextProperty("libraryModel",  library);
    qml.rootContext()->setContextProperty("artistModel",   artists);
    qml.rootContext()->setContextProperty("albumModel",    albums);
    qml.rootContext()->setContextProperty("trackDb",       db);
    qml.rootContext()->setContextProperty("currentTrack",  currentTrack);
    qml.rootContext()->setContextProperty("musicBrainz",   mbClient);
    qml.rootContext()->setContextProperty("coverArtClient", coverArt);
    qml.rootContext()->setContextProperty("lyricsClient",  lyricsClient);
    qml.rootContext()->setContextProperty("geminiClient",  geminiClient);
    qml.rootContext()->setContextProperty("playlistMgr",   playlistMgr);

    fprintf(stderr, "[4] loading QML\n"); fflush(stderr);
    qml.load(QUrl("qrc:/AuradecApp/src/qml/main.qml"));

    fprintf(stderr, "[5] root objects: %d\n", (int)qml.rootObjects().size()); fflush(stderr);
    if (qml.rootObjects().isEmpty()) { fprintf(stderr, "QML load failed\n"); return 1; }

    fprintf(stderr, "[6] entering event loop\n"); fflush(stderr);
    return app.exec();
}
