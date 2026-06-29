import qs.modules.common
import QtQuick

/**
 * The Nintendo-Power accent stripe — repeating gold bands over a fading red base, ported from
 * the user's website (.np-stripes). Static (painted on resize only), so it's cheap. Used as a
 * thin signature accent along the bar's edge; reusable on other surfaces.
 */
Canvas {
    id: root
    property color gold: DoorwayPalette.powerGold
    property color red: DoorwayPalette.powerRed
    property int band: 10
    property int gap: 5
    property bool vertical: false // run the bands down a cartridge-edge label instead of across

    implicitHeight: 3

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (!root.vertical) {
            // Horizontal: red base strong at the left, fading out (the logo energy band).
            const g = ctx.createLinearGradient(0, 0, width, 0)
            g.addColorStop(0.0, Qt.rgba(red.r, red.g, red.b, 0.85))
            g.addColorStop(1.0, Qt.rgba(red.r, red.g, red.b, 0.35))
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
            ctx.fillStyle = root.gold
            for (let x = 0; x < width; x += root.band + root.gap)
                ctx.fillRect(x, 0, root.band, height)
        } else {
            // Vertical: a cartridge end-label band.
            const g = ctx.createLinearGradient(0, 0, 0, height)
            g.addColorStop(0.0, Qt.rgba(red.r, red.g, red.b, 0.85))
            g.addColorStop(1.0, Qt.rgba(red.r, red.g, red.b, 0.35))
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
            ctx.fillStyle = root.gold
            for (let y = 0; y < height; y += root.band + root.gap)
                ctx.fillRect(0, y, width, root.band)
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVerticalChanged: requestPaint()
}
