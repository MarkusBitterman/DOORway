import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A magazine section header — small-caps serif title over a hairline rule, with an
 * optional trailing ink glyph button. The shared masthead for every left-sidebar page.
 */
ColumnLayout {
    id: root
    property string title: ""
    property string buttonSymbol: ""
    property string buttonTooltip: ""
    signal buttonClicked()

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        StyledText {
            text: root.title
            font.family: Editorial.serifFont
            font.capitalization: Font.SmallCaps
            font.letterSpacing: 1
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Editorial.ink
            Layout.fillWidth: true
        }
        EditorialIconButton {
            visible: root.buttonSymbol.length > 0
            symbol: root.buttonSymbol
            tooltip: root.buttonTooltip
            onClicked: root.buttonClicked()
        }
    }
    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Editorial.rule }
}
