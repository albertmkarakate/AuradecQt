import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

Item {
    id: root
    width: 200; height: 240

    property string title:    ""
    property string artist:   ""
    property string codec:    ""
    property bool   playing:    false
    property bool   hasArtwork: false
    property int    trackId:  -1
    property string path:     ""

    signal playRequested(string path, int id)
    signal playNextRequested(string path, int id)
    signal addToQueueRequested(string path, int id)
    signal editRequested(int id)
    signal addToPlaylistRequested(int id)

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 20
        color: "#110E18"
        border.color: ma.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.25) : Qt.rgba(1,1,1,0.06)
        border.width: 1

        transform: Translate { y: ma.containsMouse ? -4 : 0; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }

        Rectangle {
            id: artworkRect
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            height: width
            radius: 12
            color: "#1a1520"
            clip: true

            Image {
                id: artImg
                anchors.fill: parent
                source: (root.hasArtwork && root.trackId > 0) ? "image://artwork/" + root.trackId : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "♫"
                font.pixelSize: 36
                color: "#3a2e4a"
                visible: artImg.status !== Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                visible: ma.containsMouse

                Rectangle {
                    anchors.centerIn: parent
                    width: 44; height: 44
                    radius: 22
                    color: "#FF5C1A"
                    opacity: 0.95

                    Text {
                        anchors.centerIn: parent
                        text: root.playing ? "⏸" : "▶"
                        font.pixelSize: 18
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playRequested(root.path, root.trackId)
                    }
                }
            }
        }

        Column {
            anchors.top: artworkRect.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 10
            spacing: 3

            Text {
                width: parent.width
                text: root.title || "Unknown"
                font.family: "Syne"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#ECE5D8"
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.artist || "Unknown Artist"
                font.family: "Barlow"
                font.pixelSize: 12
                color: Qt.rgba(236/255,229/255,216/255,0.55)
                elide: Text.ElideRight
            }

            Rectangle {
                height: 18; width: codecLabel.implicitWidth + 10
                radius: 4
                color: Qt.rgba(255/255,92/255,26/255,0.12)
                visible: root.codec !== ""

                Text {
                    id: codecLabel
                    anchors.centerIn: parent
                    text: root.codec
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: "#FF5C1A"
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                var pt = ma.mapToItem(Controls.Overlay.overlay, mouse.x, mouse.y)
                cardMenu.x = pt.x
                cardMenu.y = pt.y
                cardMenu.open()
            } else {
                root.playRequested(root.path, root.trackId)
            }
        }
    }

    TrackContextMenu {
        id: cardMenu
        trackId: root.trackId
        path:    root.path
        onPlayRequested:           (p, id) => root.playRequested(p, id)
        onPlayNextRequested:       (p, id) => root.playNextRequested(p, id)
        onAddToQueueRequested:     (p, id) => root.addToQueueRequested(p, id)
        onEditRequested:           (id)    => root.editRequested(id)
        onAddToPlaylistRequested:  (id)    => root.addToPlaylistRequested(id)
    }
}
