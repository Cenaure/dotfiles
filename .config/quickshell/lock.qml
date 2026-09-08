import QtQuick

import Quickshell
import Quickshell.Wayland

import "modules/lock"

// The lock screen. A second quickshell root alongside shell.qml, run as its own
// process rather than living in the bar's:
//
//     ~/.config/quickshell/scripts/lock.bash
//
// It sits in this directory rather than off on its own so that `qs.services`
// and `qs.configurations` resolve exactly as they do for the shell --- which is
// the whole point, because it means the lock screen reads the same palette and
// wallpaper the desktop is using and recolours with it.
//
// The compositor keeps this surface up until the process says otherwise, so a
// crash here would leave a session with no way back in. Two things guard that,
// both in lock.bash: `misc:allow_session_lock_restore`, which lets a fresh lock
// take over from a dead one, and the preview mode below, which is how you check
// that authentication actually works before ever locking with it.
ShellRoot {
  id: root

  // Draws the surface in an ordinary window and never touches the compositor's
  // lock, so a broken password check costs you a window to close rather than
  // the session:
  //
  //     ~/.config/quickshell/scripts/lock.bash --preview
  readonly property bool preview: Quickshell.env("QS_LOCK_PREVIEW") === "1"

  property bool locked: true

  Auth {
    id: auth

    onSucceeded: {
      // Tells logind the session is no longer locked, which is what anything
      // else watching the session state --- idle daemons, the login manager ---
      // goes by.
      Quickshell.execDetached(["loginctl", "unlock-session"]);

      if (root.preview) {
        Qt.quit();
        return;
      }

      root.locked = false;
    }
  }

  WlSessionLock {
    id: sessionLock

    locked: root.locked && !root.preview

    // One surface per monitor, made and destroyed by the compositor as screens
    // come and go. They share the one Auth above, so the password is typed once
    // whichever screen you are looking at.
    WlSessionLockSurface {
      color: "black"

      LockSurface {
        anchors.fill: parent
        auth: auth
      }
    }
  }

  // The lock is gone from the compositor's side the moment `locked` goes false,
  // but the process has to outlive that by a frame or the surface is torn down
  // mid-unlock and the screen flickers black on the way out.
  Timer {
    running: !root.locked
    interval: 120
    onTriggered: Qt.quit()
  }

  Loader {
    active: root.preview

    sourceComponent: FloatingWindow {
      title: "Lock screen preview"
      implicitWidth: 1280
      implicitHeight: 720
      color: "black"

      LockSurface {
        anchors.fill: parent
        auth: auth
      }
    }
  }
}
