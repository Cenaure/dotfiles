pragma Singleton
// The per-player watchers below are nested components that reach back to this
// singleton's id, which needs the bound scoping rules to be legal.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The one media player the shell follows, and everything modules/media needs in
// order to draw it.
//
// MPRIS exposes every player on the bus at once --- a browser tab, a music app
// and a video call can all be there together --- so the first job here is to
// pick which one the widget is about. The second is `active`, the single flag
// that decides whether the widget may appear at all.
//
// Nothing about looks lives here; that is MediaConfig and modules/media.
Singleton {
  id: root

  // ------------------------------------------------------------- behaviour --

  // A player that is merely paused keeps the widget on screen. Without this the
  // widget would vanish the instant you pressed its own pause button, taking
  // the play button with it and leaving no way to resume. Turn it off to follow
  // playback literally: on screen only while sound is actually coming out.
  property bool keepVisibleWhenPaused: true

  // How often the elapsed time is re-read while playing. MPRIS players do not
  // push position, so it has to be asked for; once a second is enough for a
  // progress bar and costs one D-Bus round trip.
  readonly property int positionInterval: 1000

  // ------------------------------------------------------------- selection --

  readonly property var players: Mpris.players?.values ?? []

  // The player everything below reports on. Null when nothing is on the bus.
  property MprisPlayer player: null

  // Preference order: whatever is actually playing, then whatever we were
  // already following (so a pause does not hand the widget to some other app),
  // then the first player that can be controlled at all.
  function pick(): var {
    const list = root.players;

    if (list.length === 0)
      return null;

    for (const candidate of list) {
      if (candidate.isPlaying)
        return candidate;
    }

    if (root.player && list.includes(root.player))
      return root.player;

    for (const candidate of list) {
      if (candidate.canControl)
        return candidate;
    }

    return list[0];
  }

  function refresh() {
    root.player = root.pick();
    root.reevaluate();
  }

  // Re-picks whenever a player appears or disappears...
  Instantiator {
    model: Mpris.players

    onObjectAdded: root.refresh()
    onObjectRemoved: root.refresh()

    delegate: QtObject {
      id: entry

      required property MprisPlayer modelData

      // ...and whenever one of them starts or stops, which is what moves the
      // widget from a paused player to the one that just began.
      property Connections watcher: Connections {
        target: entry.modelData

        function onPlaybackStateChanged() {
          root.refresh();
        }
      }
    }
  }

  Component.onCompleted: root.refresh()

  // ------------------------------------------------------------ visibility --

  readonly property bool playing: root.player?.isPlaying ?? false
  readonly property bool stopped: !root.player || root.player.playbackState === MprisPlaybackState.Stopped

  // The flag modules/media gates on. It latches on when playback starts and
  // only lets go when the player stops or leaves the bus, so a pause holds the
  // widget in place rather than dismissing it.
  property bool active: false

  function reevaluate() {
    if (!root.player || root.stopped) {
      root.active = false;
      return;
    }

    if (root.playing) {
      root.active = true;
      return;
    }

    // Paused, with a player still there.
    if (!root.keepVisibleWhenPaused)
      root.active = false;
  }

  onPlayingChanged: root.reevaluate()
  onStoppedChanged: root.reevaluate()

  // ----------------------------------------------------------------- track --

  readonly property string title: root.player?.trackTitle ?? ""
  readonly property string artist: root.player?.trackArtist ?? ""
  readonly property string album: root.player?.trackAlbum ?? ""
  readonly property string artUrl: root.player?.trackArtUrl ?? ""

  // Artist wins the subtitle; the album fills in for the players that report no
  // artist at all (browsers commonly report only a page title).
  readonly property string subtitle: root.artist || root.album

  readonly property real length: root.player?.lengthSupported ? (root.player.length ?? 0) : 0
  readonly property real position: root.player?.positionSupported ? (root.player.position ?? 0) : 0
  readonly property real progress: root.length > 0 ? Math.min(1, Math.max(0, root.position / root.length)) : 0

  // Position is a plain D-Bus read rather than a signalled property: re-emitting
  // its change signal is what makes Quickshell fetch it again.
  Timer {
    running: root.playing && root.player !== null
    interval: root.positionInterval
    repeat: true
    triggeredOnStart: true
    onTriggered: root.player.positionChanged()
  }

  // ---------------------------------------------------------------- source --

  // A key for the app behind the sound, in the same shape as the window classes
  // BarConfig.appIcons is keyed by, so the bar's icon map answers for both.
  //
  // The desktop entry is the reliable one ("spotify", "firefox"); identity is a
  // display name that usually still contains the app name ("Mozilla Firefox");
  // the bus address is the last resort, since it carries a per-instance suffix
  // (org.mpris.MediaPlayer2.firefox.instance_1).
  readonly property string sourceKey: {
    const player = root.player;

    if (!player)
      return "";

    if (player.desktopEntry)
      return player.desktopEntry.toLowerCase();

    if (player.identity)
      return player.identity.toLowerCase();

    return (player.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "").split(".")[0].toLowerCase();
  }

  readonly property string sourceName: root.player?.identity || root.sourceKey

  // -------------------------------------------------------------- controls --

  readonly property bool canGoNext: root.player?.canGoNext ?? false
  readonly property bool canGoPrevious: root.player?.canGoPrevious ?? false
  readonly property bool canTogglePlaying: root.player?.canTogglePlaying ?? false
  readonly property bool canSeek: (root.player?.canSeek ?? false) && root.length > 0

  function next() {
    if (root.canGoNext)
      root.player.next();
  }

  function previous() {
    if (root.canGoPrevious)
      root.player.previous();
  }

  function togglePlaying() {
    if (root.canTogglePlaying)
      root.player.togglePlaying();
  }

  // Stop, not pause: playback ends and the position resets, which drops
  // `active` and dismisses the widget.
  function stop() {
    if (root.player)
      root.player.stop();
  }

  function seekToFraction(fraction: real) {
    if (!root.canSeek)
      return;

    root.player.position = Math.min(1, Math.max(0, fraction)) * root.length;
  }

  // ---------------------------------------------------------------- format --

  // Seconds to m:ss, growing to h:mm:ss only when the track is that long.
  function formatTime(seconds: real): string {
    if (!isFinite(seconds) || seconds <= 0)
      return "0:00";

    const total = Math.floor(seconds);
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const secs = total % 60;
    const pad = value => value < 10 ? `0${value}` : `${value}`;

    return hours > 0 ? `${hours}:${pad(minutes)}:${pad(secs)}` : `${minutes}:${pad(secs)}`;
  }
}
