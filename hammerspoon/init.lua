-- ============================================================================
-- Hammerspoon Configuration
-- ============================================================================
-- This file enables vim-like navigation in Slack and provides basic
-- Hammerspoon utilities. Config is symlinked from ~/dotfiles/hammerspoon/
--
-- Reload config: Ctrl+Alt+Cmd+R
-- ============================================================================

-- ============================================================================
-- STARTUP NOTIFICATION
-- ============================================================================
-- Why: Confirms Hammerspoon loaded successfully after changes
hs.notify.new({title="Hammerspoon", informativeText="Config loaded ✓"}):send()

-- ============================================================================
-- CONFIG RELOAD HOTKEY
-- ============================================================================
-- Why: Essential for rapid development - reload config without restarting app
-- Hotkey: Ctrl+Alt+Cmd+R
-- Reason for combo: Unlikely to conflict, uses all modifier keys for safety
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "R", function()
  hs.reload()
end)

-- Show notification after reload completes
hs.alert.show("Config Reloaded")

-- ============================================================================
-- SLACK VIM NAVIGATION
-- ============================================================================
-- Provides vim-like keybindings for Slack using Accessibility APIs
-- Based on: https://github.com/dbalatero/dotfiles/tree/main/hammerspoon/slack
--
-- Keybindings (only active when Slack is focused):
--   j - Scroll down
--   k - Scroll up
--   Ctrl+h - Focus main message box
--   Ctrl+l - Focus thread message box
--   Ctrl+r - Start "/remind me at" command
--   Ctrl+t - Open thread on current message
--   Shift+Cmd+Delete - Leave current channel
-- ============================================================================

require("slack")

-- ============================================================================
-- FUTURE EXTENSIONS (commented out - uncomment to enable)
-- ============================================================================

-- Window Management Example:
-- Why: You already use aerospace, but here's how you'd do it in Hammerspoon
--
-- hs.hotkey.bind({"cmd", "alt"}, "left", function()
--   local win = hs.window.focusedWindow()
--   local f = win:frame()
--   local screen = win:screen()
--   local max = screen:frame()
--
--   f.x = max.x
--   f.y = max.y
--   f.w = max.w / 2
--   f.h = max.h
--   win:setFrame(f)
-- end)

-- Application Launcher Example:
-- Why: Quick app switching with keyboard
--
-- hs.hotkey.bind({"cmd", "alt"}, "t", function()
--   hs.application.launchOrFocus("Alacritty")
-- end)

-- ============================================================================
-- DEBUGGING HELPERS
-- ============================================================================
-- Uncomment to see console output (useful for debugging)
-- hs.hotkey.bind({"cmd", "alt"}, "c", function()
--   hs.console.hswindow():focus()
-- end)

print("Hammerspoon config loaded successfully")
