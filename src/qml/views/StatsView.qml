import QtQuick
import QtQuick.Layouts
import AuradecApp

Item {
    id: root

    property var topPlayed:   []
    property var recentPlayed: []
    property var codecData:   []

    function refresh() {
        var all = trackDb.allTracks("", "", "", false, "playCount", false)
        topPlayed = all.filter(function(t) { return t.playCount > 0 }).slice(0, 10)
        var rec = trackDb.allTracks("", "", "", false, "lastPlayed", false)
        recentPlayed = rec.filter(function(t) { return t.lastPlayed > 0 }).slice(0, 8)
        var stats = trackDb.codecStats()
        var colors = ["#FF5C1A","#F5B32A","#29F89E","#FF4D6A","#A78BFA","#60A5FA"]
        var total = libraryModel.count || 1
        var r = []; var i = 0
        for (var c in stats) {
            r.push({ name: c.toUpperCase(), count: stats[c], frac: stats[c] / total, color: colors[i % colors.length] })
            if (++i >= 6) break
        }
        codecData = r
    }

    Component.onCompleted: refresh()
    Connections { target: libraryModel; function onCountChanged() { Qt.callLater(refresh) } }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40; anchors.rightMargin: 40
        anchors.topMargin: 32; anchors.bottomMargin: 32
        contentHeight: mainCol.implicitHeight + 32
        clip: true

        Column {
            id: mainCol
            width: parent.width
            spacing: 28

            Column {
                width: parent.width; spacing: 4
                Text {
                    text: "Statistics"
                    font.family: "Syne"; font.pixelSize: 32; font.weight: Font.Bold
                    color: "#ECE5D8"
                }
                Text {
                    text: "Library insights and playback history"
                    font.family: "Barlow"; font.pixelSize: 14
                    color: Qt.rgba(236/255,229/255,216/255,0.45)
                }
            }

            // Totals row
            Row {
                width: parent.width; spacing: 16

                Repeater {
                    model: [
                        { label: "Tracks",  value: libraryModel.count,  icon: "♫" },
                        { label: "Artists", value: artistModel.count,   icon: "♪" },
                        { label: "Albums",  value: albumModel.count,    icon: "◉" },
                        { label: "Played",  value: root.topPlayed.length > 0 ?
                                            root.topPlayed.reduce(function(acc, t){ return acc + t.playCount }, 0) : 0,
                                            icon: "▶" }
                    ]
                    delegate: Rectangle {
                        width: (mainCol.width - 48) / 4; height: 88
                        radius: 16; color: "#0E0B13"
                        border.color: Qt.rgba(1,1,1,0.06)

                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon; font.pixelSize: 20
                                color: "#FF5C1A"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                font.family: "Syne"; font.pixelSize: 22; font.weight: Font.Bold
                                color: "#ECE5D8"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: "Barlow"; font.pixelSize: 11
                                color: Qt.rgba(236/255,229/255,216/255,0.40)
                                font.letterSpacing: 0.5
                            }
                        }
                    }
                }
            }

            // Two-column: Top Played + Codec breakdown
            RowLayout {
                width: parent.width; spacing: 16

                // Top Played
                Rectangle {
                    Layout.fillWidth: true
                    height: topPlayedContent.implicitHeight + 32
                    radius: 16; color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)

                    Column {
                        id: topPlayedContent
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top; anchors.margins: 20
                        spacing: 0

                        Text {
                            text: "TOP PLAYED"
                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Bold
                            font.letterSpacing: 2; color: "#F5B32A"
                        }
                        Item { width: 1; height: 12 }

                        Repeater {
                            model: root.topPlayed
                            delegate: Item {
                                width: parent.width; height: 44

                                Rectangle {
                                    anchors.bottom: parent.bottom; height: 1; width: parent.width
                                    color: Qt.rgba(1,1,1,0.04)
                                }

                                RowLayout {
                                    anchors.fill: parent; spacing: 8

                                    Text {
                                        text: (index + 1) + "."
                                        font.family: "JetBrains Mono"; font.pixelSize: 11
                                        color: Qt.rgba(236/255,229/255,216/255,0.25)
                                        Layout.preferredWidth: 24
                                    }

                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            width: parent.width
                                            text: modelData.title || "Unknown"
                                            font.family: "Barlow"; font.pixelSize: 13; color: "#ECE5D8"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: modelData.artist || "Unknown Artist"
                                            font.family: "Barlow"; font.pixelSize: 11
                                            color: Qt.rgba(236/255,229/255,216/255,0.45)
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        height: 20; width: playsLbl.implicitWidth + 12; radius: 10
                                        color: Qt.rgba(255/255,92/255,26/255,0.12)
                                        Text {
                                            id: playsLbl; anchors.centerIn: parent
                                            text: modelData.playCount + "×"
                                            font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#FF5C1A"
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.topPlayed.length === 0
                            text: "No plays recorded yet"
                            font.family: "Barlow"; font.pixelSize: 13
                            color: Qt.rgba(236/255,229/255,216/255,0.30)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 20
                        }
                    }
                }

                // Codec breakdown
                Rectangle {
                    Layout.preferredWidth: mainCol.width * 0.36
                    height: topPlayedContent.implicitHeight + 32
                    radius: 16; color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)

                    Column {
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top; anchors.margins: 20
                        spacing: 0

                        Text {
                            text: "FORMAT BREAKDOWN"
                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Bold
                            font.letterSpacing: 2; color: "#29F89E"
                        }
                        Item { width: 1; height: 16 }

                        Rectangle {
                            width: parent.width; height: 6; radius: 3; color: "#1a1520"

                            Row {
                                anchors.fill: parent; spacing: 0
                                Repeater {
                                    model: root.codecData
                                    delegate: Rectangle {
                                        height: parent.height
                                        width: modelData.frac * parent.width
                                        color: modelData.color
                                        radius: index === 0 ? 3 : 0
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 12 }

                        Repeater {
                            model: root.codecData
                            delegate: Item {
                                width: parent.width; height: 36

                                RowLayout {
                                    anchors.fill: parent; spacing: 8

                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: modelData.color
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "JetBrains Mono"; font.pixelSize: 12
                                        color: "#ECE5D8"; Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.count + " tracks"
                                        font.family: "Barlow"; font.pixelSize: 11
                                        color: Qt.rgba(236/255,229/255,216/255,0.40)
                                    }

                                    Text {
                                        text: Math.round(modelData.frac * 100) + "%"
                                        font.family: "JetBrains Mono"; font.pixelSize: 11
                                        color: modelData.color
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.codecData.length === 0
                            text: "No library data"
                            font.family: "Barlow"; font.pixelSize: 13
                            color: Qt.rgba(236/255,229/255,216/255,0.30)
                            anchors.topMargin: 20
                        }
                    }
                }
            }

            // Recently Played
            Rectangle {
                width: parent.width
                height: recentContent.implicitHeight + 32
                radius: 16; color: "#0E0B13"; border.color: Qt.rgba(1,1,1,0.06)
                visible: root.recentPlayed.length > 0

                Column {
                    id: recentContent
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "RECENTLY PLAYED"
                        font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 2; color: "#A78BFA"
                    }
                    Item { width: 1; height: 12 }

                    Flow {
                        width: parent.width; spacing: 8

                        Repeater {
                            model: root.recentPlayed
                            delegate: Rectangle {
                                height: 52; width: (recentContent.width - 24) / 4
                                radius: 12; color: "#16121E"
                                border.color: Qt.rgba(1,1,1,0.06)

                                Column {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 2
                                    Text {
                                        width: parent.width
                                        text: modelData.title || "Unknown"
                                        font.family: "Barlow"; font.pixelSize: 12; color: "#ECE5D8"
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData.artist || "Unknown"
                                        font.family: "Barlow"; font.pixelSize: 10
                                        color: Qt.rgba(236/255,229/255,216/255,0.45)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
