import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: false
    readonly property string helper: Quickshell.env("VELUM_ROOT") + "/scripts/dashboard/data.py"
    property var stats: ({})
    property var previous: null
    property real cpu: -1
    property real receiveRate: 0
    property real sendRate: 0
    property var history: []
    property string statsError: ""
    property var weather: ({configured: false})
    property var locations: []
    property string weatherError: ""
    property string searchMessage: ""
    property double lastWeather: 0
    readonly property bool weatherBusy: weatherProcess.running
    readonly property bool searchBusy: searchProcess.running

    function decode(text) {
        try { return JSON.parse(text); }
        catch (e) { return {ok: false, error: "Could not read dashboard data."}; }
    }
    function refreshWeather() {
        if (weatherProcess.running) return;
        weatherError = "";
        weatherProcess.command = ["python3", helper, "--weather"];
        weatherProcess.running = true;
    }
    function searchCity(city) {
        if (searchProcess.running) return;
        locations = [];
        searchMessage = "";
        searchProcess.command = ["python3", helper, "--search", city];
        searchProcess.running = true;
    }
    function selectCity(location) {
        if (weatherProcess.running) return;
        weatherError = "";
        weather = {configured: true, location: location};
        locations = [];
        searchMessage = "";
        weatherProcess.command = ["python3", helper, "--location", String(location.latitude), String(location.longitude), location.name];
        weatherProcess.running = true;
    }
    onActiveChanged: {
        if (active) {
            previous = null;
            cpu = -1;
            statsProcess.running = true;
            if (Date.now() - lastWeather > 900000) refreshWeather();
        }
    }
    Timer { interval: 2000; running: root.active; repeat: true; onTriggered: if (!statsProcess.running) statsProcess.running = true }
    Timer { interval: 900000; running: root.active; repeat: true; onTriggered: root.refreshWeather() }
    Process {
        id: statsProcess
        command: ["python3", root.helper, "--stats"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sample = root.decode(text);
                if (!sample.ok) { root.statsError = sample.error; return; }
                root.statsError = "";
                const old = root.previous;
                if (old && sample.cpuTotal > old.cpuTotal) {
                    root.cpu = Math.max(0, Math.min(1, 1 - (sample.cpuIdle - old.cpuIdle) / (sample.cpuTotal - old.cpuTotal)));
                    const elapsed = sample.time - old.time;
                    root.receiveRate = Math.max(0, (sample.network.rx - old.network.rx) / elapsed);
                    root.sendRate = Math.max(0, (sample.network.tx - old.network.tx) / elapsed);
                    root.history = root.history.concat([root.cpu]).slice(-40);
                }
                root.stats = sample;
                root.previous = sample;
            }
        }
        onExited: (code, status) => { if (code !== 0) root.statsError = "System metrics unavailable. Check that Python 3 is installed."; }
    }
    Process {
        id: weatherProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.decode(text);
                if (result.ok) { root.weather = result; root.lastWeather = Date.now(); }
                else root.weatherError = "Weather unavailable: " + result.error;
            }
        }
        onExited: (code, status) => { if (code !== 0) root.weatherError = "Weather helper unavailable. Check that Python 3 is installed."; }
    }
    Process {
        id: searchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.decode(text);
                root.locations = result.locations || [];
                root.searchMessage = result.ok ? (root.locations.length ? "Choose a location" : "No matching locations. Try a nearby city.") : result.error;
            }
        }
        onExited: (code, status) => { if (code !== 0) root.searchMessage = "Location search unavailable. Check that Python 3 is installed."; }
    }
}
