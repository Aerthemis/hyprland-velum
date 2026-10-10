pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    property var workspaceIds: [1, 2, 3, 4, 5]
    property int activeWorkspace: 1
    property var occupiedWorkspaces: []
    property string windowTitle: ""
    property string timeText: ""
    property string dateText: ""
    property bool dashboardOpen: false
    property string systemPage: ""
    property var systemStatus: ({})
    signal workspaceRequested(int workspace)
    signal dashboardRequested()
    signal systemRequested(string page)
    implicitHeight: Theme.barHeight
    color: Theme.background
    Behavior on color { ColorAnimation { duration: Theme.motion } }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.line
        opacity: 0.5
    }

    RowLayout {
        id: leftSection
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 10
        VelumMark {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            osId: root.systemStatus.os?.id || ""
            osLike: root.systemStatus.os?.idLike || []
            osName: root.systemStatus.os?.name || ""
        }
        RowLayout {
            spacing: 2
            Repeater {
                model: root.workspaceIds
                delegate: Button {
                    id: workspaceButton
                    required property int modelData
                    readonly property bool selected: root.activeWorkspace === modelData
                    readonly property bool occupied: root.occupiedWorkspaces.includes(modelData)
                    implicitWidth: 26
                    implicitHeight: 28
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: "Workspace " + modelData
                    ToolTip.visible: hovered
                    ToolTip.text: "Workspace " + modelData
                    ToolTip.delay: 700
                    onClicked: root.workspaceRequested(modelData)
                    contentItem: Text {
                        text: workspaceButton.modelData.toString()
                        font.family: Theme.barFont
                        font.pixelSize: 12
                        font.bold: false
                        color: workspaceButton.selected ? Theme.accent : (workspaceButton.occupied ? Theme.text : Theme.muted)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 4
                        color: workspaceButton.hovered || workspaceButton.down ? Theme.raised : "transparent"
                        border.width: workspaceButton.activeFocus ? 1 : 0
                        border.color: Theme.accent
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: workspaceButton.selected ? 14 : 3
                            height: 2
                            radius: 1
                            color: workspaceButton.selected ? Theme.accent : Theme.muted
                            visible: workspaceButton.selected || workspaceButton.occupied
                        }
                    }
                }
            }
        }
    }

    // Keep the clock at the screen center, independent of side content.
    Button {
        id: clockLabel
        objectName: "clockDateTimeButton"
        readonly property bool showDate: root.dateText.length > 0 && root.width / 2 - clockText.implicitWidth / 2 - 28 - dateLabel.implicitWidth > leftSection.x + leftSection.width + 24
        readonly property real dateExtent: showDate ? dateLabel.implicitWidth + 20 : 0
        anchors.verticalCenter: parent.verticalCenter
        x: root.width / 2 - clockText.implicitWidth / 2 - 8 - dateExtent
        implicitWidth: clockText.implicitWidth + 16 + dateExtent
        padding: 8
        topPadding: 0
        bottomPadding: 0
        implicitHeight: 28
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: "Open dashboard, " + root.dateText + " " + root.timeText
        ToolTip.visible: hovered
        ToolTip.text: "Calendar, media, performance and weather"
        ToolTip.delay: 700
        HoverHandler {
            onHoveredChanged: {
                if (hovered && !root.dashboardOpen)
                    root.dashboardRequested()
            }
        }
        onClicked: root.dashboardRequested()
        contentItem: Item {
            Text {
                id: dateLabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                visible: clockLabel.showDate
                text: root.dateText
                color: root.dashboardOpen ? Theme.accent : Theme.muted
                font.family: Theme.barFont
                font.pixelSize: 12
            }
            Text {
                id: clockText
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.timeText
                color: root.dashboardOpen ? Theme.accent : Theme.text
                font.family: Theme.barFont
                font.pixelSize: 12
            }
        }
        background: Rectangle {
            radius: 4
            color: clockLabel.hovered || root.dashboardOpen ? Theme.raised : "transparent"
            border.width: clockLabel.activeFocus ? 1 : 0
            border.color: Theme.accent
        }
    }
    Text {
        anchors { left: leftSection.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
        width: Math.max(0, clockLabel.x - x - 18)
        visible: root.width > 1000
        text: root.windowTitle
        elide: Text.ElideRight
        color: Theme.muted
        font.family: Theme.barFont
        font.pixelSize: 12
    }
    RowLayout {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 6
        SystemTrayStrip { visible: items.length > 0 }
        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; color: Theme.line; Layout.leftMargin: 2; Layout.rightMargin: 2 }
        IconButton { glyph: "󰂯"; hint: "Bluetooth controls"; selected: root.systemPage === "bluetooth"; onClicked: root.systemRequested("bluetooth") }
        IconButton {
            readonly property var network: root.systemStatus.wifi || ({})
            readonly property bool cableConnected: !!network.ethernet?.connected
            readonly property var activeWifi: (network.networks || []).find(entry => entry.active)
            readonly property real signalStrength: activeWifi?.signal ?? 0
            glyph: cableConnected ? "󰈀" : !network.available || !network.enabled ? "󰤮" : !network.connected ? "󰤭" : signalStrength >= 75 ? "󰤨" : signalStrength >= 50 ? "󰤥" : signalStrength >= 25 ? "󰤢" : "󰤟"
            hint: !network.available ? "NetworkManager unavailable" : cableConnected ? "Ethernet · " + (network.ethernet.connection || network.ethernet.device) : network.connected ? "Wi-Fi · " + (network.connection || "Connected") : network.enabled ? "Wi-Fi · not connected" : "Wi-Fi off"
            selected: root.systemPage === "network"
            onClicked: root.systemRequested("network")
        }
        IconButton {
            readonly property real volume: root.systemStatus.audio?.volume ?? 0
            glyph: root.systemStatus.audio?.muted ? "󰖁" : volume < 0.01 ? "󰖁" : volume < 0.5 ? "󰖀" : "󰕾"
            hint: "Audio controls · " + (root.systemStatus.audio?.muted ? "Muted" : Math.round(volume * 100) + "%")
            selected: root.systemPage === "audio"
            onClicked: root.systemRequested("audio")
        }
        IconButton { glyph: "󰍹"; hint: "Display controls"; selected: root.systemPage === "display"; onClicked: root.systemRequested("display") }
        IconButton { glyph: "󰁹"; hint: "Power controls"; selected: root.systemPage === "power"; onClicked: root.systemRequested("power") }
    }
}
