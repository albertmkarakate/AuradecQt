import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

Item {
    id: root

    // Stations list — preset + user-added custom
    property var stations: [
        { id: "r1", name: "Lagos Heat",      genre: "Afrobeats",   country: "Nigeria",      color: "#FF5C1A", url: "" },
        { id: "r2", name: "Soweto Pulse",    genre: "Amapiano",    country: "South Africa", color: "#29F89E", url: "" },
        { id: "r3", name: "Kampala Tonight", genre: "Afro-fusion", country: "Uganda",       color: "#F5B32A", url: "" },
        { id: "r4", name: "Accra Jazz Club", genre: "Highlife",    country: "Ghana",        color: "#FF4D6A", url: "" },
        { id: "r5", name: "Nairobi Sundown", genre: "Genge",       country: "Kenya",        color: "#60A5FA", url: "" },
        { id: "r6", name: "Dakar Drum FM",   genre: "Mbalax",      country: "Senegal",      color: "#A78BFA", url: "" },
    ]

    property string activeStationId: ""
    property string addUrlText: ""

    function playStation(station) {
        if (!station.url || station.url.trim() === "") return
        activeStationId = station.id
        audioEngine.play(station.url.trim())
    }

    function stopStation() {
        activeStationId = ""
        audioEngine.stop()
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        contentHeight: mainCol.implicitHeight
        clip: true

        Column {
            id: mainCol
            width: parent.width
            spacing: 32

            // Header
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Radio"
                    font.family: "Syne"; font.pixelSize: 32; font.weight: Font.Bold
                    color: "#ECE5D8"
                }
                Text {
                    text: "Live cultural stations from around the world"
                    font.family: "Barlow"; font.pixelSize: 14
                    color: Qt.rgba(236/255,229/255,216/255,0.45)
                }
            }

            // Featured Stations eyebrow
            Text {
                text: "FEATURED STATIONS"
                font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Bold
                font.letterSpacing: 2
                color: "#F5B32A"
            }

            // Station grid
            Flow {
                id: stationGrid
                width: parent.width
                spacing: 16

                Repeater {
                    model: root.stations
                    delegate: RadioStationCard {
                        stationId: modelData.id
                        name:      modelData.name
                        genre:     modelData.genre
                        country:   modelData.country
                        accentColor: modelData.color
                        hasUrl:    modelData.url !== ""
                        active:    root.activeStationId === modelData.id

                        onPlayClicked: {
                            if (root.activeStationId === modelData.id) {
                                root.stopStation()
                            } else {
                                root.playStation(modelData)
                            }
                        }
                    }
                }
            }

            // Custom stations eyebrow
            Text {
                text: "CUSTOM STATIONS"
                font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Bold
                font.letterSpacing: 2
                color: Qt.rgba(236/255,229/255,216/255,0.35)
            }

            // Add stream row
            Rectangle {
                width: parent.width; height: 72; radius: 20
                color: Qt.rgba(1,1,1,0.03)
                border.color: Qt.rgba(1,1,1,0.06)
                border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12

                    Rectangle {
                        width: 40; height: 40; radius: 12
                        color: Qt.rgba(255/255,92/255,26/255,0.10)
                        border.color: Qt.rgba(255/255,92/255,26/255,0.20)

                        Text {
                            anchors.centerIn: parent; text: "+"
                            font.pixelSize: 22; color: "#FF5C1A"
                        }
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 6

                        Text {
                            text: "Add Custom Station"
                            font.family: "Barlow"; font.pixelSize: 14; font.weight: Font.Medium
                            color: "#ECE5D8"
                        }

                        Rectangle {
                            width: parent.width; height: 28; radius: 8
                            color: "#08060B"
                            border.color: urlInput.activeFocus ? Qt.rgba(255/255,92/255,26/255,0.5) : Qt.rgba(1,1,1,0.10)

                            TextInput {
                                id: urlInput
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Barlow"; font.pixelSize: 12
                                color: "#ECE5D8"
                                clip: true

                                Text {
                                    anchors.fill: parent; anchors.leftMargin: 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Paste Icecast · Shoutcast · HTTP stream URL…"
                                    font.family: "Barlow"; font.pixelSize: 12
                                    color: Qt.rgba(236/255,229/255,216/255,0.25)
                                    visible: urlInput.text.length === 0
                                }

                                onAccepted: addStreamBtn.addStream()
                            }
                        }
                    }

                    Rectangle {
                        id: addStreamBtn
                        height: 36; width: addStreamLabel.implicitWidth + 24; radius: 18
                        color: addStreamMa.containsMouse ? Qt.rgba(255/255,92/255,26/255,0.85) : Qt.rgba(255/255,92/255,26/255,0.70)
                        enabled: urlInput.text.trim().length > 0

                        function addStream() {
                            var url = urlInput.text.trim()
                            if (!url) return
                            var newStation = {
                                id: "custom_" + Date.now(),
                                name: "Custom Stream",
                                genre: "Stream",
                                country: "",
                                color: "#FF5C1A",
                                url: url
                            }
                            root.stations = root.stations.concat([newStation])
                            root.playStation(newStation)
                            urlInput.text = ""
                        }

                        Text {
                            id: addStreamLabel; anchors.centerIn: parent
                            text: "Play Stream"
                            font.family: "Barlow"; font.pixelSize: 12; font.weight: Font.Bold
                            color: "white"
                        }
                        MouseArea {
                            id: addStreamMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            enabled: urlInput.text.trim().length > 0
                            onClicked: addStreamBtn.addStream()
                        }
                    }
                }
            }

            // Info text
            Text {
                text: "Preset station stream URLs are not pre-configured — paste an Icecast or Shoutcast stream URL above to tune in."
                font.family: "Barlow"; font.pixelSize: 11
                color: Qt.rgba(236/255,229/255,216/255,0.25)
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }

    // Inline component for station card
    component RadioStationCard: Rectangle {
        id: card
        width: 200; height: 180
        radius: 20
        color: active
               ? Qt.lighter(accentColor, 0.1)
               : (cardMa.containsMouse ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03))
        border.color: active
                      ? Qt.rgba(parseInt(accentColor.slice(1,3),16)/255,
                                parseInt(accentColor.slice(3,5),16)/255,
                                parseInt(accentColor.slice(5,7),16)/255, 0.50)
                      : (cardMa.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06))
        border.width: 1

        property string stationId:   ""
        property string name:        ""
        property string genre:       ""
        property string country:     ""
        property string accentColor: "#FF5C1A"
        property bool   hasUrl:      false
        property bool   active:      false

        signal playClicked()

        transform: Translate {
            y: cardMa.containsMouse ? -4 : 0
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Column {
            anchors.fill: parent; anchors.margins: 20
            spacing: 0

            // Icon circle
            Rectangle {
                width: 48; height: 48; radius: 14
                color: Qt.rgba(
                    parseInt(card.accentColor.slice(1,3),16)/255,
                    parseInt(card.accentColor.slice(3,5),16)/255,
                    parseInt(card.accentColor.slice(5,7),16)/255, 0.13)
                border.color: Qt.rgba(
                    parseInt(card.accentColor.slice(1,3),16)/255,
                    parseInt(card.accentColor.slice(3,5),16)/255,
                    parseInt(card.accentColor.slice(5,7),16)/255, 0.25)

                Text {
                    anchors.centerIn: parent; text: "📡"
                    font.pixelSize: 22
                }
            }

            Item { width: 1; height: 14 }

            // Name
            Text {
                width: parent.width
                text: card.name
                font.family: "Syne"; font.pixelSize: 15; font.weight: Font.Bold
                color: "#ECE5D8"; elide: Text.ElideRight
            }

            Item { width: 1; height: 4 }

            // Genre · Country
            Row {
                spacing: 4
                Text {
                    text: card.genre
                    font.family: "Barlow"; font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.55)
                }
                Text {
                    text: "·"
                    font.family: "Barlow"; font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.25)
                    visible: card.country !== ""
                }
                Text {
                    text: card.country
                    font.family: "Barlow"; font.pixelSize: 11
                    color: Qt.rgba(236/255,229/255,216/255,0.55)
                    visible: card.country !== ""
                }
            }

            Item { width: 1; height: 14 }

            // Status row
            Row {
                spacing: 8
                height: 16

                // Animated EQ bars when active
                Row {
                    spacing: 2
                    height: 14
                    visible: card.active
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: [5, 8, 6, 9, 4, 7]
                        delegate: Rectangle {
                            width: 2; radius: 1
                            color: card.accentColor

                            property real baseH: modelData * 1.4

                            height: baseH

                            SequentialAnimation on height {
                                running: card.active
                                loops: Animation.Infinite
                                NumberAnimation { to: baseH * 0.3; duration: 300 + index * 60; easing.type: Easing.InOutSine }
                                NumberAnimation { to: baseH;       duration: 300 + index * 60; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.active ? "● LIVE" : (card.hasUrl ? "○ TAP TO LISTEN" : "○ NO STREAM")
                    font.family: "JetBrains Mono"; font.pixelSize: 9; font.weight: Font.Bold
                    font.letterSpacing: 1.8
                    color: card.active
                           ? card.accentColor
                           : Qt.rgba(236/255,229/255,216/255,card.hasUrl ? 0.35 : 0.20)
                }
            }
        }

        MouseArea {
            id: cardMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: card.hasUrl ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (card.hasUrl) card.playClicked() }
        }
    }
}
