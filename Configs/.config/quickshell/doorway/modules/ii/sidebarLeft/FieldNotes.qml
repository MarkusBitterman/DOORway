import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * "Field Notes" — the merged scratch page: a markdown text scratchpad on top and a
 * compact list of scratchpad *windows* (special workspaces) below. One place for
 * everything you're keeping to one side.
 */
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string notesDir: {
        const xdg = Quickshell.env("XDG_DATA_HOME");
        const home = Quickshell.env("HOME");
        return (xdg || home + "/.local/share") + "/doorway/notes";
    }
    readonly property string notesFile: root.notesDir + "/scratchpad.md"

    readonly property var scratchWindows: HyprlandData.windowList.filter(
        w => w.workspace?.name?.startsWith("special:"))
    function wsName(full) { return full?.startsWith("special:") ? full.slice(8) : full ?? ""; }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) HyprlandData.updateWindowList();
        }
    }

    FileView {
        id: notesView
        path: Qt.resolvedUrl(root.notesFile)
        onLoaded: editor.text = notesView.text()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["bash", "-c", `mkdir -p '${root.notesDir}'`]);
                notesView.setText("");
            }
        }
        Component.onCompleted: reload()
    }
    Timer { id: saveTimer; interval: 500; onTriggered: notesView.setText(editor.text) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        EditorialSectionHead {
            title: qsTr("Field Notes")
            buttonSymbol: "save"
            buttonTooltip: qsTr("Save timestamped copy")
            onButtonClicked: {
                const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
                Quickshell.execDetached(["bash", "-c",
                    `mkdir -p '${root.notesDir}' && cp '${root.notesFile}' '${root.notesDir}/${ts}.md' 2>/dev/null || true`]);
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: EditorialScrollBar {}
            StyledTextArea {
                id: editor
                width: parent.width
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                placeholderText: qsTr("Write markdown notes here…")
                background: null
                color: Editorial.ink
                selectedTextColor: Editorial.ink
                selectionColor: Qt.rgba(0.42, 0.35, 0.28, 0.30)
                placeholderTextColor: Editorial.inkMuted
                font.family: Editorial.monoFont
                font.pixelSize: Appearance.font.pixelSize.small
                onTextChanged: saveTimer.restart()
            }
        }

        // --- Scratchpad windows ---
        StyledText {
            Layout.topMargin: 2
            text: qsTr("Windows")
            font.family: Editorial.serifFont
            font.capitalization: Font.SmallCaps
            font.letterSpacing: 1
            font.pixelSize: Appearance.font.pixelSize.small
            color: Editorial.ink
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }

        StyledText {
            visible: root.scratchWindows.length === 0
            text: qsTr("No scratchpad windows")
            font.family: Editorial.serifFont
            font.italic: true
            color: Editorial.inkMuted
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        Repeater {
            model: root.scratchWindows
            delegate: MouseArea {
                id: winRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 26
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "togglespecialworkspace", root.wsName(modelData.workspace?.name)])

                Rectangle {
                    anchors.fill: parent
                    color: winRow.containsMouse ? Editorial.tint : "transparent"
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 3
                    anchors.rightMargin: 3
                    spacing: 8
                    Rectangle { implicitWidth: 7; implicitHeight: 7; color: Editorial.ink; Layout.alignment: Qt.AlignVCenter }
                    StyledText {
                        text: winRow.modelData.title ?? ""
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Editorial.ink
                    }
                    StyledText {
                        text: root.wsName(winRow.modelData.workspace?.name)
                        font.family: Editorial.bodyFont
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Editorial.inkMuted
                    }
                }
            }
        }
    }
}
