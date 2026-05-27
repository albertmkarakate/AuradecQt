import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AuradecApp

Item {
    id: root

    property string title:      currentTrack.id > 0 ? (currentTrack.title || "Unknown") : "Nothing playing"
    property string artist:     currentTrack.artist
    property string album:      currentTrack.album
    property string codec:      currentTrack.codec
    property int    bitrate:    currentTrack.bitrate
    property int    sampleRate: currentTrack.sampleRate
    property bool   playing:    audioEngine.playing
    property var    upNextQueue:  []
    property int    upNextIndex:  -1
    signal queueRemoveAt(int absoluteIndex)
    property bool   isFav:      currentTrack.id > 0 && trackDb.isFavorite(currentTrack.id)
    property bool   showLyrics:    false
    property string lyricsSource:  ""

    RowLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 40

        // Left: Hero + controls
        Column {
            Layout.preferredWidth: 320
            Layout.alignment: Qt.AlignTop
            spacing: 24

            // Artwork
            Rectangle {
                width: 280; height: 280
                radius: 24
                color: "#1a1520"
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: currentTrack.hasArtwork && currentTrack.id > 0
                            ? "image://artwork/" + currentTrack.id
                            : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: currentTrack.hasArtwork && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent; text: "♫"
                    font.pixelSize: 80; color: "#3a2e4a"
                    visible: !currentTrack.hasArtwork
                }

                // Playing glow overlay
                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: "transparent"
                    border.color: Qt.rgba(255/255,92/255,26/255,0.30)
                    border.width: root.playing ? 2 : 0
                    Behavior on border.width { NumberAnimation { duration: 300 } }
                }
            }

            // Title
            Text {
                width: parent.width
                text: root.title
                font.family: "Syne"; font.pixelSize: 26; font.weight: Font.Bold
                color: "#ECE5D8"; wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // Artist
            Text {
                width: parent.width
                text: root.artist || "Unknown Artist"
                font.family: "Barlow"; font.pixelSize: 16
                color: Qt.rgba(236/255,229/255,216/255,0.55)
                horizontalAlignment: Text.AlignHCenter
            }

            // Action row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                // Heart / favorite
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: root.isFav ? Qt.rgba(255/255,77/255,106/255,0.15)
                                      : (heartMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04))
                    Text {
                        anchors.centerIn: parent
                        text: root.isFav ? "♥" : "♡"
                        font.pixelSize: 18
                        color: root.isFav ? "#FF4D6A" : Qt.rgba(236/255,229/255,216/255,0.6)
                    }
                    MouseArea {
                        id: heartMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (currentTrack.id > 0) {
                                trackDb.toggleFavorite(currentTrack.id)
                                root.isFav = trackDb.isFavorite(currentTrack.id)
                            }
                        }
                    }
                }

                // Play/pause
                Rectangle {
                    width: 56; height: 56; radius: 28
                    color: playMa.containsMouse ? "#FF7A40" : "#FF5C1A"
                    Text {
                        anchors.centerIn: parent
                        text: root.playing ? "⏸" : "▶"
                        font.pixelSize: 22; color: "white"
                    }
                    MouseArea {
                        id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.playing ? audioEngine.pause() : audioEngine.resume()
                    }
                }

                // Lyrics toggle
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: root.showLyrics ? Qt.rgba(255/255,92/255,26/255,0.15)
                                           : (lyricsMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04))
                    border.color: root.showLyrics ? Qt.rgba(255/255,92/255,26/255,0.35) : "transparent"
                    Text { anchors.centerIn: parent; text: "♪"; font.pixelSize: 18
                           color: root.showLyrics ? "#FF5C1A" : Qt.rgba(236/255,229/255,216/255,0.6) }
                    MouseArea {
                        id: lyricsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.showLyrics = !root.showLyrics
                    }
                }

                // Queue scroll-to-top
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: queueMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                    Text { anchors.centerIn: parent; text: "≡"; font.pixelSize: 18; color: Qt.rgba(236/255,229/255,216/255,0.6) }
                    MouseArea {
                        id: queueMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: upNextList.positionViewAtBeginning()
                    }
                }
            }
        }

        // Center: Track details
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: 20

            // Big stat chips
            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 16; rowSpacing: 16

                Repeater {
                    model: [
                        { label: "Plays",   value: currentTrack.playCount > 0 ? currentTrack.playCount : "—" },
                        { label: "Year",    value: currentTrack.year > 0 ? currentTrack.year : "—" },
                        { label: "Genre",   value: currentTrack.genre || "—" },
                        { label: "Format",  value: (root.codec || "—") + (root.bitrate > 0 ? " · " + root.bitrate + "k" : "") }
                    ]
                    delegate: Rectangle {
                        width: (parent.width - 16) / 2; height: 72
                        radius: 16; color: "#0E0B13"
                        border.color: Qt.rgba(1,1,1,0.06)

                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: modelData.label
                                font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.Bold
                                font.letterSpacing: 1.2
                                color: Qt.rgba(236/255,229/255,216/255,0.35)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: modelData.value
                                font.family: "Syne"; font.pixelSize: 18; font.weight: Font.Bold
                                color: "#ECE5D8"
                                anchors.horizontalCenter: parent.horizontalCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }
                }
            }

            // Sample rate detail
            Rectangle {
                width: parent.width; height: 52; radius: 16
                color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                Row {
                    anchors.centerIn: parent; spacing: 32
                    Repeater {
                        model: [
                            { k: "Sample Rate", v: root.sampleRate > 0 ? (root.sampleRate/1000).toFixed(1) + " kHz" : "—" },
                            { k: "Album",       v: root.album || "—" },
                        ]
                        delegate: Column {
                            spacing: 2; anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.k; font.family: "Barlow"; font.pixelSize: 9
                                   font.letterSpacing: 1; color: Qt.rgba(236/255,229/255,216/255,0.30) }
                            Text { text: modelData.v; font.family: "JetBrains Mono"; font.pixelSize: 12
                                   color: "#ECE5D8"; elide: Text.ElideRight; width: 140 }
                        }
                    }
                }
            }
        }

        // Right: File Info + Up Next (or Lyrics when showLyrics)
        ColumnLayout {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            spacing: 16

            StackLayout {
                id: rightStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.showLyrics ? 1 : 0

                // ── Page 0: File Info + Up Next ────────────────────────
                ColumnLayout {
                    spacing: 16

                    // File info
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: fileInfoCol.implicitHeight + 32
                        radius: 16
                        color: "#0E0B13"
                        border.color: Qt.rgba(1,1,1,0.06)

                        Column {
                            id: fileInfoCol
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 0

                            Text {
                                text: "File Info"
                                font.family: "Syne"; font.pixelSize: 12; font.weight: Font.Bold
                                color: Qt.rgba(236/255,229/255,216/255,0.40)
                                bottomPadding: 12
                            }

                            Repeater {
                                model: [
                                    {k:"Format",      v: root.codec      || "—"},
                                    {k:"Bitrate",     v: root.bitrate > 0 ? root.bitrate + " kbps" : "—"},
                                    {k:"Sample Rate", v: root.sampleRate > 0 ? (root.sampleRate/1000).toFixed(1) + " kHz" : "—"},
                                    {k:"Album",       v: root.album      || "—"},
                                    {k:"Year",        v: currentTrack.year > 0 ? currentTrack.year : "—"},
                                    {k:"Genre",       v: currentTrack.genre || "—"},
                                ]
                                delegate: RowLayout {
                                    width: parent.width
                                    height: 32

                                    Text {
                                        text: modelData.k
                                        font.family: "Barlow"; font.pixelSize: 12
                                        color: Qt.rgba(236/255,229/255,216/255,0.40)
                                        Layout.preferredWidth: 100
                                    }
                                    Text {
                                        text: modelData.v
                                        font.family: "JetBrains Mono"; font.pixelSize: 12
                                        color: "#ECE5D8"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Up Next
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: "#0E0B13"
                        border.color: Qt.rgba(1,1,1,0.06)
                        clip: true

                        Column {
                            id: upNextHeader
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            anchors.bottomMargin: 0
                            spacing: 0

                            Item {
                                width: parent.width; height: 28

                                Text {
                                    text: "Up Next"
                                    font.family: "Syne"; font.pixelSize: 12; font.weight: Font.Bold
                                    color: Qt.rgba(236/255,229/255,216/255,0.40)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        var rem = root.upNextQueue.length - root.upNextIndex - 1
                                        return rem > 0 ? rem + " tracks" : ""
                                    }
                                    font.family: "JetBrains Mono"; font.pixelSize: 10
                                    color: Qt.rgba(236/255,229/255,216/255,0.25)
                                }
                            }
                        }

                        ListView {
                            id: upNextList
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: upNextHeader.bottom
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 4
                            clip: true
                            spacing: 2

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            model: {
                                if (root.upNextIndex < 0 || root.upNextQueue.length === 0) return []
                                var result = []
                                for (var i = root.upNextIndex + 1; i < root.upNextQueue.length; i++)
                                    result.push(root.upNextQueue[i])
                                return result
                            }

                            delegate: Item {
                                width: upNextList.width; height: 44
                                property var td: trackDb.trackById(modelData.id)

                                Rectangle {
                                    anchors.fill: parent; radius: 8
                                    color: qMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                                }

                                Row {
                                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                    spacing: 10

                                    Rectangle {
                                        width: 32; height: 32; radius: 6; color: "#1a1520"; clip: true
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            id: qArt
                                            anchors.fill: parent
                                            source: (modelData.hasArtwork && modelData.id > 0) ? "image://artwork/" + modelData.id : ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: status === Image.Ready
                                        }
                                        Text {
                                            anchors.centerIn: parent; text: "♫"; font.pixelSize: 14
                                            color: "#3a2e4a"; visible: qArt.status !== Image.Ready
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2; width: parent.width - 50

                                        Text {
                                            width: parent.width
                                            text: td ? (td.title || "Unknown") : "Unknown"
                                            font.family: "Barlow"; font.pixelSize: 13
                                            color: "#ECE5D8"; elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: td ? (td.artist || "Unknown Artist") : "Unknown Artist"
                                            font.family: "Barlow"; font.pixelSize: 11
                                            color: Qt.rgba(236/255,229/255,216/255,0.45); elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    id: qMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.queueRemoveAt(root.upNextIndex + 1 + index)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Queue is empty"
                                font.family: "Barlow"; font.pixelSize: 13
                                color: Qt.rgba(236/255,229/255,216/255,0.25)
                                visible: upNextList.count === 0
                            }
                        }
                    }
                }

                // ── Page 1: Lyrics ────────────────────────────────────
                LyricsPanel {
                    id: lyricsPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    plainLyrics:  currentTrack.lyrics
                    syncedLyrics: currentTrack.syncedLyrics
                    position:     audioEngine.position
                    loading:      lyricsClient.busy
                    statusText:   lyricsClient.statusText
                    sourceLabel:  root.lyricsSource
                }
            }
        }
    }

    // ── Lyrics fetching logic ─────────────────────────────────────────
    onShowLyricsChanged: {
        if (root.showLyrics) {
            fetchLyricsForCurrentTrack()
        } else {
            lyricsClient.cancelFetch()
        }
    }

    Connections {
        target: currentTrack
        function onIdChanged() {
            lyricsClient.cancelFetch()
            if (root.showLyrics)
                fetchLyricsForCurrentTrack()
        }
    }

    Connections {
        target: lyricsClient
        function onLyricsReady(plain, synced, source) {
            currentTrack.setLyrics(plain, synced)
            root.lyricsSource = source || ""
            if (currentTrack.id > 0 && (plain || synced)) {
                var lyricsJson = JSON.stringify({plain: plain || "", synced: synced || ""})
                trackDb.updateTrack(currentTrack.id, {lyrics: lyricsJson})
            }
        }
        function onFetchError(msg) {
            currentTrack.clearLyrics()
            root.lyricsSource = ""
        }
    }

    function fetchLyricsForCurrentTrack() {
        if (currentTrack.id < 0) return
        if (currentTrack.lyrics || currentTrack.syncedLyrics) return
        if (root.artist && root.title) {
            lyricsClient.fetchLyrics(root.artist, root.title, Math.floor(audioEngine.duration / 1000))
        }
    }
}
