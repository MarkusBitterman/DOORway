import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * A single hardware indicator light — the little LED that tells you a console toggle is ON.
 *
 * Off: a dark pip sunk into the plastic (ledOff + a faint inner shadow ring).
 * On:  filled in `color` with a soft NeonGlow halo, so it reads as actually emitting light
 *      rather than just being a colored dot. The glow is `cached` (see NeonGlow), so an
 *      always-present pip costs nothing when unlit and one cheap render when lit.
 */
Item {
    id: root
    property bool lit: false
    property color color: DoorwayPalette.ledGold
    property real size: 6

    implicitWidth: size
    implicitHeight: size

    // Emissive halo — only meaningful when lit. Declared before the pip so it renders behind.
    NeonGlow {
        target: pip
        glowColor: root.color
        intensity: 0.6
        visible: root.lit
    }

    Rectangle {
        id: pip
        anchors.fill: parent
        radius: width / 2
        color: root.lit ? root.color : DoorwayPalette.ledOff
        border.width: 1
        // A bright rim when lit (the hot edge of an LED); a dark sunk rim when off.
        border.color: root.lit ? Qt.lighter(root.color, 1.3) : Qt.rgba(0, 0, 0, 0.55)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
