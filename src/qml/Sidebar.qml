import QtQuick
import QtQuick.Layouts
import AuradecApp

Rectangle {
    id: root
    width: 272
    color: Qt.rgba(14/255, 11/255, 19/255, 0.95)

    property string activeTab: "library"
    property int    librarySubTab: 0  // 0=tracks 1=artists 2=albums

    signal tabChanged(string tab)
    signal libraryTabSelected(int idx)

    // Top border right edge
    Rectangle {
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 1; color: Qt.rgba(1,1,1,0.06)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 16
        spacing: 0

        // Logo
        Row {
            Layout.leftMargin: 24
            Layout.bottomMargin: 32
            spacing: 12

            Canvas {
                width: 32; height: 32
                property real breathe: 1.0
                onPaint: {
                    var ctx = getContext("2d"), cx = 16, cy = 16
                    ctx.clearRect(0,0,32,32)
                    ctx.setLineDash([2,3])
                    ;[4,7,10,13].forEach(function(r,i){
                        ctx.globalAlpha = 0.25 + i*0.20
                        ctx.strokeStyle = "#FF5C1A"
                        ctx.lineWidth = 1.2
                        ctx.beginPath(); ctx.arc(cx,cy,r*breathe,0,Math.PI*2); ctx.stroke()
                    })
                    ctx.globalAlpha=1; ctx.fillStyle="#FF5C1A"
                    ctx.beginPath(); ctx.arc(cx,cy,3,0,Math.PI*2); ctx.fill()
                    ctx.setLineDash([])
                }
                SequentialAnimation on breathe {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.06; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.95; duration: 2000; easing.type: Easing.InOutSine }
                }
                onBreatheChanged: requestPaint()
            }

            Column {
                spacing: -2; anchors.verticalCenter: parent.verticalCenter
                Row {
                    Text { text: "AURA"; font.family: "Syne"; font.pixelSize: 14; font.weight: Font.ExtraBold; color: "#ECE5D8"; font.letterSpacing: 2 }
                    Text { text: "DEC"; font.family: "Syne"; font.pixelSize: 14; font.weight: Font.ExtraBold; color: "#FF5C1A"; font.letterSpacing: 2 }
                }
                Text { text: "music player"; font.family: "Barlow"; font.pixelSize: 10; color: Qt.rgba(236/255,229/255,216/255,0.30); font.letterSpacing: 1 }
            }
        }

        // Nav items
        Column {
            Layout.fillWidth: true
            spacing: 2

            NavItem { label:"Library";     icon:"♪"; active: root.activeTab==="library";     onClicked: root.tabChanged("library") }

            // Library subnav
            Column {
                width: parent.width
                visible: root.activeTab === "library"
                spacing: 0

                SubNavItem { label:"Tracks";  count: libraryModel.count; active: root.librarySubTab===0; onClicked: root.libraryTabSelected(0) }
                SubNavItem { label:"Artists"; count: artistModel.count;  active: root.librarySubTab===1; onClicked: root.libraryTabSelected(1) }
                SubNavItem { label:"Albums";  count: albumModel.count;   active: root.librarySubTab===2; onClicked: root.libraryTabSelected(2) }
            }

            NavItem { label:"Now Playing"; icon:"▶"; active: root.activeTab==="nowplaying"; onClicked: root.tabChanged("nowplaying") }
            NavItem { label:"Playlists";   icon:"☰"; active: root.activeTab==="playlists";  onClicked: root.tabChanged("playlists") }
            NavItem { label:"Radio";       icon:"📡"; active: root.activeTab==="radio";      onClicked: root.tabChanged("radio") }
            NavItem { label:"Stats";       icon:"◈"; active: root.activeTab==="stats";       onClicked: root.tabChanged("stats") }
            NavItem { label:"Settings";    icon:"⚙"; active: root.activeTab==="settings";   onClicked: root.tabChanged("settings") }
        }

        Item { Layout.fillHeight: true }

        // Mini now-playing info
        Rectangle {
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            Layout.fillWidth: true
            height: currentTrack.id > 0 ? 56 : 0
            visible: height > 0
            radius: 12
            color: Qt.rgba(255/255,92/255,26/255,0.07)
            border.color: Qt.rgba(255/255,92/255,26/255,0.15)

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 10

                // Animated EQ bars
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: [0.6, 1.0, 0.4, 0.8, 0.5]
                        delegate: Rectangle {
                            width: 3; radius: 1.5
                            color: "#FF5C1A"
                            anchors.bottom: parent ? parent.bottom : undefined
                            property real maxH: 16 * modelData

                            height: audioEngine.playing ? maxH : 3

                            SequentialAnimation on height {
                                running: audioEngine.playing
                                loops: Animation.Infinite
                                NumberAnimation { to: maxH * 0.3; duration: 200 + index * 80; easing.type: Easing.InOutSine }
                                NumberAnimation { to: maxH;       duration: 200 + index * 60; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 40

                    Text {
                        width: parent.width
                        text: currentTrack.title || "Unknown"
                        font.family: "Barlow"; font.pixelSize: 12; font.weight: Font.Medium
                        color: "#ECE5D8"; elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: currentTrack.artist || "Unknown Artist"
                        font.family: "Barlow"; font.pixelSize: 11
                        color: Qt.rgba(236/255,229/255,216/255,0.45); elide: Text.ElideRight
                    }
                }
            }
        }

        // Storage widget
        Rectangle {
            id: storageWidget
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            height: statsCol.implicitHeight + 16
            radius: 12
            color: Qt.rgba(1,1,1,0.04)
            border.color: Qt.rgba(1,1,1,0.06)
            Layout.fillWidth: true

            property var codecData: {
                if (libraryModel.count === 0) return []
                var stats = trackDb.codecStats()
                var colors = ["#FF5C1A","#F5B32A","#29F89E","#FF4D6A","#A78BFA"]
                var result = []
                var i = 0
                for (var codec in stats) {
                    result.push({ name: codec, count: stats[codec],
                                  frac: stats[codec] / libraryModel.count,
                                  color: colors[i % colors.length] })
                    if (++i >= 5) break
                }
                return result
            }

            Column {
                id: statsCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 14; anchors.rightMargin: 14
                anchors.topMargin: 10
                spacing: 8

                Item {
                    width: parent.width; height: 16

                    Text {
                        text: "Library"
                        font.family: "Barlow"; font.pixelSize: 11
                        color: Qt.rgba(236/255,229/255,216/255,0.40)
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: libraryModel.count + " tracks"
                        font.family: "JetBrains Mono"; font.pixelSize: 10
                        color: Qt.rgba(236/255,229/255,216/255,0.30)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Progress bar segments
                Rectangle {
                    width: parent.width; height: 4; radius: 2; color: "#1a1520"

                    Row {
                        anchors.fill: parent; spacing: 0

                        Repeater {
                            model: storageWidget.codecData
                            delegate: Rectangle {
                                height: parent.height
                                width: modelData.frac * parent.width
                                color: modelData.color
                                radius: index === 0 ? 2 : 0
                            }
                        }
                    }
                }

                // Codec legend
                Flow {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: storageWidget.codecData
                        delegate: Row {
                            spacing: 4

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: modelData.color
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name + " " + modelData.count
                                font.family: "JetBrains Mono"; font.pixelSize: 9
                                color: Qt.rgba(236/255,229/255,216/255,0.35)
                            }
                        }
                    }
                }
            }
        }
    }

}
