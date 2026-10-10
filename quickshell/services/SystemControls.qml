import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root
    property string page: ""
    property var snapshot: ({})
    property string error: ""
    property bool busy: false
    property var networkPrevious: null
    property var networkDetails: ({networkKey: "", lanIp: "", wanIp: "", wanError: ""})
    property string networkDetailsRequestedKey: ""
    readonly property PwNode audioSink: Pipewire.defaultAudioSink
    readonly property var outputSinks: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream)
    readonly property var view: root.statusWithAudio()
    readonly property string helper: Quickshell.env("VELUM_ROOT") + "/scripts/system/control.py"
    PwObjectTracker { objects: root.outputSinks }
    function audioAvailable() {
        return !!root.audioSink && root.audioSink.ready && !!root.audioSink.audio;
    }
    function statusWithAudio() {
        const result = Object.assign({}, root.snapshot);
        const audio = root.audioSink?.audio;
        result.audio = {
            available: root.audioAvailable(),
            volume: audio?.volume ?? 0,
            muted: audio?.muted ?? false,
            output: root.audioSink?.description || root.audioSink?.name || "Default output",
            outputs: root.outputSinks.filter(node => !!node.audio).map(node => ({
                id: node.id,
                name: node.nickname || node.description || node.name,
                active: node.id === root.audioSink?.id,
                ready: node.ready
            }))
        };
        return result;
    }
    function parse(text) {
        try { return JSON.parse(text); }
        catch (e) { return {ok: false, error: "Could not read system service status."}; }
    }
    function refresh() {
        if (readProcess.running) return;
        readProcess.running = true;
    }
    function refreshNetwork() {
        if (networkProcess.running) return;
        networkProcess.command = ["python3", helper, "network"];
        networkProcess.running = true;
    }
    function refreshNetworkDetails(networkKey) {
        if (!networkKey || networkDetailsProcess.running || networkDetailsRequestedKey === networkKey) return;
        networkDetailsRequestedKey = networkKey;
        networkDetailsProcess.command = ["python3", helper, "network-details"];
        networkDetailsProcess.running = true;
    }
    function acceptNetwork(value) {
        const now = Date.now();
        const changed = !networkPrevious || networkPrevious.networkKey !== value.networkKey;
        const previous = changed ? null : networkPrevious;
        if (changed) {
            networkDetailsRequestedKey = "";
            networkDetails = {
                networkKey: value.networkKey,
                lanIp: "",
                wanIp: "",
                wanError: value.networkKey ? "" : "No active network connection."
            };
        }
        const elapsed = previous ? Math.max(0.001, (now - previous.time) / 1000) : 1;
        const network = Object.assign({}, value, {
            lanIp: networkDetails.lanIp,
            wanIp: networkDetails.wanIp,
            wanError: networkDetails.wanError,
            rxRate: previous ? Math.max(0, (value.rx - previous.rx) / elapsed) : 0,
            txRate: previous ? Math.max(0, (value.tx - previous.tx) / elapsed) : 0
        });
        networkPrevious = {networkKey: value.networkKey, rx: value.rx, tx: value.tx, time: now};
        snapshot = Object.assign({}, snapshot, {network: network});
        if (value.networkKey) refreshNetworkDetails(value.networkKey);
    }
    function acceptNetworkDetails(value) {
        if (value.networkKey !== networkPrevious?.networkKey) return;
        networkDetails = {networkKey: value.networkKey, lanIp: value.lanIp || "", wanIp: value.wanIp || "", wanError: value.wanError || ""};
        snapshot = Object.assign({}, snapshot, {network: Object.assign({}, snapshot.network || ({}), networkDetails)});
    }
    function act(name, values) {
        if (name === "audio-mute") {
            if (!root.audioAvailable()) { error = "PipeWire has no ready default audio output."; return; }
            root.audioSink.audio.muted = !root.audioSink.audio.muted;
            error = "";
            return;
        }
        if (name === "audio-volume") {
            if (!root.audioAvailable()) { error = "PipeWire has no ready default audio output."; return; }
            root.audioSink.audio.volume = Math.max(0, Math.min(100, Number(values[0]))) / 100;
            error = "";
            return;
        }
        if (name === "audio-output") {
            const node = root.outputSinks.find(candidate => candidate.id === Number(values[0]));
            if (!node || !node.ready) { error = "That PipeWire output is no longer available."; return; }
            Pipewire.preferredDefaultAudioSink = node;
            error = "";
            return;
        }
        if (actionProcess.running) return;
        error = "";
        const args = values.map(String);
        actionProcess.inputPayload = "";
        actionProcess.stdinEnabled = false;
        if (name === "wifi-network-connect" && args.length > 1) {
            actionProcess.inputPayload = JSON.stringify({password: args[1]}) + "\n";
            actionProcess.stdinEnabled = true;
            args.splice(1, 1);
        }
        actionProcess.command = ["python3", helper, "action", name, "--", ...args];
        actionProcess.running = true;
    }
    Component.onCompleted: refresh()
    Timer { interval: 15000; repeat: true; running: true; onTriggered: root.refresh() }
    Timer { interval: 2000; repeat: true; running: root.page === "network"; onTriggered: root.refreshNetwork() }
    onPageChanged: if (page === "network") refreshNetwork()
    Process {
        id: readProcess
        command: ["python3", root.helper, "snapshot"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parse(text);
                if (result.ok) { root.snapshot = result; root.error = ""; }
                else root.error = result.error;
            }
        }
        onExited: (code, status) => { if (code) root.error = "System status unavailable. Check the optional Arch desktop services."; }
    }
    Process {
        id: networkProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parse(text);
                if (result.ok) root.acceptNetwork(result);
            }
        }
    }
    Process {
        id: networkDetailsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parse(text);
                if (result.ok) root.acceptNetworkDetails(result);
            }
        }
    }
    Process {
        id: actionProcess
        property string inputPayload: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parse(text);
                root.error = result.ok ? "" : (result.error || "System control failed.");
                if (result.ok) root.refresh();
            }
        }
        onExited: (code, status) => { root.busy = false; if (code) root.error = "System control failed. Check service status."; }
        onRunningChanged: {
            root.busy = running;
            if (running && inputPayload.length) {
                write(inputPayload);
                inputPayload = "";
                stdinEnabled = false;
            }
        }
    }
}
