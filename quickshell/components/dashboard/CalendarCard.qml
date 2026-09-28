pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../../theme"
import "CalendarMath.js" as CalendarMath

ColumnLayout {
    id: root
    required property date today
    property date selectedDate: today
    property int year: today.getFullYear()
    property int month: today.getMonth()
    spacing: 10
    function moveMonth(step) {
        const date = new Date(year, month + step, 1, 12);
        year = date.getFullYear();
        month = date.getMonth();
    }
    function reset() {
        year = today.getFullYear(); month = today.getMonth(); selectedDate = today;
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
            font.family: Theme.displayFont; font.pixelSize: 18; color: Theme.text
        }
        SoftButton { text: "‹"; hint: "Previous month"; onClicked: root.moveMonth(-1) }
        SoftButton { text: "›"; hint: "Next month"; onClicked: root.moveMonth(1) }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 2; rowSpacing: 3
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Text {
                required property string modelData
                Layout.fillWidth: true; Layout.preferredWidth: 30
                text: modelData; horizontalAlignment: Text.AlignHCenter
                color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11
            }
        }
        Repeater {
            model: 42
            SoftButton {
                required property int index
                readonly property date date: CalendarMath.cell(root.year, root.month, index)
                Layout.fillWidth: true; Layout.preferredWidth: 30
                implicitWidth: 30; implicitHeight: 30
                text: date.getDate()
                hint: Qt.formatDate(date, "dddd, d MMMM yyyy")
                selected: CalendarMath.sameDay(date, root.selectedDate)
                opacity: date.getMonth() === root.month ? 1 : 0.4
                onClicked: root.selectedDate = date
                Rectangle {
                    anchors { bottom: parent.bottom; bottomMargin: 2; horizontalCenter: parent.horizontalCenter }
                    width: 4; height: 2; radius: 1
                    color: parent.selected ? Theme.ink : Theme.accent
                    visible: CalendarMath.sameDay(parent.date, root.today)
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.selectedDate, "ddd, d MMM yyyy")
            color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
        }
        SoftButton { text: "Today"; hint: "Return to today"; onClicked: root.reset() }
    }
}
