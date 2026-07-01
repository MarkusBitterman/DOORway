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

    // --- Cartridge-faceplate plastic tones (central tuning for the whole UI) ---
    readonly property color plasticShellTop:    "#2C2822" // bar/sidebar shell, top-lit; also a *raised* key face
    readonly property color plasticShellBottom: "#191611"
    readonly property color plasticPanelTop:    "#241F18" // recessed inner panels / cards; also a *pressed* key face
    readonly property color plasticPanelBottom: "#16120E"
    readonly property color plasticEdge:        "#0C0906" // dark molded border
    readonly property color bevelHighlight:     Qt.rgba(1, 1, 1, 0.06)
    readonly property color bevelShadow:        Qt.rgba(0, 0, 0, 0.45)

    // --- Hardware-control semantics (LED pips, lit faces) ---
    // A raised key sits on shell tones and depresses into panel tones — the existing
    // tokens already encode raised-vs-recessed, so no extra plastic colors are needed.
    readonly property color ledGold:  powerGold     // default ON indicator
    readonly property color ledGrass: grassBright   // success / "active" toggles
    readonly property color ledRed:   redBright     // destructive / danger
    readonly property color ledOff:   "#0A0805"     // unlit pip, sunk into the face
}
