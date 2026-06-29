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
    property int band: 18
    property int gap: 8

    implicitHeight: 3

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        // Red base — strong at the left, fading out (the logo energy band).
        const g = ctx.createLinearGradient(0, 0, width, 0)
        g.addColorStop(0.0, Qt.rgba(red.r, red.g, red.b, 0.55))
        g.addColorStop(0.6, Qt.rgba(red.r, red.g, red.b, 0.0))
        ctx.fillStyle = g
        ctx.fillRect(0, 0, width, height)
        // Gold dashes.
        ctx.fillStyle = root.gold
        for (let x = 0; x < width; x += root.band + root.gap)
            ctx.fillRect(x, 0, root.band, height)
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
