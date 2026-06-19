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
    property string _primarySource: source !== "" ? Quickshell.iconPath(source, _localSvg) : ""
    property bool _svgFailed: false

    // Reset fallback state when the requested icon name changes
    onSourceChanged: _svgFailed = false

    Image {
        id: iconImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        // XDG theme → local SVG → local PNG
        source: root._svgFailed ? root._localPng : root._primarySource
        // opacity:0 keeps the item in the scene graph so MultiEffect can render from it.
        // visible:false would silently prevent MultiEffect from producing any output.
        opacity: root.colorize ? 0 : 1

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
