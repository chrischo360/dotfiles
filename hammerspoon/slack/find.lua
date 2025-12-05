-- Hammerspoon Slack - UI Element Finder
-- Based on: https://github.com/dbalatero/dotfiles/blob/main/hammerspoon/slack/find.lua
--
-- This module provides utilities for traversing Slack's accessibility tree
-- to find specific UI elements (message boxes, buttons, etc.)

local module = {}

-- Recursively traverse an element's children using depth-first search
-- matchFn: predicate function that returns true when element is found
-- Returns: first matching element or nil
module.traverseChildren = function(element, matchFn)
  if matchFn(element) then
    return element
  else
    local children = element:attributeValue("AXChildren")

    if children and #children > 0 then
      for _, child in ipairs(children) do
        local result = module.traverseChildren(child, matchFn)
        if result then
          return result
        end
      end
    end

    return nil
  end
end

-- Search through element tree using a chain of predicates
-- Each predicate narrows down to a specific child element
--
-- Example:
--   searchByChain(window, {
--     function(elem) return hasClass(elem, "main-container") end,
--     function(elem) return elem:attributeValue("AXRole") == "AXTextArea" end
--   })
--
-- startElement: root element to start search from
-- fns: array of predicate functions to apply in sequence
-- debugPrint: optional flag to print intermediate results
module.searchByChain = function(startElement, fns, debugPrint)
  debugPrint = debugPrint or false
  local current = startElement

  for _, predicate in ipairs(fns) do
    current = module.traverseChildren(current, predicate)

    if debugPrint then
      print("Got: " .. hs.inspect.inspect(current))
    end

    if not current then
      return nil
    end
  end

  return current
end

return module
