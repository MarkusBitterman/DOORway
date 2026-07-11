import qs.modules.common
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell

/**
 * The DOORway "ENCOM Boardroom" shell surface — a live GLSL data-flow screen
 * (assets/shaders/sidebar/encom_dataflow.frag.qsb): vertical neon signal lanes
 * with traveling comet-packets over ink black, recolored to DOORway (heroBlue→
 * skyHint glow, powerGold pings). The right sidebar's cyberpunk backdrop.
 *
 * Mirrors WalnutBackground's role and API (horizontal is accepted for drop-in
 * parity but the flow is always vertical). Mode-independent: like the walnut
 * veneer, the boardroom screen is a fixed identity — it does not flip on the
 * light/dark cartridge; only the wells (HudPanels) sitting on top change.
 *
 * `activity` (0..1) is fed to the shader's uActivity uniform — bind it to live
 * load (e.g. max(net%, cpu%)) so the traces surge under real system activity.
 * `active` gates the animation clock so the shader burns no GPU while the
 * sidebar is hidden — bind it to GlobalStates.sidebarRightOpen from the caller.
 *
 * Rounded corners via OpacityMask (Qt clip only clips to the bounding rect,
 * leaving the square shader quad poking past the radius).
 */
Item {
    id: root
    property bool horizontal: false         // accepted for WalnutBackground parity; flow is vertical
    property real radius: 0
    property color edgeColor: DoorwayPalette.plasticEdge
    property real borderWidth: 1
    property real activity: 0               // 0..1 → uActivity uniform
    property bool active: true              // clock gate (bind to sidebar-open state)
    property real pixelScale: 0.6           // render below native for the VCS APU, then upscale

    // Actual FBO pixel size the shader renders at. iResolution is passed to match
    // so the shader's scanlines land on real pixels rather than sub-pixel.
    readonly property size renderSize: Qt.size(
        Math.max(2, Math.round(width * pixelScale)),
        Math.max(2, Math.round(height * pixelScale)))

    FrameAnimation {
        id: clock
        running: root.visible && root.active
    }

    // Shader rendered into an offscreen low-res layer so it can be masked and
    // cheaply upscaled (smooth — the neon glow should not read as chunky RF pixels).
    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: root.renderSize

        Rectangle {
            anchors.fill: parent
            color: DoorwayPalette.inkBlack   // ground / fallback before first frame
        }

        ShaderEffect {
            anchors.fill: parent
            property real iTime: clock.elapsedTime
            property vector2d iResolution: Qt.vector2d(root.renderSize.width, root.renderSize.height)
            property real uActivity: root.activity
            fragmentShader: Qt.resolvedUrl("../../../assets/shaders/sidebar/encom_dataflow.frag.qsb")
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

    // Molded outer edge (transparent fill so the screen shows through).
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.edgeColor
        visible: root.borderWidth > 0
    }
}
