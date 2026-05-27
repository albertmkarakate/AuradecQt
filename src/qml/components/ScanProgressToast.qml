import QtQuick

Item {
    id: root
    anchors.fill: parent

    // Scan progress pill
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320; height: 44
        radius: 22
        color: "#0E0B13"
        border.color: Qt.rgba(255/255,92/255,26/255,0.30)
        visible: scanProgress.total > 0 && scanProgress.done < scanProgress.total

        Row {
            anchors.centerIn: parent; spacing: 12

            Text {
                text: "Scanning..."
                font.family: "Barlow"; font.pixelSize: 13
                color: "#ECE5D8"; anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 120; height: 4; radius: 2; color: "#1a1520"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: scanProgress.total > 0
                           ? parent.width * scanProgress.done / scanProgress.total : 0
                    height: parent.height; radius: 2; color: "#FF5C1A"
                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }

            Text {
                text: scanProgress.done + "/" + scanProgress.total
                font.family: "JetBrains Mono"; font.pixelSize: 11
                color: Qt.rgba(236/255,229/255,216/255,0.50)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    QtObject {
        id: scanProgress
        property int done: 0
        property int total: 0
    }

    // Toast notification
    Rectangle {
        id: toast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 72
        anchors.horizontalCenter: parent.horizontalCenter
        width: toastText.implicitWidth + 40; height: 40
        radius: 20
        color: "#0E0B13"
        border.color: Qt.rgba(41/255,248/255,158/255,0.40)
        opacity: 0; visible: opacity > 0
        property string message: ""

        Text {
            id: toastText; anchors.centerIn: parent; text: toast.message
            font.family: "Barlow"; font.pixelSize: 13; color: "#29F89E"
        }

        SequentialAnimation {
            id: toastAnim
            NumberAnimation { target: toast; property: "opacity"; to: 1; duration: 200 }
            PauseAnimation  { duration: 2400 }
            NumberAnimation { target: toast; property: "opacity"; to: 0; duration: 300 }
        }

        function show(msg) {
            toast.message = msg
            toastAnim.restart()
        }
    }

    Connections {
        target: trackScanner
        function onScanProgress(done, total) {
            scanProgress.done = done
            scanProgress.total = total
        }
        function onScanComplete(added) {
            Qt.callLater(() => {
                scanProgress.done = 0
                scanProgress.total = 0
                toast.show(added > 0 ? "Added " + added + " tracks" : "Library up to date")
            })
        }
    }
}
