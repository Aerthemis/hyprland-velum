pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../../theme"
import "Weather.js" as Weather

ColumnLayout {
    id: root
    required property var backend
    spacing: 14
    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: city
            Layout.fillWidth: true
            placeholderText: "Search for a city"
            color: Theme.text
            placeholderTextColor: Theme.muted
            font.family: Theme.font
            background: Rectangle { color: Theme.background; radius: 8; border.width: 1; border.color: city.activeFocus ? Theme.accent : Theme.line }
            Accessible.name: "Weather city"
            maximumLength: 120
            onAccepted: root.backend.searchCity(text)
        }
        SoftButton { text: root.backend.searchBusy ? "Searching…" : "Search"; enabled: !root.backend.searchBusy && city.text.trim().length > 1; onClicked: root.backend.searchCity(city.text) }
        SoftButton { text: "↻"; hint: "Refresh weather"; enabled: !root.backend.weatherBusy; onClicked: root.backend.refreshWeather() }
    }
    Text { Layout.fillWidth: true; text: root.backend.searchMessage; visible: text.length > 0; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
    Repeater {
        model: root.backend.locations
        SoftButton {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.name; hint: modelData.name
            enabled: !root.backend.weatherBusy
            onClicked: root.backend.selectCity(modelData)
        }
    }
    Text {
        Layout.fillWidth: true
        text: root.backend.weather.location?.name ?? "Your weather, here."
        color: Theme.text; font.family: Theme.displayFont; font.pixelSize: 23; wrapMode: Text.WordWrap
    }
    Text {
        Layout.fillWidth: true
        text: root.backend.weatherBusy ? "Updating forecast…" : root.backend.weatherError || (!root.backend.weather.configured ? "Choose a city to see current conditions and a five-day forecast." : "")
        visible: text.length > 0
        color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap
    }
    RowLayout {
        visible: !!root.backend.weather.current
        spacing: 24
        Text { text: Math.round(root.backend.weather.current?.temperature_2m ?? 0) + "°"; color: Theme.accent; font.family: Theme.displayFont; font.pixelSize: 64 }
        ColumnLayout {
            Text { text: Weather.description(root.backend.weather.current?.weather_code ?? -1); color: Theme.text; font.family: Theme.font; font.pixelSize: 18 }
            Text { text: "Feels like " + Math.round(root.backend.weather.current?.apparent_temperature ?? 0) + "°C"; color: Theme.muted; font.family: Theme.font }
            Text { text: "Wind " + (root.backend.weather.current?.wind_speed_10m ?? 0) + " km/h · Humidity " + (root.backend.weather.current?.relative_humidity_2m ?? 0) + "%"; color: Theme.muted; font.family: Theme.font }
        }
    }
    Repeater {
        model: root.backend.weather.daily?.time ?? []
        RowLayout {
            required property int index
            required property string modelData
            Layout.fillWidth: true
            Text { text: Qt.formatDate(new Date(parent.modelData + "T12:00:00"), "ddd, d MMM"); color: Theme.text; font.family: Theme.font; Layout.preferredWidth: 110 }
            Text { text: Weather.description(root.backend.weather.daily.weather_code[parent.index]); color: Theme.muted; font.family: Theme.font; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: Math.round(root.backend.weather.daily.temperature_2m_min[parent.index]) + "° / " + Math.round(root.backend.weather.daily.temperature_2m_max[parent.index]) + "°"; color: Theme.text; font.family: Theme.barFont; font.pixelSize: 12 }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Weather: <a href='https://open-meteo.com/'>Open-Meteo</a> · Locations: <a href='https://www.geonames.org/'>GeoNames</a><br>Search sends the city name; forecasts use the location you choose."
        textFormat: Text.RichText
        linkColor: Theme.accent
        onLinkActivated: link => Qt.openUrlExternally(link)
        wrapMode: Text.WordWrap; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
    }
    Text {
        visible: !!root.backend.weather.fetched
        text: "Updated " + Qt.formatDateTime(new Date((root.backend.weather.fetched || 0) * 1000), "HH:mm")
        color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
    }
}
