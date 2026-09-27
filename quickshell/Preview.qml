import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "components"
import "theme"

ApplicationWindow {
    id: root
    title: "Velum — preview"
    visible: true
    width: 1120
    height: 720
    minimumWidth: 640
    minimumHeight: 460
    color: Theme.background
    property int workspace: 1
    property bool appearanceOpen: true
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.appearanceOpen = false
    }
    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: Qt.quit()
    }
    onClosing: Qt.quit()

    Item {
        id: scene
        anchors.fill: parent
        Backdrop {
            anchors.fill: parent
        }
        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.displayFont
                font.pixelSize: root.width < 800 ? 76 : 100
                font.weight: Font.Light
                font.letterSpacing: -5
            }
            RowLayout {
                spacing: 9
                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 2
                    color: Theme.accent
                }
                Text {
                    text: "Workspace " + root.workspace.toString().padStart(2, "0")
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }
        Bar {
            id: bar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            height: Theme.barHeight
            activeWorkspace: root.workspace
            occupiedWorkspaces: [1, 3]
            timeText: Qt.formatDateTime(clock.date, "HH:mm")
            dateText: Qt.formatDateTime(clock.date, "ddd, d MMM")
            appearanceOpen: root.appearanceOpen
            onWorkspaceRequested: workspace => root.workspace = workspace
            onAppearanceRequested: root.appearanceOpen = !root.appearanceOpen
        }
        AppearanceCard {
            id: card
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: bar.y + bar.height + 12 + (root.appearanceOpen ? 0 : -8)
            width: Math.min(310, root.width - 32)
            height: implicitHeight
            opacity: root.appearanceOpen ? 1 : 0
            visible: opacity > 0
            enabled: root.appearanceOpen
            onCloseRequested: root.appearanceOpen = false
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.motion
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: Theme.motion
                    easing.type: Easing.OutCubic
                }
            }
        }
        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 28
            }
            Text {
                text: "VELUM  /  001"
                color: Theme.muted
                font.family: Theme.displayFont
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: "DESKTOP PREVIEW"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 9
                font.letterSpacing: 1.8
            }
        }
    }
    // Optional development capture, never enabled during ordinary use.
    Timer {
        interval: 1200
        running: Quickshell.env("VELUM_CAPTURE") !== ""
        onTriggered: scene.grabToImage(result => {
            const saved = result.saveToFile(Quickshell.env("VELUM_CAPTURE"));
            console.log("VELUM_CAPTURE", saved ? "saved" : "failed");
            Qt.quit();
        })
    }
}
