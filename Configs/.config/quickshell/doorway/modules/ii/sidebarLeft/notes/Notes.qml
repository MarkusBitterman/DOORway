import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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

    // Debounce writes — flush 500ms after the user stops typing.
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: notesView.setText(editor.text)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // --- Section head ---
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: qsTr("Notes")
                font.family: Editorial.serifFont
                font.capitalization: Font.SmallCaps
                font.letterSpacing: 1
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Editorial.ink
                Layout.fillWidth: true
            }
            EditorialIconButton {
                symbol: "save"
                tooltip: qsTr("Save timestamped copy")
                onClicked: {
                    const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
                    Quickshell.execDetached(["bash", "-c",
                        `mkdir -p '${root.notesDir}' && cp '${root.notesFile}' '${root.notesDir}/${ts}.md' 2>/dev/null || true`
                    ]);
                }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: EditorialScrollBar {}

            // Typed manuscript — mono ink straight on the page (paper shows through).
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
    }
}
