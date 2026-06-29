// The media controls card: album art (+ blurred ambient backdrop), title/artist, a large
// live spectrum (WaveVisualizer fed by the real cava service), a seekable scrubber, and
// transport. Wrapped in the cyberpunk NeonGlow for visual cohesion with the bar.
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

Item {
    id: root
    anchors.fill: parent

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property string title: StringUtils.cleanMusicTitle(player?.trackTitle) || Translation.tr("No media")
    readonly property string artist: player?.trackArtist ?? ""
    readonly property real progress: (player?.length ?? 0) > 0 ? (player.position / player.length) : 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        const m = Math.floor(s / 60);
        const ss = s % 60;
        return m + ":" + (ss < 10 ? "0" + ss : ss);
    }

    // Refresh the displayed position once a second while playing (Mpris position is polled).
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    // A flat hover-highlight transport button.
    component TransportButton: Rectangle {
        id: tb
        property string icon
        property real diameter: 32
        property real glyphSize: Appearance.font.pixelSize.larger
        signal activated()
        implicitWidth: diameter
        implicitHeight: diameter
        radius: diameter / 2
        color: tbMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: tb.icon
            iconSize: tb.glyphSize
            fill: 1
            color: Appearance.colors.colOnLayer1
        }
        MouseArea {
            id: tbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.activated()
        }
    }

    StyledRectangularShadow { target: card }
    Loader {
        active: Config.options.bar.glow?.enable ?? false
        anchors.fill: card
        sourceComponent: NeonGlow {
            anchors.fill: undefined
            target: card
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: (Config.options.bar.glow?.enable ?? false)
            ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
        clip: true

        // Ambient blurred album-art backdrop.
        Image {
            id: backdrop
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: status === Image.Ready
            opacity: 0.22
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 64
                blur: 1
                saturation: 0.3
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Album art (rounded), with a music-note fallback.
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 132
                implicitHeight: 132

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2
                    visible: !art.visible
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: 56
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: (root.player?.trackArtUrl ?? "") !== "" && status === Image.Ready
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: Rectangle {
                            width: art.width
                            height: art.height
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            // Metadata + visualizer + scrubber + transport.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.artist.length > 0
                    text: root.artist
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                // Live spectrum — finally puts WaveVisualizer to work, fed by real cava data.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 28
                    clip: true
                    WaveVisualizer {
                        anchors.fill: parent
                        points: Cava.values
                        maxVisualizerValue: Cava.maxValue
                        live: root.player?.isPlaying ?? false
                        color: Appearance.colors.colPrimary
                        smoothing: 2
                    }
                }

                // Scrubber.
                Rectangle {
                    id: scrubTrack
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Appearance.colors.colLayer2
                    Rectangle {
                        height: parent.height
                        radius: 2
                        width: parent.width * Math.min(1, Math.max(0, root.progress))
                        color: Appearance.colors.colPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player?.canSeek ?? false
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => {
                            if (root.player && root.player.length > 0) {
                                root.player.position = (mouse.x / width) * root.player.length;
                                root.player.positionChanged();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: root.fmt(root.player?.position ?? 0)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: root.fmt(root.player?.length ?? 0)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                // Transport.
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    TransportButton {
                        icon: "skip_previous"
                        enabled: MprisController.canGoPrevious
                        opacity: enabled ? 1 : 0.4
                        onActivated: MprisController.previous()
                    }
                    Rectangle { // play / pause — accented
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 20
                        color: Appearance.colors.colPrimary
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                            iconSize: 24
                            fill: 1
                            color: Appearance.m3colors.m3onPrimary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.togglePlaying()
                        }
                    }
                    TransportButton {
                        icon: "skip_next"
                        enabled: MprisController.canGoNext
                        opacity: enabled ? 1 : 0.4
                        onActivated: MprisController.next()
                    }
                }
            }
        }
    }
}
