local dummy = {}

--- A sparse grid of buckets that objects can be placed into. Used for
--- tracking actors by x,y position in Level.
--- @class SparseMap : Object
--- @field map table<integer, table<any, boolean>>
--- @field list table<any, table<integer, boolean>>
--- @overload fun(): SparseMap
local SparseMap = prism.Object:extend("SparseMap")

--- The constructor for the 'SparseMap' class.
--- Initializes the map and counters.
function SparseMap:__new()
   self.__count = 0
   self.map = {}
   self.list = {}
end

--- Gets the values stored at the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return table<any, boolean?> elements A set[actor]=bool of values stored at the specified coordinates, or an empty table if none.
function SparseMap:get(x, y)
   return self.map[prism.Vector2._hash(x, y)] or dummy
end

--- Gets the values stored at the specified hash.
--- @param hash number The hash value of the coordinates.
--- @return table<any, boolean?> elements A table of values stored at the specified hash, or an empty table if none.
function SparseMap:getByHash(hash)
   return self.map[hash] or dummy
end

--- Returns an iterator over all entries in the sparse map.
--- @return function An iterator that returns the value, coordinates, and hash for each entry.
function SparseMap:each()
   local value, hashTable
   local hash

   return function()
      while true do
         if hashTable then
            hash = next(hashTable, hash)
            if hash then
               local x, y = prism.Vector2._unhash(hash)
               return x, y, value
            else
               hashTable = nil
            end
         end

         value, hashTable = next(self.list, value)
         hash = nil

         if not value then return nil end
      end
   end
end

--- Returns the total number of entries in the sparse map.
--- @return number -- The total number of entries.
function SparseMap:count()
   return self.__count
end

--- Returns the number of values stored at the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return number -- The number of values stored at the specified coordinates.
function SparseMap:countCell(x, y)
   local count = 0

   for _, _ in pairs(self.map[prism.Vector2._hash(x, y)] or dummy) do
      count = count + 1
   end

   return count
end

--- Checks whether the specified value is stored at the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param value any The value to check.
--- @return boolean -- True if the value is stored at the specified coordinates, false otherwise.
function SparseMap:has(x, y, value)
   local xyhash = prism.Vector2._hash(x, y)
   if not self.map[xyhash] then return false end
   return self.map[xyhash][value] or false
end

--- Checks where the specified value exists within the map.
--- @param value any
--- @return boolean containsValue
function SparseMap:contains(value)
   return self.list[value] ~= nil
end

--- Inserts a value at the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param val any The value to insert.
function SparseMap:insert(x, y, val)
   local xyhash = prism.Vector2._hash(x, y)
   if not self.map[xyhash] then self.map[xyhash] = {} end
   if not self.list[val] then self.list[val] = {} end

   self.__count = self.__count + 1

   self.list[val][xyhash] = true
   self.map[xyhash][val] = true
end

--- Removes a value from the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param val any The value to remove.
--- @return boolean -- True if the value was successfully removed, false otherwise.
function SparseMap:remove(x, y, val)
   local xyhash = prism.Vector2._hash(x, y)
   if not self.map[xyhash] then return false end

   self.__count = self.__count - 1
   self.list[val][xyhash] = nil
   self.map[xyhash][val] = nil
   return true
end

function SparseMap:removeAll(val)
   if not self.list[val] then return end

   for hash, _ in pairs(self.list[val]) do
      self.map[hash][val] = nil
   end

   self.list[val] = nil
end

-- Some quick n dirty testing
local test = SparseMap()
test:insert(1, 1, "test")
test:insert(1, 2, "test2")
test:insert(3, 1, "test3")

assert(test:count() == 3)
assert(test:countCell(1, 1) == 1)
assert(test:countCell(1, 2) == 1)
assert(test:countCell(3, 1) == 1)
assert(test:has(1, 1, "test"))
assert(test:has(1, 2, "test2"))
assert(test:has(3, 1, "test3"))
assert(test:get(1, 1).test)
assert(test:get(1, 2).test2)
assert(test:get(3, 1).test3)
assert(not test:has(1, 1, "test4"))
assert(test:remove(1, 1, "test"))
assert(test:count() == 2)

return SparseMap
