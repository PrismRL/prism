-- Based on anim8
--[[ Copyright (c) 2011 Enrique García Cota

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

--- @alias AnimationFactory fun(...): Animation
--- @alias AnimationFrame fun(display: Display, x?: number, y?: number) | Sprite

--- An animation to be played in a display. Yield an :lua:class:`AnimationMessage` to play one.
--- Animations can be built with a list of frames and durations, or with a custom function.
--- @class Animation : Object
--- @field custom? fun(time: number, display: Display): boolean
--- @field frames? AnimationFrame[]
--- @field durations? number|table
--- @field onLoop? fun(self: Animation)|string
--- @field intervals? number[]
--- @field totalDuration? number
--- @field timer number,
--- @field position? integer
--- @field status "playing"|"paused"
--- @overload fun(frames: AnimationFrame[]|(fun(time: number, display: Display): boolean), durations?: number|table, onLoop?: fun(animation: Animation)|string): Animation
local Animation = prism.Object:extend("Animation")

--- @param arr table
--- @return table
local function cloneArray(arr)
   local result = {}
   for i = 1, #arr do
      result[i] = arr[i]
   end
   return result
end

--- @param str number|string
--- @return number?, number?, integer
local function parseInterval(str)
   if type(str) == "number" then return str, str, 1 end
   str = str:gsub("%s", "") -- remove spaces
   local min, max = str:match("^(%d+)-(%d+)$")
   assert(min and max, ("Could not parse interval from %q"):format(str))
   min, max = tonumber(min), tonumber(max)
   local step = min <= max and 1 or -1
   return min, max, step
end

--- @param durations number|table
--- @param frameCount integer
--- @return table
local function parseDurations(durations, frameCount)
   local result = {}
   if type(durations) == "number" then
      for i = 1, frameCount do
         result[i] = durations
      end
   else
      local min, max, step
      for key, duration in pairs(durations) do
         assert(
            type(duration) == "number",
            "The value [" .. tostring(duration) .. "] should be a number"
         )
         min, max, step = parseInterval(key)
         for i = min, max, step do
            result[i] = duration
         end
      end
   end

   if #result < frameCount then
      error(
         "The durations table has length of "
            .. tostring(#result)
            .. ", but it should be >= "
            .. tostring(frameCount)
      )
   end

   return result
end

--- @param durations number|table
--- @return table, integer
local function parseIntervals(durations)
   local result, time = { 0 }, 0
   for i = 1, #durations do
      time = time + durations[i]
      result[i + 1] = time
   end
   return result, time
end

--- @class MultiSprite : Sprite
--- @field range string An range string, e.g. "1-5" representing indices 1, 2, 3, 4, 5.

--- Helper function to easily build a list of frames with the same settings over a range of indices.
--- @param ... MultiSprite
--- @return Sprite[]
function Animation.buildFrames(...)
   --- @type Sprite[]
   local result = {}
   local args = { ... }

   for a = 1, #args do
      local min, max, step = parseInterval(args[a].range)
      for i = min, max, step do
         result[#result + 1] = {
            index = i,
            color = args[a].color,
            background = args[a].background,
            size = args[a].size or 1,
            layer = args[a].layer,
         }
      end
   end

   return result
end

local nop = function() end

--- @param frames AnimationFrame[]|fun(time: number, display: Display)
--- @param durations number|table
--- @param onLoop fun(animation: Animation)|string?
function Animation:__new(frames, durations, onLoop)
   if type(frames) == "function" then
      self.custom = frames
   else
      local td = type(durations)
      if (td ~= "number" or durations <= 0) and td ~= "table" then
         error("durations must be a positive number. Was " .. tostring(durations))
      end
      onLoop = onLoop or nop
      durations = parseDurations(durations, #frames)
      local intervals, totalDuration = parseIntervals(durations)
      self.frames = cloneArray(frames)
      self.durations = durations
      self.intervals = intervals
      self.totalDuration = totalDuration
      self.onLoop = onLoop
      self.position = 1
   end
   self.timer = 0
   self.status = "playing"
end

--- @return boolean -- Whether this is a custom animation or not.
function Animation:isCustom()
   return not not self.custom
end

--- @return Animation
function Animation:clone()
   local newAnim = Animation(self.frames, self.durations, self.onLoop)
   return newAnim
end

--- @param intervals number[]
--- @param timer number
--- @return integer
local function seekFrameIndex(intervals, timer)
   local high, low, i = #intervals - 1, 1, 1

   while low <= high do
      i = math.floor((low + high) / 2)
      if timer >= intervals[i + 1] then
         low = i + 1
      elseif timer < intervals[i] then
         high = i - 1
      else
         return i
      end
   end

   return i
end

--- @param dt number
function Animation:update(dt)
   if self.status ~= "playing" then return end

   self.timer = self.timer + dt
   if self.custom then return end
   local loops = math.floor(self.timer / self.totalDuration)
   if loops ~= 0 then
      self.timer = self.timer - self.totalDuration * loops
      local f = type(self.onLoop) == "function" and self.onLoop or self[self.onLoop]
      f(self)
   end

   self.position = seekFrameIndex(self.intervals, self.timer)
end

--- Pauses the animation, setting the status to "paused".
function Animation:pause()
   self.status = "paused"
end

--- @param position integer
function Animation:gotoFrame(position)
   self.position = position
   self.timer = self.intervals[self.position]
end

function Animation:pauseAtEnd()
   self.position = #self.frames
   self.timer = self.totalDuration
   self:pause()
end

function Animation:pauseAtStart()
   self.position = 1
   self.timer = 0
   self:pause()
end

function Animation:resume()
   self.status = "playing"
end

--- @param display Display
--- @param x? number
--- @param y? number
function Animation:draw(display, x, y)
   if self.frames then
      local frame = self.frames[self.position]
      if type(frame) == "function" then
         frame(display, x, y)
      else
         --- @cast frame Drawable
         display:putDrawable(x, y, frame)
      end
   else
      if self.custom(self.timer, display) then self:pause() end
   end
end

return Animation
