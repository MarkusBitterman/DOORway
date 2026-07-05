import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) HyprlandData.updateWindowList();
        }
    }

    readonly property var scratchWindows: HyprlandData.windowList.filter(
        w => w.workspace?.name?.startsWith("special:")
    )

    function wsName(full) {
        return full?.startsWith("special:") ? full.slice(8) : full ?? "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // --- Section head ---
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: qsTr("Scratchpads")
                font.family: Editorial.serifFont
                font.capitalization: Font.SmallCaps
                font.letterSpacing: 1
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Editorial.ink
                Layout.fillWidth: true
            }
            EditorialIconButton {
                symbol: "move_down"
                tooltip: qsTr("Move focused window to special:main")
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "movetoworkspacesilent", "special:main"])
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }

        FadeLoader {
            shown: root.scratchWindows.length === 0
            Layout.fillWidth: true
            sourceComponent: StyledText {
                text: qsTr("No scratchpad windows")
                font.family: Editorial.serifFont
                font.italic: true
                color: Editorial.inkMuted
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: EditorialScrollBar {}

            ListView {
                id: scratchList
                model: root.scratchWindows

                delegate: Item {
                    required property var modelData
                    width: scratchList.width
                    height: 46

                    Rectangle {
                        anchors.fill: parent
                        color: rowMa.containsMouse ? Editorial.tint : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 3
                        anchors.rightMargin: 3
                        spacing: 10

                        Rectangle { // ink bullet
                            implicitWidth: 7; implicitHeight: 7
                            color: Editorial.ink
                            Layout.alignment: Qt.AlignVCenter
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            StyledText {
                                text: modelData.title ?? ""
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Editorial.ink
                            }
                            StyledText {
                                text: "special · " + root.wsName(modelData.workspace?.name)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.family: Editorial.bodyFont
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Editorial.inkMuted
                            }
                        }
                    }

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1
                        color: Editorial.rule
                        opacity: 0.55
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                            "togglespecialworkspace",
                            root.wsName(modelData.workspace?.name)])
                    }
                }
            }
        }
    }
}
