import QtQuick
import QtQuick.Layouts
import "../../theme"

ColumnLayout {
    id: root
    property string label: ""
    property string detail: ""
    property real value: -1
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        Text { text: root.label; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; Layout.fillWidth: true }
        Text { text: root.detail; color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11 }
    }
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 5; radius: 3; color: Theme.background
        Rectangle { width: parent.width * Math.max(0, Math.min(1, root.value)); height: parent.height; radius: 3; color: Theme.accent; Behavior on width { NumberAnimation { duration: Theme.motion } } }
    }
}
