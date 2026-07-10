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
 * Keys: Space = next shader · L = run lock state machine · Esc = force unlock
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
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space) DoorwayLock.rollShader();
            else if (event.key === Qt.Key_L) DoorwayLock.lock();
            else if (event.key === Qt.Key_Escape) DoorwayLock.unlock();
        }
    }
}
