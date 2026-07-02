import QtQuick
import Quickshell
import QtQuick.Effects

Item {
    id: root

    property bool colorize: false
    property color color
    property string source: ""
    property string iconFolder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))
    width: 30
    height: 30

    // Expose load state so callers can hide when no icon resolves
    property bool valid: iconImage.status === Image.Ready

    property string _localSvg: iconFolder + "/" + source + ".svg"
    property string _localPng: iconFolder + "/" + source + ".png"
    // iconPath's string-fallback overload treats the fallback as a theme icon NAME
    // (QIcon::fromTheme), so a file URL can't go there — check=true returns "" when
    // the icon is absent from the theme, letting us fall back to the local file.
    property string _primarySource: source !== "" ? (Quickshell.iconPath(source, true) || _localSvg) : ""
    property bool _svgFailed: false

    // Reset fallback state when the requested icon name changes
    onSourceChanged: _svgFailed = false

    Image {
        id: iconImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        // XDG theme → local SVG → local PNG
        source: root._svgFailed ? root._localPng : root._primarySource
        // opacity:0 + layer.enabled keeps the item in the scene graph with a committed
        // offscreen texture so MultiEffect can render from it. visible:false removes it
        // from the scene graph entirely, and opacity:0 alone lets the optimizer skip it.
        opacity: root.colorize ? 0 : 1
        layer.enabled: root.colorize

        onStatusChanged: {
            if (status === Image.Error && !root._svgFailed)
                root._svgFailed = true
        }
    }

    MultiEffect {
        anchors.fill: iconImage
        visible: root.colorize
        source: iconImage
        colorization: 1.0
        colorizationColor: root.color
    }
}
