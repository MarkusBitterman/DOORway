import QtQuick
import qs.services
import qs.modules.common

/**
 * The unlock prompt, styled as a cartridge label: ink plastic, gold rule,
 * Departure Mono, powerRed on failure. Display-only — keystrokes are routed
 * by the surface into DoorwayLock's shared buffer, so every monitor mirrors.
 * Fades in over the running shader when the state machine enters PROMPT.
 */
Item {
    id: root

    readonly property bool showing: DoorwayLock.state === DoorwayLock.statePrompt
        || DoorwayLock.state === DoorwayLock.stateAuthenticating

    opacity: showing ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 380
        height: col.implicitHeight + 40
        radius: Appearance.rounding.verysmall
        color: DoorwayPalette.inkBlack
        border.width: 2
        border.color: DoorwayLock.authFailed ? DoorwayPalette.powerRed : DoorwayPalette.powerGold

        // failure shake, arcade-cabinet style
        transform: Translate { id: shake; x: 0 }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -12; duration: 40 }
            NumberAnimation { target: shake; property: "x"; to: 10; duration: 40 }
            NumberAnimation { target: shake; property: "x"; to: -6; duration: 40 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 40 }
        }
        Connections {
            target: DoorwayLock
            function onAuthFailedChanged() {
                if (DoorwayLock.authFailed) shakeAnim.restart();
            }
        }

        Column {
            id: col
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 12

            Text {
                text: DoorwayLock.state === DoorwayLock.stateAuthenticating
                    ? "CHECKING…"
                    : (DoorwayLock.authFailed && DoorwayLock.failMessage.length > 0
                        ? DoorwayLock.failMessage : "PASSWORD")
                color: DoorwayLock.authFailed ? DoorwayPalette.powerRed : DoorwayPalette.powerGold
                font.family: Appearance.font.family.display
                font.pixelSize: 14
                font.letterSpacing: 2
            }

            // masked buffer — chunky blocks, one per character
            Rectangle {
                width: parent.width
                height: 42
                radius: 3
                color: Qt.darker(DoorwayPalette.inkBlack, 1.3)
                border.width: 1
                border.color: Qt.alpha(DoorwayPalette.agedPaper, 0.25)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    elide: Text.ElideLeft
                    text: "■".repeat(DoorwayLock.passwordBuffer.length)
                        + (blink.on && DoorwayLock.state === DoorwayLock.statePrompt ? "_" : "")
                    color: DoorwayPalette.agedPaper
                    font.family: Appearance.font.family.display
                    font.pixelSize: 20
                }
            }

            Text {
                text: "ENTER TO UNLOCK · IT'S DANGEROUS TO GO ALONE"
                color: Qt.alpha(DoorwayPalette.agedPaper, 0.45)
                font.family: Appearance.font.family.display
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        }
    }

    Timer {
        id: blink
        property bool on: true
        interval: 530
        repeat: true
        running: root.showing
        onTriggered: on = !on
    }
}
