import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    visible: true // always show the drawer/left-sidebar launcher

    property real buttonPadding: 5
    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        width: 19.5
        height: 19.5
        source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
        // The Atari Fuji is a colored brand mark — show its true red. Monochrome symbolic
        // icons (distro logos, etc.) still get themed to the bar color.
        colorize: Config.options.bar.topLeftIcon !== 'atari'
        color: Appearance.colors.colOnLayer0
    }
}
