import QtQuick

Rectangle {
    id: root
    color: "#060507"
    signal dismissed()

    // Breathing logo rings
    Canvas {
        id: logo
        width: 120; height: 120
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -80

        property real breathe: 1.0
        property color ringColor: "#FF5C1A"

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = height / 2
            var radii = [10, 18, 27, 37, 48]
            ctx.setLineDash([4, 6])

            for (var i = 0; i < radii.length; i++) {
                ctx.globalAlpha = (0.15 + i * 0.17) * breathe
                ctx.strokeStyle = ringColor
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.arc(cx, cy, radii[i] * breathe, 0, Math.PI * 2)
                ctx.stroke()
            }
            ctx.globalAlpha = 1
            ctx.fillStyle = ringColor
            ctx.beginPath()
            ctx.arc(cx, cy, 4.5 * breathe, 0, Math.PI * 2)
            ctx.fill()
            ctx.setLineDash([])
        }

        SequentialAnimation on breathe {
            loops: Animation.Infinite
            NumberAnimation { to: 1.10; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.92; duration: 1600; easing.type: Easing.InOutSine }
        }
        onBreatheChanged: requestPaint()
    }

    // Wordmark
    Row {
        anchors.top: logo.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        Text {
            text: "AURA"
            font.family: "Syne"; font.pixelSize: 36; font.weight: Font.ExtraBold
            color: "#ECE5D8"
            font.letterSpacing: 6
        }
        Text {
            text: "DEC"
            font.family: "Syne"; font.pixelSize: 36; font.weight: Font.ExtraBold
            color: "#FF5C1A"
            font.letterSpacing: 6
        }
    }

    // Tagline
    Text {
        anchors.top: logo.bottom
        anchors.topMargin: 70
        anchors.horizontalCenter: parent.horizontalCenter
        text: "native sound, zero compromise"
        font.family: "Barlow"; font.pixelSize: 13; font.weight: Font.Light
        color: Qt.rgba(236/255,229/255,216/255,0.45)
        font.letterSpacing: 3
    }

    // EQ bars
    Row {
        anchors.bottom: dots.top
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5

        Repeater {
            model: [0.5, 0.8, 0.6, 1.0, 0.7]
            delegate: Rectangle {
                width: 3
                height: 24 * modelData
                radius: 2
                color: "#FF5C1A"
                opacity: 0.7
                anchors.bottom: parent ? parent.bottom : undefined

                SequentialAnimation on height {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 120 }
                    NumberAnimation { to: 6; duration: 400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 28 * modelData; duration: 400; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // Loading dots
    Row {
        id: dots
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Repeater {
            model: 3
            delegate: Rectangle {
                width: 6; height: 6; radius: 3
                color: "#FF5C1A"

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 240 }
                    NumberAnimation { to: 1.0; duration: 400 }
                    NumberAnimation { to: 0.2; duration: 400 }
                    PauseAnimation { duration: (2 - index) * 240 }
                }
            }
        }
    }

    Timer {
        interval: 1800
        running: true
        onTriggered: root.dismissed()
    }

    OpacityAnimator on opacity {
        from: 0; to: 1; duration: 400
    }
}
