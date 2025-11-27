local bit = require "bit"

--- A class representing a cascade of BitmaskBuffers for kernel checks, all at the same resolution.
--- @class CascadingBitmaskBuffer : Object
--- @field cascade BitmaskBuffer[]
--- @overload fun(w: integer, h: integer, maxCascadeLevel: integer): CascadingBitmaskBuffer
local CascadingBitmaskBuffer = prism.Object:extend("CascadingBitmaskBuffer")

--- Constructor for the CascadingBitmaskBuffer class.
--- @param w integer The width of all buffers in the cascade.
--- @param h integer The height of all buffers in the cascade.
--- @param maxCascadeLevel integer The maximum cascade level (e.g., 5 for 1x1 to 5x5 kernels).
function CascadingBitmaskBuffer:__new(w, h, maxCascadeLevel)
   self.width = w
   self.height = h
   self.maxCascadeLevel = maxCascadeLevel
   self.cascade = {}

   -- Create all cascade levels with the same dimensions
   for level = 1, maxCascadeLevel do
      self.cascade[level] = prism.BitmaskBuffer(w, h)
   end
end

-- Helper function to safely get a mask value from a BitmaskBuffer.
-- Returns 0 if the coordinates are out of bounds, preventing errors.
local function safeGetMaskValue(self, buffer, xCoord, yCoord)
   if xCoord >= 1 and xCoord <= self.width and yCoord >= 1 and yCoord <= self.height then
      return buffer:getMask(xCoord, yCoord)
   end
   return 0
end

function CascadingBitmaskBuffer:_cascade(xInitial, yInitial)
   local currentMinX = xInitial
   local currentMaxX = xInitial
   local currentMinY = yInitial
   local currentMaxY = yInitial

   local kernelSize = 2

   for changedLevel = 2, self.maxCascadeLevel do
      local prevLevelBuffer = self.cascade[changedLevel - 1]
      local currentLevelBuffer = self.cascade[changedLevel]

      local nextMinX = self.width + 1 -- Initialize beyond max
      local nextMaxX = 0 -- Initialize before min
      local nextMinY = self.height + 1
      local nextMaxY = 0

      local checkRegionMinX = math.max(1, currentMinX - 1)
      local checkRegionMaxX = math.min(self.width, currentMaxX)
      local checkRegionMinY = math.max(1, currentMinY - 1)
      local checkRegionMaxY = math.min(self.height, currentMaxY)

      local levelChanged = false

      for ky = checkRegionMinY, checkRegionMaxY do
         for kx = checkRegionMinX, checkRegionMaxX do
            local val1 = safeGetMaskValue(self, prevLevelBuffer, kx, ky)
            local val2 = safeGetMaskValue(self, prevLevelBuffer, kx + 1, ky)
            local val3 = safeGetMaskValue(self, prevLevelBuffer, kx, ky + 1)
            local val4 = safeGetMaskValue(self, prevLevelBuffer, kx + 1, ky + 1)

            local newValue = bit.band(val1, val2, val3, val4)
            local oldValue = currentLevelBuffer:getMask(kx, ky)

            if newValue ~= oldValue then
               currentLevelBuffer:setMask(kx, ky, newValue)
               levelChanged = true

               nextMinX = math.min(nextMinX, kx - (kernelSize - 1))
               nextMaxX = math.min(self.width, math.max(nextMaxX, kx))
               nextMinY = math.min(nextMinY, ky - (kernelSize - 1))
               nextMaxY = math.min(self.height, math.max(nextMaxY, ky))
            end
         end
      end

      if not levelChanged then break end

      currentMinX = math.max(1, nextMinX)
      currentMaxX = math.min(self.width, nextMaxX)
      currentMinY = math.max(1, nextMinY)
      currentMaxY = math.min(self.height, nextMaxY)

      if currentMinX > currentMaxX or currentMinY > currentMaxY then break end
   end
end

function CascadingBitmaskBuffer:setMask(x, y, value)
   self.cascade[1]:setMask(x, y, value)
   self:_cascade(x, y)
end

--- Get the mask value at specific coordinates for a given cascade level.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param level integer The cascade level (1-based).
--- @return integer The mask value at (x, y) for the specified level.
function CascadingBitmaskBuffer:getMask(x, y, level)
   local buffer = self:getCascadeLevel(level)
   return buffer:getMask(x, y)
end

--- Get the BitmaskBuffer for a specific cascade level.
--- @param level integer The cascade level (1-based).
--- @return BitmaskBuffer buffer The BitmaskBuffer for the given level.
function CascadingBitmaskBuffer:getCascadeLevel(level)
   assert(
      level >= 1 and level <= self.maxCascadeLevel,
      "Cascade level out of range (" .. level .. ")"
   )
   return self.cascade[level]
end

return CascadingBitmaskBuffer
