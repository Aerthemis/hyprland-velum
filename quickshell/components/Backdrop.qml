import QtQuick
import "../theme"

Rectangle {
    id: root
    color: Theme.background
    clip: true
    Behavior on color { ColorAnimation { duration: Theme.motion } }
    Canvas {
        id: ribbons
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: Theme
            function onLightChanged() { ribbons.requestPaint(); }
            function onAccentIndexChanged() { ribbons.requestPaint(); }
        }
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            // Original contour wallpaper: slow folds, not an external bitmap.
            for (let i = 26; i >= 0; --i) {
                const d = i * 14;
                ctx.beginPath();
                ctx.moveTo(w * .56 + d, -50);
                ctx.bezierCurveTo(w * .08 + d, h * .42, w * 1.14 + d, h * .32, w * .48 + d, h + 50);
                ctx.lineWidth = i % 5 === 0 ? 1.3 : .65;
                ctx.strokeStyle = Qt.alpha(Theme.accent, Theme.light ? .20 : .13);
                ctx.stroke();
            }
            const glow = ctx.createRadialGradient(w * .76, h * .46, 0, w * .76, h * .46, w * .6);
            glow.addColorStop(0, Qt.alpha(Theme.accent, .12));
            glow.addColorStop(1, "transparent");
            ctx.fillStyle = glow;
            ctx.fillRect(0, 0, w, h);
        }
    }
}
