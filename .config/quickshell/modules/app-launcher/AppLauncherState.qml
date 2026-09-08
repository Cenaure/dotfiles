pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isOpen: false
  property var recentIds: []

  // State
  property var recentIdsSerialized: []

  function toggle() { isOpen = !isOpen }
  function close() { isOpen = false }
  function open() { isOpen = true }
}