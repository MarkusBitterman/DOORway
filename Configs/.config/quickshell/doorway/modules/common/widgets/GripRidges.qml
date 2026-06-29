import QtQuick

/**
 * Molded grip ridges — the vertical grooves on the grip of an NES/SNES cartridge. Drawn as
 * lit-left / shadowed-right line pairs so the grooves read as 3D plastic. Static (painted on
 * resize only), so it's cheap. Used at the ends of the cartridge-faceplate bar.
 */
Canvas {
    id: root
    property color highlight: Qt.rgba(1, 1, 1, 0.07)
    property color shadow: Qt.rgba(0, 0, 0, 0.45)
    property int ridges: 5
    property real ridgeW: 2
    property real gap: 2

    implicitWidth: ridges * ridgeW + (ridges - 1) * gap

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        for (let i = 0; i < root.ridges; i++) {
            const x = i * (root.ridgeW + root.gap)
            ctx.fillStyle = root.highlight
            ctx.fillRect(x, 0, 1, height)                    // lit left edge of the ridge
            ctx.fillStyle = root.shadow
            ctx.fillRect(x + root.ridgeW - 1, 0, 1, height)  // shadowed right edge (the groove)
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
