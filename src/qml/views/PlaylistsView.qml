import QtQuick
import QtQuick.Layouts
import AuradecApp

Item {
    id: root

    signal playTrack(string path, int id)
    signal playNext(string path, int id)
    signal addToQueue(string path, int id)

    property int    activePlaylistId:   -1
    property string activePlaylistName: ""
    property var    playlists:          []
    property var    tracks:             []

    function refreshPlaylists() {
        root.playlists = playlistMgr.allPlaylists()
        if (root.activePlaylistId >= 0) refreshTracks()
    }
    function refreshTracks() {
        root.tracks = root.activePlaylistId >= 0
                      ? playlistMgr.playlistTracks(root.activePlaylistId) : []
    }
    function openPlaylist(id, name) {
        root.activePlaylistId   = id
        root.activePlaylistName = name
        refreshTracks()
    }
    function closePlaylist() {
        root.activePlaylistId   = -1
        root.activePlaylistName = ""
        root.tracks = []
    }

    Component.onCompleted: refreshPlaylists()

    Connections {
        target: playlistMgr
        function onPlaylistsChanged()           { root.refreshPlaylists() }
        function onPlaylistTracksChanged(pid)   { if (pid === root.activePlaylistId) root.refreshTracks() }
    }

    // ── Sidebar (playlist list) ─────────────────────────────────────────────
    Rectangle {
        id: sidebar
        width: 220
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: "#08060C"

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // Header
            Item {
                Layout.fillWidth: true; height: 56
                Text {
                    anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                    text: "Playlists"; font.family: "Syne"; font.pixelSize: 16
                    font.weight: Font.Bold; color: "#ECE5D8"
                }
                Rectangle {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 28; height: 28; radius: 14
                    color: newMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.18) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent; text: "+"
                        font.pixelSize: 18; color: "#FF5C1A"
                    }
                    MouseArea {
                        id: newMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: newPlaylistDialog.open()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255/255,92/255,26/255,0.10) }

            // Playlist items
            ListView {
                id: sideList
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: root.playlists

                delegate: Item {
                    width: sideList.width; height: 48
                    required property var modelData

                    Rectangle {
                        anchors.fill: parent
                        color: root.activePlaylistId === modelData.id
                               ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    RowLayout {
                        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 12 }
                        anchors.verticalCenter: parent.verticalCenter; spacing: 8

                        Column {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: modelData.name; elide: Text.ElideRight
                                width: parent.width
                                font.family: "Barlow"; font.pixelSize: 13
                                color: root.activePlaylistId === modelData.id ? "#FF5C1A" : "#ECE5D8"
                            }
                            Text {
                                text: modelData.trackCount + " track" + (modelData.trackCount !== 1 ? "s" : "")
                                font.family: "Barlow"; font.pixelSize: 11
                                color: Qt.rgba(236/255,229/255,216/255,0.40)
                            }
                        }

                        // Delete button
                        Item {
                            width: 20; height: 20
                            visible: delMa.containsMouse || rowMa.containsMouse

                            Text {
                                anchors.centerIn: parent; text: "✕"
                                font.pixelSize: 10
                                color: Qt.rgba(255/255,92/255,26/255,0.70)
                            }
                            MouseArea {
                                id: delMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.activePlaylistId === modelData.id) root.closePlaylist()
                                    playlistMgr.deletePlaylist(modelData.id)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPlaylist(modelData.id, modelData.name)
                    }
                }

                // Empty state
                Item {
                    anchors.fill: parent
                    visible: root.playlists.length === 0
                    Text {
                        anchors.centerIn: parent; text: "No playlists yet"
                        font.family: "Barlow"; font.pixelSize: 13
                        color: Qt.rgba(236/255,229/255,216/255,0.30)
                    }
                }
            }
        }
    }

    // ── Track list ─────────────────────────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        color: "#060507"

        // Placeholder when no playlist selected
        Item {
            anchors.fill: parent
            visible: root.activePlaylistId < 0
            Column {
                anchors.centerIn: parent; spacing: 12
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "♪"; font.pixelSize: 56
                    color: Qt.rgba(255/255,92/255,26/255,0.20)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Select a playlist"; font.family: "Syne"; font.pixelSize: 18
                    font.weight: Font.Bold
                    color: Qt.rgba(236/255,229/255,216/255,0.40)
                }
            }
        }

        // Playlist detail
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            visible: root.activePlaylistId >= 0

            // Header bar
            Item {
                Layout.fillWidth: true; height: 56

                RowLayout {
                    anchors { left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 16 }
                    anchors.verticalCenter: parent.verticalCenter; spacing: 12

                    Text {
                        text: root.activePlaylistName
                        font.family: "Syne"; font.pixelSize: 18; font.weight: Font.Bold
                        color: "#ECE5D8"; Layout.fillWidth: true; elide: Text.ElideRight
                    }

                    // Play all
                    Rectangle {
                        width: 96; height: 32; radius: 16
                        color: playAllMa.containsMouse ? "#FF5C1A" : Qt.rgba(255/255,92/255,26/255,0.15)
                        border.color: "#FF5C1A"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        visible: root.tracks.length > 0
                        Text {
                            anchors.centerIn: parent; text: "▶  Play all"
                            font.family: "Barlow"; font.pixelSize: 12
                            color: playAllMa.containsMouse ? "white" : "#FF5C1A"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: playAllMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.tracks.length === 0) return
                                let first = root.tracks[0]
                                root.playTrack(first.path, first.id)
                                for (let i = 1; i < root.tracks.length; i++)
                                    root.addToQueue(root.tracks[i].path, root.tracks[i].id)
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255/255,92/255,26/255,0.10) }

            // Track list
            ListView {
                id: trackList
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: root.tracks

                delegate: Item {
                    id: dlg
                    width: trackList.width; height: 52
                    required property var modelData
                    required property int index

                    Drag.active: handleMa.drag.active
                    Drag.source: dlg
                    Drag.hotSpot: Qt.point(width / 2, height / 2)

                    states: State {
                        when: dlg.Drag.active
                        ParentChange { target: dlg; parent: trackList }
                        AnchorChanges { target: dlg; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                    }

                    DropArea {
                        anchors.fill: parent
                        onEntered: (drag) => {
                            var fi = drag.source.index; var ti = dlg.index
                            if (fi !== ti) { playlistMgr.moveTrack(root.activePlaylistId, fi, ti); root.refreshTracks() }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: trkMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }

                    RowLayout {
                        anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 16 }
                        anchors.verticalCenter: parent.verticalCenter; spacing: 10

                        Text {
                            text: "⠿"; font.pixelSize: 14
                            color: Qt.rgba(236/255,229/255,216/255,0.22)
                            Layout.preferredWidth: 14
                            MouseArea { id: handleMa; anchors.fill: parent; drag.target: dlg; drag.axis: Drag.YAxis; cursorShape: Qt.SizeVerCursor }
                        }
                        Text {
                            text: (index + 1) + ""; font.family: "JetBrains Mono"; font.pixelSize: 11
                            color: Qt.rgba(236/255,229/255,216/255,0.30); Layout.preferredWidth: 24
                        }
                        Column {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: modelData.title || "Unknown"
                                font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                                elide: Text.ElideRight; width: parent.width
                            }
                            Text {
                                text: (modelData.artist || "Unknown") + (modelData.album ? "  ·  " + modelData.album : "")
                                font.family: "Barlow"; font.pixelSize: 11
                                color: Qt.rgba(236/255,229/255,216/255,0.45)
                                elide: Text.ElideRight; width: parent.width
                            }
                        }
                        Text {
                            property int secs: modelData.duration || 0
                            text: Math.floor(secs / 60) + ":" + String(secs % 60).padStart(2, "0")
                            font.family: "JetBrains Mono"; font.pixelSize: 11
                            color: Qt.rgba(236/255,229/255,216/255,0.35)
                        }
                        Item {
                            width: 20; height: 20; visible: trkMa.containsMouse
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: Qt.rgba(255/255,92/255,26/255,0.70) }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: playlistMgr.removeTrack(root.activePlaylistId, modelData.id) }
                        }
                    }

                    MouseArea {
                        id: trkMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: root.playTrack(modelData.path, modelData.id)
                    }
                }

                // Empty playlist state
                Item {
                    anchors.fill: parent
                    visible: root.tracks.length === 0
                    Text {
                        anchors.centerIn: parent
                        text: "Playlist is empty\nRight-click tracks to add them here"
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "Barlow"; font.pixelSize: 13
                        color: Qt.rgba(236/255,229/255,216/255,0.30)
                        lineHeight: 1.6
                    }
                }
            }
        }
    }

    // ── New Playlist Dialog ─────────────────────────────────────────────────
    Item {
        id: newPlaylistDialog
        anchors.fill: parent
        visible: false

        function open() { nameField.text = ""; visible = true; nameField.forceActiveFocus() }
        function close() { visible = false }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.60)
            MouseArea { anchors.fill: parent; onClicked: newPlaylistDialog.close() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 320; height: 140; radius: 12
            color: "#0E0B13"; border.color: Qt.rgba(255/255,92/255,26/255,0.30)

            Column {
                anchors { fill: parent; margins: 20 }
                spacing: 16

                Text {
                    text: "New Playlist"; font.family: "Syne"; font.pixelSize: 15
                    font.weight: Font.Bold; color: "#ECE5D8"
                }

                Rectangle {
                    width: parent.width; height: 36; radius: 8
                    color: "#1a1520"; border.color: Qt.rgba(255/255,92/255,26/255,0.25)

                    TextInput {
                        id: nameField
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                        clip: true
                        Keys.onReturnPressed: createAndClose()
                        Keys.onEscapePressed: newPlaylistDialog.close()
                        Text {
                            anchors.fill: parent; anchors.verticalCenter: parent.verticalCenter
                            text: "Playlist name…"; color: Qt.rgba(236/255,229/255,216/255,0.30)
                            font.family: "Barlow"; font.pixelSize: 13
                            visible: nameField.text.length === 0 && !nameField.activeFocus
                        }
                    }
                }

                Row {
                    spacing: 8; anchors.right: parent.right

                    Rectangle {
                        width: 64; height: 28; radius: 14
                        color: cancelMa.containsMouse ? "#1a1520" : "transparent"
                        border.color: Qt.rgba(236/255,229/255,216/255,0.20)
                        Text { anchors.centerIn: parent; text: "Cancel"
                               font.family: "Barlow"; font.pixelSize: 12
                               color: Qt.rgba(236/255,229/255,216/255,0.60) }
                        MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: newPlaylistDialog.close() }
                    }

                    Rectangle {
                        width: 64; height: 28; radius: 14
                        color: createMa.containsMouse ? "#FF5C1A" : Qt.rgba(255/255,92/255,26/255,0.15)
                        border.color: "#FF5C1A"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "Create"
                               font.family: "Barlow"; font.pixelSize: 12
                               color: createMa.containsMouse ? "white" : "#FF5C1A"
                               Behavior on color { ColorAnimation { duration: 120 } } }
                        MouseArea { id: createMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: createAndClose() }
                    }
                }
            }
        }

        function createAndClose() {
            let n = nameField.text.trim()
            if (n.length === 0) return
            let id = playlistMgr.createPlaylist(n)
            if (id >= 0) root.openPlaylist(id, n)
            newPlaylistDialog.close()
        }
    }
}
