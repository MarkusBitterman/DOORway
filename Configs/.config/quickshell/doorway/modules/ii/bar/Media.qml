import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        Item {
            id: mediaIconArea
            implicitWidth: 20
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            ClippedFilledCircularProgress {
                id: mediaCircProg
                anchors.fill: parent
                value: (activePlayer?.position ?? 0) / (activePlayer?.length ?? 1)
                implicitSize: 20
                colPrimary: Appearance.colors.colOnSecondaryContainer
                enableAnimation: false

                Rectangle {
                    width: mediaCircProg.implicitSize
                    height: mediaCircProg.implicitSize
                    radius: width / 2
                    color: "white"
                }
            }

            FrameAnimation {
                id: vizAnim
                running: mediaIconArea.visible

                property real t: 0.0
                property real smoothedAmp: 0.0
                property real targetAmp: (activePlayer?.playbackState == MprisPlaybackState.Playing)
                                          ? Math.max(0.35, Audio.value)
                                          : 0.0

                readonly property var freqs:  [1.4, 2.2, 1.8, 2.7]
                readonly property var phases: [0.0, 1.1, 2.4, 0.6]
                property var heights: [0.0, 0.0, 0.0, 0.0]

                onTriggered: {
                    t += elapsedTime
                    var alpha = smoothedAmp < targetAmp ? 0.15 : 0.05
                    smoothedAmp = smoothedAmp * (1 - alpha) + targetAmp * alpha
                    var h = []
                    for (var i = 0; i < 4; i++)
                        h.push(Math.max(0, Math.sin(t * freqs[i] + phases[i])) * smoothedAmp)
                    heights = h
                    spectrumCanvas.requestPaint()
                }
            }

            Canvas {
                id: spectrumCanvas
                anchors.fill: parent
                z: 1

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var barW   = 2
                    var gap    = 1
                    var totalW = 4 * barW + 3 * gap
                    var startX = (width - totalW) / 2
                    var midY   = height / 2
                    var maxH   = height * 0.38
                    var c      = Appearance.colors.colPrimary

                    for (var i = 0; i < 4; i++) {
                        var barH = Math.max(1, vizAnim.heights[i] * maxH * 2)
                        var x    = startX + i * (barW + gap)
                        var y    = midY - barH / 2
                        var grad = ctx.createLinearGradient(x, y, x, y + barH)
                        grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.95))
                        grad.addColorStop(0.5, Qt.rgba(c.r, c.g, c.b, 0.60))
                        grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.15))
                        ctx.fillStyle = grad
                        ctx.fillRect(x, y, barW, barH)
                    }
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                z: 2
                fill: 1
                text: activePlayer?.isPlaying ? "pause" : "music_note"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
                opacity: vizAnim.smoothedAmp < 0.05 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: Appearance.colors.colOnLayer1
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

    }

}
