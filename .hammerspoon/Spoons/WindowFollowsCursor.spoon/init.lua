--- Usage in ~/.hammerspoon/init.lua:
---   hs.loadSpoon("WindowFollowsCursor")
---   spoon.WindowFollowsCursor:start()

---@diagnostic disable: undefined-global
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowFollowsCursor"
obj.version = "1.0"
obj.author = "Sinisa"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal state
obj._filter = nil

-- Only act on real, movable application windows. Dialogs, sheets, popovers,
-- and fullscreen windows are skipped so the move does not feel janky.
local function shouldMove(win)
  if not win then
    return false
  end
  if not win:isStandard() then
    return false
  end
  if win:isFullScreen() then
    return false
  end
  if win:role() ~= "AXWindow" then
    return false
  end
  return true
end

local function onWindowCreated(win)
  if not shouldMove(win) then
    return
  end

  local mouseScreen = hs.mouse.getCurrentScreen()
  if not mouseScreen then
    return
  end

  if win:screen():id() ~= mouseScreen:id() then
    -- moveToScreen preserves relative position/size; ensureInScreenBounds
    -- (third arg) keeps the window from landing off-screen.
    win:moveToScreen(mouseScreen, false, true)
  end
end

--- WindowFollowsCursor:start()
--- Method
--- Starts watching for new windows and moving them to the cursor's screen.
---
--- Returns:
---  * The WindowFollowsCursor object
function obj:start()
  if self._filter then
    return self
  end
  self._filter = hs.window.filter.new(nil)
  self._filter:subscribe(hs.window.filter.windowCreated, onWindowCreated)
  return self
end

--- WindowFollowsCursor:stop()
--- Method
--- Stops watching for new windows.
---
--- Returns:
---  * The WindowFollowsCursor object
function obj:stop()
  if not self._filter then
    return self
  end
  self._filter:unsubscribe(hs.window.filter.windowCreated)
  self._filter = nil
  return self
end

return obj
