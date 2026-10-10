import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "components"
import "components/system"
import "services"
import "theme"

ApplicationWindow {
    id: root
    title: "Velum — preview"
    visible: true
    width: Number(Quickshell.env("VELUM_PREVIEW_WIDTH") || 1120)
    height: 720
    minimumWidth: 640
    minimumHeight: 460
    color: Theme.background
    property int workspace: 1
    property bool dashboardOpen: Quickshell.env("VELUM_CAPTURE_DASHBOARD") === "1"
    property string systemPage: ""
    SystemControls { id: controls; page: root.systemPage }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Shortcut {
        sequence: "Escape"
        onActivated: { root.dashboardOpen = false; root.systemPage = ""; }
    }
    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: Qt.quit()
    }
    onClosing: Qt.quit()
    onActiveChanged: {
        if (!active) {
            root.dashboardOpen = false;
            root.systemPage = "";
        }
    }

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
                margins: 0
            }
            height: Theme.barHeight
            activeWorkspace: root.workspace
            occupiedWorkspaces: [1, 3]
            timeText: Qt.formatDateTime(clock.date, "HH:mm")
            dateText: Qt.formatDateTime(clock.date, "ddd, d MMM")
            dashboardOpen: root.dashboardOpen
            systemPage: root.systemPage
            systemStatus: controls.view
            onWorkspaceRequested: workspace => root.workspace = workspace
            onDashboardRequested: { root.dashboardOpen = !root.dashboardOpen; }
            onSystemRequested: page => { root.dashboardOpen = false; root.systemPage = root.systemPage === page ? "" : page; }
        }
        MouseArea {
            anchors { fill: parent; topMargin: Theme.barHeight }
            z: 1
            visible: root.systemPage.length > 0
            enabled: visible
            onClicked: {
                root.dashboardOpen = false;
                root.systemPage = "";
            }
        }
        SystemControlCard {
            id: systemCard
            z: 2
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: bar.y + bar.height + 12 + (root.systemPage.length ? 0 : -8)
            width: Math.min(330, root.width - 32)
            height: implicitHeight
            page: root.systemPage
            status: controls.view
            error: controls.error
            busy: controls.busy
            opacity: root.systemPage.length ? 1 : 0
            visible: opacity > 0
            enabled: root.systemPage.length > 0
            onActionRequested: (action, values) => action === "refresh" ? controls.refresh() : controls.act(action, values)
            onCloseRequested: root.systemPage = ""
            Behavior on opacity { NumberAnimation { duration: Theme.motion } }
            Behavior on y { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
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
    DashboardOverlay {
        parent: scene
        anchors.fill: parent
        open: root.dashboardOpen
        panel.tab: Number(Quickshell.env("VELUM_CAPTURE_TAB") || 0)
        onCloseRequested: root.dashboardOpen = false
    }
    // Optional development capture, never enabled during ordinary use.
    Timer {
        interval: 3200
        running: Quickshell.env("VELUM_CAPTURE") !== ""
        onTriggered: scene.grabToImage(result => {
            const saved = result.saveToFile(Quickshell.env("VELUM_CAPTURE"));
            console.log("VELUM_CAPTURE", saved ? "saved" : "failed");
            Qt.quit();
        })
    }
}
