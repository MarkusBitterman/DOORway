import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.notes
import qs.modules.ii.sidebarLeft.overview
import qs.modules.ii.sidebarLeft.scratchpads
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property int sidebarPadding: 10

    // Editorial identity lives in the Editorial singleton (ink on the always-light page).
    readonly property var tabs: [
        { name: qsTr("Notes") },
        { name: qsTr("Overview") },
        { name: qsTr("Scratchpads") }
    ]
    property int currentTab: 0

    implicitHeight: bg.implicitHeight
    implicitWidth: bg.implicitWidth

    // Bias the drop shadow toward the bottom-right so the page reads as lifting off the
    // desk on its outer edges (the spine side stays pinned to the bezel).
    StyledRectangularShadow { target: bg; offset: Qt.vector2d(1.5, 2.5) }

    MagazinePaper {
        id: bg
        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: Appearance.sizes.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        radius: 0   // crisp square corners — a bound page, not a rounded Material card

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 18                 // clear the spine gutter
            anchors.rightMargin: 14                // clear the right page-edge lift
            anchors.topMargin: 12
            anchors.bottomMargin: bg.liftSize      // clear the bottom page-edge lift
            spacing: root.sidebarPadding

            // --- Masthead ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                // The Nintendo-Power band — the one spot of colour, tying this magazine
                // to DOORway's own identity rather than a generic cream-and-serif template.
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 3
                    Layout.bottomMargin: 5
                    color: Editorial.folioAccent
                }
                StyledText {
                    text: "DOORWAY"
                    font.family: Editorial.serifFont
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    font.letterSpacing: 4
                    color: Editorial.ink
                }
                StyledText {
                    Layout.bottomMargin: 4
                    text: `The Desk Edition · ${root.tabs[root.currentTab]?.name ?? ""}`
                    font.family: Editorial.serifFont
                    font.italic: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Editorial.inkMuted
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 2; color: Editorial.ink }
                Item { implicitHeight: 2 }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.ink; opacity: 0.45 }
            }

            // --- Editorial section tabs (no Material pills; active = ink underline) ---
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 18

                Repeater {
                    model: root.tabs
                    delegate: MouseArea {
                        id: tab
                        required property int index
                        required property var modelData
                        readonly property bool active: root.currentTab === index
                        implicitWidth: tabCol.implicitWidth
                        implicitHeight: tabCol.implicitHeight
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = tab.index

                        ColumnLayout {
                            id: tabCol
                            spacing: 3
                            StyledText {
                                text: tab.modelData.name
                                font.family: Editorial.serifFont
                                font.capitalization: Font.SmallCaps
                                font.letterSpacing: 1.5
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: tab.active ? Font.Bold : Font.Normal
                                color: tab.active ? Editorial.ink : Editorial.inkMuted
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 2
                                color: Editorial.ink
                                opacity: tab.active ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true } // push tabs left, magazine-style
            }

            // --- Article well: content typeset directly on the page (no card) ---
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentTab

                Notes {}
                Overview {}
                Scratchpads {}
            }

            // --- Bottom folio ---
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "DOORway"
                    font.family: Editorial.serifFont
                    font.italic: true
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Editorial.inkMuted
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `№ ${root.currentTab + 1} / ${root.tabs.length}`
                    font.family: Editorial.serifFont
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Editorial.inkMuted
                }
            }
        }
    }

    // Persist the active tab, clamped in case a stored index predates dropping Tasks.
    Component.onCompleted: {
        if (Persistent.ready)
            root.currentTab = Math.min(Persistent.states.sidebar.leftTab ?? 0, root.tabs.length - 1);
    }
    onCurrentTabChanged: {
        if (Persistent.ready)
            Persistent.states.sidebar.leftTab = root.currentTab;
    }
}
