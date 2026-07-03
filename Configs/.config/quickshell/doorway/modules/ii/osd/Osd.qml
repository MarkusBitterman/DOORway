// DOORway QuickShell — Phase 15: volume/brightness on-screen display.
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: osdScope
    property string activeType: "volume"

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            osdScope.activeType = "brightness";
            GlobalStates.osdBrightnessOpen = true;
            GlobalStates.osdVolumeOpen = false;
            osdHideTimer.restart();
        }
    }

    Connections {
        target: Audio
        function onValueChanged() {
            osdScope.activeType = "volume";
            GlobalStates.osdVolumeOpen = true;
            GlobalStates.osdBrightnessOpen = false;
            osdHideTimer.restart();
        }
    }

    Timer {
        id: osdHideTimer
        interval: 2000
        onTriggered: {
            GlobalStates.osdBrightnessOpen = false;
            GlobalStates.osdVolumeOpen = false;
        }
    }

    PanelWindow {
        id: osdPanel
        visible: GlobalStates.osdBrightnessOpen || GlobalStates.osdVolumeOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { bottom: true }
        margins { bottom: Appearance.sizes.hyprlandGapsOut * 2 + 8 }

        implicitWidth: 280
        implicitHeight: 64

        readonly property real brightnessValue: Brightness.monitors[0]?.brightness ?? 0
        readonly property real volumeValue: Audio.value ?? 0
        readonly property bool isBrightness: osdScope.activeType === "brightness"

        StyledRectangularShadow {
            target: osdPill
        }

        // Cartridge readout: a raised plastic panel housing a VU-style segmented meter.
        Rectangle {
            id: osdPill
            anchors.centerIn: parent
            width: parent.width - 8
            height: parent.height - 8
            radius: Appearance.rounding.verysmall  // squared cartridge corners, not a pill
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: DoorwayPalette.plasticShellTop }
                GradientStop { position: 1.0; color: DoorwayPalette.plasticShellBottom }
            }
            border.width: 1
            border.color: DoorwayPalette.plasticEdge

            // Bevel: lit top, shadowed bottom — the cartridge faceplate signature.
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                height: 1
                color: DoorwayPalette.bevelHighlight
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
                height: 1
                color: DoorwayPalette.bevelShadow
            }

            // Faint CRT scanlines drawn over the readout face (cheap, static, clipped to panel).
            Column {
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: Math.ceil(osdPill.height / 3)
                    Rectangle {
                        width: osdPill.width
                        height: 1
                        color: Qt.rgba(0, 0, 0, 0.10)
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                MaterialSymbol {
                    text: osdPanel.isBrightness
                        ? (Hyprsunset.gamma < 100 ? "wb_twilight" : "light_mode")
                        : (Audio.sink?.audio.muted ? "volume_off"
                            : osdPanel.volumeValue > 0.66 ? "volume_up"
                            : osdPanel.volumeValue > 0.33 ? "volume_down"
                            : "volume_mute")
                    iconSize: 20
                    color: DoorwayPalette.agedPaper
                }

                SegmentMeter {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    value: osdPanel.isBrightness
                        ? osdPanel.brightnessValue
                        : Math.min(1.0, osdPanel.volumeValue)
                    // Brightness is a calm gold readout; volume can run "into the red" near max.
                    peakFraction: osdPanel.isBrightness ? 0 : 0.15
                }

                StyledText {
                    text: osdPanel.isBrightness
                        ? Math.round(osdPanel.brightnessValue * 100) + "%"
                        : Math.round(osdPanel.volumeValue * 100) + "%"
                    font.family: Appearance.font.family.display  // Departure Mono — pixel readout
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: DoorwayPalette.agedPaper
                    Layout.minimumWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
