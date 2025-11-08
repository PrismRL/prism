local bit = require("bit") -- LuaJIT's bit library

---@class SparseArray : Object
---@field private data table<number, any> # Internal storage table mapping index -> item
---@field private freeIndices number[] # List of freed indices available for reuse
---@field private generations table<number, number> # Generation counters per slot
---@field private maxIndex integer
---@overload fun(): SparseArray
local SparseArray = prism.Object:extend("SparseArray")

local INDEX_BITS = 32
local INDEX_MASK = 0xFFFFFFFF -- (1 << 32) - 1

--- Packs index and generation into a single integer handle.
--- @param index number The slot index
--- @param generation number The generation count
--- @return number handle Packed handle as a Lua number
local function pack_handle(index, generation)
   return index + generation * 2^32
end

--- Unpacks a handle into index and generation components.
--- @param handle number The packed handle
--- @return number index The slot index
--- @return number generation The generation count
local function unpack_handle(handle)
   local index = bit.band(handle, INDEX_MASK)
   local generation = math.floor(handle / 2^32)
   return index, generation
end

--- Constructs a new SparseArray instance.
--- Constructs a new SparseArray instance.
function SparseArray:__new()
   self.data = {}
   self.freeIndices = {}
   self.generations = {}
   self.maxIndex = 0
end

--- Adds an item to the sparse array.
--- @param item any
--- @return number handle
function SparseArray:add(item)
   local index
   if #self.freeIndices > 0 then
      index = table.remove(self.freeIndices)
   else
      index = self.maxIndex + 1
      self.maxIndex = index
   end

   self.data[index] = item
   self.generations[index] = self.generations[index] or 0
   return pack_handle(index, self.generations[index])
end

--- Removes an item by handle.
--- @param handle number
function SparseArray:remove(handle)
   local index, gen = unpack_handle(handle)
   if self.data[index] ~= nil and self.generations[index] == gen then
      local data = self.data[index]
      self.data[index] = nil
      self.generations[index] = self.generations[index] + 1
      table.insert(self.freeIndices, index)

      if index == self.maxIndex then
         while self.maxIndex > 0 and self.data[self.maxIndex] == nil do
            self.maxIndex = self.maxIndex - 1
         end
      end
      
      return data
   end
end

--- Retrieves an item from the sparse array by its handle.
--- @param handle number The packed handle representing the item.
--- @return any|nil The item at the given handle, or nil if not found or stale.
function SparseArray:get(handle)
   local index, gen = unpack_handle(handle)
   print(index, gen)
   if self.generations[index] == gen then
      return self.data[index]
   end
end


--- Clears the sparse array.
function SparseArray:clear()
   self.data = {}
   self.freeIndices = {}
   self.generations = {}
   self.maxIndex = 0
end

--- Iterates over valid (handle, item) pairs up to the last live slot.
function SparseArray:pairs()
   local i = 0
   return function()
      for n = i + 1, self.maxIndex do
         local item = self.data[n]
         if item ~= nil then
            i = n
            local handle = pack_handle(n, self.generations[n] or 0)
            return handle, item
         end
      end
      return nil
   end
end

--- Prints the contents and free indices for debugging purposes.
function SparseArray:debugPrint()
   for i, v in pairs(self.data) do
      print(("Index %d: %s (Gen %d)"):format(i, tostring(v), self.generations[i] or 0))
   end
   print("Free indices:", table.concat(self.freeIndices, ", "))
end

return SparseArray
