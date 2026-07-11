import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Literary readout — shows a quote whose text contains the current time, with
 * the time phrase itself lit in powerGold (the signature literature-clock
 * effect), over the ENCOM boardroom backdrop. Data from the LiteratureClock
 * service. Collapses to nothing on the rare minute with no quote.
 */
HudPanel {
    id: root
    // ?? false guards the first binding pass, where the lazily-constructed
    // singleton can momentarily read undefined (see quickshell lazy-singleton note).
    visible: LiteratureClock.valid ?? false
    implicitHeight: visible ? layout.implicitHeight + 24 : 0

    // Build rich text with the time phrase emphasized. Each slice is HTML-escaped
    // so quote punctuation (&, <, >) and newlines can't corrupt the markup.
    function esc(s) {
        return String(s)
            .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            .replace(/\n/g, "<br/>");
    }
    readonly property string richQuote: {
        const q = LiteratureClock.quote;
        const t = LiteratureClock.timestring;
        if (!q) return "";
        const idx = t ? q.toLowerCase().indexOf(t.toLowerCase()) : -1;
        if (idx < 0) return esc(q);
        const pre = q.slice(0, idx);
        const mid = q.slice(idx, idx + t.length);
        const post = q.slice(idx + t.length);
        const gold = String(DoorwayPalette.powerGold);
        return esc(pre) + '<b><font color="' + gold + '">' + esc(mid) + '</font></b>' + esc(post);
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // framing header — this is a "readout" on the boardroom screen
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            MaterialSymbol {
                text: "auto_stories"
                iconSize: 15
                color: Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.7)
            }
            StyledText {
                text: Translation.tr("LITERARY CLOCK")
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.5)
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.richQuote
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            maximumLineCount: 6
            elide: Text.ElideRight
            font.family: Appearance.font.family.reading
            font.pixelSize: Appearance.font.pixelSize.small
            color: DoorwayPalette.agedPaper
            lineHeight: 1.15
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: "— " + LiteratureClock.title + ", " + LiteratureClock.author
            wrapMode: Text.WordWrap
            font.family: Appearance.font.family.reading
            font.italic: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Qt.rgba(DoorwayPalette.agedPaper.r, DoorwayPalette.agedPaper.g, DoorwayPalette.agedPaper.b, 0.55)
        }
    }
}
