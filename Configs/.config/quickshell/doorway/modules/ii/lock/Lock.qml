import QtQuick
import Quickshell

/**
 * DOORway Lock surface root. The real WlSessionLock binding lands in Phase 5;
 * until then this hosts only the dev harness — a normal floating window with
 * the same component stack, so visuals and PAM iterate with zero lockout risk.
 */
Scope {
    Loader {
        active: Quickshell.env("DOORWAY_LOCK_TEST") === "1"
        sourceComponent: LockTestHarness {}
    }
}
