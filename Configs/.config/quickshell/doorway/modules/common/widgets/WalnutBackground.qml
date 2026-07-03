import qs.modules.common
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell

/**
 * The DOORway "Black Walnut" shell surface — a procedurally-generated walnut veneer
 * (assets/textures/walnut-{h,v}.png, see gen-walnut.sh) finished with a top-lit lacquer
 * sheen and a molded-edge border, echoing the Atari VCS 800 "Black Walnut" faceplate.
 *
 * Used as the *shell* background of the bar and sidebars. The light/dark "wells" that sit
 * on top of it (BarGroup, sidebar cards) keep their own plasticPanel treatment, so the
 * woodgrain is mode-independent — walnut stays walnut; only the wells flip light/dark.
 *
 * Rounded corners are achieved by OpacityMask (Qt clip only clips to the bounding rect,
 * leaving square texture corners poking past the radius).
 */
Item {
    id: root
    property bool horizontal: true          // grain direction: bar = horizontal, sidebars = vertical
    property real radius: 0
    property bool sheen: true               // top-lit gloss + bottom shadow (lacquered furniture look)
    property color edgeColor: DoorwayPalette.plasticEdge
    property real borderWidth: 1
    property int fillMode: Image.PreserveAspectCrop

    // Woodgrain + lacquer sheen, rendered into an offscreen layer so it can be masked.
    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true

        Image {
            anchors.fill: parent
            source: Quickshell.shellPath(root.horizontal
                ? "assets/textures/walnut-h.png"
                : "assets/textures/walnut-v.png")
            fillMode: root.fillMode
            cache: true
            smooth: true
            asynchronous: true
        }

        // Lacquer sheen: a bright top-lit gloss fading out, with a settled bottom shadow.
        Rectangle {
            anchors.fill: parent
            visible: root.sheen
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, 0.11) }
                GradientStop { position: 0.14; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 0.85; color: "transparent" }
                GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.24) }
            }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    OpacityMask {
        anchors.fill: parent
        source: content
        maskSource: mask
    }

    // Molded outer edge (transparent fill so the texture shows through).
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.edgeColor
        visible: root.borderWidth > 0
    }
}
