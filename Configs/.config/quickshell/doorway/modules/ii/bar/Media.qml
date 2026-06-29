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

    // Real spectrum from cava when available; otherwise a volume-driven fallback.
    readonly property bool useCava: Cava.available && Cava.values.length >= Cava.bars
    readonly property int vuSegments: 7
    readonly property color _vuDim: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
    // Per-segment levels (0..1) for the horizontal VU strip — one frequency band each.
    readonly property var vuLevels: {
        const n = root.vuSegments
        const out = new Array(n).fill(0)
        const playing = (root.activePlayer?.playbackState === MprisPlaybackState.Playing)
        if (!playing) return out
        if (root.useCava) {
            const v = Cava.values
            const per = Math.max(1, Math.floor(v.length / n))
            for (let i = 0; i < n; i++) {
                let s = 0
                for (let k = 0; k < per; k++) s += v[i * per + k] || 0
                out[i] = Math.min(1, (s / per) / Cava.maxValue * 1.7)
            }
        } else { // no cava running: a static level meter from volume
            const base = Math.max(0.25, Audio.value)
            for (let i = 0; i < n; i++) out[i] = Math.max(0.05, base - i * 0.06)
        }
        return out
    }

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
            implicitWidth: mediaRow.implicitWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent
                spacing: 4

                // Play / pause glyph — always visible, in the gold accent.
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    fill: 1
                    text: (root.activePlayer?.isPlaying ?? false) ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colPrimary
                }

                // Horizontal segmented VU strip — each LED tracks a frequency band (cava).
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Repeater {
                        model: root.vuSegments
                        delegate: Rectangle {
                            required property int index
                            implicitWidth: 3
                            implicitHeight: 13
                            radius: 1
                            color: ColorUtils.mix(Appearance.colors.colPrimary, root._vuDim,
                                                  Math.min(1, root.vuLevels[index] ?? 0))
                            Behavior on color { ColorAnimation { duration: 90 } }
                        }
                    }
                }
            }

            // Thin retro progress underline (track position).
            Rectangle {
                anchors { left: mediaRow.left; right: mediaRow.right; bottom: parent.bottom }
                height: 2
                radius: 1
                color: root._vuDim
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * Math.min(1, Math.max(0, (root.activePlayer?.position ?? 0) / (root.activePlayer?.length ?? 1)))
                    radius: 1
                    color: Appearance.colors.colPrimary
                }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
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
