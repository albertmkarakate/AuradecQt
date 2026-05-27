import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

Item {
    id: root
    width: parent.width
    height: 60

    property int    trackId:  -1
    property string path:     ""
    property string title:    ""
    property string artist:   ""
    property string album:    ""
    property string codec:    ""
    property int    bitrate:    0
    property int    duration:   0
    property int    playCount:  0
    property int    rating:     0
    property bool   hasArtwork: false
    property bool   playing:    false

    signal playRequested(string path, int id)
    signal playNextRequested(string path, int id)
    signal addToQueueRequested(string path, int id)
    signal editRequested(int id)
    signal addToPlaylistRequested(int id)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        radius: 10
        color: root.playing
               ? Qt.rgba(255/255,92/255,26/255,0.08)
               : (ma.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 12

            // Artwork / play indicator
            Rectangle {
                width: 36; height: 36
                radius: 8
                color: "#1a1520"
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: listArtImg
                    anchors.fill: parent
                    source: (root.hasArtwork && root.trackId > 0) ? "image://artwork/" + root.trackId : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready && !root.playing
                }

                Text {
                    anchors.centerIn: parent
                    text: root.playing ? "▶" : "♫"
                    font.pixelSize: root.playing ? 14 : 16
                    color: root.playing ? "#FF5C1A" : "#3a2e4a"
                    visible: root.playing || listArtImg.status !== Image.Ready
                }
            }

            // Title + artist
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: root.title || "Unknown"
                    font.family: "Barlow"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: root.playing ? "#FF5C1A" : "#ECE5D8"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.artist || "Unknown Artist"
                    font.family: "Barlow"
                    font.pixelSize: 12
                    color: Qt.rgba(236/255,229/255,216/255,0.5)
                    elide: Text.ElideRight
                }
            }

            // Codec badge
            Rectangle {
                height: 18
                width: codecTxt.implicitWidth + 10
                radius: 4
                color: Qt.rgba(255/255,92/255,26/255,0.12)
                visible: root.codec !== ""
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: codecTxt
                    anchors.centerIn: parent
                    text: root.codec
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: "#FF5C1A"
                }
            }

            // Play count
            Text {
                text: root.playCount > 0 ? root.playCount + "×" : ""
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: Qt.rgba(236/255,229/255,216/255,0.25)
                Layout.alignment: Qt.AlignVCenter
                width: 30
                horizontalAlignment: Text.AlignRight
            }

            // Bitrate
            Text {
                text: root.bitrate > 0 ? root.bitrate + "k" : ""
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: Qt.rgba(236/255,229/255,216/255,0.30)
                Layout.alignment: Qt.AlignVCenter
                width: 36
                horizontalAlignment: Text.AlignRight
            }

            // Rating dots (0–5)
            Row {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                visible: root.rating > 0
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        width: 6; height: 6; radius: 3
                        color: index < root.rating ? "#FF5C1A" : Qt.rgba(255/255,92/255,26/255,0.18)
                    }
                }
            }

            // Duration
            Text {
                text: {
                    if (!root.duration) return "--:--"
                    var s = Math.floor(root.duration / 1000)
                    var m = Math.floor(s / 60)
                    var sec = s % 60
                    return m + ":" + (sec < 10 ? "0" : "") + sec
                }
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: Qt.rgba(236/255,229/255,216/255,0.50)
                Layout.alignment: Qt.AlignVCenter
                width: 44
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 60
            height: 1
            color: Qt.rgba(1,1,1,0.05)
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
                contextMenu.x = pt.x
                contextMenu.y = pt.y
                contextMenu.open()
            } else {
                root.playRequested(root.path, root.trackId)
            }
        }
    }

    TrackContextMenu {
        id: contextMenu
        trackId: root.trackId
        path:    root.path
        onPlayRequested:          (p, id) => root.playRequested(p, id)
        onPlayNextRequested:      (p, id) => root.playNextRequested(p, id)
        onAddToQueueRequested:    (p, id) => root.addToQueueRequested(p, id)
        onEditRequested:          (id)    => root.editRequested(id)
        onAddToPlaylistRequested: (id)    => root.addToPlaylistRequested(id)
    }
}
