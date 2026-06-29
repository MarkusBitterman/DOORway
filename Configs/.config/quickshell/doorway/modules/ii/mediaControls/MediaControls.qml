// DOORway QuickShell — media controls popup. Wires up GlobalStates.mediaControlsOpen,
// which Media.qml has toggled on left-click since Phase 15 but nothing listened to.
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.mediaControlsOpen

        function hide() {
            GlobalStates.mediaControlsOpen = false;
        }

        exclusiveZone: 0
        // Pad by elevationMargin so the neon glow / drop shadow isn't clipped at the edges.
        implicitWidth: Appearance.sizes.mediaControlsWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: Appearance.sizes.mediaControlsHeight + Appearance.sizes.elevationMargin * 2
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:mediaControls"
        WlrLayershell.keyboardFocus: GlobalStates.mediaControlsOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Top edge only → compositor centers it horizontally, just under the bar.
        anchors { top: true }
        margins { top: Appearance.sizes.barHeight }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() { panelWindow.hide(); }
        }

        Loader {
            active: GlobalStates.mediaControlsOpen
            anchors.fill: parent
            anchors.margins: Appearance.sizes.elevationMargin
            focus: GlobalStates.mediaControlsOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) panelWindow.hide();
            }
            sourceComponent: MediaControlsContent {}
        }
    }
}
