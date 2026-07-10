import QtQuick
import qs.services
import qs.modules.common

/**
 * The signal dies. Drives signal_cutout.frag's `progress` uniform 0→1 over
 * intro.durationMs: static burst → vertical collapse to a hot line →
 * phosphor dot decay to black. Fully opaque while running (it covers the
 * screensaver starting beneath); emits finished() so DoorwayLock advances.
 * skip() jumps to the end — any keypress during the intro should call it.
 */
Item {
    id: root

    signal finished()

    property real progress: 0

    function start() {
        progress = 0;
        anim.restart();
    }

    function skip() {
        anim.stop();
        root.progress = 1;
        root.finished();
    }

    onVisibleChanged: if (!visible) anim.stop()

    FrameAnimation {
        id: clock
        running: root.visible
    }

    ShaderEffect {
        anchors.fill: parent
        property real iTime: clock.elapsedTime
        property vector2d iResolution: Qt.vector2d(width, height)
        property real progress: root.progress
        fragmentShader: Qt.resolvedUrl("../../../assets/shaders/lock/signal_cutout.frag.qsb")
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Config.options.lock.intro.durationMs
        onFinished: root.finished()
    }
}
