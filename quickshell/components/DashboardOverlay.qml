import QtQuick
import "../theme"

Item {
    id: root
    property bool open: false
    property bool pollData: true
    property alias panel: dashboard
    signal closeRequested()
    opacity: open ? 1 : 0
    visible: opacity > 0
    enabled: open
    Behavior on opacity { NumberAnimation { duration: Theme.motion } }
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    DashboardPanel {
        id: dashboard
        objectName: "dashboardPanel"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barHeight + 12 + (root.open ? 0 : -8)
        width: Math.min(1020, parent.width - 24)
        height: Math.min(590, parent.height - Theme.barHeight - 24)
        active: root.open
        pollData: root.pollData
        onCloseRequested: root.closeRequested()
        Behavior on y { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; z: -1; onClicked: {} }
    }
}
