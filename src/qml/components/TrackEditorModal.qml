import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import AuradecApp

Controls.Dialog {
    id: root

    property int    trackId:       -1
    property string trackPath:     ""
    property string trackTitle:    ""
    property string trackArtist:   ""
    property string trackAlbum:    ""
    property string trackGenre:    ""
    property string trackComposer: ""
    property int    trackYear:     0
    property string trackLyrics:   ""
    property int    trackRating:   0
    property string geminiApiKey:  ""

    signal saved()

    modal: true
    closePolicy: Controls.Popup.CloseOnEscape

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 640
    height: 680

    background: Rectangle { color: "#161616"; radius: 40; border.color: Qt.rgba(1,1,1,0.10) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "transparent"
            Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.topMargin: 24

            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text { text: "Editor Engine"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 2; color: "#FF5C1A" }
                Text { text: "Edit Track Information"; font.family: "Syne"; font.pixelSize: 24; font.weight: Font.Bold; color: "#ECE5D8" }
            }

            Rectangle {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: Qt.rgba(1,1,1,0.05); border.color: Qt.rgba(1,1,1,0.10)
                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 14; color: Qt.rgba(236,229,216,0.60) }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
            }
        }

        // ── Tabs ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44
            color: Qt.rgba(1,1,1,0.03)
            Layout.leftMargin: 24; Layout.rightMargin: 24

            Row {
                anchors.centerIn: parent; spacing: 4

                Repeater {
                    model: ["Auto-Fetch", "Metadata Tags", "Lyrics Editor", "Album Artwork"]
                    delegate: Rectangle {
                        height: 32; width: tabLabel.implicitWidth + 24; radius: 12
                        color: tabBar.currentIndex === index
                               ? Qt.rgba(1,1,1,0.12)
                               : (tabMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")

                        Text {
                            id: tabLabel; anchors.centerIn: parent; text: modelData
                            font.family: "Barlow"; font.pixelSize: 12
                            font.weight: tabBar.currentIndex === index ? Font.Medium : Font.Normal
                            color: tabBar.currentIndex === index ? "#ECE5D8" : Qt.rgba(236,229,216,0.40)
                        }
                        MouseArea { id: tabMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: tabBar.currentIndex = index }
                    }
                }
            }
        }

        // ── Body ──
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.topMargin: 8
            clip: true

            StackLayout {
                id: bodyStack
                anchors.fill: parent
                currentIndex: tabBar.currentIndex

                // ── Tab 0: Auto-Fetch ──
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        ColumnLayout { spacing: 12
                            RowLayout { spacing: 10
                                ColumnLayout { spacing: 4; Layout.fillWidth: true
                                    Text { text: "Track Title *"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
                                    Rectangle { Layout.fillWidth: true; height: 40; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: fetchTitleInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                                        TextInput { id: fetchTitleInput; anchors.fill: parent; anchors.margins: 12; verticalAlignment: TextInput.AlignVCenter
                                            text: root.trackTitle; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                                            onAccepted: searchMB() } } }
                                ColumnLayout { spacing: 4; Layout.fillWidth: true
                                    Text { text: "Artist"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
                                    Rectangle { Layout.fillWidth: true; height: 40; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: fetchArtistInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                                        TextInput { id: fetchArtistInput; anchors.fill: parent; anchors.margins: 12; verticalAlignment: TextInput.AlignVCenter
                                            text: root.trackArtist; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                                            onAccepted: searchMB() } } }
                                ColumnLayout { spacing: 4; Layout.fillWidth: true
                                    Text { text: "Album"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
                                    Rectangle { Layout.fillWidth: true; height: 40; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: fetchAlbumInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                                        TextInput { id: fetchAlbumInput; anchors.fill: parent; anchors.margins: 12; verticalAlignment: TextInput.AlignVCenter
                                            text: root.trackAlbum; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                                            onAccepted: searchMB() } } }
                            }

                            RowLayout { spacing: 8
                                Rectangle {
                                    height: 40; width: searchBtnLabel.implicitWidth + 32; radius: 20
                                    color: mbSearching ? Qt.rgba(255,92,26,0.50) : Qt.rgba(255,92,26,0.85)
                                    enabled: fetchTitleInput.text.trim() !== "" && !mbSearching

                                    Text { id: searchBtnLabel; anchors.centerIn: parent
                                        text: mbSearching ? "Searching..." : "Search MusicBrainz"
                                        font.family: "Barlow"; font.pixelSize: 12; font.weight: Font.Bold; color: "white" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: searchMB() }
                                }

                                Rectangle {
                                    height: 40; width: geminiBtnLabel.implicitWidth + 32; radius: 20
                                    color: geminiSearching
                                           ? Qt.rgba(245/255,179/255,42/255,0.40)
                                           : Qt.rgba(245/255,179/255,42/255,0.80)
                                    enabled: fetchTitleInput.text.trim() !== "" && !geminiSearching

                                    Text { id: geminiBtnLabel; anchors.centerIn: parent
                                        text: geminiSearching ? "Asking Gemini..." : "✨ Gemini AI"
                                        font.family: "Barlow"; font.pixelSize: 12; font.weight: Font.Bold; color: "white" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: askGemini() }
                                }
                            }
                        }

                        Text {
                            visible: mbError !== ""; text: mbError
                            font.family: "Barlow"; font.pixelSize: 11; color: "#EF4444"
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }

                        Text {
                            visible: geminiError !== ""; text: geminiError
                            font.family: "Barlow"; font.pixelSize: 11; color: "#F59E0B"
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }

                        Text {
                            visible: mbResults.length > 0
                            text: mbResults.length + " match" + (mbResults.length !== 1 ? "es" : "")
                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1
                            color: Qt.rgba(236,229,216,0.30)
                        }

                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            spacing: 6; clip: true; model: mbResults
                            Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: parent.width; height: 56; radius: 16
                                color: appliedMbid === modelData.mbid
                                       ? Qt.rgba(255,92,26,0.12)
                                       : (resMa.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03))
                                border.color: appliedMbid === modelData.mbid
                                               ? Qt.rgba(255,92,26,0.40)
                                               : (resMa.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent")

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 8
                                    ColumnLayout { spacing: 2; Layout.fillWidth: true
                                        Text { text: modelData.title || "Unknown"; font.family: "Barlow"; font.pixelSize: 13; font.weight: Font.Medium; color: "#ECE5D8"; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: (modelData.artist || "") + (modelData.album ? " · " + modelData.album : "") + (modelData.year ? " (" + modelData.year + ")" : ""); font.family: "Barlow"; font.pixelSize: 11; color: Qt.rgba(236,229,216,0.45); elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    Text { text: modelData.score + "%"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Bold
                                        color: modelData.score >= 90 ? "#34D399" : (modelData.score >= 70 ? "#F59E0B" : Qt.rgba(236,229,216,0.40)) }
                                    Text { visible: appliedMbid === modelData.mbid; text: "✓"; font.pixelSize: 14; color: "#FF5C1A" }
                                }
                                MouseArea { id: resMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: applyMBResult(modelData) }
                            }
                        }
                    }

                    function searchMB() {
                        mbError = ""
                        mbResults = []
                        appliedMbid = ""
                        mbSearching = true
                        musicBrainz.search(fetchTitleInput.text, fetchArtistInput.text, fetchAlbumInput.text)
                    }

                    function askGemini() {
                        geminiError = ""
                        geminiSearching = true
                        if (!root.geminiApiKey || root.geminiApiKey.trim() === "") {
                            geminiError = "No Gemini API key — add one in Settings → Lyrics."
                            geminiSearching = false
                            return
                        }
                        geminiClient.enrichTrack(fetchTitleInput.text, fetchArtistInput.text, fetchAlbumInput.text, root.geminiApiKey)
                    }
                }

                // ── Tab 1: Metadata Tags ──
                MetadataSection { id: metaSection }

                // ── Tab 2: Lyrics Editor ──
                LyricsSection {
                    id: lyricsSection
                    geminiApiKey: root.geminiApiKey
                    trackTitle:   root.trackTitle
                    trackArtist:  root.trackArtist
                }

                // ── Tab 3: Album Artwork ──
                ArtworkSection {
                    id: artworkSection
                    trackArtist: root.trackArtist
                    trackAlbum:  root.trackAlbum
                }
            }
        }

        // ── Footer ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 80
            color: Qt.rgba(1,1,1,0.03)
            Layout.leftMargin: 32; Layout.rightMargin: 32

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; spacing: 12

                Rectangle {
                    height: 44; width: cancelLabel.implicitWidth + 40; radius: 22
                    color: "transparent"; border.color: Qt.rgba(1,1,1,0.12)
                    Text { id: cancelLabel; anchors.centerIn: parent; text: "Cancel"
                        font.family: "Barlow"; font.pixelSize: 13; font.weight: Font.DemiBold; color: "#ECE5D8" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }

                Rectangle {
                    height: 44; width: saveLabel.implicitWidth + 48; radius: 22
                    color: saving ? Qt.rgba(255,92,26,0.50) : Qt.rgba(255,92,26,0.90)
                    Text { id: saveLabel; anchors.centerIn: parent
                        text: saving ? "Saving..." : "Save Changes"
                        font.family: "Barlow"; font.pixelSize: 13; font.weight: Font.Bold; color: "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        enabled: !saving; onClicked: doSave() }
                }
            }
        }
    }

    // ── State ──
    property var    mbResults:      []
    property string mbError:        ""
    property string appliedMbid:    ""
    property bool   mbSearching:    false
    property bool   geminiSearching: false
    property string geminiError:    ""
    property bool   saving:         false

    function applyMBResult(result) {
        appliedMbid = result.mbid
        metaSection.title    = result.title  || metaSection.title
        metaSection.artist   = result.artist || metaSection.artist
        metaSection.album    = result.album  || metaSection.album
        if (result.genre) metaSection.genre = result.genre
        if (result.year)  metaSection.year  = String(result.year)
        tabBar.currentIndex = 1
    }

    function doSave() {
        saving = true
        var fields = {}
        fields["title"]    = metaSection.title.trim()
        fields["artist"]   = metaSection.artist.trim()
        fields["album"]    = metaSection.album.trim()
        fields["genre"]    = metaSection.genre.trim()
        fields["composer"] = metaSection.composer.trim()

        var y = parseInt(metaSection.year)
        if (!isNaN(y) && y > 0) fields["year"] = y

        var r = parseInt(metaSection.rating)
        if (!isNaN(r) && r >= 0 && r <= 5) fields["rating"] = r

        fields["lyrics"] = lyricsSection.lyrics

        trackDb.updateTrack(root.trackId, fields)
        trackDb.writeFileTags(root.trackId)

        if (artworkSection.artworkPreview !== "" &&
            artworkSection.artworkPreview !== "image://artwork/" + root.trackId) {
            trackDb.saveArtwork(root.trackId, artworkSection.artworkPreview)
        }

        libraryModel.reload()
        artistModel.reload()
        albumModel.reload()

        saving = false
        root.saved()
        root.close()
    }

    Connections {
        target: geminiClient
        function onMetadataReady(meta) {
            geminiSearching = false
            geminiError = ""
            if (meta.title)  metaSection.title  = meta.title
            if (meta.artist) metaSection.artist = meta.artist
            if (meta.album)  metaSection.album  = meta.album
            if (meta.genre)  metaSection.genre  = meta.genre
            if (meta.year)   metaSection.year   = String(meta.year)
            tabBar.currentIndex = 1
        }
        function onFetchError(msg) {
            geminiSearching = false
            geminiError = "Gemini: " + msg
        }
    }

    onOpened: {
        mbError = ""; mbResults = []; appliedMbid = ""; mbSearching = false
        geminiSearching = false; geminiError = ""; saving = false

        metaSection.title    = root.trackTitle
        metaSection.artist   = root.trackArtist
        metaSection.album    = root.trackAlbum
        metaSection.genre    = root.trackGenre
        metaSection.composer = root.trackComposer
        metaSection.year     = root.trackYear > 0 ? root.trackYear.toString() : ""
        metaSection.rating   = root.trackRating > 0 ? root.trackRating.toString() : "0"
        lyricsSection.lyrics = root.trackLyrics

        artworkSection.artworkPreview  = root.trackId > 0 ? "image://artwork/" + root.trackId : ""
        artworkSection.searchingForArt = false
        artworkSection.searchStatus    = ""
        artworkSection.triedDeezer     = false
    }

    Connections {
        target: musicBrainz
        function onResultsReady(results) {
            if (artworkSection.searchingForArt) return
            mbSearching = false
            mbResults = results
        }
        function onSearchError(msg) {
            if (artworkSection.searchingForArt) return
            mbSearching = false
            mbError = msg
        }
    }

    Item { id: tabBar; property int currentIndex: 0 }
}
