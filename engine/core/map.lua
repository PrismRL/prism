--- A map manager class that extends the Grid class to handle map-specific functionalities.
--- @class Map : Grid
--- @field opacityCache BooleanBuffer Caches the opaciy of the cell + actors in each tile for faster fov calculation.
--- @field passableCache BitmaskBuffer
--- @overload fun(width: integer, height: integer, initialValue: CellFactory): Map
local Map = prism.Grid:extend("Map")

Map.serializationBlacklist = {
   opacityCache = true,
   passableCache = true,
}

--- The constructor for the 'Map' class.
--- Initializes the map with the specified dimensions and initial value, and sets up the opacity caches.
--- @param w number The width of the map.
--- @param h number The height of the map.
function Map:__new(w, h, cellFactory)
   self.super.__new(self, w, h)

   self.opacityCache = prism.BooleanBuffer(w, h)
   self.passableCache = prism.BitmaskBuffer(w, h)

   for x, y, _ in self:each() do
      self:set(x, y, cellFactory())
   end
end

--- Sets the cell at the specified coordinates to the given value.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @param cell Cell The cell to set.
function Map:set(x, y, cell)
   assert(cell:isInstance(), "Attempted to add an uninstantiated cell to map!")

   prism.Grid.set(self, x, y, cell)
   self:updateCaches(x, y)
end

--- Gets the cell at the specified coordinates.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @return Cell cell The cell at the specified coordinates.
function Map:get(x, y)
   --- @diagnostic disable-next-line
   return prism.Grid.get(self, x, y)
end

--- Updates the opacity cache at the specified coordinates.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
function Map:updateCaches(x, y)
   local cell = self:get(x, y)
   self.opacityCache:set(x, y, cell:has(prism.components.Opaque))
   self.passableCache:setMask(x, y, cell:getCollisionMask())
end

--- Returns true if the cell at the specified coordinates is passable, false otherwise.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @param mask Bitmask The collision mask.
--- @return boolean -- True if the cell is passable, false otherwise.
function Map:getCellPassable(x, y, mask)
   return prism.Collision.checkBitmaskOverlap(self.passableCache:getMask(x, y), mask)
end

--- Returns true if the cell at the specified coordinates is opaque, false otherwise.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @return boolean True if the cell is opaque, false otherwise.
function Map:getCellOpaque(x, y)
   return self.opacityCache:get(x, y)
end

--- Returns true if the (x, y) coordinate is within the bounds of the map.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @return boolean True if the coordinates are within bounds, false otherwise.
function Map:isInBounds(x, y)
   return x >= 1 and x <= self.w and y >= 1 and y <= self.h
end

function Map:__wire()
   local w, h = self.w, self.h
   self.opacityCache = prism.BooleanBuffer(w, h)
   self.passableCache = prism.BitmaskBuffer(w, h)

   for x, y, _ in self:each() do
      self:updateCaches(x, y)
   end
end

return Map
