import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * A discrete bar-graph readout — the lit blocks of a console VU meter / equalizer.
 *
 * `value` (0..1) lights blocks left-to-right. Lit blocks glow `litColor`, switching to
 * `peakColor` for the top `peakFraction` of the range (the classic "into the red"). Unlit
 * blocks sit dark and recessed (`dimColor`) so the meter reads even at zero. Each block is
 * a hard-edged plastic chip, not a rounded pill — that squareness is the retro tell.
 */
Item {
    id: root
    property real value: 0
    property int segments: 14
    property color litColor: DoorwayPalette.ledGold
    property color peakColor: DoorwayPalette.redBright
    property color dimColor: Qt.rgba(0, 0, 0, 0.42)
    property real peakFraction: 0.15   // top 15% of blocks light up in peakColor
    property real spacing: 2
    property real segmentRadius: 1

    implicitHeight: 14

    Row {
        id: row
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                // Width is derived so N blocks + (N-1) gaps exactly fill the row.
                width: (root.width - root.spacing * (root.segments - 1)) / root.segments
                height: root.height
                radius: root.segmentRadius

                readonly property real threshold: (index + 1) / root.segments
                readonly property bool on: root.value >= threshold - (1 / root.segments) * 0.5
                readonly property bool peak: index >= root.segments * (1 - root.peakFraction)

                color: on ? (peak ? root.peakColor : root.litColor) : root.dimColor
                // Lit chips get a hot top edge; dark chips get a recessed inner shadow.
                border.width: 1
                border.color: on ? Qt.lighter(color, 1.25) : Qt.rgba(0, 0, 0, 0.5)

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}
