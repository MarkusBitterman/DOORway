import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * An ENCOM boardroom control — the hud-language sibling of PlasticKey, for the
 * right sidebar only. Where PlasticKey is molded cartridge plastic, HudKey is
 * drawn line-work on the boardroom screen: transparent face, 1px hairline frame,
 * and a small square state pip in the corner instead of a domed LED.
 *
 * States are conveyed the GriD way — line weight and fill, no bevels, no bounce:
 * rest = faint hairline; hover = lifted fill; toggled = bright frame + sky wash
 * with the pip lit in `ledColor` (powerGold by default: gold is the boardroom's
 * single warm accent, reserved for "live/now").
 *
 * API-compatible with PlasticKey (ledColor/showLed, GroupButton plumbing) so
 * the sidebar's toggle implementations can swap base types without rewiring.
 */
GroupButton {
    id: root

    property color ledColor: DoorwayPalette.powerGold
    property bool showLed: true

    bounce: false
    buttonRadius: 3
    buttonRadiusPressed: 2

    background: Rectangle {
        radius: root.radius
        color: root.toggled
            ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b,
                      root.down ? 0.24 : root.hovered ? 0.19 : 0.14)
            : Qt.rgba(1, 1, 1, root.down ? 0.10 : root.hovered ? 0.06 : 0)
        border.width: 1
        border.color: root.toggled ? DoorwayPalette.hudLineBright
            : root.hovered ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.45)
            : DoorwayPalette.hudLine

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Square state pip — lit when toggled, an empty outline otherwise.
        Rectangle {
            visible: root.showLed
            width: 5
            height: 5
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 4
                rightMargin: 4
            }
            color: root.toggled ? root.ledColor : "transparent"
            border.width: root.toggled ? 0 : 1
            border.color: DoorwayPalette.hudLine

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
