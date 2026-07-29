--- Usage in ~/.hammerspoon/init.lua:
---   hs.loadSpoon("WindowFollowsCursor")
---   spoon.WindowFollowsCursor:start()

---@diagnostic disable: undefined-global
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowFollowsCursor"
obj.version = "1.1"
obj.author = "Sinisa"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal state
obj._filter = nil
obj._pending = {}

-- The AX windowCreated notification fires the instant the window element
-- exists, before most apps have applied their own saved frame. Moving at that
-- point either sees a not-yet-standard window or gets immediately overwritten,
-- so the move is deferred until the app has settled.
local MOVE_DELAY = 0.15

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

local function moveToCursorScreen(win)
  if not shouldMove(win) then
    return
  end

  local mouseScreen = hs.mouse.getCurrentScreen()
  local winScreen = win:screen()
  if not mouseScreen or not winScreen then
    return
  end

  if winScreen:id() ~= mouseScreen:id() then
    -- setFrameCorrectness works around the AX "stickiness" at the boundary
    -- between screens documented in hs.window.setFrameCorrectness, which
    -- otherwise leaves a cross-screen move partially or wholly unapplied.
    -- Duration 0 keeps the whole call synchronous, so save/restore is safe and
    -- the app cannot clobber the window mid-animation.
    local correctness = hs.window.setFrameCorrectness
    hs.window.setFrameCorrectness = true
    -- moveToScreen preserves relative position/size; ensureInScreenBounds
    -- (third arg) keeps the window from landing off-screen.
    win:moveToScreen(mouseScreen, false, true, 0)
    hs.window.setFrameCorrectness = correctness

    -- Moving a window across screens drops its key status; the app stays
    -- active but the window itself is no longer focused until it is clicked.
    win:focus()
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
  self._pending = {}
  self._filter = hs.window.filter.new(nil)
  self._filter:subscribe(hs.window.filter.windowCreated, function(win)
    local id = win and win:id()
    if not id or self._pending[id] then
      return
    end
    self._pending[id] = hs.timer.doAfter(MOVE_DELAY, function()
      self._pending[id] = nil
      moveToCursorScreen(win)
    end)
  end)
  return self
end

--- WindowFollowsCursor:stop()
--- Method
--- Stops watching for new windows.
---
--- Returns:
---  * The WindowFollowsCursor object
function obj:stop()
  for id, timer in pairs(self._pending) do
    timer:stop()
    self._pending[id] = nil
  end
  if not self._filter then
    return self
  end
  self._filter:unsubscribeAll()
  self._filter:delete()
  self._filter = nil
  return self
end

return obj
