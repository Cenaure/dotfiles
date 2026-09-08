local M = {}

M.terminal = "kitty"
M.fileManager = "nautilus"
-- The quickshell app launcher, toggled over its IpcHandler rather than
-- spawned: the shell is already running, so this just flips its state.
M.menu = "qs ipc call appLauncher toggle"
M.themeSwitcher = "qs ipc call themeSwitcher toggle"
M.notificationsCenter = "qs ipc call notificationCenter toggle"
return M