import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root
    property string osId: ""
    property var osLike: []
    property string osName: ""
    readonly property var logos: ({
        arch: "", debian: "", fedora: "", ubuntu: "",
        nixos: "", gentoo: "", linuxmint: "", opensuse: "",
        manjaro: "", rhel: "", centos: "", linux: ""
    })
    readonly property string logo: {
        if (logos[osId]) return logos[osId];
        for (const family of osLike) if (logos[family]) return logos[family];
        return osId ? logos.linux : "";
    }
    implicitWidth: 18
    implicitHeight: 18
    Accessible.name: osName || "Velum"
    ToolTip.visible: hovered.hovered
    ToolTip.text: osName || "Velum"
    ToolTip.delay: 700
    HoverHandler { id: hovered }
    PixelIcon {
        anchors.fill: parent
        symbol: "velum"
        visible: !root.logo
    }
    Text {
        anchors.fill: parent
        text: root.logo
        visible: !!root.logo
        color: Theme.text
        font.family: Theme.barFont
        font.pixelSize: 17
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
