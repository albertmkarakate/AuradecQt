import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property alias title:    metaTitleInput.text
    property alias artist:   metaArtistInput.text
    property alias album:    metaAlbumInput.text
    property alias genre:    metaGenreInput.text
    property alias composer: metaComposerInput.text
    property alias year:     metaYearInput.text
    property string rating:  "0"

    GridLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        columns: 2
        rowSpacing: 16
        columnSpacing: 20

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Track Title *"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaTitleInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaTitleInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" } } }

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Artist"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaArtistInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaArtistInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" } } }

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Album"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaAlbumInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaAlbumInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" } } }

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Genre"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaGenreInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaGenreInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" } } }

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Composer"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaComposerInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaComposerInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8" } } }

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Release Year"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaYearInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaYearInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                    validator: IntValidator { bottom: 0; top: 9999 } } } }

        ColumnLayout { spacing: 8; Layout.fillWidth: true
            Text { text: "RATING"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Row {
                spacing: 6
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        width: 32; height: 32; radius: 16
                        color: index < parseInt(root.rating)
                               ? Qt.rgba(255/255,92/255,26/255,0.85)
                               : (starMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.18) : Qt.rgba(1,1,1,0.06))
                        border.color: index < parseInt(root.rating) ? "#FF5C1A" : Qt.rgba(1,1,1,0.12)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "★"; font.pixelSize: 15
                               color: index < parseInt(root.rating) ? "white" : Qt.rgba(236,229,216,0.28) }
                        MouseArea { id: starMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.rating = (index + 1 === parseInt(root.rating)) ? "0" : String(index + 1) }
                    }
                }
                Text {
                    text: parseInt(root.rating) > 0 ? parseInt(root.rating) + " / 5" : "Not rated"
                    font.family: "Barlow"; font.pixelSize: 11
                    color: Qt.rgba(236,229,216,0.35); anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 8
                }
            }
        }
    }
}
