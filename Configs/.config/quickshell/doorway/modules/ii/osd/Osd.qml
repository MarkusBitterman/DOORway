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
            osdScope.showVolume();
        }
    }

    // Mute lives on a different Pipewire property than volume — `wpctl set-mute` flips
    // `muted` without ever touching `volume`, so Audio.onValueChanged never fires and the
    // OSD used to stay hidden through the one state change most worth announcing.
    // Target the audio object indirectly (`?? null`): Bluetooth sinks disconnect and get
    // replaced, and a hard binding would quietly stop delivering after the first swap.
    Connections {
        target: Audio.sink?.audio ?? null
        function onMutedChanged() {
            osdScope.showVolume();
        }
    }

    function showVolume() {
        osdScope.activeType = "volume";
        GlobalStates.osdVolumeOpen = true;
        GlobalStates.osdBrightnessOpen = false;
        osdHideTimer.restart();
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
        readonly property bool isMuted: !isBrightness && (Audio.sink?.audio.muted ?? false)

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
            // A red bezel is the fastest peripheral tell that something is cut.
            border.color: osdPanel.isMuted ? DoorwayPalette.redBright : DoorwayPalette.plasticEdge

            Behavior on border.color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            // Warning wash over the whole faceplate — tints the readout, sits under the
            // scanlines and the row so it reads as backlight, not as a drawn element.
            Rectangle {
                anchors.fill: parent
                color: DoorwayPalette.redBright
                opacity: osdPanel.isMuted ? 0.12 : 0
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

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
                        : (osdPanel.isMuted ? "volume_off"
                            : osdPanel.volumeValue > 0.66 ? "volume_up"
                            : osdPanel.volumeValue > 0.33 ? "volume_down"
                            : "volume_mute")
                    iconSize: 20
                    color: osdPanel.isMuted ? DoorwayPalette.redBright : DoorwayPalette.agedPaper

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                SegmentMeter {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    value: osdPanel.isBrightness
                        ? osdPanel.brightnessValue
                        : Math.min(1.0, osdPanel.volumeValue)
                    // Brightness is a calm gold readout; volume can run "into the red" near max.
                    peakFraction: osdPanel.isBrightness ? 0 : 0.15
                    // Ghosted-not-blank: nudging volume while muted still moves the bar, so the
                    // level you'll come back to stays visible without ever looking live.
                    muted: osdPanel.isMuted
                }

                // Readout column: percentage normally, an inverse-video MUTE tag when cut.
                // Inverse video (red fill, dark glyphs) is unmissable and, unlike a blink,
                // stays legible for the whole two seconds the OSD is up.
                Item {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 18

                    StyledText {
                        anchors.fill: parent
                        visible: !osdPanel.isMuted
                        text: osdPanel.isBrightness
                            ? Math.round(osdPanel.brightnessValue * 100) + "%"
                            : Math.round(osdPanel.volumeValue * 100) + "%"
                        font.family: Appearance.font.family.display  // Departure Mono — pixel readout
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: DoorwayPalette.agedPaper
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: osdPanel.isMuted
                        radius: 1
                        color: DoorwayPalette.redBright
                        border.width: 1
                        border.color: Qt.darker(DoorwayPalette.redBright, 1.4)

                        StyledText {
                            anchors.centerIn: parent
                            // Deliberately not Translation.tr'd: Departure Mono is a Latin-only
                            // pixel font, so a translated tag would render as tofu in the readout.
                            text: "MUTE"
                            font.family: Appearance.font.family.display
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.letterSpacing: 1
                            color: DoorwayPalette.inkBlack
                        }
                    }
                }
            }
        }
    }
}
