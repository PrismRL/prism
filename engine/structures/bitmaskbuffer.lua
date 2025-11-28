local ok, ffi = pcall(require, "ffi")
--- @diagnostic disable-next-line
if not ok then ffi = nil end
--- @cast ffi ffilib
local bit = require "bit"

--- @alias Bitmask integer

--- A class representing a 2D bitmask buffer using 16-bit integers.
--- @class BitmaskBuffer : Object
--- @overload fun(w: integer, h: integer): BitmaskBuffer
local BitmaskBuffer = prism.Object:extend("BitmaskBuffer")

--- Constructor for the BitmaskBuffer class.
--- @param w integer The width of the buffer.
--- @param h integer The height of the buffer.
function BitmaskBuffer:__new(w, h)
   self.w = w
   self.h = h

   -- Initialize the buffer with zeroed 16-bit values
   if ffi then
      self.buffer = ffi.new("uint16_t[?]", w * h)
   else
      self.buffer = {}
   end
end

--- Calculate the index in the buffer array for the given coordinates.
--- @param x integer The x-coordinate (1-based).
--- @param y integer The y-coordinate (1-based).
--- @return integer index The corresponding index in the buffer array.
function BitmaskBuffer:getIndex(x, y)
   assert(x > 0 and y > 0, "Index out of bounds (" .. x .. ", " .. y .. ")")
   assert(x <= self.w and y <= self.h, "Index out of bounds (" .. x .. ", " .. y .. ")")
   return (y - 1) * self.w + (x - 1)
end

--- Clear the buffer, setting all values to zero.
function BitmaskBuffer:clear()
   ffi.fill(self.buffer, ffi.sizeof("uint16_t") * self.w * self.h)
end

if not ffi then BitmaskBuffer.clear = function(self)
   self.buffer = {}
end end

--- Set a specific bit at the given coordinates.
--- @param x integer The x-coordinate (1-based).
--- @param y integer The y-coordinate (1-based).
--- @param bitIndex integer The bit index (0-15) to set.
--- @param v boolean The value to set (true to set, false to clear).
function BitmaskBuffer:setBit(x, y, bitIndex, v)
   assert(bitIndex >= 0 and bitIndex < 16, "Bit index out of range (" .. bitIndex .. ")")
   local index = self:getIndex(x, y)
   if v then
      self.buffer[index] = bit.bor(self.buffer[index] or 0, bit.lshift(1, bitIndex))
   else
      self.buffer[index] = bit.band(self.buffer[index] or 0, bit.bnot(bit.lshift(1, bitIndex)))
   end
end

--- Get the value of a specific bit at the given coordinates.
--- @param x integer The x-coordinate (1-based).
--- @param y integer The y-coordinate (1-based).
--- @param bitIndex integer The bit index (0-15) to retrieve.
--- @return boolean value The value of the bit (true if set, false if not).
function BitmaskBuffer:getBit(x, y, bitIndex)
   assert(bitIndex >= 0 and bitIndex < 16, "Bit index out of range (" .. bitIndex .. ")")
   local index = self:getIndex(x, y)
   return bit.band(self.buffer[index], bit.lshift(1, bitIndex)) ~= 0
end

--- Get the full 16-bit mask value at the given coordinates.
--- @param x integer The x-coordinate (1-based).
--- @param y integer The y-coordinate (1-based).
--- @return Bitmask value The 16-bit mask value.
function BitmaskBuffer:getMask(x, y)
   return self.buffer[self:getIndex(x, y)] or 0
end

--- Set the full 16-bit mask value at the given coordinates.
--- @param x integer The x-coordinate (1-based).
--- @param y integer The y-coordinate (1-based).
--- @param value Bitmask The 16-bit value to set.
function BitmaskBuffer:setMask(x, y, value)
   self.buffer[self:getIndex(x, y)] = value
end

return BitmaskBuffer
