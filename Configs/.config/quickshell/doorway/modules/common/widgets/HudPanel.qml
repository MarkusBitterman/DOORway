import qs.modules.common
import QtQuick

/**
 * Boardroom instrument panel — a framed zone on the right sidebar's flat ink
 * ground. Opaque fill (text always sits on solid ground — the data-flow shader
 * never bleeds under content), 1px hairline frame, near-rectilinear corners.
 * `showTicks` adds bright corner brackets for major frames (GriD-style).
 *
 * Drop-in Rectangle subclass: callers keep layout/clip/implicit* properties.
 * Mode-independent, like everything on the boardroom surface.
 */
Rectangle {
    id: root

    // Kept for caller compatibility; panels default to opaque now — translucency
    // over the old full-field shader was the sidebar's core legibility failure.
    property real fillAlpha: 1.0
    property real edgeAlpha: 1.0
    property bool showTicks: false
    property real tickSize: 7

    radius: 3
    color: Qt.rgba(DoorwayPalette.hudPanel.r,
                   DoorwayPalette.hudPanel.g,
                   DoorwayPalette.hudPanel.b,
                   root.fillAlpha)
    border.width: 1
    border.color: Qt.rgba(DoorwayPalette.hudLine.r,
                          DoorwayPalette.hudLine.g,
                          DoorwayPalette.hudLine.b,
                          DoorwayPalette.hudLine.a * root.edgeAlpha)

    // Corner brackets — four L-shaped ticks over the frame corners.
    Repeater {
        model: root.showTicks ? 4 : 0
        delegate: Item {
            id: tick
            required property int index
            readonly property bool atRight: index % 2 === 1
            readonly property bool atBottom: index >= 2
            width: root.tickSize
            height: root.tickSize
            anchors {
                left: tick.atRight ? undefined : parent.left
                right: tick.atRight ? parent.right : undefined
                top: tick.atBottom ? undefined : parent.top
                bottom: tick.atBottom ? parent.bottom : undefined
            }
            Rectangle { // horizontal arm
                width: parent.width
                height: 1
                y: tick.atBottom ? tick.height - 1 : 0
                color: DoorwayPalette.hudLineBright
            }
            Rectangle { // vertical arm
                width: 1
                height: parent.height
                x: tick.atRight ? tick.width - 1 : 0
                color: DoorwayPalette.hudLineBright
            }
        }
    }
}
