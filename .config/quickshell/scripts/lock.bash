#!/usr/bin/env bash
#
# Locks the session with the quickshell lock screen in ../lock.qml. Run by the
# power menu's Lock tile, and usable by hand or from a Hyprland keybind:
#
#     ./lock.bash              # lock the session
#     ./lock.bash --preview    # draw the lock screen in an ordinary window
#
# Use --preview the first time, and after any change to the PAM configuration.
# It runs the real password check without registering a session lock, so a
# stack that rejects every password costs you a window to close rather than the
# only way back into your session.
#
# If a lock ever does get stuck: switch to a text console with Ctrl+Alt+F2, log
# in, and run `loginctl unlock-session` followed by `pkill -f lock.qml`.
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
LOCK_QML="$(dirname -- "$SCRIPT_DIR")/lock.qml"

[[ -f $LOCK_QML ]] || { echo "lock: no lock.qml at $LOCK_QML" >&2; exit 1; }

case "${1:-}" in
    --preview)
        export QS_LOCK_PREVIEW=1
        ;;
    "")
        # Already locked, so a second one would sit uselessly on top of the
        # first. Hyprland would refuse it anyway; this makes the reason clear.
        if pgrep -f "qs.*${LOCK_QML}" >/dev/null 2>&1; then
            echo "lock: already locked" >&2
            exit 0
        fi

        # Hyprland refuses a second session lock while one is already
        # registered, which is the right default right up until the process
        # holding it dies without unlocking --- at which point the screen stays
        # blank with no way back in. Allowing a restore means running this
        # script again replaces the stale lock instead of doing nothing: the
        # difference between a recoverable session and a reboot.
        #
        # Set here rather than from lock.qml because it has to be true *before*
        # the lock is registered, and by the time QML is running it already is.
        hyprctl keyword misc:allow_session_lock_restore 1 >/dev/null 2>&1 || true
        ;;
    *)
        echo "usage: ${0##*/} [--preview]" >&2
        exit 2
        ;;
esac

exec qs -p "$LOCK_QML"
