import QtQuick

import Quickshell
import Quickshell.Services.Pam

import qs.configurations

// The password check behind the lock screen, kept apart from the surface that
// draws it. There is one of these for the whole lock, not one per monitor: the
// typed password and the attempt in flight are properties of the session, not
// of a screen, so plugging in a second display cannot end up with two half
// typed passwords.
Item {
  id: root

  // What has been typed so far. Owned here rather than in the field so that
  // every monitor's field shows the same thing.
  property string password: ""

  // An attempt is with PAM and has not come back. The field goes inert for the
  // duration --- PAM takes a deliberate second or so to reject a wrong
  // password, and letting more typing pile up behind that is confusing.
  readonly property bool busy: pam.active

  // What to say under the field. PAM's own wording when it gives us any, since
  // it is the only thing that knows about expired passwords or lockouts.
  property string message: ""
  property bool failed: false

  signal succeeded
  signal rejected

  function submit() {
    if (root.busy || root.password === "")
      return;

    root.failed = false;
    root.message = "";

    if (!pam.start()) {
      root.failed = true;
      root.message = "Could not start authentication";
      root.rejected();
    }
  }

  function clear() {
    root.password = "";
    root.failed = false;
    root.message = "";
  }

  PamContext {
    id: pam

    config: LockConfig.pamConfig
    // The session's own user. Nothing else can unlock this screen, so there is
    // no account to choose between.
    user: Quickshell.env("USER") || Quickshell.env("LOGNAME")

    // Fires for every prompt and notice PAM emits. A prompt gets the password;
    // anything else is a notice worth showing, which is where "password
    // expired" and faillock's lockout warning arrive.
    onPamMessage: {
      if (pam.responseRequired) {
        pam.respond(root.password);
        return;
      }

      if (pam.message !== "")
        root.message = pam.message;
    }

    onCompleted: result => {
      // Dropped whatever the answer was: a correct password is finished with,
      // and a wrong one should not be sitting in the field to be resubmitted.
      root.password = "";

      if (result === PamResult.Success) {
        root.failed = false;
        root.message = "";
        root.succeeded();
        return;
      }

      root.failed = true;

      // Only when PAM said nothing itself, so its wording always wins.
      if (root.message === "")
        root.message = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";

      root.rejected();
    }

    onError: error => {
      root.password = "";
      root.failed = true;
      root.message = "Authentication error: " + PamError.toString(error);
      root.rejected();
    }
  }
}
