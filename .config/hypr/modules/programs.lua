local M = {}

M.terminal = "kitty"
M.fileManager = "nautilus"
-- The quickshell app launcher, toggled over its IpcHandler rather than
-- spawned: the shell is already running, so this just flips its state.
M.menu = "qs ipc call appLauncher toggle"
M.themeSwitcher = "qs ipc call themeSwitcher toggle"
M.notificationsCenter = "qs ipc call notificationCenter toggle"
M.powerMenu = "qs ipc call powerMenu toggle"

-- Restarts the whole shell rather than toggling a single window: kills the
-- running quickshell instance if there is one, starts it otherwise. Matched on
-- the process name because `qs list` still exits 0 when nothing is running.
M.shellToggle = "if pgrep -x qs > /dev/null; then qs kill; else qs; fi"

return M