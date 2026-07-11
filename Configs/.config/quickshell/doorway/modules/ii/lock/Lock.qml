import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

/**
 * DOORway Lock root: binds the DoorwayLock service's state to the
 * ext-session-lock protocol. WlSessionLock instantiates one LockSurface
 * per screen while locked; on unlock the compositor tears them down.
 * The floating harness (DOORWAY_LOCK_TEST=1) coexists for development.
 */
Scope {
    WlSessionLock {
        id: sessionLock
        locked: DoorwayLock.locked
        surface: LockSurface {}
    }

    Loader {
        active: Quickshell.env("DOORWAY_LOCK_TEST") === "1"
        sourceComponent: LockTestHarness {}
    }
}
