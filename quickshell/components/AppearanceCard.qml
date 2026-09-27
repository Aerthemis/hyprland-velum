import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    signal closeRequested()
    implicitWidth: 310
    implicitHeight: contents.implicitHeight + 40
    radius: 24
    color: Theme.surface
    border.width: 1
    border.color: Theme.line
    ColumnLayout {
        id: contents
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 18
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text { text: "Make room for you."; color: Theme.text; font.family: Theme.displayFont; font.pixelSize: 19 }
                Text { text: "Appearance"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
            }
            SoftButton { text: "×"; hint: "Close appearance"; onClicked: root.closeRequested() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        Text { text: "MOOD"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
        RowLayout {
            Layout.fillWidth: true
            SoftButton { Layout.fillWidth: true; text: "Moonlight"; selected: !Theme.light; onClicked: Theme.light = false }
            SoftButton { Layout.fillWidth: true; text: "Daybreak"; selected: Theme.light; onClicked: Theme.light = true }
        }
        Text { text: "ACCENT"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ["Iris", "Sage", "Clay"]
                delegate: SoftButton {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    selected: Theme.accentIndex === index
                    onClicked: Theme.accentIndex = index
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 18; height: 2; radius: 1
                        color: Theme.accents[parent.index]
                        visible: !parent.selected
                    }
                }
            }
        }
    }
}
