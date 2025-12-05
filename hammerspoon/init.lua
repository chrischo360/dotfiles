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
-- DISABLED: Now using Homerow (successor to Vimac) for Slack navigation
-- Homerow provides better hint-mode and scroll support without focus issues
--
-- To re-enable Hammerspoon Slack bindings, uncomment the section below
-- ============================================================================

--[[
-- Create a window filter to detect when Slack is focused
local slackFilter = hs.window.filter.new('Slack')

-- Store hotkeys so we can delete them when Slack loses focus
local slackHotkeys = {}

-- Function to enable Slack vim bindings
local function enableSlackBindings()
  -- Only enable if not already enabled (prevents duplicate bindings)
  if #slackHotkeys > 0 then
    return
  end

  -- Helper function: Check if message input is focused
  -- Why: Prevents j/k from scrolling when you're typing in the input field
  local function isInputFocused()
    local focusedElement = hs.uielement.focusedElement()
    if not focusedElement then return false end

    local role = focusedElement:role()
    local roleDescription = focusedElement:roleDescription()

    -- Debug: uncomment to see what element is focused
    -- print("Focused role:", role, "roleDescription:", roleDescription)

    -- Only consider it focused if it's specifically a text input
    -- AXTextField = single-line input
    -- AXTextArea = multi-line input (like message compose box)
    if role == "AXTextField" or role == "AXTextArea" then
      -- Additional check: make sure it's actually the message input
      -- Slack's message input usually has a specific description
      if roleDescription and roleDescription:lower():match("message") then
        return true
      end
      -- Fallback: if roleDescription contains "text field"
      if roleDescription and roleDescription:lower():match("text field") then
        return true
      end
    end

    return false
  end

  -- j = scroll down messages (mouse scroll - smooth and fast!)
  -- Why: Mouse scroll events are smoother than keyboard shortcuts
  -- Only works when NOT in input field (normal mode)
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({}, "j", function()
    local inputFocused = isInputFocused()
    -- Uncomment next line to debug focus detection:
    -- print("j pressed - input focused:", inputFocused)

    if not inputFocused then
      -- Scroll down 3 units (adjust number for speed preference)
      hs.eventtap.event.newScrollEvent({0, -3}, {}, 'line'):post()
    end
  end)

  -- k = scroll up messages (mouse scroll - smooth and fast!)
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({}, "k", function()
    if not isInputFocused() then
      -- Scroll up 3 units
      hs.eventtap.event.newScrollEvent({0, 3}, {}, 'line'):post()
    end
  end)

  -- i = focus message input (enter "insert mode")
  -- Why: Vim-like modal editing - 'i' to start typing
  -- Uses Cmd+Shift+K which is Slack's "Jump to search" then Tab to message input
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({}, "i", function()
    if not isInputFocused() then
      -- Focus the message input box
      -- Slack doesn't have a direct shortcut, so we click the input field
      -- Alternative: Just start typing - Slack auto-focuses input
      local app = hs.application.get("Slack")
      if app then
        local window = app:focusedWindow()
        if window then
          -- Send a click to approximate message input location
          -- This is a workaround - may need adjustment based on window size
          local frame = window:frame()
          local inputX = frame.x + frame.w / 2
          local inputY = frame.y + frame.h - 100
          hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, {x=inputX, y=inputY}):post()
          hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, {x=inputX, y=inputY}):post()
        end
      end
    end
  end)

  -- Esc = blur/unfocus input (exit "insert mode" back to "normal mode")
  -- Why: Vim-like escape back to normal mode for navigation
  -- Solution: Send Esc twice - first clears any draft, second unfocuses
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({}, "escape", function()
    -- Always send Escape - Slack will handle it appropriately
    -- First Esc: clears draft/formatting
    hs.eventtap.keyStroke({}, "escape")

    -- Small delay then send second Esc to unfocus
    hs.timer.doAfter(0.1, function()
      hs.eventtap.keyStroke({}, "escape")
    end)
  end)

  -- Ctrl+j = next channel (Alt+Down in Slack)
  -- Why Ctrl: Less likely to conflict with typing, ergonomic for channel switching
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({"ctrl"}, "j", function()
    hs.eventtap.keyStroke({"alt"}, "down")
  end)

  -- Ctrl+k = previous channel (Alt+Up in Slack)
  slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({"ctrl"}, "k", function()
    hs.eventtap.keyStroke({"alt"}, "up")
  end)

  -- Optional: Uncomment to add more vim bindings
  -- gg = jump to top (Cmd+Up in Slack)
  -- slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({}, "g", function()
  --   hs.eventtap.keyStroke({"cmd"}, "up")
  -- end, nil, function()
  --   hs.eventtap.keyStroke({"cmd"}, "up")
  -- end)

  -- G = jump to bottom (Cmd+Down in Slack)
  -- slackHotkeys[#slackHotkeys + 1] = hs.hotkey.bind({"shift"}, "g", function()
  --   hs.eventtap.keyStroke({"cmd"}, "down")
  -- end)

  print("Slack vim bindings enabled")
end

-- Function to disable Slack vim bindings
local function disableSlackBindings()
  -- Delete all active Slack hotkeys
  for _, hotkey in ipairs(slackHotkeys) do
    hotkey:delete()
  end
  slackHotkeys = {}
  print("Slack vim bindings disabled")
end

-- Enable bindings when Slack window is focused
-- Why: Automatically activates when you switch to Slack
slackFilter:subscribe(hs.window.filter.windowFocused, function()
  enableSlackBindings()
end)

-- Disable bindings when Slack window loses focus
-- Why: Prevents j/k from breaking other apps (especially terminal, editor)
slackFilter:subscribe(hs.window.filter.windowUnfocused, function()
  disableSlackBindings()
end)

-- Enable bindings if Slack is already focused when Hammerspoon starts
if hs.window.focusedWindow() and hs.window.focusedWindow():application():name() == "Slack" then
  enableSlackBindings()
end
--]]

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
