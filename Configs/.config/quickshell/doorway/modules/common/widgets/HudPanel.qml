import qs.modules.common
import QtQuick

/**
 * Translucent neon "HUD panel" — the well that floats over the EncomBackground
 * boardroom screen on the right sidebar. Semi-transparent ink lets the data-flow
 * glow through the gaps between cards, with a thin sky/hero edge-glow border so
 * each panel reads as an edge-lit heads-up display element.
 *
 * Drop-in replacement for the plasticPanelTop→Bottom gradient card recipe: it is
 * a Rectangle, so callers keep all their layout/clip/implicit* properties and
 * simply stop declaring gradient/radius/border themselves.
 *
 * Mode-independent, like the boardroom backdrop it sits on — the panels do not
 * flip on the light/dark cartridge.
 */
Rectangle {
    id: root

    // Translucency of the ink ground. Lower = more shader bleeds through.
    property real fillAlpha: 0.55
    // Edge-glow strength.
    property real edgeAlpha: 0.65

    radius: Appearance.rounding.verysmall
    color: Qt.rgba(DoorwayPalette.inkBlack.r,
                   DoorwayPalette.inkBlack.g,
                   DoorwayPalette.inkBlack.b,
                   root.fillAlpha)
    border.width: 1
    border.color: Qt.rgba(DoorwayPalette.skyHint.r,
                          DoorwayPalette.skyHint.g,
                          DoorwayPalette.skyHint.b,
                          root.edgeAlpha)
}
