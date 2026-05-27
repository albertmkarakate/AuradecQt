import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import AuradecApp

Item {
    id: root

    property int    libraryTab: 0  // 0=Tracks 1=Artists 2=Albums
    property int    viewMode:   0  // 0=grid 1=list
    property string searchText: ""
    property int    currentTrackId: -1
    property string drillLabel: ""
    signal playTrack(string path, int id)
    signal playNext(string path, int id)
    signal addToQueue(string path, int id)
    signal editTrack(int id)
    signal addToPlaylist(int id)
    signal artistInfoRequested(string name)
    property bool   favsOnly:    false
    property string sortCol:     "artist"
    property bool   sortAsc:     true
    property bool   drillIsAlbum: false
    property string drillArtist: ""
    property string drillAlbum:  ""
    property int    drillArtworkId: -1

    function drillInto(label, artist, album) {
        drillLabel = label; drillIsAlbum = album !== ""; drillArtist = artist; drillAlbum = album; drillArtworkId = -1; libraryTab = 0; searchText = ""
        if (artist !== "") libraryModel.setArtistFilter(artist)
        else               libraryModel.setAlbumFilter(album)
    }
    function drillBack() {
        drillLabel = ""; drillArtist = ""; drillAlbum = ""; drillArtworkId = -1; searchText = ""
        libraryModel.clearFilters()
    }
    function applySort(col) {
        if (sortCol === col) sortAsc = !sortAsc
        else { sortCol = col; sortAsc = true }
        libraryModel.setSort(sortCol, sortAsc)
    }

    // Search + toolbar
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            spacing: 16

            // Tab buttons
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: ["Tracks","Artists","Albums"]
                    delegate: Rectangle {
                        height: 32
                        width: tabLabel.implicitWidth + 24
                        radius: 999
                        color: root.libraryTab === index
                               ? Qt.rgba(255/255,92/255,26/255,0.15)
                               : (tabMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
                        border.color: root.libraryTab === index
                                      ? Qt.rgba(255/255,92/255,26/255,0.40)
                                      : "transparent"

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Barlow"
                            font.pixelSize: 13
                            font.weight: root.libraryTab === index ? Font.Medium : Font.Normal
                            color: root.libraryTab === index ? "#FF5C1A" : Qt.rgba(236/255,229/255,216/255,0.6)
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.libraryTab = index
                        }
                    }
                }
            }

            // Search
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 999
                color: Qt.rgba(1,1,1,0.06)
                border.color: searchInput.activeFocus ? Qt.rgba(255/255,92/255,26/255,0.40) : Qt.rgba(1,1,1,0.10)

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    spacing: 8

                    Text {
                        text: "⌕"; font.pixelSize: 14
                        color: Qt.rgba(236/255,229/255,216/255,0.40)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TextInput {
                        id: searchInput
                        width: parent.parent.width - (root.searchText !== "" ? 68 : 50)
                        text: root.searchText
                        font.family: "Barlow"; font.pixelSize: 13
                        color: "#ECE5D8"
                        selectionColor: Qt.rgba(255/255,92/255,26/255,0.40)
                        onTextChanged: {
                            root.searchText = text
                            root.drillLabel = ""
                            libraryModel.clearFilters()
                            if (text !== "") libraryModel.setFilter(text)
                        }
                    }
                }

                // Clear search button
                Text {
                    text: "✕"
                    font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.50)
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.searchText !== ""

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = ""
                            root.searchText = ""
                            libraryModel.clearFilters()
                        }
                    }
                }
            }

            // View toggle
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                visible: root.libraryTab === 0

                Repeater {
                    model: ["⊞","☰"]
                    delegate: Rectangle {
                        width: 32; height: 32; radius: 8
                        color: root.viewMode === index
                               ? Qt.rgba(255/255,92/255,26/255,0.15)
                               : (vmMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 14
                            color: root.viewMode === index ? "#FF5C1A" : Qt.rgba(236/255,229/255,216/255,0.5)
                        }

                        MouseArea {
                            id: vmMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.viewMode = index
                        }
                    }
                }
            }

            // Favorites toggle
            Rectangle {
                width: 32; height: 32; radius: 999
                color: root.favsOnly ? Qt.rgba(255/255,77/255,106/255,0.20) : (favMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
                border.color: root.favsOnly ? Qt.rgba(255/255,77/255,106/255,0.50) : "transparent"
                Text { anchors.centerIn: parent; text: root.favsOnly ? "♥" : "♡"; font.pixelSize: 15
                       color: root.favsOnly ? "#FF4D6A" : Qt.rgba(236/255,229/255,216/255,0.50) }
                MouseArea {
                    id: favMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.favsOnly = !root.favsOnly; libraryModel.setFavoritesOnly(root.favsOnly) }
                }
            }

            // Import folder button
            Rectangle {
                height: 32; width: importLabel.implicitWidth + 20; radius: 999
                color: importMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.20) : Qt.rgba(255/255,92/255,26/255,0.10)
                border.color: Qt.rgba(255/255,92/255,26/255,0.30)
                Text { id: importLabel; anchors.centerIn: parent; text: "+ Import"
                       font.family: "Barlow"; font.pixelSize: 13; color: "#FF5C1A" }
                MouseArea { id: importMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: trackScanner.pickAndScan() }
            }
        }
    }


    // Sort bar (tracks tab only, no drill-down)
    Row {
        id: sortBar
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.leftMargin: 32
        height: root.libraryTab === 0 && root.drillLabel === "" ? 30 : 0
        visible: height > 0
        spacing: 4
        clip: true

        Repeater {
            model: [
                { col: "artist",    label: "Artist"   },
                { col: "title",     label: "Title"    },
                { col: "album",     label: "Album"    },
                { col: "year",      label: "Year"     },
                { col: "duration",  label: "Duration" },
                { col: "playCount", label: "Plays"    }
            ]
            delegate: Rectangle {
                height: 22; width: srtLbl.implicitWidth + 16; radius: 999
                anchors.verticalCenter: parent.verticalCenter
                color: root.sortCol === modelData.col
                       ? Qt.rgba(255/255,92/255,26/255,0.15)
                       : (srtMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
                border.color: root.sortCol === modelData.col
                              ? Qt.rgba(255/255,92/255,26/255,0.35)
                              : "transparent"

                Text {
                    id: srtLbl
                    anchors.centerIn: parent
                    text: modelData.label + (root.sortCol === modelData.col ? (root.sortAsc ? " ↑" : " ↓") : "")
                    font.family: "Barlow"; font.pixelSize: 11
                    color: root.sortCol === modelData.col
                           ? "#FF5C1A"
                           : Qt.rgba(236/255,229/255,216/255,0.45)
                }
                MouseArea {
                    id: srtMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applySort(modelData.col)
                }
            }
        }
    }

    // Drill-down header: artwork + name + back
    Rectangle {
        id: drillHeader
        anchors { top: sortBar.bottom; left: parent.left; right: parent.right; leftMargin: 24; rightMargin: 24; topMargin: 6 }
        visible: root.drillLabel !== ""; height: visible ? 80 : 0; color: "transparent"
        Connections {
            target: libraryModel
            function onCountChanged() {
                if (root.drillLabel !== "" && root.drillArtworkId < 0 && libraryModel.count > 0) {
                    var snap = libraryModel.snapshot()
                    if (snap.length > 0) root.drillArtworkId = snap[0].id || -1
                }
            }
        }
        RowLayout {
            anchors.fill: parent; spacing: 16
            Rectangle {
                height: 32; width: backLbl.implicitWidth + 20; radius: 16
                color: backDrillMa.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06)
                Layout.alignment: Qt.AlignVCenter
                Text { id: backLbl; anchors.centerIn: parent; text: "← All"
                       font.family: "Barlow"; font.pixelSize: 12; color: Qt.rgba(236/255,229/255,216/255,0.70) }
                MouseArea { id: backDrillMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.drillBack() }
            }
            Rectangle {
                width: 56; height: 56; radius: root.drillIsAlbum ? 10 : 28
                color: "#1a1520"; clip: true; Layout.alignment: Qt.AlignVCenter
                Image { anchors.fill: parent
                        source: root.drillArtworkId > 0 ? "image://artwork/" + root.drillArtworkId : ""
                        fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                Text { anchors.centerIn: parent; text: "♫"; font.pixelSize: 22
                       color: "#3a2e4a"; visible: root.drillArtworkId <= 0 }
            }
            Column {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 2
                Text { text: root.drillIsAlbum ? "ALBUM COLLECTION" : "ARTIST"
                       font.family: "JetBrains Mono"; font.pixelSize: 9; font.weight: Font.Bold
                       font.letterSpacing: 2; color: "#F5B32A" }
                Text { text: root.drillLabel; font.family: "Syne"; font.pixelSize: 20
                       font.weight: Font.Bold; color: "#ECE5D8"; elide: Text.ElideRight; width: parent.width }
                Text { text: libraryModel.count + " track" + (libraryModel.count !== 1 ? "s" : "")
                       font.family: "Barlow"; font.pixelSize: 12; color: Qt.rgba(236/255,229/255,216/255,0.35) }
            }
            Rectangle {
                visible: !root.drillIsAlbum; Layout.alignment: Qt.AlignVCenter
                height: 32; width: aiBtnLbl.implicitWidth + 20; radius: 16
                color: aiBtnMa.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.05)
                border.color: Qt.rgba(1,1,1,0.10)
                Text { id: aiBtnLbl; anchors.centerIn: parent; text: "ℹ  Artist Info"
                       font.family: "Barlow"; font.pixelSize: 12; color: Qt.rgba(236/255,229/255,216/255,0.60) }
                MouseArea { id: aiBtnMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.artistInfoRequested(root.drillLabel) }
            }
            Rectangle {
                visible: libraryModel.count > 0; Layout.alignment: Qt.AlignVCenter
                height: 32; width: paLbl.implicitWidth + 20; radius: 16
                color: paMa.containsMouse ? "#FF5C1A" : Qt.rgba(255/255,92/255,26/255,0.15)
                border.color: "#FF5C1A"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text { id: paLbl; anchors.centerIn: parent; text: "▶  Play All"
                       font.family: "Barlow"; font.pixelSize: 12
                       color: paMa.containsMouse ? "white" : "#FF5C1A"
                       Behavior on color { ColorAnimation { duration: 120 } } }
                MouseArea { id: paMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var snap = libraryModel.snapshot()
                                if (snap.length === 0) return
                                root.playTrack(snap[0].path, snap[0].id)
                                for (var i = 1; i < snap.length; i++)
                                    root.addToQueue(snap[i].path, snap[i].id)
                            } }
            }
        }
    }

    // Content area
    Item {
        anchors.top: root.drillLabel !== "" ? drillHeader.bottom : sortBar.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // TRACKS — grid
        GridView {
            id: gridView
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            visible: root.libraryTab === 0 && root.viewMode === 0
            cellWidth: 216
            cellHeight: 256
            clip: true
            model: libraryModel

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                TrackCard {
                    anchors.centerIn: parent
                    width: 200; height: 240
                    title:      model.title
                    artist:     model.artist
                    codec:      model.codec
                    trackId:    model.trackId
                    hasArtwork: model.hasArtwork
                    path:       model.path
                    rating:     model.rating || 0
                    playing:    root.currentTrackId === model.trackId
                    onPlayRequested:            (p, id) => root.playTrack(p, id)
                    onPlayNextRequested:        (p, id) => root.playNext(p, id)
                    onAddToQueueRequested:      (p, id) => root.addToQueue(p, id)
                    onEditRequested:            (id)    => root.editTrack(id)
                    onAddToPlaylistRequested:   (id)    => root.addToPlaylist(id)
                }
            }
        }

        // TRACKS — list
        ListView {
            id: listView
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            visible: root.libraryTab === 0 && root.viewMode === 1
            clip: true
            model: libraryModel
            spacing: 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: TrackListItem {
                width: listView.width
                title:      model.title
                artist:     model.artist
                album:      model.album
                codec:      model.codec
                bitrate:    model.bitrate
                duration:   model.duration
                playCount:  model.playCount
                rating:     model.rating || 0
                trackId:    model.trackId
                hasArtwork: model.hasArtwork
                path:       model.path
                playing:    root.currentTrackId === model.trackId
                onPlayRequested:           (p, id) => root.playTrack(p, id)
                onPlayNextRequested:       (p, id) => root.playNext(p, id)
                onAddToQueueRequested:     (p, id) => root.addToQueue(p, id)
                onEditRequested:           (id)    => root.editTrack(id)
                onAddToPlaylistRequested:  (id)    => root.addToPlaylist(id)
            }
        }

        // ARTISTS
        GridView {
            id: artistGrid
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            visible: root.libraryTab === 1
            cellWidth: 180; cellHeight: 200
            clip: true
            model: artistModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: ArtistCard {
                width: artistGrid.cellWidth; height: artistGrid.cellHeight
                name: model.name; count: model.count; imageUrl: model.imageUrl || ""
                onDrillRequested: (n) => root.drillInto(n, n, "")
            }
        }

        // ALBUMS
        GridView {
            id: albumGrid
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            visible: root.libraryTab === 2
            cellWidth: 200; cellHeight: 240
            clip: true
            model: albumModel

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: AlbumCard {
                width: albumGrid.cellWidth; height: albumGrid.cellHeight
                name: model.name; artist: model.artist; coverId: model.coverId
                onDrillRequested: (n) => root.drillInto(n, "", n)
            }
        }

        // Empty state
        EmptyLibraryState {
            anchors.fill: parent
            visible: libraryModel.count === 0 && root.libraryTab === 0 && root.drillLabel === ""
        }
    }

    component EmptyLibraryState: Item {
        Column {
            anchors.centerIn: parent; spacing: 16
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "♫"; font.pixelSize: 64; color: Qt.rgba(255/255,92/255,26/255,0.25) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No music yet"
                   font.family: "Syne"; font.pixelSize: 20; font.weight: Font.Bold; color: Qt.rgba(236/255,229/255,216/255,0.50) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Import a folder to get started"
                   font.family: "Barlow"; font.pixelSize: 14; color: Qt.rgba(236/255,229/255,216/255,0.30) }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 40; width: emCtaLbl.implicitWidth + 32; radius: 20
                color: emMa.containsMouse ? "#FF5C1A" : Qt.rgba(255/255,92/255,26/255,0.15)
                border.color: "#FF5C1A"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { id: emCtaLbl; anchors.centerIn: parent; text: "Import Music"
                       font.family: "Barlow"; font.pixelSize: 14; font.weight: Font.Medium
                       color: emMa.containsMouse ? "white" : "#FF5C1A"
                       Behavior on color { ColorAnimation { duration: 150 } } }
                MouseArea { id: emMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: trackScanner.pickAndScan() }
            }
        }
    }
}
