--[[
   MIT License

   Copyright (c) 2019 Andrew Minnich

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
--]]

local loveCallbacks = {
   "directorydropped",
   "draw",
   "filedropped",
   "focus",
   "gamepadaxis",
   "gamepadpressed",
   "gamepadreleased",
   "joystickaxis",
   "joystickhat",
   "joystickpressed",
   "joystickreleased",
   "joystickremoved",
   "keypressed",
   "keyreleased",
   "load",
   "lowmemory",
   "mousefocus",
   "mousemoved",
   "mousepressed",
   "mousereleased",
   "quit",
   "resize",
   "run",
   "textedited",
   "textinput",
   "threaderror",
   "touchmoved",
   "touchpressed",
   "touchreleased",
   "update",
   "visible",
   "wheelmoved",
   "joystickadded",
}

-- returns a list of all the items in t1 that aren't in t2
local function exclude(t1, t2)
   local set = {}
   for _, item in ipairs(t1) do
      set[item] = true
   end
   for _, item in ipairs(t2) do
      set[item] = nil
   end
   local t = {}
   for item, _ in pairs(set) do
      table.insert(t, item)
   end
   return t
end

--- A state manager that uses a stack to hold states. Implementation taken from https://github.com/tesselode/roomy.
--- @class GameStateManager : Object
--- @field private states GameState[]
--- @overload fun(): GameStateManager
local StateManager = prism.Object:extend("GameStateManager")

function StateManager:__new()
   self.states = {}
end

--- Emits an event to the current state, passing any extra parameters along to it.
--- @param event string The event to emit.
--- @param ... any Additional parameters to pass to the state.
function StateManager:emit(event, ...)
   local state = self.states[#self.states]
   if state and state[event] then state[event](state, ...) end
end

--- Changes the currently active state.
--- @param ... any Additional parameters to pass to the state.
function StateManager:enter(next, ...)
   local previous = self.states[#self.states]
   self:emit("unload", next, ...)
   previous.manager = nil
   next.manager = self
   self.states[#self.states] = next
   self:emit("load", previous, ...)
end

--- Pushes a new state onto the stack, making it the new active state.
--- @param next GameState The state to push.
--- @param ... any Additional parameters to pass to the state.
function StateManager:push(next, ...)
   local previous = self.states[#self.states]
   next.manager = self
   self:emit("pause", next, ...)
   self.states[#self.states + 1] = next
   self:emit("load", previous, ...)
end

--- Removes the active state from the stack and resumes the previous one.
--- @param ... any Additional parameters to pass to the state.
function StateManager:pop(...)
   local previous = self.states[#self.states]
   local next = self.states[#self.states - 1]
   self:emit("unload", next, ...)
   previous.manager = nil
   self.states[#self.states] = nil
   self:emit("resume", previous, ...)
end

--- Hooks the love callbacks into the manager's, overwriting the originals.
--- @param options? { include: string[], exclude: string[] } Lists of callbacks to include or exclude.
function StateManager:hook(options)
   options = options or {}
   local callbacks = options.include or loveCallbacks
   if options.exclude then callbacks = exclude(callbacks, options.exclude) end
   for _, callbackName in ipairs(callbacks) do
      local oldCallback = love[callbackName]

      -- Since we call the oldCallback first and Input:update() resets the input state, Input
      -- must be hooked first.
      if oldCallback and callbackName == "update" then
         prism.logger.warn(
            "Callbacks existed before hook! Ensure spectrum.Input:hook() was called first if using."
         )
      end

      if oldCallback then
         love[callbackName] = function(...)
            oldCallback(...)
            self:emit(callbackName, ...)
         end
      else
         love[callbackName] = function(...)
            self:emit(callbackName, ...)
         end
      end
   end
end

return StateManager
