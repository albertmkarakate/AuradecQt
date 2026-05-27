import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AuradecApp

Item {
    id: root

    /// Plain lyrics (newline-separated text)
    property string plainLyrics: ""
    /// LRC synced lyrics ([mm:ss.xx]text format)
    property string syncedLyrics: ""
    /// Current playback position in milliseconds
    property int position: 0
    /// Whether synced lyrics are available
    readonly property bool hasSynced: syncedLyrics.trim() !== ""
    /// Whether we're currently showing anything
    readonly property bool hasContent: plainLyrics.trim() !== "" || syncedLyrics.trim() !== ""
    /// Status text (e.g. "Fetching…", "No lyrics found")
    property string statusText: ""
    /// Whether to show loading indicator
    property bool loading: false
    /// Source attribution label (e.g. "lrclib.net", "Spotify")
    property string sourceLabel: ""

    /// Internal parsed synced lines
    property var _lines: []
    property int _currentIndex: -1

    onSyncedLyricsChanged: { _lines = parseLRC(syncedLyrics); _currentIndex = findCurrent() }
    onPositionChanged: { _currentIndex = findCurrent() }

    function parseLRC(lrc) {
        var result = []
        var lines = lrc.split('\n')
        var regex = /\[(\d+):(\d+)\.(\d+)\](.*)/
        for (var i = 0; i < lines.length; i++) {
            var m = regex.exec(lines[i])
            if (m) {
                var mins = parseInt(m[1])
                var secs = parseInt(m[2])
                var frac = parseInt(m[3].substring(0, 2)) * 10
                result.push({ time: mins * 60000 + secs * 1000 + frac, text: m[4].trim() })
            }
        }
        result.sort(function(a, b) { return a.time - b.time })
        return result
    }

    function findCurrent() {
        if (!hasSynced || _lines.length === 0) return -1
        for (var i = _lines.length - 1; i >= 0; i--) {
            if (position >= _lines[i].time) return i
        }
        return 0
    }

    // ── Layout ──
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Loading indicator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.loading ? 2 : 0
            color: AuradecTheme.brandDim
            visible: root.loading

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.3
                height: 2
                radius: 1
                color: AuradecTheme.brand
                NumberAnimation on x {
                    from: -width
                    to: parent.width
                    duration: 1200
                    loops: Animation.Infinite
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // No content state
            Text {
                anchors.centerIn: parent
                text: root.loading ? "Fetching lyrics…"
                    : root.statusText ? root.statusText
                    : root.hasContent ? ""
                    : "No lyrics available"
                font.family: AuradecTheme.fontBody; font.pixelSize: 13
                color: AuradecTheme.textMuted
                visible: !root.hasContent || root.statusText !== ""
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 32
                wrapMode: Text.WordWrap
            }

            // Synced lyrics view
            ListView {
                id: syncedView
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                model: root._lines
                visible: root.hasSynced && root.statusText === ""
                spacing: 8
                snapMode: ListView.NoSnap
                preferredHighlightBegin: height * 0.35
                preferredHighlightEnd: height * 0.45
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 300

                delegate: Text {
                    width: syncedView.width - 32
                    text: modelData.text
                    font.family: AuradecTheme.fontBody
                    font.pixelSize: index === root._currentIndex ? 17 : 13
                    font.weight: index === root._currentIndex ? Font.Medium : Font.Normal
                    color: index === root._currentIndex
                           ? AuradecTheme.textPrimary
                           : AuradecTheme.textSecondary
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3

                    Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Center indicator line
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.top
                    anchors.verticalCenterOffset: parent.height * 0.4
                    height: 1
                    color: AuradecTheme.brandDim
                    opacity: root._currentIndex >= 0 ? 1 : 0
                }
            }

            // Plain lyrics view
            Flickable {
                id: plainView
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                contentHeight: plainText.height + 32
                clip: true
                visible: !root.hasSynced && root.hasContent && root.statusText === ""

                Text {
                    id: plainText
                    width: parent.width
                    text: root.plainLyrics
                    font.family: AuradecTheme.fontBody
                    font.pixelSize: 14
                    font.weight: Font.Normal
                    color: AuradecTheme.textPrimary
                    wrapMode: Text.WordWrap
                    lineHeight: 1.6
                    topPadding: 16
                    bottomPadding: 16
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }

    // Source attribution
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 6
        anchors.rightMargin: 12
        text: root.sourceLabel !== "" ? "Source · " + root.sourceLabel : ""
        font.family: "JetBrains Mono"; font.pixelSize: 9
        font.letterSpacing: 1
        color: Qt.rgba(236/255,229/255,216/255,0.20)
        visible: root.sourceLabel !== "" && root.hasContent
    }
}
