//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// DOORway QuickShell — forked from end-4/dots-hyprland (GPLv3)
// Phase 12: top bar only. Sidebars, OSD, notifications follow in Phases 13-15.

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

ShellRoot {
    id: root

    Component.onCompleted: {
        ThemeMode.load() // eager-load so the theme IPC target + shortcut register
        Hyprsunset.load() // eager-load so the night-light window applies without waiting for UI to touch it
        DoorwayLock.load() // eager-load so the lock IPC target registers before any surface exists
        GameMode.load() // eager-load so `qs ipc call gameMode toggle` resolves before the sidebar is ever opened
        DoorwayCrtShader.load() // same: the documented `qs ipc call crtShader toggle` never registered without this
    }

    // Phase 12: bar only. IllogicalImpulseFamily is bar-only until Phase 13.
    Loader {
        active: Config.ready
        sourceComponent: IllogicalImpulseFamily {}
    }
}
