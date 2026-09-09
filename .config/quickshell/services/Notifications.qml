pragma Singleton
// The expiry timers below are nested components that reach back to this
// singleton's id, which needs the bound scoping rules to be legal.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification server, and the two views of it the shell draws:
//
//   popups   the few that are on screen right now, newest first, each on its
//            own countdown --- modules/notifications/NotificationPopup
//   history  everything still being kept, newest first --- NotificationCenter
//
// A notification stays alive for exactly as long as it is `tracked`. Dropping
// out of the popup list only takes it off the screen; it is dismiss() that
// actually ends it and takes it out of the history too.
Singleton {
  id: root

  // ------------------------------------------------------------- behaviour --

  // Used when the sender does not ask for a particular timeout, which most of
  // them do not.
  property int defaultTimeout: 5000
  property int lowTimeout: 3000
  // Critical notifications are the ones you must not miss, so they stay up
  // until they are clicked away.
  property bool criticalNeverExpires: true

  // Popups past this stay in the history but never reach the screen, so a burst
  // cannot paper over the desktop.
  property int maxPopups: 4
  // Oldest beyond this are dropped as new ones arrive.
  property int historyLimit: 50

  // ------------------------------------------------------------------ server --

  NotificationServer {
    id: server

    // Notifications do not survive a shell reload; the senders are still there
    // and anything that still matters will be sent again.
    keepOnReload: false

    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: notification => {
      // Nothing exists until this is set: an untracked notification is closed
      // and destroyed the moment this handler returns.
      notification.tracked = true;

      root.arrivals[notification.id] = Date.now();
      root.now = Date.now();

      // Do not disturb silences the screen, not the record: everything still
      // lands in the centre to be read later.
      if (!root.doNotDisturb)
        root.showPopup(notification.id);

      root.trimHistory();
    }
  }

  // ------------------------------------------------------------------ views --

  // Newest first, which is the order both views want and the opposite of the
  // order the server appends in.
  readonly property var history: {
    const tracked = server.trackedNotifications?.values ?? [];

    return tracked.slice().reverse();
  }

  readonly property int count: root.history.length

  // Which of the tracked notifications are currently on screen. Held as ids
  // rather than as objects so that a notification closing anywhere --- by the
  // sender, by a click, by the centre --- takes it out of here for free.
  property var popupIds: []

  readonly property var popups: {
    const ids = root.popupIds;

    return root.history.filter(notification => ids.includes(notification.id)).slice(0, root.maxPopups);
  }

  function showPopup(id: int) {
    if (root.popupIds.includes(id))
      return;

    root.popupIds = root.popupIds.concat([id]);
  }

  // Takes it off the screen and leaves it in the history. This is what an
  // expiring countdown does; it is not the same as closing the notification.
  function hidePopup(id: int) {
    root.popupIds = root.popupIds.filter(value => value !== id);
  }

  function dismissAllPopups() {
    root.popupIds = [];
  }

  // While the pointer is over the stack the countdowns hold, so a notification
  // cannot expire out from under a click aimed at one of its actions.
  property bool popupsPaused: false

  // --------------------------------------------------------------- countdown --

  // One timer per popup, created and destroyed with it.
  Instantiator {
    model: root.popups

    delegate: Timer {
      id: countdown

      required property var modelData

      readonly property int timeout: root.timeoutFor(countdown.modelData)

      // A zero timeout means this one waits for you.
      running: countdown.timeout > 0 && !root.popupsPaused
      interval: countdown.timeout
      repeat: false

      onTriggered: root.popupExpired(countdown.modelData)
    }
  }

  // Milliseconds this notification should stay on screen, or 0 to stay until
  // dismissed. The sender's own request wins where it made one: expireTimeout
  // is in seconds, with -1 meaning "you decide" and 0 meaning "never".
  function timeoutFor(notification): int {
    if (!notification)
      return 0;

    if (root.criticalNeverExpires && notification.urgency === NotificationUrgency.Critical)
      return 0;

    const requested = notification.expireTimeout;

    if (requested === 0)
      return 0;

    if (requested > 0)
      return Math.round(requested * 1000);

    return notification.urgency === NotificationUrgency.Low ? root.lowTimeout : root.defaultTimeout;
  }

  function popupExpired(notification) {
    if (!notification)
      return;

    root.hidePopup(notification.id);

    // Transient notifications are the ones that are only worth saying once ---
    // volume steps, track changes --- so they leave nothing behind.
    if (notification.transient)
      notification.expire();
  }

  // ----------------------------------------------------------------- actions --

  // Ends the notification: off the screen and out of the history.
  function dismiss(notification) {
    if (!notification)
      return;

    root.hidePopup(notification.id);
    notification.dismiss();
  }

  function clearAll() {
    // Copied first: dismissing walks the model out from under the loop.
    for (const notification of root.history.slice())
      notification.dismiss();

    root.dismissAllPopups();
  }

  // Runs one of the buttons the sender offered. Unless it asked to stay
  // resident, acting on a notification is done with it.
  function invoke(notification, action) {
    if (!notification || !action)
      return;

    action.invoke();

    if (!notification.resident)
      root.dismiss(notification);
  }

  function trimHistory() {
    const tracked = server.trackedNotifications?.values ?? [];

    // Oldest first here, so the front of the list is what goes.
    for (let i = 0; i < tracked.length - root.historyLimit; i++)
      tracked[i].dismiss();
  }

  // ---------------------------------------------------------------- arrivals --

  // id -> epoch milliseconds. Notifications carry no timestamp of their own, so
  // the only record of when one landed is the one kept here.
  property var arrivals: ({})

  // Everything relative in the centre is written against this rather than
  // against the clock directly, so the ages all re-render together on a tick
  // instead of each one needing its own timer.
  property double now: Date.now()

  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: root.now = Date.now()
  }

  function ageOf(notification): string {
    if (!notification)
      return "";

    const arrived = root.arrivals[notification.id];

    if (!arrived)
      return "";

    const seconds = Math.max(0, Math.round((root.now - arrived) / 1000));

    if (seconds < 60)
      return "now";

    const minutes = Math.floor(seconds / 60);

    if (minutes < 60)
      return `${minutes}m`;

    const hours = Math.floor(minutes / 60);

    if (hours < 24)
      return `${hours}h`;

    return `${Math.floor(hours / 24)}d`;
  }

  // ------------------------------------------------------------------- state --

  readonly property bool doNotDisturb: state.adapter.doNotDisturb

  function setDoNotDisturb(value: bool) {
    state.adapter.doNotDisturb = value;
    state.writeAdapter();

    // Whatever is already on screen goes with it, rather than sitting there
    // until it happens to time out.
    if (value)
      root.dismissAllPopups();
  }

  function toggleDoNotDisturb() {
    root.setDoNotDisturb(!root.doNotDisturb);
  }

  FileView {
    id: state

    path: Qt.resolvedUrl("../state/notifications.state.json")
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      property bool doNotDisturb: false
    }
  }
}
