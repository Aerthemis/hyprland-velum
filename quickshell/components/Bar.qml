pragma ComponentBehavior: Bound
import QtQuick
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
    signal workspaceRequested(int workspace)
    signal appearanceRequested()
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.line
    border.width: 1
    Behavior on color { ColorAnimation { duration: Theme.motion } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 10
        spacing: 12
        VelumMark { Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
        Text {
            visible: root.width > 760
            text: "velum"
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 17
            font.weight: Font.Medium
        }
        Rectangle { implicitWidth: 1; implicitHeight: 18; color: Theme.line }
        RowLayout {
            spacing: 3
            Repeater {
                model: root.workspaceIds
                delegate: SoftButton {
                    required property int modelData
                    text: modelData.toString().padStart(2, "0")
                    hint: "Workspace " + modelData
                    selected: root.activeWorkspace === modelData
                    implicitWidth: selected ? 44 : 34
                    onClicked: root.workspaceRequested(modelData)
                    Behavior on implicitWidth { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: 3; height: 3; radius: 2
                        color: Theme.muted
                        visible: !parent.selected && root.occupiedWorkspaces.includes(parent.modelData)
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.width > 900 ? root.windowTitle : ""
            color: Theme.muted
            elide: Text.ElideRight
            font.family: Theme.font
            font.pixelSize: 12
        }
        Text {
            visible: root.width > 700
            text: root.dateText
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
        }
        Text {
            text: root.timeText
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 15
            font.weight: Font.Medium
        }
        Rectangle { implicitWidth: 1; implicitHeight: 18; color: Theme.line }
        SoftButton {
            text: Theme.light ? "◐" : "◑"
            hint: "Switch light / dark appearance"
            onClicked: Theme.light = !Theme.light
        }
        SoftButton {
            text: "•••"
            hint: "Open appearance"
            selected: root.appearanceOpen
            onClicked: root.appearanceRequested()
        }
    }
}
