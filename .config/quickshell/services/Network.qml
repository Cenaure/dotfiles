pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// The one network connection the bar reports on, and the list the popup offers.
//
// Quickshell's Networking sits on NetworkManager and exposes every device at
// once. Picking which one the widget is about, and keeping the wifi scanner off
// unless somebody is looking at the list, both live here.
Singleton {
  id: root

  readonly property var devices: Networking.devices?.values ?? []

  readonly property var wifiDevice: root.devices.find(device =>
    device.type === DeviceType.Wifi) ?? null
  readonly property var wiredDevice: root.devices.find(device =>
    device.type === DeviceType.Wired) ?? null

  // A cable beats wifi when it is actually up, which matches what the traffic
  // is doing.
  readonly property bool wired: root.wiredDevice?.connected ?? false

  readonly property var device: root.wired ? root.wiredDevice : root.wifiDevice

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiAvailable: root.wifiDevice !== null
    && Networking.wifiHardwareEnabled

  readonly property bool connected: root.device?.connected ?? false
  readonly property bool connecting: root.device?.state === ConnectionState.Connecting

  // ------------------------------------------------------------- networks --

  readonly property var networks: {
    const list = root.wifiDevice?.networks?.values ?? [];

    // Connected first so it is always at the top, then the ones already set up,
    // then everything else strongest first. Copied before sorting: the model's
    // own array is not ours to reorder.
    return list.slice().sort((a, b) => {
      if (a.connected !== b.connected)
        return a.connected ? -1 : 1;

      if (a.known !== b.known)
        return a.known ? -1 : 1;

      return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
    });
  }

  readonly property var activeNetwork: root.networks.find(network =>
    network.connected) ?? null

  // What the bar shows next to the icon, and the popup's header.
  readonly property string label: {
    if (root.wired)
      return "Ethernet";

    if (!root.wifiEnabled)
      return "Wi-Fi off";

    if (root.activeNetwork)
      return root.activeNetwork.name;

    return root.connecting ? "Connecting" : "Offline";
  }

  // 0..1, as NetworkManager reports it.
  readonly property real strength: root.activeNetwork?.signalStrength ?? 0

  readonly property bool online: Networking.connectivity === NetworkConnectivity.Full

  // --------------------------------------------------------------- control --

  // Scanning is a radio doing work, so it runs only while the list is open.
  property bool scanning: false

  Binding {
    target: root.wifiDevice
    property: "scannerEnabled"
    value: root.scanning
    when: root.wifiDevice !== null
  }

  function setWifiEnabled(enabled: bool) {
    Networking.wifiEnabled = enabled;
  }

  function toggleWifi() {
    root.setWifiEnabled(!root.wifiEnabled);
  }

  // Connecting to something already set up needs nothing from us; a new secured
  // network needs the passphrase, which is what the popup asks for.
  function connectTo(network) {
    if (!network)
      return;

    network.connect();
  }

  function connectWithPassword(network, password: string) {
    if (!network)
      return;

    network.connectWithPsk(password);
  }

  function disconnect() {
    if (root.device)
      root.device.disconnect();
  }

  function forget(network) {
    if (network?.known)
      network.forget();
  }

  // Open networks and ones already configured can be joined with a click;
  // anything else has to be asked for a passphrase first.
  function needsPassword(network): bool {
    if (!network || network.known)
      return false;

    return network.security !== WifiSecurityType.Open
      && network.security !== WifiSecurityType.Owe;
  }

  function isSecured(network): bool {
    if (!network)
      return false;

    return network.security !== WifiSecurityType.Open
      && network.security !== WifiSecurityType.Owe
      && network.security !== WifiSecurityType.Unknown;
  }
}
