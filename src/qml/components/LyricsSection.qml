import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

Item {
    id: root
    property alias lyrics: lyricsText.text
    property string geminiApiKey: ""
    property string trackTitle:   ""
    property string trackArtist:  ""
    property bool   aiWorking:    false
    property string aiError:      ""

    Connections {
        target: geminiClient
        function onLyricsReady(text) {
            if (!root.aiWorking) return
            root.aiWorking = false; root.aiError = ""
            lyricsText.text = text
        }
        function onFetchError(msg) {
            if (!root.aiWorking) return
            root.aiWorking = false; root.aiError = msg
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Lyrics"
                font.family: "JetBrains Mono"; font.pixelSize: 10; font.letterSpacing: 1
                color: Qt.rgba(236,229,216,0.45); Layout.fillWidth: true
            }
            Text {
                visible: root.aiError !== ""; text: root.aiError
                font.family: "Barlow"; font.pixelSize: 10
                color: Qt.rgba(255,92,26,0.80)
                Layout.maximumWidth: 180; elide: Text.ElideRight
            }
            Rectangle {
                height: 28; width: aiLabel.implicitWidth + 20; radius: 10
                color: aiBtnMa.containsMouse ? Qt.rgba(255,92,26,0.25) : Qt.rgba(255,92,26,0.15)
                border.color: Qt.rgba(255,92,26,0.35)
                visible: root.geminiApiKey !== ""
                enabled: !root.aiWorking && root.trackTitle !== ""
                opacity: enabled ? 1.0 : 0.5
                Text { id: aiLabel; anchors.centerIn: parent
                    text: root.aiWorking ? "Generating…" : "✨ AI Lyrics"
                    font.family: "Barlow"; font.pixelSize: 10; font.weight: Font.DemiBold; color: "#FF5C1A" }
                MouseArea { id: aiBtnMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: parent.enabled
                    onClicked: {
                        root.aiWorking = true; root.aiError = ""
                        geminiClient.fetchLyrics(root.trackTitle, root.trackArtist, root.geminiApiKey)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Qt.rgba(1,1,1,0.05)
            border.color: lyricsText.activeFocus ? Qt.rgba(255,92,26,0.5) : Qt.rgba(1,1,1,0.10)

            Flickable {
                id: lyricsFlick
                anchors.fill: parent; anchors.margins: 4
                contentWidth: parent.width - 8
                contentHeight: lyricsText.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                TextEdit {
                    id: lyricsText
                    width: lyricsFlick.width - 12
                    font.family: "Barlow"; font.pixelSize: 13
                    color: "#ECE5D8"
                    wrapMode: Text.WordWrap
                    selectByMouse: true
                    selectionColor: Qt.rgba(255,92,26,0.30)
                }
            }
        }

        Text {
            text: root.geminiApiKey !== ""
                  ? "Tip: Click ✨ AI Lyrics to auto-fill. You can edit the result before saving."
                  : "Tip: Paste lyrics or set a Gemini API key in Settings to enable AI generation."
            font.family: "Barlow"; font.pixelSize: 10
            color: Qt.rgba(236,229,216,0.25)
            wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
    }
}
