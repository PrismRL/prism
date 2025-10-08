---Represents all user input state for the current frame.
---@class IO : Object
---@field mx integer
---@field my integer
---@field mdown boolean
---@field mpressed boolean
---@field mreleased boolean
---@field keysDown table<string, boolean>
---@field textInput string
local IO = prism.Object:extend "IO"

---Creates a new IO instance.
function IO:__new()
  self.mx, self.my = 0, 0
  self.mdown, self.mpressed, self.mreleased = false, false, false
  self.keysDown = {}
  self.textInput = ""
end

---Feeds mouse input to the IO system.
---@param cellx integer|nil
---@param celly integer|nil
---@param isDown boolean|nil
---@param pressed boolean|nil
---@param released boolean|nil
function IO:feedMouse(cellx, celly, isDown, pressed, released)
  self.mx        = (cellx   ~= nil) and cellx   or self.mx
  self.my        = (celly   ~= nil) and celly   or self.my
  self.mdown     = not not isDown
  self.mpressed  = not not pressed
  self.mreleased = not not released
end

---Feeds keyboard input to the IO system.
---@param key string
---@param down boolean
function IO:feedKey(key, down)
  self.keysDown[key] = down and true or nil
end

---Feeds a text character to the IO system.
---@param char string
function IO:feedText(char)
  self.textInput = self.textInput .. char
end

---Ends the current frame, clearing transient input state.
function IO:endFrame()
  self.textInput = ""
  self.keysDown  = {}
end

return IO
