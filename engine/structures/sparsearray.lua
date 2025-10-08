local bit = require("bit") -- LuaJIT's bit library

---@class SparseArray : Object
---@field private data table<number, any> # Internal storage table mapping index -> item
---@field private freeIndices number[] # List of freed indices available for reuse
---@field private generations table<number, number> # Generation counters per slot
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
function SparseArray:__new()
   self.data = {}
   self.freeIndices = {}
   self.generations = {}
end

--- Adds an item to the sparse array.
--- @param item any The item to add.
--- @return number handle A packed handle representing the item's location.
function SparseArray:add(item)
   local index
   if #self.freeIndices > 0 then
      index = table.remove(self.freeIndices)
   else
      index = #self.data + 1
   end

   self.data[index] = item
   self.generations[index] = self.generations[index] or 0
   return pack_handle(index, self.generations[index])
end

--- Removes an item from the sparse array by its handle.
--- @param handle number The packed handle representing the item.
function SparseArray:remove(handle)
   local index, gen = unpack_handle(handle)
   if self.data[index] ~= nil and self.generations[index] == gen then
      local data = self.data[index]
      self.data[index] = nil
      self.generations[index] = self.generations[index] + 1
      table.insert(self.freeIndices, index)
      return data
   end
end

--- Retrieves an item from the sparse array by its handle.
--- @param handle number The packed handle representing the item.
--- @return any|nil The item at the given handle, or nil if not found or stale.
function SparseArray:get(handle)
   local index, gen = unpack_handle(handle)
   if self.generations[index] == gen then
      return self.data[index]
   end
end

--- Clears the sparse array, removing all items and resetting state.
function SparseArray:clear()
   self.data = {}
   self.freeIndices = {}
   self.generations = {}
end

--- Returns an iterator over valid (handle, item) pairs in the sparse array.
--- @return fun(): (number?, any?) Iterator function returning (handle, item)
function SparseArray:pairs()
   local data = self.data
   local generations = self.generations
   local i = 0
   return function()
      repeat
         i = i + 1
         local item = data[i]
         if item ~= nil then
            local handle = pack_handle(i, generations[i] or 0)
            return handle, item
         end
      until i > #data
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
