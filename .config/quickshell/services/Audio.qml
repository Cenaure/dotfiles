pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// The audio graph, as far as the bar and its mixer need it.
//
// Pipewire only keeps a node's volume and mute state live while the node is
// tracked, so everything on offer here is bound into the tracker below. Without
// that the numbers are whatever they happened to be when the node appeared.
Singleton {
  id: root

  readonly property int volumeStep: 5

  readonly property var nodes: Pipewire.nodes?.values ?? []

  // Devices are the nodes that are not streams; the direction tells sinks from
  // sources. A playback stream is confusingly also isSink --- it feeds one ---
  // so isStream has to be checked first.
  readonly property var sinks: root.nodes.filter(node =>
    node.audio && !node.isStream && node.isSink)
  readonly property var sources: root.nodes.filter(node =>
    node.audio && !node.isStream && !node.isSink)

  // Applications currently playing something.
  readonly property var streams: root.nodes.filter(node =>
    node.audio && node.isStream && node.isSink)

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  // Everything the mixer can show, kept live for as long as this exists.
  PwObjectTracker {
    objects: root.sinks
      .concat(root.sources)
      .concat(root.streams)
  }

  // ----------------------------------------------------------------- output --

  readonly property real volume: root.sink?.audio?.volume ?? 0
  readonly property bool muted: root.sink?.audio?.muted ?? false

  readonly property real inputVolume: root.source?.audio?.volume ?? 0
  readonly property bool inputMuted: root.source?.audio?.muted ?? false

  // ---------------------------------------------------------------- control --

  // Volume is a plain 0..1 float, and pipewire will happily go above 1. Kept
  // capped here: a slider that can push past its own track is a way to blow
  // your ears out by accident.
  function setVolumeOf(node, value: real) {
    if (!node?.audio)
      return;

    node.audio.volume = Math.min(1, Math.max(0, value));
  }

  function setVolume(value: real) {
    root.setVolumeOf(root.sink, value);
  }

  function nudgeVolume(steps: int) {
    root.setVolume(root.volume + steps * root.volumeStep / 100);
  }

  function setMutedOf(node, value: bool) {
    if (node?.audio)
      node.audio.muted = value;
  }

  function toggleMute() {
    root.setMutedOf(root.sink, !root.muted);
  }

  function toggleInputMute() {
    root.setMutedOf(root.source, !root.inputMuted);
  }

  // Picking a device sets the preference rather than the default outright, so
  // pipewire keeps honouring it as devices come and go.
  function selectSink(node) {
    if (node)
      Pipewire.preferredDefaultAudioSink = node;
  }

  function selectSource(node) {
    if (node)
      Pipewire.preferredDefaultAudioSource = node;
  }

  // ----------------------------------------------------------------- labels --

  // Devices describe themselves; streams do not, and have to be named after the
  // application behind them.
  function labelOf(node): string {
    if (!node)
      return "";

    if (!node.isStream)
      return node.description || node.nickname || node.name;

    const properties = node.properties ?? {};

    return properties["application.name"]
      || properties["media.name"]
      || node.name
      || "Unknown";
  }

  // A key for the app behind a stream, shaped like the window classes
  // BarConfig.appIcons is keyed by, so a stream gets the same icon its window
  // has in the bar.
  function iconKeyOf(node): string {
    if (!node?.isStream)
      return "";

    const properties = node.properties ?? {};

    return (properties["application.name"] || "").toLowerCase();
  }

  // ------------------------------------------------------------------ mixer --

  // The full mixer, for the things this panel deliberately does not do:
  // routing, per-app device moves, latency.
  property string externalMixer: "pavucontrol"

  function openExternalMixer() {
    mixerProcess.running = true;
  }

  Process {
    id: mixerProcess

    command: ["sh", "-c", root.externalMixer]
  }
}
