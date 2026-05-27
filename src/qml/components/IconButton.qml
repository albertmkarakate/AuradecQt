import QtQuick

Item {
    id: root
    width: 36; height: 36

    property string icon: ""
    property color  iconColor: Qt.rgba(236/255,229/255,216/255,0.6)
    property real   iconSize: 16
    property bool   toggled: false
    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.toggled
               ? Qt.rgba(255/255,92/255,26/255,0.15)
               : (ma.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent")

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: root.iconSize
            color: root.toggled ? "#FF5C1A" : root.iconColor
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
