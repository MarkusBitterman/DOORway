import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: stopwatchTab
    Layout.fillWidth: true
    Layout.fillHeight: true

    Item {
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
        }

        RowLayout { // Elapsed
            id: elapsedIndicator
            
            anchors {
                top: undefined
                verticalCenter: parent.verticalCenter
                left: controlButtons.left
                leftMargin: 6
            }

            states: State {
                name: "hasLaps"
                when: TimerService.stopwatchLaps.length > 0
                AnchorChanges {
                    target: elapsedIndicator
                    anchors.top: parent.top
                    anchors.verticalCenter: undefined
                    anchors.left: controlButtons.left
                }
            }

            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            spacing: 0
            StyledText {
                // Layout.preferredWidth: elapsedIndicator.width * 0.6 // Prevent shakiness
                font.pixelSize: 40
                color: DoorwayPalette.hudText
                text: {
                    let totalSeconds = Math.floor(TimerService.stopwatchTime) / 100
                    let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                    let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                    return `${minutes}:${seconds}`
                }
            }
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: 40
                color: DoorwayPalette.hudTextDim
                text: {
                    return `:<sub>${(Math.floor(TimerService.stopwatchTime) % 100).toString().padStart(2, '0')}</sub>`
                }
            }
        }

        // Laps
        StyledListView {
            id: lapsList
            anchors {
                top: elapsedIndicator.bottom
                bottom: controlButtons.top
                left: parent.left
                right: parent.right
                topMargin: 16
                bottomMargin: 16
            }
            spacing: 4
            clip: true
            popin: true

            model: ScriptModel {
                values: TimerService.stopwatchLaps.map((v, i, arr) => arr[arr.length - 1 - i])
            }

            delegate: Rectangle {
                id: lapItem
                required property int index
                required property var modelData
                property var horizontalPadding: 10
                property var verticalPadding: 6
                width: lapsList.width
                implicitHeight: lapRow.implicitHeight + verticalPadding * 2
                implicitWidth: lapRow.implicitWidth + horizontalPadding * 2
                color: DoorwayPalette.hudCard
                radius: Appearance.rounding.small

                RowLayout {
                    id: lapRow
                    anchors {
                        fill: parent
                        leftMargin: lapItem.horizontalPadding
                        rightMargin: lapItem.horizontalPadding
                        topMargin: lapItem.verticalPadding
                        bottomMargin: lapItem.verticalPadding
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: DoorwayPalette.hudTextDim
                        text: `${TimerService.stopwatchLaps.length - lapItem.index}.`
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: {
                            const lapTime = lapItem.modelData
                            const _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                            const totalSeconds = Math.floor(lapTime) / 100
                            const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                            const seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                            return `${minutes}:${seconds}.${_10ms}`
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: DoorwayPalette.powerGold
                        text: {
                            const originalIndex = TimerService.stopwatchLaps.length - lapItem.index - 1
                            const lastTime = originalIndex > 0 ? TimerService.stopwatchLaps[originalIndex - 1] : 0
                            const lapTime = lapItem.modelData - lastTime
                            const _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                            const totalSeconds = Math.floor(lapTime) / 100
                            const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                            const seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                            return `+${minutes == "00" ? "" : minutes + ":"}${seconds}.${_10ms}`
                        }
                    }
                }
            }
        }

        RowLayout {
            id: controlButtons
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 6
            }
            spacing: 4

            RippleButton {
                Layout.preferredHeight: 35
                Layout.preferredWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger

                onClicked: {
                    TimerService.toggleStopwatch()
                }

                colBackground: TimerService.stopwatchRunning ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.14) : DoorwayPalette.powerGold 
                colBackgroundHover: TimerService.stopwatchRunning ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.20) : Qt.lighter(DoorwayPalette.powerGold, 1.10) 
                colRipple: TimerService.stopwatchRunning ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.26) : Qt.lighter(DoorwayPalette.powerGold, 1.18) 

                contentItem: StyledText {
                    horizontalAlignment: Text.AlignHCenter
                    color: TimerService.stopwatchRunning ? DoorwayPalette.hudText : DoorwayPalette.inkBlack
                    text: TimerService.stopwatchRunning ? Translation.tr("Pause") : TimerService.stopwatchTime === 0 ? Translation.tr("Start") : Translation.tr("Resume")
                }
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger

                onClicked: {
                    if (TimerService.stopwatchRunning) 
                        TimerService.stopwatchRecordLap()
                    else 
                        TimerService.stopwatchReset()
                }
                enabled: TimerService.stopwatchTime > 0 || Persistent.states.timer.stopwatch.laps.length > 0

                colBackground: TimerService.stopwatchRunning ? DoorwayPalette.hudCard : Qt.rgba(DoorwayPalette.redBright.r, DoorwayPalette.redBright.g, DoorwayPalette.redBright.b, 0.18)
                colBackgroundHover: TimerService.stopwatchRunning ? Qt.lighter(DoorwayPalette.hudCard, 1.35) : Qt.rgba(DoorwayPalette.redBright.r, DoorwayPalette.redBright.g, DoorwayPalette.redBright.b, 0.26)
                colRipple: TimerService.stopwatchRunning ? Qt.lighter(DoorwayPalette.hudCard, 1.60) : Qt.rgba(DoorwayPalette.redBright.r, DoorwayPalette.redBright.g, DoorwayPalette.redBright.b, 0.34)

                contentItem: StyledText {
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.stopwatchRunning ? Translation.tr("Lap") : Translation.tr("Reset")
                    color: TimerService.stopwatchRunning ? DoorwayPalette.hudText : DoorwayPalette.redBright
                }
            }
        }
    }
}