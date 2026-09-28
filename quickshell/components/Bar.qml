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
    property bool appearanceOpen: false
    property bool dashboardOpen: false
    signal workspaceRequested(int workspace)
    signal appearanceRequested()
    signal dashboardRequested()
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
        VelumMark { Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
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
                        text: workspaceButton.modelData
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
        anchors.centerIn: parent
        implicitWidth: clockText.implicitWidth + 16
        implicitHeight: 28
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: "Open dashboard, " + root.timeText
        ToolTip.visible: hovered
        ToolTip.text: "Calendar, media, performance and weather"
        ToolTip.delay: 700
        onClicked: root.dashboardRequested()
        contentItem: Text {
            id: clockText
            text: root.timeText
            color: root.dashboardOpen ? Theme.accent : Theme.text
            font.family: Theme.barFont
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 4
            color: clockLabel.hovered || root.dashboardOpen ? Theme.raised : "transparent"
            border.width: clockLabel.activeFocus ? 1 : 0
            border.color: Theme.accent
        }
    }
    Text {
        anchors { right: clockLabel.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        visible: x > leftSection.x + leftSection.width + 24
        text: root.dateText
        color: Theme.muted
        font.family: Theme.barFont
        font.pixelSize: 12
    }
    Text {
        anchors { left: leftSection.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
        width: Math.max(0, root.width / 2 - x - 165)
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
        IconButton {
            // Nerd Font weather-night / weather-sunny: matches Omarchy’s nightlight icon.
            glyph: "󰔎"
            hint: "Switch light / dark appearance"
            onClicked: Theme.light = !Theme.light
        }
        IconButton {
            // Nerd Font palette: Omarchy’s Theme menu glyph.
            glyph: "󰸌"
            hint: "Open appearance"
            selected: root.appearanceOpen
            onClicked: root.appearanceRequested()
        }
    }
}
