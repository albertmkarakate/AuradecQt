import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import AuradecApp

Rectangle {
    id: root
    height: 112
    color: "#0A0810"

    signal nextClicked()
    signal prevClicked()
    signal shuffleToggled(bool on)
    signal repeatToggled(bool on)
    signal toggleLyrics()

    property bool shuffleOn: false
    property bool repeatOn:  false
    property bool lyricsVisible: false

    // Top border
    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.rgba(1,1,1,0.08) }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 0

        // Left — artwork + track info
        Row {
            spacing: 14
            Layout.preferredWidth: 280
            Layout.alignment: Qt.AlignVCenter

            // Artwork thumbnail
            Rectangle {
                width: 56; height: 56; radius: 10
                color: "#1a1520"
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: currentTrack.id > 0 && currentTrack.hasArtwork
                            ? "image://artwork/" + currentTrack.id
                            : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: currentTrack.hasArtwork && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent; text: "♫"
                    font.pixelSize: 24; color: "#3a2e4a"
                    visible: !currentTrack.hasArtwork || parent.children[0].status !== Image.Ready
                }
            }

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter
                width: 190

                Text {
                    width: parent.width
                    text: currentTrack.id > 0
                          ? (currentTrack.title || "Unknown")
                          : "No track selected"
                    font.family: "Barlow"; font.pixelSize: 14; font.weight: Font.Medium
                    color: "#ECE5D8"; elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: currentTrack.artist || "Unknown Artist"
                    font.family: "Barlow"; font.pixelSize: 12
                    color: Qt.rgba(236/255,229/255,216/255,0.50); elide: Text.ElideRight
                }

                Rectangle {
                    height: 16; width: codecBadge.implicitWidth + 8; radius: 3
                    color: Qt.rgba(255/255,92/255,26/255,0.12)
                    visible: currentTrack.codec !== ""

                    Text {
                        id: codecBadge
                        anchors.centerIn: parent
                        text: currentTrack.codec || "—"
                        font.family: "JetBrains Mono"; font.pixelSize: 9; color: "#FF5C1A"
                    }
                }
            }
        }

        // Center — transport + seek
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 10

            // Transport buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: ["⇄","⏮","▶","⏭","↺"]
                    delegate: Rectangle {
                        width: modelData === "▶" ? 44 : 36
                        height: width; radius: width / 2

                        readonly property bool isActive:
                            (modelData === "⇄" && root.shuffleOn) ||
                            (modelData === "↺" && root.repeatOn)

                        color: modelData === "▶"
                               ? (tMa.containsMouse ? "#FF7A40" : "#FF5C1A")
                               : isActive
                                 ? Qt.rgba(255/255,92/255,26/255,0.18)
                                 : (tMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04))

                        Text {
                            anchors.centerIn: parent
                            text: modelData === "▶" && audioEngine.playing ? "⏸" : modelData
                            font.pixelSize: modelData === "▶" ? 18 : 14
                            color: modelData === "▶" ? "white"
                                 : parent.isActive ? "#FF5C1A"
                                 : Qt.rgba(236/255,229/255,216/255,0.7)
                        }

                        MouseArea {
                            id: tMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                switch (modelData) {
                                    case "▶": audioEngine.playing ? audioEngine.pause() : audioEngine.resume(); break
                                    case "⏮": root.prevClicked(); break
                                    case "⏭": root.nextClicked(); break
                                    case "⇄": root.shuffleOn = !root.shuffleOn; root.shuffleToggled(root.shuffleOn); break
                                    case "↺": root.repeatOn  = !root.repeatOn;  root.repeatToggled(root.repeatOn);   break
                                }
                            }
                        }
                    }
                }
            }

            // Seek bar + timestamps
            RowLayout {
                width: parent.width
                spacing: 10

                Text {
                    text: formatMs(audioEngine.position)
                    font.family: "JetBrains Mono"; font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.50)
                }

                // Seek slider
                Item {
                    id: seekBar
                    Layout.fillWidth: true; height: 20
                    property bool   dragging: false
                    property real   dragFrac: 0

                    Rectangle {
                        id: seekTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2; color: "#1a1520"

                        Rectangle {
                            width: {
                                if (audioEngine.duration <= 0) return 0
                                var f = seekBar.dragging ? seekBar.dragFrac
                                                        : audioEngine.position / audioEngine.duration
                                return Math.max(0, Math.min(1, f)) * parent.width
                            }
                            height: parent.height; radius: 2; color: "#FF5C1A"
                            Behavior on width { enabled: !seekBar.dragging; NumberAnimation { duration: 200 } }
                        }
                    }

                    // Thumb — 4px always, grows to 12px on hover/drag
                    Rectangle {
                        id: seekThumb
                        property real sz: (seekMa.containsMouse || seekBar.dragging) ? 12 : 4
                        width: sz; height: sz; radius: sz / 2; color: "#FF5C1A"
                        anchors.verticalCenter: seekTrack.verticalCenter
                        x: {
                            if (audioEngine.duration <= 0) return -sz / 2
                            var f = seekBar.dragging ? seekBar.dragFrac
                                                     : audioEngine.position / audioEngine.duration
                            return Math.max(0, Math.min(1, f)) * seekBar.width - sz / 2
                        }
                        Behavior on sz { NumberAnimation { duration: 120 } }
                        scale: seekBar.dragging ? 1.2 : 1
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: seekMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            seekBar.dragging = true
                            seekBar.dragFrac = Math.max(0, Math.min(mouseX / width, 1))
                        }
                        onPositionChanged: {
                            if (pressed)
                                seekBar.dragFrac = Math.max(0, Math.min(mouseX / width, 1))
                        }
                        onReleased: {
                            if (audioEngine.duration > 0)
                                audioEngine.seek(seekBar.dragFrac * audioEngine.duration)
                            seekBar.dragging = false
                        }
                    }
                }

                Text {
                    text: formatMs(audioEngine.duration)
                    font.family: "JetBrains Mono"; font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.50)
                }
            }
        }

        // Right — lyrics toggle + volume
        Row {
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 10
            layoutDirection: Qt.RightToLeft

            // Lyrics toggle button
            Rectangle {
                width: 32; height: 32; radius: 8
                color: root.lyricsVisible
                       ? AuradecTheme.brandDim
                       : (lyrMa.containsMouse ? AuradecTheme.surfaceHover : "transparent")
                anchors.verticalCenter: parent.verticalCenter
                visible: currentTrack.id > 0

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    font.pixelSize: 20
                    color: root.lyricsVisible ? AuradecTheme.brand : AuradecTheme.textSecondary
                }

                MouseArea {
                    id: lyrMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleLyrics()
                }
            }

            Row {
                spacing: 8; anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "🔉"; font.pixelSize: 14
                    color: Qt.rgba(236/255,229/255,216/255,0.5)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: volBar
                    width: 80; height: 20; anchors.verticalCenter: parent.verticalCenter
                    property bool  dragging: false
                    property real  dragFrac: 0

                    Rectangle {
                        id: volTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2; color: "#1a1520"

                        Rectangle {
                            width: {
                                var f = volBar.dragging ? volBar.dragFrac : audioEngine.volume
                                return Math.max(0, Math.min(1, f)) * parent.width
                            }
                            height: parent.height; radius: 2; color: "#FF5C1A"
                        }
                    }

                    Rectangle {
                        width: 12; height: 12; radius: 6; color: "#FF5C1A"
                        anchors.verticalCenter: volTrack.verticalCenter
                        x: {
                            var f = volBar.dragging ? volBar.dragFrac : audioEngine.volume
                            return Math.max(0, Math.min(1, f)) * volBar.width - 6
                        }
                        visible: volMa.containsMouse || volBar.dragging
                        scale: volBar.dragging ? 1.3 : 1
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: volMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            volBar.dragging = true
                            volBar.dragFrac = Math.max(0, Math.min(mouseX / width, 1))
                        }
                        onPositionChanged: {
                            if (pressed) {
                                volBar.dragFrac = Math.max(0, Math.min(mouseX / width, 1))
                                audioEngine.setVolume(volBar.dragFrac)
                            }
                        }
                        onReleased: {
                            audioEngine.setVolume(volBar.dragFrac)
                            volBar.dragging = false
                        }
                    }
                }

                Text {
                    text: "🔊"; font.pixelSize: 14
                    color: Qt.rgba(236/255,229/255,216/255,0.5)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    function formatMs(ms) {
        if (!ms || ms <= 0) return "0:00"
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        var sec = s % 60
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }
}
