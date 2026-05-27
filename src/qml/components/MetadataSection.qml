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
    property alias rating:   metaRatingInput.text

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

        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "Rating (0-5)"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1; color: Qt.rgba(236,229,216,0.45) }
            Rectangle { Layout.fillWidth: true; height: 44; radius: 16; color: Qt.rgba(1,1,1,0.05); border.color: metaRatingInput.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)
                TextInput { id: metaRatingInput; anchors.fill: parent; anchors.margins: 14; verticalAlignment: TextInput.AlignVCenter
                    font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                    validator: IntValidator { bottom: 0; top: 5 } } } }
    }
}
