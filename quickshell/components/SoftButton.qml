import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root
    property bool selected: false
    property string hint: ""
    implicitHeight: 34
    implicitWidth: Math.max(34, label.implicitWidth + 24)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: hint || text
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    ToolTip.delay: 700
    contentItem: Text {
        id: label
        text: root.text
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: root.selected ? Font.DemiBold : Font.Medium
        color: root.selected ? Theme.ink : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 12
        color: root.selected ? Theme.accent : (root.hovered || root.down ? Theme.raised : "transparent")
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.motion } }
    }
}
