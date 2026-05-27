import QtQuick

// Colorful gradient placeholder for missing artwork.
// seed: string used to derive color palette index
// showNote: show ♫ instead of initials (for tracks)
Rectangle {
    id: root
    property string seed:      ""
    property bool   showNote:  false

    readonly property var palette: [
        ["#FF5C1A","#7A2000"],
        ["#F5B32A","#7A5800"],
        ["#29F89E","#006B47"],
        ["#FF4D6A","#7A0020"],
        ["#A78BFA","#3D1A9B"],
        ["#60A5FA","#0A3A8B"],
        ["#FB923C","#7A3800"],
        ["#34D399","#006040"],
    ]

    readonly property int palIdx: {
        if (!seed || seed.length === 0) return 0
        var h = 0
        for (var i = 0; i < Math.min(seed.length, 6); i++)
            h = (h + seed.charCodeAt(i)) % 8
        return h
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: root.palette[root.palIdx][0] }
        GradientStop { position: 1.0; color: root.palette[root.palIdx][1] }
    }

    Text {
        anchors.centerIn: parent
        text: root.showNote ? "♫" : (root.seed ? root.seed.charAt(0).toUpperCase() : "♫")
        font.family: "Syne"
        font.pixelSize: Math.max(12, Math.min(parent.width, parent.height) * 0.38)
        font.weight: Font.Bold
        color: Qt.rgba(1, 1, 1, 0.55)
    }
}
