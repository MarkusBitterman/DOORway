import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * "The Almanac" — today's conditions plus the weekly forecast, sun times and UV.
 * All from the Weather service; the weekly `daily` array is emitted by
 * doorway-pirateweather.py (arrives on the next weather refresh after deploy).
 */
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    readonly property var w: Weather.data

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        EditorialSectionHead {
            title: qsTr("The Almanac")
            buttonSymbol: "refresh"
            buttonTooltip: qsTr("Refresh weather")
            onButtonClicked: Weather.getData()
        }

        ScrollView {
            id: almScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: EditorialScrollBar {}

            ColumnLayout {
                width: almScroll.availableWidth
                spacing: 8

                // Today's headline
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 12
                    StyledText {
                        text: root.w.icon || "cloud"
                        font.family: Appearance.font.family.iconMaterial
                        font.pixelSize: 54
                        color: Editorial.ink
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: root.w.temp || "--°"
                            font.family: Editorial.serifFont
                            font.weight: Font.Bold
                            font.pixelSize: 40
                            color: Editorial.ink
                        }
                        StyledText {
                            text: root.w.city || qsTr("Weather")
                            font.family: Editorial.serifFont
                            font.italic: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Editorial.inkMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: (root.w.summary || "").length > 0
                    text: root.w.summary || ""
                    font.family: Editorial.bodyFont
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Editorial.ink
                    wrapMode: Text.WordWrap
                }

                // Conditions grid
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 3
                    Repeater {
                        model: [
                            { k: qsTr("Feels like"), v: root.w.tempFeelsLike || "--°" },
                            { k: qsTr("Humidity"),   v: root.w.humidity || "--" },
                            { k: qsTr("Wind"),       v: (root.w.wind || "--") + " " + (root.w.windDir || "") },
                            { k: qsTr("UV index"),   v: root.w.uv || "--" },
                            { k: qsTr("Sunrise"),    v: root.w.sunrise || "--" },
                            { k: qsTr("Sunset"),     v: root.w.sunset || "--" },
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 6
                            StyledText {
                                text: modelData.k
                                font.family: Editorial.serifFont
                                font.capitalization: Font.SmallCaps
                                font.letterSpacing: 1
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Editorial.inkMuted
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: modelData.v
                                font.family: Editorial.bodyFont
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Editorial.ink
                            }
                        }
                    }
                }

                // Weekly forecast
                StyledText {
                    Layout.topMargin: 4
                    text: qsTr("The Week Ahead")
                    font.family: Editorial.serifFont
                    font.capitalization: Font.SmallCaps
                    font.letterSpacing: 1
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Editorial.ink
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }

                Repeater {
                    model: root.w.daily || []
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            text: modelData.day
                            font.family: Editorial.serifFont
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Editorial.ink
                            Layout.preferredWidth: 42
                        }
                        StyledText {
                            text: modelData.icon || "cloud"
                            font.family: Appearance.font.family.iconMaterial
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Editorial.inkMuted
                            Layout.preferredWidth: 26
                        }
                        StyledText {
                            text: (modelData.precip && modelData.precip !== "0%") ? modelData.precip : ""
                            font.family: Editorial.bodyFont
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Editorial.inkMuted
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: (modelData.low || "--°") + " – " + (modelData.high || "--°")
                            font.family: Editorial.bodyFont
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Editorial.ink
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: (root.w.daily?.length ?? 0) === 0
                    text: qsTr("Forecast arrives with the next weather refresh.")
                    font.family: Editorial.serifFont
                    font.italic: true
                    color: Editorial.inkMuted
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
