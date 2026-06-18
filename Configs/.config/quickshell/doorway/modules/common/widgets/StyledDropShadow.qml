import QtQuick
import QtQuick.Effects
import qs.modules.common

MultiEffect {
    required property var target
    source: target
    anchors.fill: source
    shadowEnabled: true
    shadowBlur: 0.4
    shadowColor: Appearance.colors.colShadow
}
