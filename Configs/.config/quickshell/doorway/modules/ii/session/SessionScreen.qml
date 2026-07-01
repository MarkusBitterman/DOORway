import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    // Session action button: circular ripple button + label below.
    component SessionButton: ColumnLayout {
        id: btn
        required property string icon
        required property string label
        required property var action
        property bool destructive: false
        spacing: 10

        RippleButton {
            id: rippleBtn
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 80
            implicitHeight: 80
            rippleEnabled: false  // mechanical console key, not Material ripple
            buttonRadius: Appearance.rounding.verysmall  // squared keypad button
            buttonRadiusPressed: Math.max(3, Appearance.rounding.verysmall - 3)
            // Raised plastic keys; destructive actions glow red.
            colBackground: btn.destructive
                ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.82)
                : DoorwayPalette.plasticShellTop
            colBackgroundHover: btn.destructive
                ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.68)
                : Qt.lighter(DoorwayPalette.plasticShellTop, 1.18)
            onClicked: {
                GlobalStates.sessionOpen = false;
                btn.action();
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: btn.icon
                iconSize: 36
                color: btn.destructive ? DoorwayPalette.redBright : DoorwayPalette.agedPaper
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: btn.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: DoorwayPalette.agedPaper
            opacity: 0.85
        }
    }

    IpcHandler {
        target: "sessionScreen"
        function open():  void { GlobalStates.sessionOpen = true; }
        function close(): void { GlobalStates.sessionOpen = false; }
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen; }
    }

    PanelWindow {
        id: sessionWindow
        visible: GlobalStates.sessionOpen
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        // Scrim background — clicking it closes the screen.
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: sessionWindow.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.sessionOpen = false
            }

            Keys.onEscapePressed: GlobalStates.sessionOpen = false

            // Floating card centered on screen.
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: buttonsGrid.implicitWidth + 80
                height: buttonsGrid.implicitHeight + 80
                radius: Appearance.rounding.normal
                // Cartridge faceplate housing the session keypad.
                gradient: Gradient {
                    GradientStop { position: 0.0; color: DoorwayPalette.plasticShellTop }
                    GradientStop { position: 1.0; color: DoorwayPalette.plasticShellBottom }
                }
                border.width: 1
                border.color: DoorwayPalette.plasticEdge

                // Bevel: lit top, shadowed bottom.
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
                    height: 2
                    color: DoorwayPalette.bevelHighlight
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 3 }
                    height: 2
                    color: DoorwayPalette.bevelShadow
                }

                MouseArea {
                    anchors.fill: parent
                    // Absorb clicks so scrim MouseArea doesn't close the window.
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 28

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Session")
                        font {
                            pixelSize: Appearance.font.pixelSize.huge
                            family: Appearance.font.family.display  // Departure Mono — cartridge label
                        }
                        color: DoorwayPalette.agedPaper
                        opacity: 0.9
                    }

                    GridLayout {
                        id: buttonsGrid
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3
                        rowSpacing: 20
                        columnSpacing: 24

                        SessionButton {
                            icon: "lock"
                            label: qsTr("Lock")
                            action: Session.lock
                        }
                        SessionButton {
                            icon: "bedtime"
                            label: qsTr("Suspend")
                            action: Session.suspend
                        }
                        SessionButton {
                            icon: "downloading"
                            label: qsTr("Hibernate")
                            action: Session.hibernate
                        }
                        SessionButton {
                            icon: "logout"
                            label: qsTr("Logout")
                            action: Session.logout
                            destructive: true
                        }
                        SessionButton {
                            icon: "restart_alt"
                            label: qsTr("Reboot")
                            action: Session.reboot
                            destructive: true
                        }
                        SessionButton {
                            icon: "power_settings_new"
                            label: qsTr("Shutdown")
                            action: Session.poweroff
                            destructive: true
                        }
                    }
                }
            }
        }
    }
}
