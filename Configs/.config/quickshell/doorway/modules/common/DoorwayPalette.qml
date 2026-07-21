pragma Singleton
import QtQuick
import Quickshell

/**
 * DOORway signature palette — the committed identity colors, sampled from Nintendo Power #50
 * (the same palette as the user's website, MarkusBitterman.github.io). This is the single
 * source of truth for the vivid accent hues used by bar widgets (stripe, gauges, VU meter),
 * and it seeds the Material schemes in Appearance.qml's m3colors.
 *
 * Two cartridge modes, mirroring the website's np-gray-cart / np-gold-cart token sets:
 *   dark = gray NES cartridge (the original committed scheme)
 *   gold = gold LoZ cartridge (light: aged-paper surfaces, golden plastic, ink text)
 * Switched via Config appearance.palette.mode (ThemeMode service / Super's theme IPC).
 */
Singleton {
    id: root

    readonly property bool goldCart: (Config.options?.appearance?.palette?.mode ?? "dark") === "gold"

    // --- Raw signature tokens (shared across modes) ---
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

    // --- A few lifted variants for legibility on the current surface ---
    readonly property color grassBright:   goldCart ? "#4A8C2C" : "#7FC95A"
    readonly property color redBright:     goldCart ? powerRed  : "#FF5C4A"
    readonly property color goldDim:       goldCart ? "#EAD98F" : "#5A4A12"
    // Network gauge accent. On the gold (daytime) bar the old light blue washed out, so
    // gold uses the bold deep-navy heroBlue; dark keeps the legible lighter skyHint.
    readonly property color netAccent:     goldCart ? heroBlue  : skyHint

    // --- Cartridge-faceplate plastic tones (central tuning for the whole UI) ---
    // Dark: gray NES cart (warm near-black). Gold: LoZ cart golden plastic, top-lit.
    readonly property color plasticShellTop:    goldCart ? "#D6BF71" : "#2C2822" // bar/sidebar shell, top-lit; also a *raised* key face
    readonly property color plasticShellBottom: goldCart ? "#B99D4F" : "#191611"
    readonly property color plasticPanelTop:    goldCart ? "#C7AF5F" : "#241F18" // recessed inner panels / cards; also a *pressed* key face
    readonly property color plasticPanelBottom: goldCart ? "#AB9045" : "#16120E"
    readonly property color plasticEdge:        goldCart ? "#8A7332" : "#0C0906" // molded border
    readonly property color bevelHighlight:     goldCart ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.06)
    readonly property color bevelShadow:        goldCart ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.45)

    // --- ENCOM boardroom (right sidebar) — fixed dark instrument, mode-independent ---
    // Like the walnut veneer and lock shaders, the boardroom does not flip on the
    // light/dark cartridge; everything drawn on it must use these tokens, never the
    // mode-following Appearance scheme (which resolves to ink-on-ink in gold mode).
    readonly property color hudInk:        "#0A0E14" // opaque ground (cool ink, not the warm inkBlack)
    readonly property color hudPanel:      "#0D141D" // framed panel fill
    readonly property color hudCard:       "#121B27" // raised card (notification group)
    readonly property color hudWell:       "#070A0F" // recessed well / shader scrim base
    readonly property color hudText:       "#D8E4F2" // primary readout text (~14.7:1 on hudInk)
    readonly property color hudTextDim:    "#8FA9C4" // secondary readout text (~7.7:1 on hudInk)
    readonly property color hudLabel:      Qt.rgba(skyHint.r, skyHint.g, skyHint.b, 0.62) // tracked micro-labels
    readonly property color hudLine:       Qt.rgba(skyHint.r, skyHint.g, skyHint.b, 0.28) // hairline frames
    readonly property color hudLineBright: Qt.rgba(skyHint.r, skyHint.g, skyHint.b, 0.75) // active/focused frames
    // Interactive-fill washes for hud controls floating over the boardroom (dialog
    // rows/buttons/combos) + the modal scrim. Fixed like the rest — a mode-following
    // scrim would go milky-light over the dark instrument in gold mode.
    readonly property color hudHover:      Qt.rgba(skyHint.r, skyHint.g, skyHint.b, 0.10) // hover / resting fill
    readonly property color hudHoverStrong:Qt.rgba(skyHint.r, skyHint.g, skyHint.b, 0.18) // pressed / selected fill
    readonly property color hudScrim:      Qt.rgba(0, 0, 0, 0.55)                          // modal dim behind dialogs

    // --- Hardware-control semantics (LED pips, lit faces) ---
    // A raised key sits on shell tones and depresses into panel tones — the existing
    // tokens already encode raised-vs-recessed, so no extra plastic colors are needed.
    readonly property color ledGold:  powerGold     // default ON indicator
    readonly property color ledGrass: grassBright   // success / "active" toggles
    readonly property color ledRed:   redBright     // destructive / danger
    readonly property color ledOff:   goldCart ? "#8F7A38" : "#0A0805" // unlit pip, sunk into the face
}
