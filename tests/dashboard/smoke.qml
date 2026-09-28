import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import "../../quickshell/components"
import "../../quickshell/components/dashboard"

ApplicationWindow {
    id: window
    visible: true
    width: 1000; height: 700
    property int step: 0
    TestEvent { id: events }
    QtObject {
        id: fakePlayer
        property string dbusName: "test"
        property string identity: "Test player"
        property string trackTitle: "Test track"
        property string trackArtist: "Test artist"
        property string trackArtUrl: ""
        property bool isPlaying: false
        property bool canControl: true
        property bool canTogglePlaying: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        property bool canSeek: false
        property bool lengthSupported: false
        property bool positionSupported: false
        property bool volumeSupported: false
        property real length: 0
        property real position: 0
        property real volume: 1
        property int previousCalls: 0
        property int nextCalls: 0
        function togglePlaying() { isPlaying = !isPlaying; }
        function previous() { previousCalls++; }
        function next() { nextCalls++; }
    }
    MediaCard { id: testMedia; x: 30; y: 60; width: 300; compact: true; players: [fakePlayer]; visible: window.step >= 11 }
    Bar { id: bar; width: parent.width; height: 34; timeText: "12:30"; onDashboardRequested: overlay.open = !overlay.open }
    DashboardOverlay { id: overlay; anchors.fill: parent; pollData: false; onCloseRequested: open = false }
    function check(ok, message) {
        if (!ok) { console.error("DASHBOARD_SMOKE_FAIL", message); Qt.exit(1); }
    }
    function click(item, x, y) { events.mouseClick(item, x, y, Qt.LeftButton, Qt.NoModifier, 0); }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const result = find(child, name);
            if (result) return result;
        }
        return null;
    }
    Timer {
        interval: 300; running: true; repeat: true
        onTriggered: {
            switch (window.step++) {
            case 0: window.click(bar, 500, 17); break;
            case 1:
                window.check(overlay.open, "Clock opens dashboard");
                window.click(overlay, 400, 75);
                window.check(overlay.open, "Panel whitespace keeps dashboard open");
                overlay.panel.forceActiveFocus();
                events.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
                window.check(!overlay.open, "Escape closes dashboard");
                break;
            case 2: overlay.open = true; break;
            case 3:
                window.click(overlay, 5, 680);
                window.check(!overlay.open, "Outside click closes dashboard");
                break;
            case 4: overlay.open = true; overlay.panel.tab = 1; break;
            case 5: overlay.panel.tab = 2; break;
            case 6: overlay.panel.tab = 3; break;
            case 7:
                overlay.panel.dashboardData.weather = {
                    configured: true, location: {name: "Example city"}, fetched: 1,
                    current: {temperature_2m: 18, apparent_temperature: 17, weather_code: 2, wind_speed_10m: 8, relative_humidity_2m: 60},
                    daily: {time: ["2026-09-28"], weather_code: [2], temperature_2m_min: [12], temperature_2m_max: [19]}
                };
                window.width = 640;
                break;
            case 8:
                window.check(overlay.panel.width === 616, "Narrow panel fits");
                overlay.panel.tab = 0;
                break;
            case 9:
                overlay.open = false;
                break;
            case 10:
                window.check(!overlay.visible, "Closing transition completes");
                break;
            case 11:
                for (const name of ["previousTrack", "togglePlaying", "nextTrack"]) {
                    const button = window.find(testMedia, name);
                    window.check(!!button, "Media button exists: " + name);
                    window.click(button, button.width / 2, button.height / 2);
                }
                window.check(fakePlayer.isPlaying && fakePlayer.previousCalls === 1 && fakePlayer.nextCalls === 1, "Media actions target selected player");
                fakePlayer.canControl = false;
                break;
            case 12:
                window.check(!window.find(testMedia, "togglePlaying").enabled, "Unsupported media controls disabled");
                testMedia.players = [];
                break;
            case 13:
                window.check(testMedia.player === null, "Player removal handled");
                console.log("DASHBOARD_SMOKE_PASS");
                Qt.quit();
            }
        }
    }
}
