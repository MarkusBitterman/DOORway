import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.notes
import qs.modules.ii.sidebarLeft.overview
import qs.modules.ii.sidebarLeft.scratchpads
import qs.modules.ii.sidebarRight.todo
import qs.modules.ii.sidebarRight.pomodoro
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property int sidebarPadding: 10
    // Editorial identity — always dark ink on the bright page (not theme-driven).
    readonly property string serifFont: "Georgia"
    readonly property color ink: "#2A2018"
    readonly property color inkMuted: "#6B5A48"

    implicitHeight: bg.implicitHeight
    implicitWidth: bg.implicitWidth

    StyledRectangularShadow { target: bg }

    MagazinePaper {
        id: bg
        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: Appearance.sizes.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            anchors {
                fill: parent
                margins: sidebarPadding
            }
            spacing: sidebarPadding

            // --- Masthead ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 0

                StyledText {
                    text: "DOORWAY"
                    font.family: root.serifFont
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    font.letterSpacing: 4
                    color: root.ink
                }
                StyledText {
                    Layout.bottomMargin: 4
                    text: `The Desk Edition · ${tabBar.tabButtonList[tabBar.currentIndex]?.name ?? ""}`
                    font.family: root.serifFont
                    font.italic: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.inkMuted
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 2; color: root.ink }
                Item { implicitHeight: 2 }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.ink; opacity: 0.45 }
            }

            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: [
                    { name: qsTr("Notes"),       icon: "edit_note" },
                    { name: qsTr("Overview"),    icon: "grid_view" },
                    { name: qsTr("Tasks"),       icon: "checklist" },
                    { name: qsTr("Scratchpads"), icon: "layers" }
                ]
                Component.onCompleted: {
                    if (Persistent.ready)
                        setCurrentIndex(Persistent.states.sidebar.leftTab ?? 0);
                }
                onCurrentIndexChanged: {
                    if (Persistent.ready)
                        Persistent.states.sidebar.leftTab = currentIndex;
                }
            }

            // Article well — a themed inset so the (theme-coloured) content stays readable
            // on the bright page. Reads like a column block pasted onto the magazine spread.
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: root.inkMuted

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    currentIndex: tabBar.currentIndex

                    Notes {}

                    Overview {}

                    // Tasks tab — shares state with the right sidebar's todo/pomodoro widgets
                    ColumnLayout {
                        spacing: sidebarPadding
                        TodoWidget   { Layout.fillWidth: true }
                        PomodoroWidget {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Scratchpads {}
                }
            }

            // Clear the booklet crest at the very bottom.
            Item { Layout.fillWidth: true; implicitHeight: bg.crestHeight - sidebarPadding + 2 }
        }
    }
}
