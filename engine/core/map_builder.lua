--- A map builder class that extends the SparseGrid class to handle map-specific functionalities.
--- @class MapBuilder : SparseGrid, IQueryable, SpectrumAttachable
--- @field actors ActorStorage A list of actors present in the map.
--- @field initialValue CellFactory The initial value to fill the map with.
--- @overload fun(initialValue: CellFactory): MapBuilder
local MapBuilder = prism.SparseGrid:extend("MapBuilder")

--- The constructor for the 'MapBuilder' class.
--- Initializes the map with an empty data table and actors list.
--- @param initialValue CellFactory A cell factory to define the default value of the map.
function MapBuilder:__new(initialValue)
   prism.SparseGrid.__new(self)
   self.actors = prism.ActorStorage()
   self.initialValue = initialValue
end

--- Adds an actor to the map at the specified coordinates.
--- @param actor table The actor to add.
--- @param x number? The x-coordinate.
--- @param y number? The y-coordinate.
function MapBuilder:addActor(actor, x, y)
   if x and y then
      if actor:getPosition() then
         actor:give(prism.components.Position(prism.Vector2(x, y)))
      else
         prism.logger.warn(
            "Attempted to add", actor:getName(), "to mapbuilder",
            "at position", x, ",", y, "but it did not have a position component!"
         )
      end
   end

   self.actors:addActor(actor)
end

--- Removes an actor from the map.
--- @param actor table The actor to remove.
function MapBuilder:removeActor(actor)
   self.actors:removeActor(actor)
end

--- Draws a filled rectangle on the map.
--- @param x1 number The x-coordinate of the top-left corner.
--- @param y1 number The y-coordinate of the top-left corner.
--- @param x2 number The x-coordinate of the bottom-right corner.
--- @param y2 number The y-coordinate of the bottom-right corner.
--- @param cellFactory CellFactory The cell factory to fill the rectangle with.
function MapBuilder:drawFilledRectangle(x1, y1, x2, y2, cellFactory)
   for x = x1, x2 do
      for y = y1, y2 do
         self:set(x, y, cellFactory())
      end
   end
end

--- Draws a rectangle outline on the map.
--- @param x1 number The x-coordinate of the top-left corner.
--- @param y1 number The y-coordinate of the top-left corner.
--- @param x2 number The x-coordinate of the bottom-right corner.
--- @param y2 number The y-coordinate of the bottom-right corner.
--- @param cellFactory CellFactory The cell factory to draw the rectangle with.
function MapBuilder:drawRectangle(x1, y1, x2, y2, cellFactory)
   self:drawLine(x1, y1, x1, y2, cellFactory)
   self:drawLine(x2, y1, x2, y2, cellFactory)
   self:drawLine(x1, y1, x2, y1, cellFactory)
   self:drawLine(x1, y2, x2, y2, cellFactory)
end

--- Draws a filled ellipse on the map.
--- @param cx number The x-coordinate of the center.
--- @param cy number The y-coordinate of the center.
--- @param rx number The radius along the x-axis.
--- @param ry number The radius along the y-axis.
--- @param cellFactory CellFactory The cell factory to fill the ellipse with.
function MapBuilder:drawFilledEllipse(cx, cy, rx, ry, cellFactory)
   for x = -rx, rx do
      for y = -ry, ry do
         if (x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1 then
            self:set(cx + x, cy + y, cellFactory())
         end
      end
   end
end

--- Draws a line on the map using Bresenham's line algorithm.
--- @param x1 number The x-coordinate of the starting point.
--- @param y1 number The y-coordinate of the starting point.
--- @param x2 number The x-coordinate of the ending point.
--- @param y2 number The y-coordinate of the ending point.
--- @param cellFactory CellFactory The cell factory to draw the line with.
function MapBuilder:drawLine(x1, y1, x2, y2, cellFactory)
   local dx = math.abs(x2 - x1)
   local dy = math.abs(y2 - y1)
   local sx = x1 < x2 and 1 or -1
   local sy = y1 < y2 and 1 or -1
   local err = dx - dy

   while true do
      self:set(x1, y1, cellFactory())
      if x1 == x2 and y1 == y2 then break end
      local e2 = 2 * err
      if e2 > -dy then
         err = err - dy
         x1 = x1 + sx
      end
      if e2 < dx then
         err = err + dx
         y1 = y1 + sy
      end
   end
end

--- Draws a sequence of lines between given points.
--- @param cellFactory CellFactory The cell factory to draw the lines with.
--- @param ... integer Pairs of (x, y) coordinates given as a sequence of numbers.
function MapBuilder:drawPolygon(cellFactory, ...)
   --- @type integer[]
   local points = { ... }
   assert(#points % 2 == 0, "Invalid sequence of points given!")

   for i = 1, #points - 2, 2 do
      self:drawLine(points[i], points[i + 1], points[i + 2], points[i + 3], cellFactory)
   end
end

--- Gets the value at the specified coordinates, or the initialValue if not set.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @return Cell -- The cell at the specified coordinates, or the initialValue if not set.
function MapBuilder:get(x, y)
   local value = prism.SparseGrid.get(self, x, y)
   if value == nil then value = self.initialValue end
   return value
end

--- Sets the cell at the specified coordinates.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @param cell Cell The cell to set.
function MapBuilder:set(x, y, cell)
   assert(cell:isInstance(), "set expects an instance, not a factory!")
   prism.SparseGrid.set(self, x, y, cell)
end

--- Adds padding around the map with a specified width and cell value.
--- @param width number The width of the padding to add.
--- @param cellFactory CellFactory The cell factory to use for padding.
function MapBuilder:addPadding(width, cellFactory)
   local minX, minY = math.huge, math.huge
   local maxX, maxY = -math.huge, -math.huge

   for x, y in self:each() do
      if x < minX then minX = x end
      if x > maxX then maxX = x end
      if y < minY then minY = y end
      if y > maxY then maxY = y end
   end

   for x = minX - width, maxX + width do
      for y = minY - width, minY - 1 do
         self:set(x, y, cellFactory())
      end
      for y = maxY + 1, maxY + width do
         self:set(x, y, cellFactory())
      end
   end

   for y = minY - width, maxY + width do
      for x = minX - width, minX - 1 do
         self:set(x, y, cellFactory())
      end
      for x = maxX + 1, maxX + width do
         self:set(x, y, cellFactory())
      end
   end
end

--- Blits the source MapBuilder onto this MapBuilder at the specified coordinates.
--- @param source MapBuilder The source MapBuilder to copy from.
--- @param destX number The x-coordinate of the top-left corner in the destination MapBuilder.
--- @param destY number The y-coordinate of the top-left corner in the destination MapBuilder.
--- @param maskFn fun(x: integer, y: integer, source: Cell, dest: Cell)|nil A callback function for masking. Should return true if the cell should be copied, false otherwise.
function MapBuilder:blit(source, destX, destY, maskFn)
   maskFn = maskFn or function()
      return true
   end

   for x, y, value in source:each() do
      if maskFn(x, y, value, self:get(x, y)) then
         self:set(destX + x, destY + y, source:get(x, y))
      end
   end

   -- Adjust actor positions
   for actor in source.actors:query():iter() do
      ---@diagnostic disable-next-line
      local position = actor:getPosition()
      if position then
         actor:give(prism.components.Position(position + prism.Vector2(destX, destY)))
      end

      self.actors:addActor(actor)
   end
end

--- Builds the map and returns the map and list of actors.
--- Converts the sparse grid to a contiguous grid.
--- @return Map, table -- actors map and the list of actors.
function MapBuilder:build()
   -- Determine the bounding box of the sparse grid
   local minX, minY = math.huge, math.huge
   local maxX, maxY = -math.huge, -math.huge

   for x, y in self:each() do
      if x < minX then minX = x end
      if x > maxX then maxX = x end
      if y < minY then minY = y end
      if y > maxY then maxY = y end
   end

   -- Assert that the sparse grid is not empty
   assert(minX <= maxX and minY <= maxY, "SparseGrid is empty and cannot be built into a Map.")

   local width = maxX - minX + 1
   local height = maxY - minY + 1

   -- Create a new Map and populate it with the sparse grid data
   local map = prism.Map(width, height, self.initialValue)

   for x, y, _ in self:each() do
      map:set(x - minX + 1, y - minY + 1, self:get(x, y))
   end

   -- Adjust actor positions
   for actor in self.actors:query():iter() do
      ---@diagnostic disable-next-line
      local position = actor:getPosition()
      if position then
         actor:give(prism.components.Position(position - prism.Vector2(minX - 1, minY - 1)))
      end
   end

   --- @diagnostic disable-next-line
   return map, self.actors.actors
end

function MapBuilder:eachCell()
   return self:each()
end

-- Part of the interface that Level and MapBuilder share
-- for use with geometer

--- Mirror set.
--- @param x any
--- @param y any
--- @param value Cell
function MapBuilder:setCell(x, y, value)
   self:set(x, y, value)
end

function MapBuilder:getCell(x, y)
   return self:get(x, y)
end

function MapBuilder:inBounds(x, y)
   return true
end

function MapBuilder:query(...)
   return self.actors:query(...)
end

return MapBuilder
