import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtCore
import AuradecApp

ApplicationWindow {
    id: window
    visible: true
    minimumWidth: 960
    minimumHeight: 640

    Settings {
        property alias windowWidth:  window.width
        property alias windowHeight: window.height
        property alias windowX:      window.x
        property alias windowY:      window.y
    }

    Settings {
        id: playbackSettings
        category: "playback"
        property alias shuffleOn:   window.shuffleOn
        property alias repeatOn:    window.repeatOn
        property real  volume:      1.0
        property int   lastTrackId: -1
    }

    Settings {
        id: lyricsSettings
        category: "lyrics"
        property string spotifySpDc:   ""
        property string geminiApiKey:  ""
    }
    title: currentTrack.id > 0
           ? (currentTrack.title || "Unknown") + " — " + (currentTrack.artist || "Unknown Artist") + " | Auradec"
           : "Auradec"
    color: "#060507"

    property bool   splashDone:    false
    property string activeTab:     "library"
    property int    librarySubTab: 0

    // Playlist queue — list of {path, id}
    property var    queue:         []
    property int    queueIndex:    -1
    property bool   shuffleOn:     false
    property bool   repeatOn:      false

    function playTrack(path, id) {
        playbackSettings.lastTrackId = id
        trackDb.incrementPlayCount(id)
        currentTrack.setTrack(trackDb.trackById(id))
        audioEngine.play(path)

        // Build queue from current library snapshot
        var snap = libraryModel.snapshot()
        var newQueue = []
        queueIndex = 0
        for (var i = 0; i < snap.length; i++) {
            var t = snap[i]
            newQueue.push({ path: t.path, id: t.id, hasArtwork: !!t.hasArtwork })
            if (t.id === id) queueIndex = i
        }
        queue = newQueue
    }

    function playNext() {
        if (queue.length === 0 || queueIndex < 0) return
        var next
        if (shuffleOn) {
            if (queue.length === 1) { next = 0 }
            else {
                do { next = Math.floor(Math.random() * queue.length) } while (next === queueIndex)
            }
        } else {
            next = queueIndex + 1
            if (next >= queue.length) {
                if (repeatOn) next = 0
                else return
            }
        }
        queueIndex = next
        var t = queue[next]
        trackDb.incrementPlayCount(t.id)
        currentTrack.setTrack(trackDb.trackById(t.id))
        audioEngine.play(t.path)
    }

    function addToQueue(path, id) {
        var t = trackDb.trackById(id)
        var entry = { path: path, id: id, hasArtwork: t ? !!t.hasArtwork : false }
        queue = queue.concat([entry])
    }

    function playNextInQueue(path, id) {
        var t = trackDb.trackById(id)
        var entry = { path: path, id: id, hasArtwork: t ? !!t.hasArtwork : false }
        if (queue.length === 0 || queueIndex < 0) {
            queue = [entry]
            queueIndex = -1
        } else {
            var newQueue = queue.slice(0, queueIndex + 1)
            newQueue.push(entry)
            newQueue = newQueue.concat(queue.slice(queueIndex + 1))
            queue = newQueue
        }
    }

    function removeFromQueue(idx) {
        if (idx < 0 || idx >= queue.length) return
        var newQ = queue.slice()
        newQ.splice(idx, 1)
        if (queueIndex >= idx && queueIndex > 0) queueIndex--
        queue = newQ
    }

    function playPrev() {
        if (queue.length === 0 || queueIndex < 0) return
        if (audioEngine.position > 3000) {
            audioEngine.seek(0)
            return
        }
        if (queueIndex === 0) { audioEngine.seek(0); return }
        queueIndex--
        var t = queue[queueIndex]
        trackDb.incrementPlayCount(t.id)
        currentTrack.setTrack(trackDb.trackById(t.id))
        audioEngine.play(t.path)
    }

    Component.onCompleted: {
        audioEngine.setVolume(playbackSettings.volume)
        if (typeof lyricsClient !== 'undefined')
            lyricsClient.setSpotifyToken(lyricsSettings.spotifySpDc)
        if (playbackSettings.lastTrackId > 0) {
            var t = trackDb.trackById(playbackSettings.lastTrackId)
            if (t && t.id) currentTrack.setTrack(t)
        }
    }

    // Splash
    SplashScreen {
        id: splash
        anchors.fill: parent
        visible: !splashDone
        z: 100
        onDismissed: fadeOut.start()

        SequentialAnimation {
            id: fadeOut
            NumberAnimation { target: splash; property: "opacity"; to: 0; duration: 400 }
            ScriptAction { script: splashDone = true }
        }
    }

    // Main layout
    RowLayout {
        anchors.fill: parent
        spacing: 0
        visible: splashDone

        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            activeTab: window.activeTab
            librarySubTab: window.librarySubTab
            onTabChanged: (tab) => { window.activeTab = tab }
            onLibraryTabSelected: (idx) => {
                window.librarySubTab = idx
                libraryView.libraryTab = idx
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                LibraryView {
                    id: libraryView
                    anchors.fill: parent
                    visible: window.activeTab === "library"
                    currentTrackId: currentTrack.id
                    onPlayTrack:          (path, id) => window.playTrack(path, id)
                    onPlayNext:           (path, id) => window.playNextInQueue(path, id)
                    onAddToQueue:         (path, id) => window.addToQueue(path, id)
                    onEditTrack:          (id)        => { trackEditor.openTrack(id) }
                    onAddToPlaylist:      (id)        => { playlistPicker.open(id) }
                    onArtistInfoRequested: (name)     => { artistInfoPanel.show(name) }
                }

                NowPlayingView {
                    id: nowPlayingView
                    anchors.fill: parent
                    visible: window.activeTab === "nowplaying"
                    upNextQueue: window.queue
                    upNextIndex: window.queueIndex
                    onQueueRemoveAt: (idx) => window.removeFromQueue(idx)
                }

                SettingsView {
                    anchors.fill: parent
                    visible: window.activeTab === "settings"
                }

                RadioView {
                    anchors.fill: parent
                    visible: window.activeTab === "radio"
                }

                PlaylistsView {
                    anchors.fill: parent
                    visible: window.activeTab === "playlists"
                    onPlayTrack:  (path, id) => window.playTrack(path, id)
                    onPlayNext:   (path, id) => window.playNextInQueue(path, id)
                    onAddToQueue: (path, id) => window.addToQueue(path, id)
                }

                StatsView {
                    anchors.fill: parent
                    visible: window.activeTab === "stats"
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: window.activeTab !== "library"
                          && window.activeTab !== "nowplaying"
                          && window.activeTab !== "settings"
                          && window.activeTab !== "radio"
                          && window.activeTab !== "playlists"
                          && window.activeTab !== "stats"

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var t = window.activeTab
                            return t.charAt(0).toUpperCase() + t.slice(1)
                        }
                        font.family: "Syne"; font.pixelSize: 48
                        font.weight: Font.Bold; font.italic: true
                        color: Qt.rgba(236/255,229/255,216/255,0.06)
                    }
                }
            }

            PlayerBar {
                id: playerBar
                Layout.fillWidth: true
                shuffleOn:     window.shuffleOn
                repeatOn:      window.repeatOn
                lyricsVisible: nowPlayingView.showLyrics
                onNextClicked:     window.playNext()
                onPrevClicked:     window.playPrev()
                onShuffleToggled:  (on) => { window.shuffleOn = on }
                onRepeatToggled:   (on) => { window.repeatOn  = on }
                onToggleLyrics: {
                    nowPlayingView.showLyrics = !nowPlayingView.showLyrics
                    if (nowPlayingView.showLyrics) window.activeTab = "nowplaying"
                }
            }
        }
    }

    Connections {
        target: audioEngine
        function onVolumeChanged() { playbackSettings.volume = audioEngine.volume }
        function onTrackEnded() {
            if (window.repeatOn && window.queueIndex >= 0 && window.queue.length > 0) {
                var t = window.queue[window.queueIndex]
                audioEngine.play(t.path)
            } else {
                window.playNext()
            }
        }
    }

    Item {
        focus: true
        anchors.fill: parent
        Keys.onPressed: (event) => {
            switch (event.key) {
                case Qt.Key_Space:
                    audioEngine.playing ? audioEngine.pause() : audioEngine.resume()
                    event.accepted = true
                    break
                case Qt.Key_Right:
                    if (audioEngine.duration > 0)
                        audioEngine.seek(Math.min(audioEngine.position + 5000, audioEngine.duration))
                    event.accepted = true
                    break
                case Qt.Key_Left:
                    if (audioEngine.duration > 0)
                        audioEngine.seek(Math.max(audioEngine.position - 5000, 0))
                    event.accepted = true
                    break
                case Qt.Key_MediaNext:
                    window.playNext(); event.accepted = true; break
                case Qt.Key_MediaPrevious:
                    window.playPrev(); event.accepted = true; break
                case Qt.Key_MediaPlay:
                case Qt.Key_MediaTogglePlayPause:
                    audioEngine.playing ? audioEngine.pause() : audioEngine.resume()
                    event.accepted = true
                    break
                case Qt.Key_Up:
                    if (event.modifiers & Qt.ControlModifier) {
                        audioEngine.setVolume(Math.min(1.0, audioEngine.volume + 0.05))
                        event.accepted = true
                    }
                    break
                case Qt.Key_Down:
                    if (event.modifiers & Qt.ControlModifier) {
                        audioEngine.setVolume(Math.max(0.0, audioEngine.volume - 0.05))
                        event.accepted = true
                    }
                    break
                case Qt.Key_N:
                    if (event.modifiers & Qt.ControlModifier) {
                        window.playNext(); event.accepted = true
                    }
                    break
                case Qt.Key_P:
                    if (event.modifiers & Qt.ControlModifier) {
                        window.playPrev(); event.accepted = true
                    }
                    break
                case Qt.Key_E:
                    if (event.modifiers & Qt.ControlModifier) {
                        if (currentTrack.id > 0) {
                            trackEditor.openTrack(currentTrack.id); event.accepted = true
                        }
                    }
                    break
            }
        }
    }

    // Artist info drawer
    ArtistInfoPanel {
        id: artistInfoPanel
        parent: window.contentItem
        anchors.fill: parent
        visible: false
        z: 190
        function show(name) { artistName = name; visible = true }
        onCloseRequested: visible = false
    }

    // Global playlist picker overlay
    Item {
        id: playlistPicker
        parent: window.contentItem
        anchors.fill: parent
        visible: false
        z: 200

        property int pendingTrackId: -1
        function open(trackId) { pendingTrackId = trackId; plList.model = playlistMgr.allPlaylists(); visible = true }
        function close() { visible = false; pendingTrackId = -1 }

        Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.55)
                    MouseArea { anchors.fill: parent; onClicked: playlistPicker.close() } }

        Rectangle {
            anchors.centerIn: parent; width: 280; radius: 12
            height: Math.min(48 + plList.count * 44 + 16, 320)
            color: "#0E0B13"; border.color: Qt.rgba(255/255,92/255,26/255,0.30)

            Column {
                anchors { fill: parent; margins: 0 }
                Item {
                    width: parent.width; height: 44
                    Text { anchors.centerIn: parent; text: "Add to Playlist"
                           font.family: "Syne"; font.pixelSize: 14; font.weight: Font.Bold; color: "#ECE5D8" }
                }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(255/255,92/255,26/255,0.15) }
                ListView {
                    id: plList
                    width: parent.width
                    height: Math.min(count * 44, 260)
                    clip: true
                    delegate: Item {
                        width: plList.width; height: 44
                        required property var modelData
                        Rectangle { anchors.fill: parent; color: pMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.10) : "transparent" }
                        Text { anchors.centerIn: parent; text: modelData.name
                               font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" }
                        MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { playlistMgr.addTrack(modelData.id, playlistPicker.pendingTrackId); playlistPicker.close() } }
                    }
                    Item {
                        anchors.fill: parent; visible: plList.count === 0
                        Text { anchors.centerIn: parent; text: "No playlists — create one in the Playlists tab"
                               font.family: "Barlow"; font.pixelSize: 12; color: Qt.rgba(236/255,229/255,216/255,0.40)
                               horizontalAlignment: Text.AlignHCenter; width: parent.width - 24; wrapMode: Text.WordWrap }
                    }
                }
            }
        }
    }

    // Global track editor modal
    TrackEditorModal {
        id: trackEditor
        parent: window.contentItem
        geminiApiKey: lyricsSettings.geminiApiKey

        function openTrack(id) {
            var t = trackDb.trackById(id)
            if (!t || !t.id) return
            trackEditor.trackId       = t.id
            trackEditor.trackPath     = t.path    || ""
            trackEditor.trackTitle    = t.title   || ""
            trackEditor.trackArtist   = t.artist  || ""
            trackEditor.trackAlbum    = t.album   || ""
            trackEditor.trackGenre    = t.genre   || ""
            trackEditor.trackComposer = t.composer || ""
            trackEditor.trackYear     = t.year    || 0
            trackEditor.trackLyrics   = t.lyrics  || ""
            trackEditor.trackRating   = t.rating  || 0
            trackEditor.open()
        }

        onSaved: {
            libraryModel.doReload()
            if (currentTrack.id === trackEditor.trackId) {
                currentTrack.setTrack(trackDb.trackById(trackEditor.trackId))
            }
        }
    }
}
