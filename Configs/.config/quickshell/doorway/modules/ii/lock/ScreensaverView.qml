import QtQuick
import qs.services
import qs.modules.common

/**
 * The screensaver picture: one retro-CRT ShaderEffect, rendered deliberately
 * low-res (layer.textureSize at pixelScale, nearest-neighbor upscale) for the
 * website's fat RF-adapter pixels — which is also what keeps the fireworks
 * shader affordable on the VCS APU. A signal_cutout static burst masks each
 * shader swap so rotation reads as changing the channel.
 */
Item {
    id: root

    // set by LockSurface (screen.name); harness leaves it ""
    property string screenName: ""

    readonly property var conf: Config.options.lock.screensaver
    readonly property bool shaderEnabled: !conf.disableOnScreens.includes(screenName)
    readonly property size renderSize: Qt.size(
        Math.max(2, Math.round(width * conf.pixelScale)),
        Math.max(2, Math.round(height * conf.pixelScale)))

    layer.enabled: shaderEnabled
    layer.textureSize: renderSize
    layer.smooth: false // nearest-neighbor — the pixels must stay chunky

    FrameAnimation {
        id: clock
        running: root.visible && root.shaderEnabled
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.shaderEnabled
        property real iTime: clock.elapsedTime
        property vector2d iResolution: Qt.vector2d(root.renderSize.width, root.renderSize.height)
        fragmentShader: Qt.resolvedUrl("../../../assets/shaders/lock/"
            + DoorwayLock.currentShaderName + ".frag.qsb")
    }

    // channel-change burst: signal_cutout held at low progress = pure RF snow
    ShaderEffect {
        id: burst
        anchors.fill: parent
        visible: opacity > 0
        opacity: 0
        property real iTime: clock.elapsedTime
        property vector2d iResolution: Qt.vector2d(root.renderSize.width, root.renderSize.height)
        property real progress: 0.12
        fragmentShader: Qt.resolvedUrl("../../../assets/shaders/lock/signal_cutout.frag.qsb")
    }

    Connections {
        target: DoorwayLock
        function onCurrentShaderIndexChanged() {
            if (root.shaderEnabled) burstAnim.restart();
        }
    }

    SequentialAnimation {
        id: burstAnim
        NumberAnimation { target: burst; property: "opacity"; to: 1; duration: 90 }
        NumberAnimation { target: burst; property: "opacity"; to: 0; duration: 320 }
    }

    // screens on the kill list (HEADLESS-1) get dead ink, not GPU work
    Rectangle {
        anchors.fill: parent
        visible: !root.shaderEnabled
        color: DoorwayPalette.inkBlack

        Text {
            anchors.centerIn: parent
            text: "DOORway"
            color: DoorwayPalette.agedPaper
            opacity: 0.25
            font.family: Appearance.font.family.display
            font.pixelSize: 24
        }
    }
}
