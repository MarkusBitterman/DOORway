import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * "Clippings" — recent clipboard entries (Cliphist). Click a clipping to copy it back.
 * Entries arrive as "<id>\t<preview>"; we show the preview and copy the raw entry.
 */
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Component.onCompleted: Cliphist.refresh()
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() { if (GlobalStates.sidebarLeftOpen) Cliphist.refresh(); }
    }

    function preview(entry) {
        const t = entry.indexOf("\t");
        return t >= 0 ? entry.slice(t + 1) : entry;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        EditorialSectionHead {
            title: qsTr("Clippings")
            buttonSymbol: "refresh"
            buttonTooltip: qsTr("Refresh")
            onButtonClicked: Cliphist.refresh()
        }

        FadeLoader {
            shown: (Cliphist.entries?.length ?? 0) === 0
            Layout.fillWidth: true
            sourceComponent: StyledText {
                text: qsTr("Clipboard is empty")
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
                id: clipList
                model: Cliphist.entries
                spacing: 0

                delegate: Item {
                    required property var modelData
                    width: clipList.width
                    height: Math.min(rowText.implicitHeight + 14, 68)

                    Rectangle {
                        anchors.fill: parent
                        color: clipMa.containsMouse ? Editorial.tint : "transparent"
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 3
                        anchors.rightMargin: 3
                        spacing: 10
                        Rectangle {
                            implicitWidth: 7; implicitHeight: 7
                            color: Editorial.ink
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 7
                        }
                        StyledText {
                            id: rowText
                            text: Cliphist.entryIsImage(modelData) ? qsTr("[ image ]") : root.preview(modelData)
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            font.family: Editorial.bodyFont
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Editorial.ink
                            maximumLineCount: 3
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1
                        color: Editorial.rule
                        opacity: 0.5
                    }
                    MouseArea {
                        id: clipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Cliphist.copy(modelData);
                            GlobalStates.sidebarLeftOpen = false;
                        }
                    }
                }
            }
        }
    }
}
