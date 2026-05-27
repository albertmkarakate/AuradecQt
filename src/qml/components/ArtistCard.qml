import QtQuick

Item {
    id: root
    property string name:     ""
    property int    count:    0
    property string imageUrl: ""
    signal drillRequested(string name)

    Rectangle {
        anchors.centerIn: parent
        width: 164; height: 180
        radius: 20; color: "#110E18"
        border.color: ma.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.25) : Qt.rgba(1,1,1,0.06)
        transform: Translate { y: ma.containsMouse ? -3 : 0; Behavior on y { NumberAnimation { duration: 150 } } }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 72; height: 72; radius: 36; color: "#1a1520"
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                Image {
                    id: artistImg
                    anchors.fill: parent
                    source: root.imageUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: root.imageUrl !== "" && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: root.name ? root.name[0].toUpperCase() : "?"
                    font.family: "Syne"; font.pixelSize: 28; font.weight: Font.Bold
                    color: "#FF5C1A"
                    visible: root.imageUrl === "" || artistImg.status !== Image.Ready
                }
            }

            Text {
                width: 140; anchors.horizontalCenter: parent.horizontalCenter
                text: root.name; font.family: "Barlow"; font.pixelSize: 13
                color: "#ECE5D8"; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight; wrapMode: Text.NoWrap
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.count + " tracks"
                font.family: "Barlow"; font.pixelSize: 11
                color: Qt.rgba(236/255,229/255,216/255,0.40)
            }
        }

        MouseArea {
            id: ma; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: root.drillRequested(root.name)
        }
    }
}
