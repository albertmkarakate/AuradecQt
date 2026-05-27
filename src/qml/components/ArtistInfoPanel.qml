import QtQuick
import QtQuick.Layouts
import AuradecApp

Item {
    id: root

    property string artistName: ""
    property var    artistData: null

    signal closeRequested()

    onArtistNameChanged: {
        if (artistName !== "") {
            artistData = trackDb.artistInfo(artistName)
        } else {
            artistData = null
        }
    }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    }

    // Panel slides in from right
    Rectangle {
        id: panel
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: Math.min(360, parent.width * 0.4)
        color: "#0A0810"
        border.color: Qt.rgba(255/255,92/255,26/255,0.15)

        // Close
        Rectangle {
            anchors { top: parent.top; right: parent.right; topMargin: 16; rightMargin: 16 }
            width: 28; height: 28; radius: 14
            color: closeMa.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.05)
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: Qt.rgba(236/255,229/255,216/255,0.60) }
            MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
        }

        Flickable {
            anchors.fill: parent
            anchors.topMargin: 16; anchors.bottomMargin: 16
            contentHeight: panelCol.implicitHeight + 32
            clip: true

            Column {
                id: panelCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 20; anchors.rightMargin: 20
                anchors.topMargin: 16
                spacing: 20

                // Artist avatar
                Rectangle {
                    width: 72; height: 72; radius: 36; color: "#1a1520"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        anchors.fill: parent
                        source: root.artistData && root.artistData.lastfmImageUrl
                                ? root.artistData.lastfmImageUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        clip: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.artistName ? root.artistName[0].toUpperCase() : "?"
                        font.family: "Syne"; font.pixelSize: 28; font.weight: Font.Bold; color: "#FF5C1A"
                        visible: !(root.artistData && root.artistData.lastfmImageUrl &&
                                   artistImg.status === Image.Ready)
                        property var artistImg: parent.children[0]
                    }
                }

                // Name
                Text {
                    width: parent.width; text: root.artistName
                    font.family: "Syne"; font.pixelSize: 20; font.weight: Font.Bold
                    color: "#ECE5D8"; horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                // Listeners badge
                Row {
                    visible: root.artistData && root.artistData.listeners
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                    Rectangle {
                        height: 22; width: listenersTxt.implicitWidth + 16; radius: 11
                        color: Qt.rgba(255/255,92/255,26/255,0.12)
                        Text {
                            id: listenersTxt; anchors.centerIn: parent
                            text: "♪ " + (root.artistData ? root.artistData.listeners : "")
                            font.family: "Barlow"; font.pixelSize: 11; color: "#FF5C1A"
                        }
                    }
                }

                // Tags
                Flow {
                    width: parent.width; spacing: 6
                    visible: root.artistData && root.artistData.tags && root.artistData.tags.length > 0

                    Repeater {
                        model: root.artistData && root.artistData.tags ? root.artistData.tags.slice(0, 6) : []
                        delegate: Rectangle {
                            height: 22; width: tagTxt.implicitWidth + 16; radius: 11
                            color: Qt.rgba(245/255,179/255,42/255,0.12)
                            border.color: Qt.rgba(245/255,179/255,42/255,0.20)
                            Text {
                                id: tagTxt; anchors.centerIn: parent
                                text: typeof modelData === "string" ? modelData : (modelData.name || "")
                                font.family: "Barlow"; font.pixelSize: 10; color: "#F5B32A"
                            }
                        }
                    }
                }

                // Bio summary
                Column {
                    width: parent.width; spacing: 8
                    visible: root.artistData && root.artistData.bioSummary

                    Text {
                        text: "BIOGRAPHY"
                        font.family: "JetBrains Mono"; font.pixelSize: 9; font.weight: Font.Bold
                        font.letterSpacing: 2; color: Qt.rgba(236/255,229/255,216/255,0.30)
                    }

                    Text {
                        width: parent.width
                        text: root.artistData ? (root.artistData.bioSummary || "") : ""
                        font.family: "Barlow"; font.pixelSize: 12
                        color: Qt.rgba(236/255,229/255,216/255,0.65)
                        wrapMode: Text.WordWrap; lineHeight: 1.5
                    }
                }

                // Similar artists
                Column {
                    width: parent.width; spacing: 8
                    visible: root.artistData && root.artistData.similarArtists && root.artistData.similarArtists.length > 0

                    Text {
                        text: "SIMILAR ARTISTS"
                        font.family: "JetBrains Mono"; font.pixelSize: 9; font.weight: Font.Bold
                        font.letterSpacing: 2; color: Qt.rgba(236/255,229/255,216/255,0.30)
                    }

                    Flow {
                        width: parent.width; spacing: 6

                        Repeater {
                            model: root.artistData && root.artistData.similarArtists
                                   ? root.artistData.similarArtists.slice(0, 5) : []
                            delegate: Rectangle {
                                height: 24; width: simTxt.implicitWidth + 16; radius: 12
                                color: Qt.rgba(1,1,1,0.06); border.color: Qt.rgba(1,1,1,0.10)
                                Text {
                                    id: simTxt; anchors.centerIn: parent
                                    text: typeof modelData === "string" ? modelData : (modelData.name || "")
                                    font.family: "Barlow"; font.pixelSize: 11
                                    color: Qt.rgba(236/255,229/255,216/255,0.60)
                                }
                            }
                        }
                    }
                }

                // Empty state / fetch prompt
                Column {
                    width: parent.width; spacing: 12
                    visible: !root.artistData || !root.artistData.bioSummary
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter
                        text: "No artist info available\nFetch from Last.fm via Settings"
                        font.family: "Barlow"; font.pixelSize: 12
                        color: Qt.rgba(236/255,229/255,216/255,0.30)
                        wrapMode: Text.WordWrap; lineHeight: 1.5
                    }
                }

                // MBID chip
                Rectangle {
                    visible: root.artistData && root.artistData.mbid
                    height: 22; width: mbidTxt.implicitWidth + 16; radius: 11
                    color: Qt.rgba(1,1,1,0.04); anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        id: mbidTxt; anchors.centerIn: parent
                        text: root.artistData && root.artistData.mbid
                              ? "MusicBrainz · " + root.artistData.mbid.substring(0, 8) + "…"
                              : ""
                        font.family: "JetBrains Mono"; font.pixelSize: 9
                        color: Qt.rgba(236/255,229/255,216/255,0.20)
                    }
                }
            }
        }
    }
}
