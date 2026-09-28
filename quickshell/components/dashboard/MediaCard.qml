pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."
import "../../theme"

ColumnLayout {
    id: root
    property bool active: false
    property bool compact: false
    property string selectedPlayer: ""
    property var players: Mpris.players.values
    readonly property var player: players.find(p => p.dbusName === selectedPlayer) || players.find(p => p.isPlaying) || players[0] || null
    property real position: 0
    spacing: 14
    function duration(seconds) {
        const n = Math.max(0, Math.floor(seconds));
        return Math.floor(n / 60) + ":" + (n % 60).toString().padStart(2, "0");
    }
    Timer {
        interval: 1000; repeat: true; running: root.active && root.player !== null
        triggeredOnStart: true
        onTriggered: root.position = root.player?.position ?? 0
    }
    ComboBox {
        visible: !root.compact && root.players.length > 1
        Layout.fillWidth: true
        model: root.players.map(p => p.identity)
        currentIndex: Math.max(0, root.players.indexOf(root.player))
        onActivated: root.selectedPlayer = root.players[currentIndex].dbusName
        Accessible.name: "Media player"
        palette.button: Theme.background
        palette.buttonText: Theme.text
        palette.base: Theme.surface
        palette.text: Theme.text
        palette.highlight: Theme.accent
        palette.highlightedText: Theme.ink
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.compact ? 94 : 150
        radius: 16; color: Theme.background
        Text {
            anchors.centerIn: parent
            text: ""; font.family: Theme.barFont; font.pixelSize: 32; color: Theme.accent
            visible: artwork.status !== Image.Ready
        }
        Image {
            id: artwork
            anchors.fill: parent; anchors.margins: 6
            source: root.player?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 400; sourceSize.height: 300
        }
    }
    Text {
        Layout.fillWidth: true
        text: root.player ? (root.player.trackTitle || "Unknown track") : "Nothing playing"
        elide: Text.ElideRight; color: Theme.text
        font.family: Theme.displayFont; font.pixelSize: 18
    }
    Text {
        Layout.fillWidth: true
        text: root.player ? (root.player.trackArtist || root.player.identity) : "Play something in a music app or browser."
        wrapMode: Text.WordWrap; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
    }
    Slider {
        Layout.fillWidth: true
        visible: !root.compact && !!root.player?.lengthSupported && !!root.player?.positionSupported
        enabled: !!root.player?.canSeek
        from: 0; to: Math.max(1, root.player?.length ?? 1)
        value: root.position
        Accessible.name: "Playback position"
        onMoved: if (root.player?.canSeek) root.player.position = value
    }
    Text {
        visible: !root.compact && !!root.player?.lengthSupported && !!root.player?.positionSupported
        text: root.duration(root.position) + " / " + root.duration(root.player?.length ?? 0)
        color: Theme.muted; font.family: Theme.barFont; font.pixelSize: 11
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10
        IconButton { objectName: "previousTrack"; glyph: ""; hint: "Previous track"; enabled: !!root.player?.canControl && !!root.player?.canGoPrevious; opacity: enabled ? 1 : 0.35; onClicked: root.player.previous() }
        IconButton { objectName: "togglePlaying"; glyph: root.player?.isPlaying ? "" : ""; hint: root.player?.isPlaying ? "Pause" : "Play"; selected: true; enabled: !!root.player?.canControl && !!root.player?.canTogglePlaying; opacity: enabled ? 1 : 0.35; onClicked: root.player.togglePlaying() }
        IconButton { objectName: "nextTrack"; glyph: ""; hint: "Next track"; enabled: !!root.player?.canControl && !!root.player?.canGoNext; opacity: enabled ? 1 : 0.35; onClicked: root.player.next() }
    }
    RowLayout {
        visible: !root.compact && !!root.player?.volumeSupported
        Layout.fillWidth: true
        Text { text: "Volume"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
        Slider {
            Layout.fillWidth: true
            from: 0; to: 1; value: root.player?.volume ?? 0
            enabled: !!root.player?.canControl
            Accessible.name: "Player volume"
            onMoved: if (root.player?.canControl) root.player.volume = value
        }
    }
}
