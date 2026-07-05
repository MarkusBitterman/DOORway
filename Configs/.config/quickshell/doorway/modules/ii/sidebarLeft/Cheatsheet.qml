import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * "The Index" — a reference column of Hyprland keybindings. hyprctl binds descriptions
 * are formatted "[Category] action"; the shared HyprlandKeybinds service groups by ":"
 * (which never matches), so we parse the bracketed category and decode modmask ourselves.
 */
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    function modsOf(mask) {
        var m = [];
        if (mask & 64) m.push("Super");
        if (mask & 4)  m.push("Ctrl");
        if (mask & 8)  m.push("Alt");
        if (mask & 1)  m.push("Shift");
        return m;
    }
    function comboOf(b) {
        var k = (b.key && b.key.length) ? b.key : (b.keycode ? "code " + b.keycode : "?");
        return root.modsOf(b.modmask).concat([k]).join(" + ");
    }

    // Group by [Category], dedupe identical combo+action.
    readonly property var groups: {
        var out = [], byCat = ({}), seen = ({});
        var binds = HyprlandKeybinds.keybinds || [];
        for (var i = 0; i < binds.length; i++) {
            var b = binds[i];
            var d = b.description || "";
            var mm = d.match(/^\s*\[(.+?)\]\s*(.*)$/);
            var cat = mm ? mm[1] : qsTr("Other");
            var act = mm ? mm[2] : d;
            if (!act) continue;
            var combo = root.comboOf(b);
            var key = cat + "|" + combo + "|" + act;
            if (seen[key]) continue;
            seen[key] = true;
            if (!byCat[cat]) { byCat[cat] = []; out.push({ name: cat, binds: byCat[cat] }); }
            byCat[cat].push({ combo: combo, act: act });
        }
        return out;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        EditorialSectionHead { title: qsTr("The Index") }

        ScrollView {
            id: idxScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: EditorialScrollBar {}

            ColumnLayout {
                width: idxScroll.availableWidth
                spacing: 10

                Repeater {
                    model: root.groups
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: modelData.name.replace(/\s*\|\s*/g, " · ")
                            font.family: Editorial.serifFont
                            font.capitalization: Font.SmallCaps
                            font.letterSpacing: 1
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Editorial.ink
                        }
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule; opacity: 0.6 }

                        Repeater {
                            model: modelData.binds
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 8
                                StyledText {
                                    text: modelData.combo
                                    font.family: Editorial.monoFont
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Editorial.ink
                                    Layout.preferredWidth: 128
                                }
                                StyledText {
                                    text: modelData.act
                                    font.family: Editorial.bodyFont
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Editorial.inkMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
