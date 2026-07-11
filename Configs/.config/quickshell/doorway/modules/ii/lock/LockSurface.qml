import QtQuick
import Quickshell.Wayland
import qs.services
import qs.modules.common

/**
 * One per screen, instantiated by WlSessionLock. This IS the security
 * boundary — ext-session-lock renders above everything, so the whole show
 * lives inside it. Solid inkBlack base paints the first frame before any
 * shader initializes (no desktop flash). All state lives in DoorwayLock;
 * this surface only renders it and routes raw input into it, so multiple
 * monitors stay in perfect sync.
 */
WlSessionLockSurface {
    id: surface

    color: DoorwayPalette.inkBlack

    ScreensaverView {
        anchors.fill: parent
        screenName: surface.screen?.name ?? ""
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

    // surfaces are created after lock() already set the state — catch up
    Component.onCompleted: {
        if (DoorwayLock.state === DoorwayLock.stateIntro) intro.start();
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) DoorwayLock.submit();
            else if (event.key === Qt.Key_Backspace) DoorwayLock.backspace();
            else if (event.key === Qt.Key_Escape) DoorwayLock.sleep();
            else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20) DoorwayLock.typeText(event.text);
            else DoorwayLock.wake(); // modifiers and nav keys still wake the prompt
        }
    }

    // deliberate mouse motion (accumulated, not a nudge) or any click wakes
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        property real travel: 0
        property point last: Qt.point(-1, -1)
        onPressed: DoorwayLock.wake()
        onPositionChanged: mouse => {
            if (last.x >= 0)
                travel += Math.abs(mouse.x - last.x) + Math.abs(mouse.y - last.y);
            last = Qt.point(mouse.x, mouse.y);
            if (travel > 25) {
                travel = 0;
                DoorwayLock.wake();
            }
        }
    }
}
