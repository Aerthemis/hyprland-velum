import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root
    property string symbol: "palette"
    property string hint: ""
    property bool selected: false
    implicitWidth: 30
    implicitHeight: 28
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: hint
    ToolTip.visible: hovered
    ToolTip.text: hint
    ToolTip.delay: 700
    contentItem: Item {
        PixelIcon {
            anchors.centerIn: parent
            width: 18
            height: 18
            symbol: root.symbol
            color: root.selected ? Theme.accent : Theme.text
        }
    }
    background: Rectangle {
        radius: 2
        color: root.hovered || root.down || root.selected ? Theme.raised : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.accent
    }
}
