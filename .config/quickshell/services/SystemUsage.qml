pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory load, read straight out of /proc.
//
// No subprocesses in the poll: FileView reads procfs and sysfs correctly, and
// reload() re-reads them even though their mtime never changes, so a sample
// costs a few reads rather than a few forks. That matters because this polls
// while a widget is up. The one fork is a single sensor lookup, run once.
//
// Nothing is read at all unless `tracking` is set. The stats panel turns it on
// while it is on screen and off the moment it goes away, so an idle shell does
// no work.
Singleton {
  id: root

  // ------------------------------------------------------------- behaviour --

  property bool tracking: false

  readonly property int interval: 2000
  // The first reading is only a baseline --- CPU load is the difference between
  // two samples, so there is nothing to show until the second one. This is the
  // gap before it, kept short so the panel is not blank while you look at it.
  readonly property int primeInterval: 300

  // ------------------------------------------------------------------- cpu --

  // 0..1 across all cores.
  readonly property real cpuUsage: root.cpuTotals.usage
  // 0..1 per core, in /proc/stat order.
  readonly property var coreUsage: root.cpuTotals.cores
  readonly property int coreCount: root.coreUsage.length

  // ---------------------------------------------------------------- memory --

  // Bytes.
  property real memoryTotal: 0
  property real memoryUsed: 0

  readonly property real memoryUsage: root.memoryTotal > 0
    ? Math.min(1, Math.max(0, root.memoryUsed / root.memoryTotal))
    : 0

  // ----------------------------------------------------------- temperature --

  // Degrees Celsius, 0 until a sensor has been found and read once.
  property real temperature: 0

  readonly property bool hasTemperature: root.temperature > 0

  // hwmon numbers are handed out in probe order at boot, so hwmon5 being the
  // CPU today says nothing about tomorrow. The sensor is looked up by driver
  // name instead, once, and the resulting path reused from then on.
  property string temperaturePath: ""
  property bool temperatureResolved: false

  // Preferred drivers first, and within one, the die/package reading rather
  // than whatever temp1 happens to be. Falls back to the driver's first
  // sensor, which on a CPU driver is still a CPU temperature.
  readonly property string sensorLookupScript: `
    for driver in k10temp zenpower coretemp cpu_thermal; do
      for hwmon in /sys/class/hwmon/*; do
        [ "$(cat "$hwmon/name" 2>/dev/null)" = "$driver" ] || continue

        for label in "$hwmon"/temp*_label; do
          case "$(cat "$label" 2>/dev/null)" in
            Tctl|Tdie|"Package id 0")
              echo "\${label%_label}_input"
              exit 0
              ;;
          esac
        done

        if [ -e "$hwmon/temp1_input" ]; then
          echo "$hwmon/temp1_input"
          exit 0
        fi
      done
    done
  `

  Process {
    id: sensorLookup

    command: ["sh", "-c", root.sensorLookupScript]

    stdout: StdioCollector {
      onStreamFinished: root.temperaturePath = this.text.trim()
    }
  }

  // ---------------------------------------------------------------- polling --

  FileView {
    id: statFile

    path: "/proc/stat"
    // The whole point is to read on demand, so there is nothing to preload and
    // nothing to watch --- procfs never reports a change.
    preload: false
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: memoryFile

    path: "/proc/meminfo"
    preload: false
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: temperatureFile

    path: root.temperaturePath
    preload: false
    blockLoading: true
    printErrors: false
  }

  // Last counter snapshot, which is what the next one is measured against.
  property var previousCpu: null
  property var previousCores: []

  // What the readable properties above are derived from. Replaced whole on
  // every sample so that one assignment updates everything at once.
  property var cpuTotals: ({
    usage: 0,
    cores: []
  })

  readonly property bool primed: root.previousCpu !== null

  Timer {
    id: poll

    running: root.tracking
    // Tightened until the baseline exists, then settles to the real rate.
    interval: root.primed ? root.interval : root.primeInterval
    repeat: true
    triggeredOnStart: true

    onTriggered: root.sample()
  }

  onTrackingChanged: {
    if (root.tracking) {
      // Deferred to the first time anyone looks, so a shell whose stats panel
      // is never opened never forks at all. A machine with no CPU sensor
      // resolves to an empty path, which is remembered so it is not retried on
      // every open.
      if (!root.temperatureResolved) {
        root.temperatureResolved = true;
        sensorLookup.running = true;
      }

      return;
    }

    // A delta measured across the gap while nothing was watching would describe
    // minutes of history as if it were the last two seconds, so the baseline is
    // thrown away rather than kept.
    root.previousCpu = null;
    root.previousCores = [];
    root.cpuTotals = {
      usage: 0,
      cores: []
    };

    // Temperature is an instantaneous reading rather than a delta, so a stale
    // one is merely a little old instead of wrong. It is kept, so reopening
    // the panel shows a number immediately instead of flashing an empty slot.
  }

  function sample() {
    root.sampleCpu();
    root.sampleMemory();
    root.sampleTemperature();
  }

  // ------------------------------------------------------------------ parse --

  // One "cpu" line of /proc/stat as a pair of counters. Everything but idle and
  // iowait counts as busy; the guest fields are left out because the kernel
  // already counts them inside user and nice.
  function cpuCountersOf(line): var {
    const values = line.trim().split(/\s+/).slice(1).map(Number);

    let total = 0;

    for (let i = 0; i < Math.min(8, values.length); i++)
      total += values[i];

    return {
      total: total,
      idle: (values[3] ?? 0) + (values[4] ?? 0)
    };
  }

  // Busy fraction between two snapshots of the same counter.
  function usageBetween(previous, current): real {
    if (!previous || !current)
      return 0;

    const total = current.total - previous.total;
    const idle = current.idle - previous.idle;

    if (total <= 0)
      return 0;

    return Math.min(1, Math.max(0, 1 - idle / total));
  }

  function sampleCpu() {
    statFile.reload();

    const text = statFile.text();

    if (!text)
      return;

    let aggregate = null;
    const cores = [];

    for (const line of text.split("\n")) {
      if (!line.startsWith("cpu"))
        break;  // The cpu lines are first; everything after them is other data.

      if (line.startsWith("cpu "))
        aggregate = root.cpuCountersOf(line);
      else
        cores.push(root.cpuCountersOf(line));
    }

    if (!aggregate)
      return;

    const usage = root.usageBetween(root.previousCpu, aggregate);
    const coreUsage = cores.map((counters, index) =>
      root.usageBetween(root.previousCores[index], counters));

    root.previousCpu = aggregate;
    root.previousCores = cores;

    root.cpuTotals = {
      usage: usage,
      cores: coreUsage
    };
  }

  function sampleMemory() {
    memoryFile.reload();

    const text = memoryFile.text();

    if (!text)
      return;

    const fields = {};

    for (const line of text.split("\n")) {
      const match = line.match(/^(\w+):\s+(\d+)/);

      if (match)
        fields[match[1]] = Number(match[2]) * 1024;
    }

    const total = fields.MemTotal ?? 0;

    if (total <= 0)
      return;

    // MemAvailable is the kernel's own estimate of what a new allocation could
    // actually get, which is the number worth showing. The sum is the old way
    // of guessing it, kept for kernels too old to publish it.
    const available = fields.MemAvailable
      ?? ((fields.MemFree ?? 0) + (fields.Buffers ?? 0) + (fields.Cached ?? 0));

    root.memoryTotal = total;
    root.memoryUsed = Math.max(0, total - available);
  }

  function sampleTemperature() {
    if (root.temperaturePath === "")
      return;

    temperatureFile.reload();

    const text = temperatureFile.text();

    if (!text)
      return;

    // hwmon reports millidegrees.
    const millidegrees = Number(text.trim());

    if (!isFinite(millidegrees) || millidegrees <= 0)
      return;

    root.temperature = millidegrees / 1000;
  }

  // ----------------------------------------------------------------- format --

  function formatBytes(bytes: real): string {
    if (!isFinite(bytes) || bytes <= 0)
      return "0 B";

    const units = ["B", "KiB", "MiB", "GiB", "TiB"];
    let value = bytes;
    let unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }

    // One decimal is enough to watch memory move without the number jittering.
    return `${value < 10 ? value.toFixed(1) : Math.round(value)} ${units[unit]}`;
  }

  function formatTemperature(celsius: real): string {
    if (!isFinite(celsius) || celsius <= 0)
      return "";

    // Whole degrees: the tenths a sensor reports move constantly and say
    // nothing worth reading at a glance.
    return `${Math.round(celsius)}°C`;
  }

  function formatPercent(fraction: real): string {
    if (!isFinite(fraction))
      return "0%";

    return `${Math.round(Math.min(1, Math.max(0, fraction)) * 100)}%`;
  }
}
