import QtQuick

Item {
    id: root
    property var   artworkData: null
    property int   radius: 8
    property color placeholderColor: "#1a1520"

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.placeholderColor
        visible: img.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: "♫"
            font.pixelSize: parent.width * 0.38
            color: "#3a2e4a"
        }
    }

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.artworkData ? "image://artwork/" + encodeURIComponent(JSON.stringify(root.artworkData)) : ""
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: null

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.color: "transparent"
            clip: true
        }
    }
}
