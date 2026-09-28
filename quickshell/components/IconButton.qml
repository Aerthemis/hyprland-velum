import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root
    property string glyph: ""
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
    contentItem: Text {
        text: root.glyph
        font.family: Theme.barFont
        font.pixelSize: 16
        font.weight: Font.Normal
        color: root.selected ? Theme.accent : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 2
        color: root.hovered || root.down || root.selected ? Theme.raised : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.accent
    }
}
