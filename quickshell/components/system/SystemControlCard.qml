pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../../theme"

Rectangle {
    id: root
    property string page: "audio"
    property string retainedPage: "audio"
    property var status: ({})
    property string error: ""
    property bool busy: false
    property string pendingPowerAction: ""
    property string passwordNetwork: ""
    property string wifiPassword: ""
    signal closeRequested()
    signal actionRequested(string action, var values)
    onPageChanged: if (page.length > 0) retainedPage = page
    implicitWidth: 330
    implicitHeight: Math.min(560, content.implicitHeight + 36)
    color: Theme.surface; radius: 20; border.width: 1; border.color: Theme.line
    clip: true
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: root.titleForPage(); color: Theme.text; font.family: Theme.displayFont; font.pixelSize: 19 }
                Text { text: root.subtitleForPage(); color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight }
            }
            SoftButton { text: "↻"; hint: "Refresh status"; enabled: !root.busy; onClicked: root.actionRequested("refresh", []) }
            SoftButton { text: "×"; hint: "Close system controls"; onClicked: root.closeRequested() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        Text { Layout.fillWidth: true; visible: root.error.length > 0; text: root.error; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
        Loader { Layout.fillWidth: true; sourceComponent: root.pageComponent() }
    }
    function resolvedPage() { return page.length > 0 ? page : retainedPage; }
    function titleForPage() { return ({audio:"Audio", network:"Network", bluetooth:"Bluetooth", display:"Displays", power:"Power"})[resolvedPage()] || "System"; }
    function subtitleForPage() {
        const currentPage = resolvedPage();
        if (currentPage === "audio") return status.audio?.available ? "Default output" : "PipeWire is unavailable";
        if (currentPage === "network") {
            if (!status.wifi?.available) return "NetworkManager is unavailable";
            if (status.wifi.ethernet?.connected) return "Ethernet · " + (status.wifi.ethernet.connection || status.wifi.ethernet.device);
            if (status.wifi.connected) return "Wi-Fi · " + (status.wifi.connection || "Connected");
            return "Not connected";
        }
        if (currentPage === "bluetooth") return status.bluetooth?.available ? (status.bluetooth.powered ? "Bluetooth is on" : "Bluetooth is off") : (status.bluetooth?.reason || "BlueZ is unavailable");
        if (currentPage === "display") return status.display?.available ? status.display.monitors.length + " connected" : "Hyprland display status unavailable";
        if (currentPage === "power") return status.power?.available ? "Power and charging" : "No battery detected";
        return "System controls";
    }
    function pageComponent() { return ({audio:audioPage, network:networkPage, bluetooth:bluetoothPage, display:displayPage, power:powerPage})[resolvedPage()] || audioPage; }
    function formatRate(value) {
        if (value >= 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MiB/s";
        if (value >= 1024) return (value / 1024).toFixed(1) + " KiB/s";
        return Math.round(value) + " B/s";
    }

    Component {
        id: audioPage
        ColumnLayout {
            spacing: 12
            Text { Layout.fillWidth: true; text: root.status.audio?.output || "System output"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight }
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Output volume"; color: Theme.text; font.family: Theme.font }
                Text { text: root.status.audio?.muted ? "Muted" : Math.round((root.status.audio?.volume || 0) * 100) + "%"; color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 12 }
                SoftButton { text: root.status.audio?.muted ? "Unmute" : "Mute"; hint: "Toggle mute"; enabled: !!root.status.audio?.available && !root.busy; onClicked: root.actionRequested("audio-mute", []) }
            }
            Slider { Layout.fillWidth: true; from: 0; to: 100; value: Math.min(100, (root.status.audio?.volume || 0) * 100); enabled: !!root.status.audio?.available && !root.busy; Accessible.name: "Output volume"; onMoved: root.actionRequested("audio-volume", [Math.round(value)]) }
            Text { Layout.fillWidth: true; text: "Output device"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            Repeater {
                model: root.status.audio?.outputs || []
                SoftButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: (modelData.active ? "●  " : "○  ") + modelData.name
                    hint: modelData.active ? "Current output" : "Switch output to " + modelData.name
                    selected: modelData.active
                    enabled: modelData.ready && !root.busy
                    onClicked: root.actionRequested("audio-output", [modelData.id])
                }
            }
            Text { Layout.fillWidth: true; visible: !(root.status.audio?.outputs || []).length; text: "No PipeWire output devices were found."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
        }
    }
    Component {
        id: networkPage
        ColumnLayout {
            spacing: 8
            Text { Layout.fillWidth: true; text: root.status.wifi?.ethernet?.connected ? "Cable connected · " + (root.status.wifi.ethernet.connection || root.status.wifi.ethernet.device) : root.status.wifi?.connected ? "Connected to " + (root.status.wifi.connection || "Wi-Fi") : "No active network connection"; color: Theme.text; font.family: Theme.font; elide: Text.ElideRight }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 3
                Text { text: "Interface"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                Text { Layout.fillWidth: true; text: root.status.network?.interface || "—"; color: Theme.text; font.family: Theme.barFont; font.pixelSize: 11; elide: Text.ElideRight }
                Text { text: "Receive"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                Text { Layout.fillWidth: true; text: root.formatRate(root.status.network?.rxRate || 0); color: Theme.text; font.family: Theme.barFont; font.pixelSize: 11 }
                Text { text: "Send"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                Text { Layout.fillWidth: true; text: root.formatRate(root.status.network?.txRate || 0); color: Theme.text; font.family: Theme.barFont; font.pixelSize: 11 }
                Text { text: "LAN IP"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                Text { Layout.fillWidth: true; text: root.status.network?.lanIp || "Unavailable"; color: Theme.text; font.family: Theme.barFont; font.pixelSize: 11; elide: Text.ElideRight }
                Text { text: "WAN IP"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                Text { Layout.fillWidth: true; text: root.status.network?.wanIp || (root.status.network?.wanError ? "Unavailable" : "Looking up…"); color: Theme.text; font.family: Theme.barFont; font.pixelSize: 11; elide: Text.ElideRight }
            }
            Text { Layout.fillWidth: true; visible: !root.status.network?.wanIp && !!root.status.network?.wanError; text: root.status.network?.wanError || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; wrapMode: Text.WordWrap }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Wi-Fi"; color: Theme.text; font.family: Theme.font }
                SoftButton { text: root.status.wifi?.enabled ? "Turn off" : "Turn on"; enabled: !!root.status.wifi?.available && !root.busy; onClicked: root.actionRequested("wifi-toggle", []) }
                SoftButton { text: "Scan"; hint: "Scan for available Wi-Fi networks"; enabled: !!root.status.wifi?.enabled && !root.busy; onClicked: root.actionRequested("wifi-scan", []) }
            }
            Text { Layout.fillWidth: true; text: "Available networks"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            Repeater {
                model: root.status.wifi?.networks || []
                SoftButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: (modelData.active ? "●  " : "○  ") + modelData.ssid + "    " + modelData.signal + "%" + (modelData.security && modelData.security !== "--" ? " · secured" : "")
                    hint: modelData.canConnect ? "Connect to " + modelData.ssid : modelData.requiresPassword ? "Enter the password for " + modelData.ssid : "Set up this enterprise network in NetworkManager"
                    selected: modelData.active
                    enabled: !!root.status.wifi?.enabled && (modelData.canConnect || modelData.requiresPassword) && !root.busy
                    onClicked: {
                        if (modelData.canConnect) root.actionRequested("wifi-network-connect", [modelData.ssid]);
                        else if (modelData.requiresPassword) { root.passwordNetwork = modelData.ssid; root.wifiPassword = ""; }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.passwordNetwork.length > 0
                Text { Layout.fillWidth: true; text: "Password for " + root.passwordNetwork; color: Theme.text; font.family: Theme.font; elide: Text.ElideRight }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Wi-Fi password"
                    echoMode: TextInput.Password
                    text: root.wifiPassword
                    onTextChanged: root.wifiPassword = text
                    Accessible.name: "Wi-Fi password"
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    SoftButton { text: "Cancel"; onClicked: { root.passwordNetwork = ""; root.wifiPassword = ""; } }
                    SoftButton {
                        text: "Connect"
                        enabled: root.wifiPassword.length > 0 && !root.busy
                        onClicked: {
                            root.actionRequested("wifi-network-connect", [root.passwordNetwork, root.wifiPassword]);
                            root.passwordNetwork = "";
                            root.wifiPassword = "";
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; visible: !!root.status.wifi?.enabled && !(root.status.wifi?.networks || []).length; text: "No network scan results. Select Scan to search again."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; text: "Select a protected network to enter its password."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; wrapMode: Text.WordWrap }
        }
    }
    Component {
        id: bluetoothPage
        ColumnLayout {
            spacing: 8
            Text { Layout.fillWidth: true; visible: !root.status.bluetooth?.available; text: root.status.bluetooth?.reason || "BlueZ is unavailable."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Bluetooth radio"; color: Theme.text; font.family: Theme.font }
                SoftButton { text: root.status.bluetooth?.powered ? "Turn off" : "Turn on"; enabled: !!root.status.bluetooth?.available && !root.busy; onClicked: root.actionRequested("bluetooth-toggle", []) }
                SoftButton { text: root.busy ? "Scanning…" : "Scan"; hint: "Search for nearby Bluetooth devices"; enabled: !!root.status.bluetooth?.powered && !root.busy; onClicked: root.actionRequested("bluetooth-scan", []) }
            }
            Text { Layout.fillWidth: true; text: "Paired devices"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            Repeater {
                model: root.status.bluetooth?.paired || []
                RowLayout {
                    id: pairedDeviceRow
                    required property var modelData
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: pairedDeviceRow.modelData.name; color: Theme.text; font.family: Theme.font; elide: Text.ElideRight }
                    SoftButton {
                        readonly property bool connected: (root.status.bluetooth?.connected || []).some(device => device.address === pairedDeviceRow.modelData.address)
                        text: connected ? "Disconnect" : "Connect"
                        enabled: !!root.status.bluetooth?.powered && !root.busy
                        onClicked: root.actionRequested(connected ? "bluetooth-disconnect" : "bluetooth-connect", [pairedDeviceRow.modelData.address])
                    }
                    SoftButton { text: "Forget"; hint: "Remove paired device"; enabled: !root.busy; onClicked: root.actionRequested("bluetooth-remove", [pairedDeviceRow.modelData.address]) }
                }
            }
            Text { Layout.fillWidth: true; text: "Nearby devices"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            Repeater {
                model: root.status.bluetooth?.nearby || []
                RowLayout {
                    id: nearbyDeviceRow
                    required property var modelData
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: nearbyDeviceRow.modelData.name; color: Theme.text; font.family: Theme.font; elide: Text.ElideRight }
                    SoftButton { text: "Pair"; hint: "Pair " + nearbyDeviceRow.modelData.name; enabled: !!root.status.bluetooth?.powered && !root.busy; onClicked: root.actionRequested("bluetooth-pair", [nearbyDeviceRow.modelData.address]) }
                }
            }
            Text { Layout.fillWidth: true; visible: (root.status.bluetooth?.paired || []).length === 0; text: root.status.bluetooth?.powered ? "No paired devices yet." : "Turn on Bluetooth to manage devices."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; visible: root.status.bluetooth?.powered && !(root.status.bluetooth?.nearby || []).length; text: "No unpaired devices found. Select Scan to search nearby."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
        }
    }
    Component {
        id: displayPage
        ColumnLayout {
            spacing: 10
            Repeater {
                model: root.status.display?.monitors || []
                SoftButton { required property var modelData; Layout.fillWidth: true; text: (modelData.focused ? "●  " : "○  ") + modelData.name + "   " + modelData.width + " × " + modelData.height; hint: "Focus monitor " + modelData.name; enabled: !root.busy; onClicked: root.actionRequested("focus-monitor", [modelData.name]) }
            }
            Repeater {
                model: root.status.display?.brightness || []
                ColumnLayout {
                    id: brightnessRow
                    required property var modelData
                    Layout.fillWidth: true; spacing: 2
                    RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: brightnessRow.modelData.name; color: Theme.text; font.family: Theme.font } Text { text: Math.round(slider.value) + "%"; color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11 } }
                    Slider { id: slider; Layout.fillWidth: true; from: 0; to: 100; value: parent.modelData.brightness * 100; enabled: !root.busy; Accessible.name: "Screen brightness"; onMoved: root.actionRequested("brightness", [Math.round(value)]) }
                }
            }
            Text { visible: !(root.status.display?.brightness || []).length; text: "No brightness control is available."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
        }
    }
    Component {
        id: powerPage
        ColumnLayout {
            spacing: 10
            Repeater {
                model: root.status.power?.batteries || []
                RowLayout { required property var modelData; Layout.fillWidth: true; Text { Layout.fillWidth: true; text: parent.modelData.name + " · " + parent.modelData.state; color: Theme.text; font.family: Theme.font } Text { text: parent.modelData.percentage + "%"; color: Theme.accent; font.family: Theme.barFont } }
            }
            Text { visible: !!root.status.power?.profile; text: "Power profile"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            RowLayout {
                visible: !!root.status.power?.profile; Layout.fillWidth: true
                Repeater {
                    model: ["power-saver", "balanced", "performance"]
                    SoftButton { required property string modelData; Layout.fillWidth: true; text: modelData === "power-saver" ? "Saver" : modelData === "performance" ? "Performance" : "Balanced"; selected: root.status.power?.profile === modelData; enabled: !root.busy && (modelData !== "performance" || (root.status.power?.profiles || "").includes("performance")); onClicked: root.actionRequested("power-profile", [modelData]) }
                }
            }
            Text { visible: !(root.status.power?.batteries || []).length && !root.status.power?.profile; text: "No battery or power-profile service detected."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
            Text { text: root.pendingPowerAction ? "Confirm " + root.pendingPowerAction + "?" : "Session"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["lock", "suspend", "logout", "reboot", "poweroff"]
                    SoftButton {
                        required property string modelData
                        Layout.fillWidth: true
                        text: root.pendingPowerAction === modelData ? "Confirm" : ({lock:"Lock", suspend:"Sleep", logout:"Log out", reboot:"Restart", poweroff:"Power off"})[modelData]
                        hint: root.pendingPowerAction === modelData ? "Confirm " + modelData : "Choose " + modelData
                        enabled: !root.busy
                        onClicked: {
                            if (root.pendingPowerAction === modelData) {
                                root.actionRequested("session-power", [modelData]);
                                root.pendingPowerAction = "";
                            } else root.pendingPowerAction = modelData;
                        }
                    }
                }
            }
        }
    }
}
