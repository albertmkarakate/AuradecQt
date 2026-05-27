import QtQuick
import QtQuick.Controls.Basic as Controls

Controls.Menu {
    id: root

    property int    trackId: -1
    property string path:    ""

    signal playRequested(string path, int id)
    signal playNextRequested(string path, int id)
    signal addToQueueRequested(string path, int id)
    signal editRequested(int id)
    signal addToPlaylistRequested(int trackId)

    parent: Controls.Overlay.overlay
    background: Rectangle { color: "#1a1520"; radius: 10; border.color: Qt.rgba(1,1,1,0.10) }

    Controls.MenuItem {
        text: "Play"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: root.playRequested(root.path, root.trackId)
    }
    Controls.MenuItem {
        text: "Play Next"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: root.playNextRequested(root.path, root.trackId)
    }
    Controls.MenuItem {
        text: "Add to Queue"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: root.addToQueueRequested(root.path, root.trackId)
    }
    Controls.MenuItem {
        text: "Add to Playlist…"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: root.addToPlaylistRequested(root.trackId)
    }
    Controls.MenuItem {
        text: "Toggle Favorite"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: trackDb.toggleFavorite(root.trackId)
    }
    Controls.MenuItem {
        text: "Edit Track Info"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: root.editRequested(root.trackId)
    }
    Controls.MenuItem {
        text: "Show in Files"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(255/255,92/255,26/255,0.12) : "transparent"; radius: 8 }
        onTriggered: Qt.openUrlExternally("file://" + root.path.substring(0, root.path.lastIndexOf("/")))
    }
    Controls.MenuSeparator {
        contentItem: Rectangle { implicitHeight: 1; color: Qt.rgba(1,1,1,0.08) }
    }
    Controls.MenuItem {
        text: "Remove from Library"
        contentItem: Text { text: parent.text; font.family: "Barlow"; font.pixelSize: 13; color: "#FF4D6A"; leftPadding: 12 }
        background: Rectangle { color: parent.highlighted ? Qt.rgba(1,0.30,0.42,0.12) : "transparent"; radius: 8 }
        onTriggered: {
            trackDb.deleteTrack(root.trackId)
            libraryModel.doReload()
        }
    }
}
