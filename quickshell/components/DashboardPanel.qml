pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "dashboard"
import "dashboard/Weather.js" as Weather

Rectangle {
    id: root
    property bool active: false
    property bool pollData: true
    property int tab: 0
    property alias dashboardData: backend
    signal closeRequested()
    implicitWidth: 1020
    implicitHeight: 590
    color: Theme.surface
    radius: 24
    border.width: 1; border.color: Theme.line
    clip: true
    focus: active
    Keys.onEscapePressed: root.closeRequested()
    onActiveChanged: if (active) forceActiveFocus()
    SystemClock { id: clock; precision: SystemClock.Minutes }
    DashboardData { id: backend; active: root.active && root.pollData }
    function bytes(value) {
        if (value >= 1073741824) return (value / 1073741824).toFixed(1) + " GiB";
        if (value >= 1048576) return (value / 1048576).toFixed(1) + " MiB";
        return (value / 1024).toFixed(0) + " KiB";
    }
    function percent(value) { return value < 0 ? "Sampling…" : Math.round(value * 100) + "%"; }
    function uptime() {
        const hours = Math.floor((backend.stats.uptime || 0) / 3600);
        return Math.floor(hours / 24) + "d " + hours % 24 + "h " + Math.floor((backend.stats.uptime || 0) % 3600 / 60) + "m";
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 22
        spacing: 16
        Item {
            Layout.fillWidth: true
            implicitHeight: 52
            Column {
                anchors { left: parent.left; right: closeButton.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 3
                Text { width: parent.width; elide: Text.ElideRight; text: "A little room to breathe."; color: Theme.text; font.family: Theme.displayFont; font.pixelSize: root.width < 600 ? 20 : 24 }
                Text { text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy"); color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
            }
            SoftButton { id: closeButton; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "×"; hint: "Close dashboard"; onClicked: root.closeRequested() }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["Overview", "Media", "Performance", "Weather"]
                SoftButton {
                    required property int index
                    required property string modelData
                    text: modelData; selected: root.tab === index
                    Layout.fillWidth: true
                    onClicked: root.tab = index
                }
            }
        }
        Flickable {
            id: scroll
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: width
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }
            Loader {
                id: body
                width: scroll.width
                sourceComponent: [overview, media, performance, weather][root.tab]
                onLoaded: scroll.contentY = 0
            }
        }
    }
    Component {
        id: overview
        GridLayout {
            columns: root.width >= 850 ? 3 : 1
            columnSpacing: 14; rowSpacing: 14
            Tile {
                Layout.fillWidth: true; Layout.preferredWidth: 240
                Layout.alignment: Qt.AlignTop
                ColumnLayout {
                    width: parent.width; spacing: 18
                    Text { text: Qt.formatDateTime(clock.date, "HH:mm"); font.family: Theme.displayFont; font.pixelSize: 52; font.weight: Font.Light; color: Theme.accent }
                    Text { text: "MAKE TODAY YOURS"; color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 10 }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Text {
                        Layout.fillWidth: true
                        text: backend.weather.current ? Math.round(backend.weather.current.temperature_2m) + "°C · " + Weather.description(backend.weather.current.weather_code) : "Your local forecast"
                        color: Theme.text; font.family: Theme.font; wrapMode: Text.WordWrap
                    }
                    Text { Layout.fillWidth: true; text: backend.weather.location?.name ?? "Choose a city in Weather"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    SoftButton { text: "Weather →"; onClicked: root.tab = 3 }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Metric { Layout.fillWidth: true; label: "CPU"; value: backend.cpu; detail: root.percent(value) }
                    Metric { Layout.fillWidth: true; label: "Memory"; value: backend.stats.memoryTotal ? backend.stats.memoryUsed / backend.stats.memoryTotal : -1; detail: root.percent(value) }
                    Text { text: "Up " + root.uptime(); color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11 }
                }
            }
            Tile {
                Layout.fillWidth: true; Layout.preferredWidth: 350
                Layout.alignment: Qt.AlignTop
                CalendarCard { width: parent.width; today: clock.date }
            }
            Tile {
                Layout.fillWidth: true; Layout.preferredWidth: 240
                Layout.alignment: Qt.AlignTop
                MediaCard { width: parent.width; compact: true; active: root.active && root.tab === 0 }
            }
        }
    }
    Component {
        id: media
        Tile {
            MediaCard { width: parent.width; active: root.active && root.tab === 1 }
        }
    }
    Component {
        id: performance
        ColumnLayout {
            spacing: 14
            Text { visible: backend.statsError.length > 0; text: backend.statsError; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Tile {
                Layout.fillWidth: true
                ColumnLayout {
                    width: parent.width; spacing: 14
                    Metric { Layout.fillWidth: true; label: "CPU utilization"; value: backend.cpu; detail: root.percent(value) }
                    Row {
                        Layout.fillWidth: true; Layout.preferredHeight: 72
                        spacing: 3
                        Repeater {
                            model: backend.history
                            Rectangle {
                                required property real modelData
                                width: Math.max(1, (parent.width - 39 * 3) / 40)
                                height: Math.max(2, modelData * 72); y: 72 - height
                                color: Theme.accent; radius: 2
                            }
                        }
                    }
                    Text { text: "CPU history · 2-second samples while open"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    Metric { Layout.fillWidth: true; label: "Memory"; value: backend.stats.memoryTotal ? backend.stats.memoryUsed / backend.stats.memoryTotal : -1; detail: root.bytes(backend.stats.memoryUsed || 0) + " / " + root.bytes(backend.stats.memoryTotal || 0) }
                    Metric { Layout.fillWidth: true; label: "Swap"; value: backend.stats.swapTotal ? backend.stats.swapUsed / backend.stats.swapTotal : 0; detail: backend.stats.swapTotal ? root.bytes(backend.stats.swapUsed) + " / " + root.bytes(backend.stats.swapTotal) : "Not configured" }
                    Text { text: "Network  ↓ " + root.bytes(backend.receiveRate) + "/s   ↑ " + root.bytes(backend.sendRate) + "/s"; color: Theme.text; font.family: Theme.barFont; font.pixelSize: 12 }
                    Text { text: "Uptime " + root.uptime() + " · Load " + (backend.stats.load || []).map(n => n.toFixed(2)).join(" / "); color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
            Tile {
                Layout.fillWidth: true
                ColumnLayout {
                    width: parent.width; spacing: 16
                    Repeater {
                        model: backend.stats.disks || []
                        Metric {
                            required property var modelData
                            Layout.fillWidth: true
                            label: modelData.path
                            value: modelData.used / modelData.total
                            detail: root.bytes(modelData.used) + " / " + root.bytes(modelData.total)
                        }
                    }
                    Text { text: "TEMPERATURES"; color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11 }
                    Repeater {
                        model: backend.stats.temperatures || []
                        Text { required property var modelData; text: modelData.name + "   " + modelData.value.toFixed(1) + "°C"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
                    }
                    Text { visible: !(backend.stats.temperatures || []).length; text: "No readable temperature sensors"; color: Theme.muted; font.family: Theme.font }
                }
            }
        }
    }
    Component {
        id: weather
        Tile { WeatherCard { width: parent.width; backend: root.dashboardData } }
    }
}
