import QtQuick
import Quickshell
import qs.services
import qs.modules.common

/**
 * Dev-only harness (DOORWAY_LOCK_TEST=1): the lock's component stack in a
 * resizable floating window. WlSessionLock is compositor-global — iterating
 * on the real thing means locking the real session — so everything visual
 * and the PAM flow get exercised here first.
 *
 * Dev keys are Ctrl-chorded so plain typing reaches the password buffer:
 * Ctrl+L = lock · Ctrl+N = next shader · Ctrl+U = force unlock (dev escape)
 */
FloatingWindow {
    id: win
    title: "DOORway Lock — test harness"
    implicitWidth: 960
    implicitHeight: 540
    color: DoorwayPalette.inkBlack

    ScreensaverView {
        anchors.fill: parent
        screenName: ""
    }

    PasswordPanel {
        anchors.fill: parent
    }

    CutoutIntro {
        id: intro
        anchors.fill: parent
        visible: DoorwayLock.state === DoorwayLock.stateIntro
        onFinished: DoorwayLock.introFinished()
    }

    Connections {
        target: DoorwayLock
        function onStateChanged() {
            if (DoorwayLock.state === DoorwayLock.stateIntro) intro.start();
        }
    }

    // shader name chip, dev aid only — not part of the lock UI
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        width: chipLabel.implicitWidth + 16
        height: chipLabel.implicitHeight + 8
        color: DoorwayPalette.inkBlack
        opacity: 0.8

        Text {
            id: chipLabel
            anchors.centerIn: parent
            text: DoorwayLock.currentShaderName + " · " + ["inactive", "intro", "screensaver", "prompt", "auth"][DoorwayLock.state]
            color: DoorwayPalette.powerGold
            font.family: Appearance.font.family.display
            font.pixelSize: 12
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        // The same routing LockSurface uses on the real lock (Phase 5):
        // printable keys wake AND type; Enter submits; Esc naps the prompt.
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_N) DoorwayLock.rollShader();
                else if (event.key === Qt.Key_L) DoorwayLock.lock();
                else if (event.key === Qt.Key_U) DoorwayLock.unlock(); // dev escape hatch
                return;
            }
            if (!DoorwayLock.locked) return;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) DoorwayLock.submit();
            else if (event.key === Qt.Key_Backspace) DoorwayLock.backspace();
            else if (event.key === Qt.Key_Escape) DoorwayLock.sleep();
            else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20) DoorwayLock.typeText(event.text);
            else DoorwayLock.wake(); // modifiers and nav keys still wake the prompt
        }
    }
}
