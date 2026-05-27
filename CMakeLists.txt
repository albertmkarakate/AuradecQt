cmake_minimum_required(VERSION 3.16)
project(auradec VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS
    Quick QuickControls2 Multimedia Sql Svg Concurrent Gui Core Widgets
)

find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(TAGLIB taglib)
endif()

set(SOURCES
    main.cpp
    src/backend/AudioEngine.cpp
    src/backend/TrackDatabase.cpp
    src/backend/TrackScanner.cpp
    src/backend/LibraryModel.cpp
    src/backend/ArtistModel.cpp
    src/backend/AlbumModel.cpp
    src/backend/ArtworkProvider.cpp
    src/backend/CurrentTrackInfo.cpp
    src/backend/MusicBrainzClient.cpp
    src/backend/CoverArtClient.cpp
    src/backend/LyricsClient.cpp
    src/backend/GeminiClient.cpp
    src/backend/PlaylistManager.cpp
)

set(HEADERS
    src/backend/AudioEngine.h
    src/backend/TrackDatabase.h
    src/backend/TrackScanner.h
    src/backend/LibraryModel.h
    src/backend/ArtistModel.h
    src/backend/AlbumModel.h
    src/backend/ArtworkProvider.h
    src/backend/CurrentTrackInfo.h
    src/backend/MusicBrainzClient.h
    src/backend/CoverArtClient.h
    src/backend/LyricsClient.h
    src/backend/GeminiClient.h
    src/backend/PlaylistManager.h
)

qt_add_executable(auradec ${SOURCES} ${HEADERS} resources.qrc)

set_source_files_properties(src/qml/components/AuradecTheme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(auradec
    URI AuradecApp
    VERSION 1.0
    QML_FILES
        src/qml/main.qml
        src/qml/SplashScreen.qml
        src/qml/Sidebar.qml
        src/qml/PlayerBar.qml
        src/qml/components/AuradecTheme.qml
        src/qml/components/AuradecLogo.qml
        src/qml/components/NavItem.qml
        src/qml/components/SubNavItem.qml
        src/qml/components/TrackCard.qml
        src/qml/components/TrackListItem.qml
        src/qml/components/ArtistCard.qml
        src/qml/components/AlbumCard.qml
        src/qml/components/ArtworkImage.qml
        src/qml/components/IconButton.qml
        src/qml/components/TrackEditorModal.qml
        src/qml/components/LyricsPanel.qml
        src/qml/components/TrackContextMenu.qml
        src/qml/components/MetadataSection.qml
        src/qml/components/LyricsSection.qml
        src/qml/components/ArtworkSection.qml
        src/qml/components/ScanProgressToast.qml
        src/qml/components/ArtistInfoPanel.qml
        src/qml/components/GradientPlaceholder.qml
        src/qml/views/LibraryView.qml
        src/qml/views/NowPlayingView.qml
        src/qml/views/SettingsView.qml
        src/qml/views/RadioView.qml
        src/qml/views/PlaylistsView.qml
        src/qml/views/StatsView.qml
)

target_include_directories(auradec PRIVATE src/backend)

target_link_libraries(auradec PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Sql
    Qt6::Svg
    Qt6::Concurrent
    Qt6::Widgets
    Qt6::Gui
    Qt6::Core
    Qt6::Network
)

if(TAGLIB_FOUND)
    target_include_directories(auradec PRIVATE ${TAGLIB_INCLUDE_DIRS})
    target_link_libraries(auradec PRIVATE ${TAGLIB_LIBRARIES})
    target_compile_definitions(auradec PRIVATE HAVE_TAGLIB)
endif()

enable_testing()
add_subdirectory(tests)

set_target_properties(auradec PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

install(TARGETS auradec
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
