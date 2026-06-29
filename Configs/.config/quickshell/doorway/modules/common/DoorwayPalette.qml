pragma Singleton
import QtQuick
import Quickshell

/**
 * DOORway signature palette — the committed identity colors, sampled from Nintendo Power #50
 * (the same palette as the user's website, MarkusBitterman.github.io). This is the single
 * source of truth for the vivid accent hues used by bar widgets (stripe, gauges, VU meter),
 * and it seeds the warm-dark Material scheme in Appearance.qml's m3colors.
 *
 * Unlike the matugen (wallpaper-adaptive) flow, these do NOT change with the wallpaper — see
 * MaterialThemeLoader's `committed` gate. Phase 2 may reintroduce matugen as a "hybrid" mode.
 */
Singleton {
    id: root

    // --- Raw signature tokens ---
    readonly property color powerRed:      "#E60012" // primary action / danger / the logo fire
    readonly property color powerGold:     "#FFC20E" // warmth / accent stripe / the Nintendo Power band
    readonly property color heroBlue:      "#1F3C88" // Link's tunic / links
    readonly property color skyHint:       "#6FA3D9" // lighter blue (legible on dark)
    readonly property color koholintGrass: "#5FAF3A" // success / grassland green
    readonly property color owlUmber:      "#8A4F2A" // brown earth tone
    readonly property color featherRust:   "#C46A2D" // warm rust
    readonly property color parchmentSand: "#C9A46A" // warm sandy beige
    readonly property color agedPaper:     "#EFE3C5" // warm off-white (body text on dark)
    readonly property color inkBlack:      "#1C1C1C" // ink / on-accent text
    readonly property color shadowBark:    "#3A2A1E" // dark warm brown

    // --- A few lifted variants for legibility on near-black ---
    readonly property color grassBright:   "#7FC95A"
    readonly property color redBright:      "#FF5C4A"
    readonly property color goldDim:        "#5A4A12"
}
