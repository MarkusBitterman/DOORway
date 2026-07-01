import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

/**
 * A console-hardware key — the cartridge-language replacement for a Material toggle/button.
 *
 * Resting, it's a *raised* plastic key (shell tones, lit top bevel). Pressed, it sinks into
 * the faceplate (panel tones, the lit bevel drops away, radius tightens) for a tactile,
 * mechanical feel — no Material bounce, no ripple. When `toggled`, a faint lit tint washes
 * the face and the `LedPip` in the corner comes on.
 *
 * Extends GroupButton purely to inherit its click/alt/middle plumbing and `down`/`toggled`
 * state; the Material visuals (clickBounce width-expand, the flat `color` background) are
 * overridden away here. Subclasses supply their own `contentItem`.
 */
GroupButton {
    id: root

    property color ledColor: DoorwayPalette.ledGold
    property bool showLed: true
    // The faint wash over the face when ON — keeps the plastic reading as the same material,
    // just lit, rather than recoloring it Material-style.
    property real litTintAlpha: 0.86

    bounce: false
    buttonRadius: Appearance.rounding.verysmall
    buttonRadiusPressed: Math.max(2, Appearance.rounding.verysmall - 3)

    background: Rectangle {
        id: keyFace
        radius: root.radius
        border.width: 1
        border.color: DoorwayPalette.plasticEdge

        // Raised (shell) at rest; recessed (panel) while held down.
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.down ? DoorwayPalette.plasticPanelTop : DoorwayPalette.plasticShellTop
            }
            GradientStop {
                position: 1.0
                color: root.down ? DoorwayPalette.plasticPanelBottom : DoorwayPalette.plasticShellBottom
            }
        }

        // Lit wash when toggled on — a transparentized LED color laid over the face.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.toggled
            color: ColorUtils.transparentize(root.ledColor, root.litTintAlpha)
        }

        // Bevel: lit top edge (gone when depressed), shadowed bottom edge.
        Rectangle {
            visible: !root.down
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
            height: 1
            color: DoorwayPalette.bevelHighlight
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
            height: 1
            color: DoorwayPalette.bevelShadow
        }

        // Indicator light, tucked into the top-right corner of the key.
        LedPip {
            visible: root.showLed
            lit: root.toggled
            color: root.ledColor
            size: 6
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 4
                rightMargin: 4
            }
        }
    }
}
