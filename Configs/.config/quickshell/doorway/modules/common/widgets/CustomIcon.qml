import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects

Item {
    id: root
    
    property bool colorize: false
    property color color
    property string source: ""
    property string iconFolder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))  // The folder to check first
    width: 30
    height: 30
    
    IconImage {
        id: iconImage
        anchors.fill: parent
        // Try system icon theme first (Tela etc.), fall back to assets/icons/.
        source: Quickshell.iconPath(root.source, iconFolder + "/" + root.source)
        implicitSize: root.height
    }

    Loader {
        active: root.colorize
        anchors.fill: iconImage
        sourceComponent: MultiEffect {
            anchors.fill: parent
            source: iconImage
            colorization: 1.0
            colorizationColor: root.color
        }
    }
}
