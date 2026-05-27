import QtQuick
import AuradecApp

Item {
    id: root
    property string name:    ""
    property string artist:  ""
    property int    coverId: 0
    signal drillRequested(string name)

    Rectangle {
        anchors.centerIn: parent
        width: 184; height: 224
        radius: 20; color: "#110E18"
        border.color: ma.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.25) : Qt.rgba(1,1,1,0.06)
        transform: Translate { y: ma.containsMouse ? -3 : 0; Behavior on y { NumberAnimation { duration: 150 } } }

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 8

            Rectangle {
                width: parent.width; height: width
                radius: 12; color: "#1a1520"; clip: true

                GradientPlaceholder {
                    anchors.fill: parent; radius: 12
                    seed: root.name; showNote: false
                    visible: root.coverId <= 0 || coverImg.status !== Image.Ready
                }
                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: root.coverId > 0 ? "image://artwork/" + root.coverId : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: root.coverId > 0 && status === Image.Ready
                }
            }

            Text {
                width: parent.width
                text: root.name; font.family: "Syne"; font.pixelSize: 13; font.weight: Font.Bold
                color: "#ECE5D8"; elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.artist; font.family: "Barlow"; font.pixelSize: 12
                color: Qt.rgba(236/255,229/255,216/255,0.50); elide: Text.ElideRight
            }
        }

        MouseArea {
            id: ma; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: root.drillRequested(root.name)
        }
    }
}
