import QtQuick

Canvas {
    id: canvas
    width: 48
    height: 48

    property color ringColor: "#FF5C1A"
    property real  breathe: 1.0

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var cx = width / 2
        var cy = height / 2
        var radii = [6, 11, 16, 21]

        ctx.strokeStyle = ringColor
        ctx.lineWidth = 1.5
        ctx.setLineDash([3, 4])

        for (var i = 0; i < radii.length; i++) {
            ctx.globalAlpha = 0.3 + (i / radii.length) * 0.7 * breathe
            ctx.beginPath()
            ctx.arc(cx, cy, radii[i] * breathe * (0.92 + i * 0.02), 0, Math.PI * 2)
            ctx.stroke()
        }

        ctx.globalAlpha = 1.0
        ctx.fillStyle = ringColor
        ctx.beginPath()
        ctx.arc(cx, cy, 3 * breathe, 0, Math.PI * 2)
        ctx.fill()

        ctx.setLineDash([])
    }

    SequentialAnimation on breathe {
        loops: Animation.Infinite
        NumberAnimation { to: 1.08; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.94; duration: 1800; easing.type: Easing.InOutSine }
    }

    onBreatheChanged: requestPaint()
}
