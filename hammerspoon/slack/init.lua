-- Hammerspoon Slack - Main Module
-- Based on: https://github.com/dbalatero/dotfiles/blob/main/hammerspoon/slack/init.lua
--
-- Provides vim-like keybindings for Slack navigation
--
-- Keybindings (only active when Slack is focused):
--   j - Scroll down
--   k - Scroll up
--   Ctrl+h - Focus main message box (left pane)
--   Ctrl+l - Focus thread message box (right pane)
--   Ctrl+r - Start a "/remind me at" command
--   Ctrl+t - Open thread on current message
--   Shift+Cmd+Delete - Leave current channel

local focus = require("slack.focus")

-- Scroll up in Slack (smooth mouse scroll)
local function slackUp()
  hs.eventtap.event.newScrollEvent({0, 3}, {}, 'line'):post()
end

-- Scroll down in Slack (smooth mouse scroll)
local function slackDown()
  hs.eventtap.event.newScrollEvent({0, -3}, {}, 'line'):post()
end

-- Start a reminder command in the message box
local function startSlackReminder()
  focus.mainMessageBox()

  hs.timer.doAfter(0.3, function()
    hs.eventtap.keyStrokes("/remind me at ")
  end)
end

-- Open a thread on the current message
-- 1. Focus main message box
-- 2. Go up one message
-- 3. Press 't' to open thread
-- 4. Focus thread message box
local function openSlackThread()
  focus.mainMessageBox()

  hs.timer.doAfter(0.1, function()
    slackUp()
    hs.eventtap.keyStroke({}, "t", 0)
    focus.threadMessageBox(true)
  end)
end

-- Create a modal that's only active when Slack is focused
slackModal = hs.hotkey.modal.new()

-- Bind keys to actions
-- Format: bind(modifiers, key, pressedFn, releasedFn, repeatFn)
-- pressedFn: fires when key is pressed
-- releasedFn: fires when key is released
-- repeatFn: fires when key is held down

slackModal:bind(
  { "ctrl" },
  "h",
  nil,
  focus.mainMessageBox,
  nil,
  focus.mainMessageBox
)

-- j/k for smooth scrolling (no Ctrl modifier)
slackModal:bind({}, "j", nil, slackDown, nil, slackDown)

slackModal:bind({}, "k", nil, slackUp, nil, slackUp)

slackModal:bind(
  { "ctrl" },
  "l",
  nil,
  focus.threadMessageBox,
  nil,
  focus.threadMessageBox
)

slackModal:bind(
  { "ctrl" },
  "r",
  nil,
  startSlackReminder,
  nil,
  startSlackReminder
)

slackModal:bind({ "ctrl" }, "t", nil, openSlackThread, nil, openSlackThread)

slackModal:bind({ "shift", "cmd" }, "delete", nil, focus.leaveChannel, nil, nil)

-- Watch for Slack activation/deactivation
-- Automatically enter/exit modal when Slack gains/loses focus
slackWatcher = hs.application.watcher.new(function(applicationName, eventType)
  if applicationName ~= "Slack" then
    return
  end

  if eventType == hs.application.watcher.activated then
    slackModal:enter()
  elseif eventType == hs.application.watcher.deactivated then
    slackModal:exit()
  end
end)

slackWatcher:start()

print("Slack hotkeys loaded successfully")
