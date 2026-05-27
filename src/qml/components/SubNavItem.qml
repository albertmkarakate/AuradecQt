import QtQuick

Item {
    id: root
    width: parent.width
    height: 36

    property string label: ""
    property int    count: 0
    property bool   active: false
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 12
        radius: 6
        color: root.active
               ? Qt.rgba(255/255,92/255,26/255,0.10)
               : (ma.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent")

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            spacing: 8

            Rectangle {
                width: 5; height: 5; radius: 3
                color: root.active ? "#FF5C1A" : Qt.rgba(236/255,229/255,216/255,0.25)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.label
                font.family: "Barlow"
                font.pixelSize: 13
                color: root.active ? "#ECE5D8" : Qt.rgba(236/255,229/255,216/255,0.5)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.count > 0 ? root.count : ""
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: Qt.rgba(236/255,229/255,216/255,0.30)
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
