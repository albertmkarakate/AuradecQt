cmake_minimum_required(VERSION 3.21)

find_package(Qt6 REQUIRED COMPONENTS Test Sql)

enable_testing()

# Shared backend sources needed by tests (no UI, no TagLib for simplicity)
set(BACKEND_SOURCES
    ${CMAKE_SOURCE_DIR}/src/backend/TrackDatabase.cpp
    ${CMAKE_SOURCE_DIR}/src/backend/LibraryModel.cpp
)

set(BACKEND_HEADERS
    ${CMAKE_SOURCE_DIR}/src/backend/TrackDatabase.h
    ${CMAKE_SOURCE_DIR}/src/backend/LibraryModel.h
)

set(SCANNER_SOURCES
    ${CMAKE_SOURCE_DIR}/src/backend/TrackDatabase.cpp
    ${CMAKE_SOURCE_DIR}/src/backend/TrackScanner.cpp
)

set(SCANNER_HEADERS
    ${CMAKE_SOURCE_DIR}/src/backend/TrackDatabase.h
    ${CMAKE_SOURCE_DIR}/src/backend/TrackScanner.h
)

# ── tst_TrackDatabase ──────────────────────────────────────────────────
qt_add_executable(tst_TrackDatabase
    tst_TrackDatabase.cpp
    ${BACKEND_SOURCES}
    ${BACKEND_HEADERS}
)
target_include_directories(tst_TrackDatabase PRIVATE ${CMAKE_SOURCE_DIR}/src/backend)
target_link_libraries(tst_TrackDatabase PRIVATE Qt6::Test Qt6::Sql)
add_test(NAME tst_TrackDatabase COMMAND tst_TrackDatabase)

# ── tst_LibraryModel ───────────────────────────────────────────────────
qt_add_executable(tst_LibraryModel
    tst_LibraryModel.cpp
    ${BACKEND_SOURCES}
    ${BACKEND_HEADERS}
)
target_include_directories(tst_LibraryModel PRIVATE ${CMAKE_SOURCE_DIR}/src/backend)
target_link_libraries(tst_LibraryModel PRIVATE Qt6::Test Qt6::Sql)
add_test(NAME tst_LibraryModel COMMAND tst_LibraryModel)

# ── tst_TrackScanner ───────────────────────────────────────────────────
find_package(Qt6 REQUIRED COMPONENTS Concurrent Widgets)

qt_add_executable(tst_TrackScanner
    tst_TrackScanner.cpp
    ${SCANNER_SOURCES}
    ${SCANNER_HEADERS}
)
target_include_directories(tst_TrackScanner PRIVATE ${CMAKE_SOURCE_DIR}/src/backend)
target_link_libraries(tst_TrackScanner PRIVATE
    Qt6::Test Qt6::Sql Qt6::Concurrent Qt6::Widgets)
add_test(NAME tst_TrackScanner COMMAND tst_TrackScanner)

# ── tst_LyricsClient ───────────────────────────────────────────────────
find_package(Qt6 REQUIRED COMPONENTS Network)

qt_add_executable(tst_LyricsClient
    tst_LyricsClient.cpp
    ${CMAKE_SOURCE_DIR}/src/backend/LyricsClient.cpp
    ${CMAKE_SOURCE_DIR}/src/backend/LyricsClient.h
)
target_include_directories(tst_LyricsClient PRIVATE ${CMAKE_SOURCE_DIR}/src/backend)
target_link_libraries(tst_LyricsClient PRIVATE Qt6::Test Qt6::Network)
add_test(NAME tst_LyricsClient COMMAND tst_LyricsClient)
