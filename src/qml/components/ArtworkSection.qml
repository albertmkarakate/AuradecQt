import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root

    property string artworkPreview:  ""
    property string trackArtist:     ""
    property string trackAlbum:      ""
    property bool   searchingForArt: false
    property string searchStatus:    ""
    property bool   triedDeezer:     false

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 20

        RowLayout {
            spacing: 24

            Rectangle {
                id: artworkBox
                width: 140; height: 140; radius: 24; clip: true
                color: Qt.rgba(1,1,1,0.05)
                border.color: artDrop.containsDrag ? "#FF5C1A" : Qt.rgba(1,1,1,0.10)
                border.width: artDrop.containsDrag ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.fill: parent; anchors.margins: 4
                    source: root.artworkPreview
                    fillMode: Image.PreserveAspectCrop
                    visible: root.artworkPreview !== ""
                }
                Text {
                    anchors.centerIn: parent
                    text: "♫"; font.pixelSize: 40; color: "#3a2e4a"
                    visible: root.artworkPreview === ""
                }
                Text {
                    anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                    text: "Drop image here"
                    font.family: "Barlow"; font.pixelSize: 9
                    color: Qt.rgba(236/255,229/255,216/255,0.35)
                    visible: root.artworkPreview === "" && !artDrop.containsDrag
                }
                Text {
                    anchors.centerIn: parent
                    text: "Release to use"; font.family: "Barlow"; font.pixelSize: 10
                    color: "#FF5C1A"
                    visible: artDrop.containsDrag
                }
                DropArea {
                    id: artDrop
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onDropped: (drop) => {
                        if (!drop.hasUrls) return
                        var url = drop.urls[0].toString()
                        var ext = url.split(".").pop().toLowerCase()
                        var imgExts = ["png","jpg","jpeg","webp","bmp","gif","tif","tiff"]
                        if (imgExts.indexOf(ext) >= 0)
                            root.artworkPreview = url.startsWith("file://") ? url : "file://" + url
                    }
                }
            }

            ColumnLayout {
                spacing: 10
                Text { text: "Replace Cover Image"; font.family: "Syne"; font.pixelSize: 16; font.weight: Font.Bold; color: "#ECE5D8" }
                Text { text: "Upload or search web for album artwork."; font.family: "Barlow"; font.pixelSize: 11; color: Qt.rgba(236,229,216,0.40); wrapMode: Text.WordWrap }

                RowLayout { spacing: 10
                    Rectangle {
                        height: 36; width: uploadLabel.implicitWidth + 28; radius: 18; color: "white"
                        Text { id: uploadLabel; anchors.centerIn: parent
                            text: "Upload Image"; font.family: "Barlow"; font.pixelSize: 11; font.weight: Font.Bold; color: "#000000" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: artworkFileDialog.open() }
                    }
                    Rectangle {
                        height: 36; width: removeLabel.implicitWidth + 28; radius: 18
                        color: "transparent"; border.color: Qt.rgba(1,1,1,0.15)
                        visible: root.artworkPreview !== ""
                        Text { id: removeLabel; anchors.centerIn: parent
                            text: "Remove"; font.family: "Barlow"; font.pixelSize: 11; font.weight: Font.DemiBold; color: Qt.rgba(236,229,216,0.60) }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.artworkPreview = "" }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

        Text { text: "Search Web for Cover Art"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.30) }

        RowLayout { spacing: 8
            Rectangle { Layout.fillWidth: true; height: 36; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: artSearchArtistInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: artSearchArtistInput; anchors.fill: parent; anchors.margins: 12; verticalAlignment: TextInput.AlignVCenter
                    text: root.trackArtist; font.family: "Barlow"; font.pixelSize: 12; color: "#ECE5D8"
                    } }
            Rectangle { Layout.fillWidth: true; height: 36; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: artSearchAlbumInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: artSearchAlbumInput; anchors.fill: parent; anchors.margins: 12; verticalAlignment: TextInput.AlignVCenter
                    text: root.trackAlbum; font.family: "Barlow"; font.pixelSize: 12; color: "#ECE5D8"
                    } }
            Rectangle {
                height: 36; width: artSearchLabel.implicitWidth + 24; radius: 18
                color: root.searchingForArt ? Qt.rgba(255,92,26,0.50) : Qt.rgba(255,92,26,0.85)
                Text { id: artSearchLabel; anchors.centerIn: parent
                    text: root.searchingForArt ? "Searching..." : "Search"
                    font.family: "Barlow"; font.pixelSize: 11; font.weight: Font.Bold; color: "white" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: !root.searchingForArt
                    onClicked: {
                        root.searchStatus = ""
                        root.triedDeezer = false
                        root.searchingForArt = true
                        root.searchStatus = "Searching MusicBrainz..."
                        musicBrainz.search("", artSearchArtistInput.text, artSearchAlbumInput.text)
                    } }
            }
        }

        Text {
            visible: root.searchStatus !== ""
            text: root.searchStatus
            font.family: "Barlow"; font.pixelSize: 11
            color: Qt.rgba(236,229,216,0.40)
            wrapMode: Text.WordWrap
        }
    }

    FileDialog {
        id: artworkFileDialog
        title: "Choose Album Artwork"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: root.artworkPreview = "file://" + selectedFile.toString().replace("file://", "")
    }

    Connections {
        target: musicBrainz
        function onResultsReady(results) {
            if (!root.searchingForArt) return
            root.searchingForArt = false
            if (results.length > 0 && results[0].releaseMbid) {
                root.searchStatus = "Found release. Fetching cover art..."
                coverArtClient.fetchByMbid(results[0].releaseMbid)
            } else if (results.length > 0) {
                root.searchStatus = "Found match but no release ID available — try a different search."
            } else {
                root.searchStatus = "No matches found — try changing the artist or album."
            }
        }
        function onSearchError(msg) {
            if (!root.searchingForArt) return
            root.searchingForArt = false
            root.searchStatus = "Search error: " + msg
        }
    }

    Connections {
        target: coverArtClient
        function onCoverArtReady(dataUrl) {
            root.artworkPreview = dataUrl
            root.searchStatus = "Cover art found! Save to apply."
        }
        function onFetchError(message) {
            if (!root.triedDeezer && root.trackArtist !== "" && root.trackAlbum !== "") {
                root.triedDeezer = true
                root.searchStatus = "Cover Art Archive unavailable, trying Deezer…"
                coverArtClient.fetchByAlbum(root.trackArtist, root.trackAlbum)
            } else if (root.triedDeezer) {
                root.searchStatus = "No cover art found on Deezer either."
            } else {
                root.searchStatus = message
            }
        }
    }
}
