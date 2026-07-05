pragma Singleton
import QtQuick
import Quickshell

/**
 * Editorial ink-on-paper tokens — the left sidebar's "open magazine" identity.
 * Deliberately NOT theme-driven: the page is always matte cream paper with dark
 * ink, in both dark and gold cartridge modes (the walnut right sidebar carries the
 * mode; the paper left sidebar is a fixed printed surface). The one spot of colour
 * is `folioAccent`, DOORway's own powerRed, used only on the masthead folio so the
 * page reads as *this* magazine and not a generic cream-and-serif template.
 *
 * Same-module singletons (DoorwayPalette, Appearance) resolve without an import.
 */
Singleton {
    id: root

    // --- Ink ---
    readonly property color ink:      "#2A2018" // body ink / headings
    readonly property color inkMuted: "#6B5A48" // captions, secondary, folio
    readonly property color rule:     "#C9B78C" // hairline dividers / column rules
    readonly property color tint:     Qt.rgba(0.165, 0.125, 0.094, 0.06) // hover / pull-quote wash (ink @ 6%)

    // --- Paper edge (matches MagazinePaper) ---
    readonly property color paperEdge: "#D6C6A2"

    // --- The single accent: DOORway's own masthead red ---
    readonly property color folioAccent: DoorwayPalette.powerRed

    // --- Type roles ---
    readonly property string serifFont: "Georgia"                       // masthead + section heads
    readonly property string bodyFont:  Appearance.font.family.reading  // list rows / body
    readonly property string monoFont:  Appearance.font.family.monospace // Notes manuscript
}
