import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    width: parent.width
    height: 44

    property string label: ""
    property string icon:  ""
    property bool   active: false
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        radius: 999
        color: root.active
               ? Qt.rgba(255/255, 92/255, 26/255, 0.12)
               : (ma.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            spacing: 12

            Text {
                text: root.icon
                font.pixelSize: 16
                color: root.active ? "#FF5C1A" : Qt.rgba(236/255,229/255,216/255,0.6)
                width: 20
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.label
                font.family: "Barlow"
                font.pixelSize: 14
                font.weight: root.active ? Font.Medium : Font.Normal
                color: root.active ? "#ECE5D8" : Qt.rgba(236/255,229/255,216/255,0.6)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: 3
            height: 20
            radius: 2
            color: "#FF5C1A"
            anchors.right: parent.right
            anchors.rightMargin: -1
            anchors.verticalCenter: parent.verticalCenter
            visible: root.active
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
