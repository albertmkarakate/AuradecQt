import QtQuick
import QtQuick.Layouts
import QtCore
import AuradecApp

Item {
    id: root

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 24

            Text {
                text: "Settings"
                font.family: "Syne"; font.pixelSize: 32; font.weight: Font.Bold; font.italic: true
                color: Qt.rgba(236/255,229/255,216/255,0.08)
                bottomPadding: 8
            }

            // Library
            Rectangle {
                width: parent.width; radius: 16
                color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                height: libCol.implicitHeight + 32

                Column {
                    id: libCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "LIBRARY"
                        font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Qt.rgba(236/255,229/255,216/255,0.35)
                        bottomPadding: 16
                    }

                    SRow { lbl: "Stats"; sub: libraryModel.count + " tracks · " + artistModel.count + " artists · " + albumModel.count + " albums" }
                    SRow { lbl: "Database"; sub: trackDb.databasePath() }

                    // Music folders list
                    Item {
                        width: parent.width
                        height: foldersCol.implicitHeight + 28

                        Column {
                            id: foldersCol
                            width: parent.width

                            // Header row with Rescan All button
                            Item {
                                width: parent.width; height: 52

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left; anchors.right: parent.right
                                    height: 1; color: Qt.rgba(1,1,1,0.05)
                                }

                                Text {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    text: "Music Folders"
                                    font.family: "Barlow"; font.pixelSize: 14
                                    color: "#ECE5D8"
                                }

                                Rectangle {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    height: 28; width: rescanTxt.implicitWidth + 20; radius: 14
                                    color: rescanMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.20) : Qt.rgba(255/255,92/255,26/255,0.10)
                                    border.color: Qt.rgba(255/255,92/255,26/255,0.30)
                                    Text {
                                        id: rescanTxt; anchors.centerIn: parent
                                        text: "Rescan All"
                                        font.family: "Barlow"; font.pixelSize: 12; color: "#FF5C1A"
                                    }
                                    MouseArea {
                                        id: rescanMa; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: trackScanner.rescanAll()
                                    }
                                }
                            }

                            // Per-folder rows
                            Repeater {
                                id: folderRepeater
                                model: scanFoldersList

                                delegate: Item {
                                    width: foldersCol.width; height: 48

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left; anchors.right: parent.right
                                        height: 1; color: Qt.rgba(1,1,1,0.04)
                                    }

                                    Text {
                                        anchors.left: parent.left; anchors.right: removeBtn.left
                                        anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.family: "Barlow"; font.pixelSize: 12
                                        color: Qt.rgba(236/255,229/255,216/255,0.55)
                                        elide: Text.ElideMiddle
                                    }

                                    Rectangle {
                                        id: removeBtn
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        height: 22; width: 22; radius: 11
                                        color: removeMa.containsMouse ? Qt.rgba(255/255,77/255,106/255,0.20) : Qt.rgba(1,1,1,0.05)
                                        border.color: Qt.rgba(255/255,77/255,106/255,0.25)

                                        Text {
                                            anchors.centerIn: parent; text: "✕"
                                            font.pixelSize: 9; color: "#FF4D6A"
                                        }
                                        MouseArea {
                                            id: removeMa; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                trackScanner.removeFolder(modelData)
                                                root.refreshFolders()
                                            }
                                        }
                                    }
                                }
                            }

                            // Add folder row
                            Item {
                                width: foldersCol.width; height: 48

                                Text {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    text: scanFoldersList.length === 0 ? "No folders added yet" : ""
                                    font.family: "Barlow"; font.pixelSize: 12
                                    color: Qt.rgba(236/255,229/255,216/255,0.3)
                                }

                                Rectangle {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    height: 28; width: addFolderTxt.implicitWidth + 20; radius: 14
                                    color: addFolderMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.20) : Qt.rgba(255/255,92/255,26/255,0.10)
                                    border.color: Qt.rgba(255/255,92/255,26/255,0.30)
                                    Text {
                                        id: addFolderTxt; anchors.centerIn: parent
                                        text: "+ Add Folder"
                                        font.family: "Barlow"; font.pixelSize: 12; color: "#FF5C1A"
                                    }
                                    MouseArea {
                                        id: addFolderMa; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            trackScanner.pickAndScan()
                                            root.refreshFolders()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Playback
            Rectangle {
                width: parent.width; radius: 16
                color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                height: pbCol.implicitHeight + 32

                Column {
                    id: pbCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "PLAYBACK"
                        font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Qt.rgba(236/255,229/255,216/255,0.35)
                        bottomPadding: 16
                    }

                    SRow { lbl: "Volume"; sub: Math.round(audioEngine.volume * 100) + "% — adjust with slider in player bar" }
                    SRow { lbl: "Audio backend"; sub: "Qt6 Multimedia · FFmpeg " }
                }
            }

            // Lyrics
            Rectangle {
                width: parent.width; radius: 16
                color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                height: lyrCol.implicitHeight + 32

                Column {
                    id: lyrCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "LYRICS"
                        font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Qt.rgba(236/255,229/255,216/255,0.35)
                        bottomPadding: 16
                    }

                    Item {
                        width: parent.width; height: 52

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: Qt.rgba(1,1,1,0.05)
                        }

                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: "Spotify lyrics"
                            font.family: "Barlow"; font.pixelSize: 14
                            color: "#ECE5D8"
                        }

                        Text {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: typeof lyricsClient !== 'undefined' && lyricsClient.spotifyConfigured
                                  ? "✓ Configured" : "Not set"
                            font.family: "Barlow"; font.pixelSize: 12
                            color: typeof lyricsClient !== 'undefined' && lyricsClient.spotifyConfigured
                                   ? Qt.rgba(100/255,220/255,100/255,0.7)
                                   : Qt.rgba(236/255,229/255,216/255,0.38)
                        }
                    }

                    Item {
                        width: parent.width; height: 72

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: Qt.rgba(1,1,1,0.05)
                        }

                        Text {
                            anchors.left: parent.left; anchors.top: parent.top
                            text: "sp_dc token"
                            font.family: "Barlow"; font.pixelSize: 14
                            color: "#ECE5D8"
                        }

                        Rectangle {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top; anchors.topMargin: 24
                            height: 36; radius: 8
                            color: "#08060B"; border.color: tokenInput.activeFocus ? "#FF5C1A" : Qt.rgba(1,1,1,0.08)

                            TextInput {
                                id: tokenInput
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Barlow"; font.pixelSize: 12
                                color: "#ECE5D8"
                                clip: true
                                echoMode: tokenVisible ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "\u2022"
                                property bool tokenVisible: false

                                text: lyricsSettings.spotifySpDc

                                onTextChanged: {
                                    lyricsSettings.spotifySpDc = text
                                    if (typeof lyricsClient !== 'undefined')
                                        lyricsClient.setSpotifyToken(text)
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 26
                            text: tokenInput.tokenVisible ? "Hide" : "Show"
                            font.family: "Barlow"; font.pixelSize: 10
                            color: Qt.rgba(236/255,229/255,216/255,0.35)
                            visible: tokenInput.text.length > 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tokenInput.tokenVisible = !tokenInput.tokenVisible
                            }
                        }
                    }

                    Text {
                        text: "Get sp_dc from browser cookies after logging into open.spotify.com"
                        font.family: "Barlow"; font.pixelSize: 10
                        color: Qt.rgba(236/255,229/255,216/255,0.3)
                        topPadding: 4; bottomPadding: 8
                    }

                    Item {
                        width: parent.width; height: 52

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: Qt.rgba(1,1,1,0.05)
                        }

                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: "Gemini AI lyrics"
                            font.family: "Barlow"; font.pixelSize: 14
                            color: "#ECE5D8"
                        }

                        Text {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: lyricsSettings.geminiApiKey.length > 0 ? "✓ Configured" : "Not set"
                            font.family: "Barlow"; font.pixelSize: 12
                            color: lyricsSettings.geminiApiKey.length > 0
                                   ? Qt.rgba(100/255,220/255,100/255,0.7)
                                   : Qt.rgba(236/255,229/255,216/255,0.38)
                        }
                    }

                    Item {
                        width: parent.width; height: 72

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: Qt.rgba(1,1,1,0.05)
                        }

                        Text {
                            anchors.left: parent.left; anchors.top: parent.top
                            text: "API key"
                            font.family: "Barlow"; font.pixelSize: 14
                            color: "#ECE5D8"
                        }

                        Rectangle {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top; anchors.topMargin: 24
                            height: 36; radius: 8
                            color: "#08060B"; border.color: geminiInput.activeFocus ? "#FF5C1A" : Qt.rgba(1,1,1,0.08)

                            TextInput {
                                id: geminiInput
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Barlow"; font.pixelSize: 12
                                color: "#ECE5D8"
                                clip: true
                                echoMode: geminiVisible ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "•"
                                property bool geminiVisible: false

                                text: lyricsSettings.geminiApiKey

                                onTextChanged: lyricsSettings.geminiApiKey = text
                            }
                        }

                        Text {
                            anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 26
                            text: geminiInput.geminiVisible ? "Hide" : "Show"
                            font.family: "Barlow"; font.pixelSize: 10
                            color: Qt.rgba(236/255,229/255,216/255,0.35)
                            visible: geminiInput.text.length > 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: geminiInput.geminiVisible = !geminiInput.geminiVisible
                            }
                        }
                    }

                    Text {
                        text: "Get API key from aistudio.google.com/apikey"
                        font.family: "Barlow"; font.pixelSize: 10
                        color: Qt.rgba(236/255,229/255,216/255,0.3)
                        topPadding: 4
                    }
                }
            }

            Rectangle {
                width: parent.width; radius: 16
                color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                height: aboutCol.implicitHeight + 32

                Column {
                    id: aboutCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "ABOUT"
                        font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Qt.rgba(236/255,229/255,216/255,0.35)
                        bottomPadding: 16
                    }

                    SRow { lbl: "Auradec"; sub: "Native desktop music player · v1.0.0" }
                    SRow { lbl: "Stack"; sub: "C++ · Qt6 · QML · SQLite · TagLib · FFmpeg" }
                }
            }
        }
    }

    property var scanFoldersList: []

    function refreshFolders() {
        scanFoldersList = trackScanner.scanFolders()
    }

    Component.onCompleted: refreshFolders()

    Connections {
        target: trackScanner
        function onFoldersChanged() { root.refreshFolders() }
    }
    Settings {
        id: lyricsSettings
        category: "lyrics"
        property string spotifySpDc: ""
        property string geminiApiKey: ""
    }

    component SRow: Item {
        property string lbl: ""
        property string sub: ""
        property string btn: ""
        signal btnClicked()

        width: parent.width; height: 52

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            height: 1; color: Qt.rgba(1,1,1,0.05)
        }

        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            text: lbl
            font.family: "Barlow"; font.pixelSize: 14
            color: "#ECE5D8"
        }

        Text {
            anchors.centerIn: parent
            text: sub
            font.family: "Barlow"; font.pixelSize: 12
            color: Qt.rgba(236/255,229/255,216/255,0.38)
            visible: btn === ""
        }

        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            visible: btn !== ""
            height: 28; width: btnTxt.implicitWidth + 20; radius: 14
            color: btnMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.20) : Qt.rgba(255/255,92/255,26/255,0.10)
            border.color: Qt.rgba(255/255,92/255,26/255,0.30)

            Text {
                id: btnTxt
                anchors.centerIn: parent
                text: btn
                font.family: "Barlow"; font.pixelSize: 12; color: "#FF5C1A"
            }

            MouseArea {
                id: btnMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: parent.parent.parent.btnClicked()
            }
        }
    }
}
