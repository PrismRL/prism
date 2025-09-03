--- A builder for a level. Used to define the map, actors, systems, and other settings for levels.
--- @class LevelBuilder : SparseGrid, IQueryable, SpectrumAttachable
--- @field actors ActorStorage A list of actors present in the map.
--- @field initialValue CellFactory The initial value to fill the map with.
--- @field scheduler? Scheduler
--- @field turn? TurnHandler
--- @field maximumActorSize integer
--- @field seed any
--- @field systems System[]
--- @overload fun(initialCell: CellFactory): LevelBuilder
local LevelBuilder = prism.SparseGrid:extend("LevelBuilder")
LevelBuilder._serializationBlacklist.initialValue = true

--- Initialize a new LevelBuilder.
--- @param initialCell CellFactory A cell factory to define the default value of the map.
function LevelBuilder:__new(initialCell)
   prism.SparseGrid.__new(self)
   self.actors = prism.ActorStorage()
   self.initialValue = initialCell
   self.systems = {}
end

--- Creates a LevelBuilder from an LZ4-compressed JSON file.
--- @param file string The path to the LZ4-compressed JSON file.
--- @param initialCell CellFactory A cell factory to define the default value of the map.
--- @return LevelBuilder
function LevelBuilder.fromLz4(file, initialCell)
   local contents = love.filesystem.read("level.json.gz")
   local json = love.data.decompress("string", "lz4", contents)
   local data = prism.json.decode(json)
   --- @type LevelBuilder
   local builder = prism.Object.deserialize(data)
   builder.initialValue = prism.cells.Wall
   return builder
end

--- Adds an actor to the map at the specified coordinates.
--- @param actor table The actor to add.
--- @param x number? The x-coordinate.
--- @param y number? The y-coordinate.
function LevelBuilder:addActor(actor, x, y)
   if x and y then
      if actor:getPosition() then
         actor:give(prism.components.Position(prism.Vector2(x, y)))
      else
         -- stylua: ignore
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
function LevelBuilder:removeActor(actor)
   self.actors:removeActor(actor)
end

--- Adds systems to the level.
--- @param ... System Initial systems to add to the level.
--- @return LevelBuilder
function LevelBuilder:addSystems(...)
   for _, system in ipairs { ... } do
      table.insert(self.systems, system)
   end
   return self
end

--- Adds a custom turn handler to the level.
--- @param turn TurnHandler A custom turn handler. Defaults to prism.defaultTurn.
function LevelBuilder:addTurnHandler(turn)
   self.turn = turn
end

--- Adds a custom scheduler to the level.
--- @param scheduler Scheduler A scheduler. Defaults to a SimpleScheduler.
--- @return LevelBuilder
function LevelBuilder:addScheduler(scheduler)
   self.scheduler = scheduler
   return self
end

--- Adds a custom seed to the level.
--- @param seed any A seed. Defaults to a time-based seed.
--- @return LevelBuilder
function LevelBuilder:addSeed(seed)
   self.seed = seed
   return self
end

--- Sets the maximum size for an actor to pathfind in the level.
--- @param size integer The maximum actor size. Defaults to 4.
--- @return LevelBuilder
function LevelBuilder:setMaximumActorSize(size)
   self.maximumActorSize = size
   return self
end

--- Draws a rectangle on the map.
--- @param mode "fill"|"line"
--- @param x1 number The x-coordinate of the top-left corner.
--- @param y1 number The y-coordinate of the top-left corner.
--- @param x2 number The x-coordinate of the bottom-right corner.
--- @param y2 number The y-coordinate of the bottom-right corner.
--- @param cellFactory CellFactory The cell factory to fill the rectangle with.
function LevelBuilder:rectangle(mode, x1, y1, x2, y2, cellFactory)
   if mode == "fill" then
      for x = x1, x2 do
         for y = y1, y2 do
            self:set(x, y, cellFactory())
         end
      end
   elseif mode == "line" then
      for x = x1, x2 do
         self:set(x, y1, cellFactory())
         self:set(x, y2, cellFactory())
      end

      for y = y1, y2 do
         self:set(x1, y, cellFactory())
         self:set(x2, y, cellFactory())
      end
   end
end

--- Draws an ellipse on the map.
--- @param mode "fill"|"line"
--- @param cx number The x-coordinate of the center.
--- @param cy number The y-coordinate of the center.
--- @param rx number The radius along the x-axis.
--- @param ry number The radius along the y-axis.
--- @param cellFactory CellFactory The cell factory to fill the ellipse with.
function LevelBuilder:ellipse(mode, cx, cy, rx, ry, cellFactory)
   prism.Ellipse(mode, prism.Vector2(cx, cy), rx, ry, function(x, y)
      self:set(x, y, cellFactory())
   end)
end

--- Draws a line on the map using Bresenham's line algorithm.
--- @param x1 number The x-coordinate of the starting point.
--- @param y1 number The y-coordinate of the starting point.
--- @param x2 number The x-coordinate of the ending point.
--- @param y2 number The y-coordinate of the ending point.
--- @param cellFactory CellFactory The cell factory to draw the line with.
function LevelBuilder:line(x1, y1, x2, y2, cellFactory)
   local line = prism.Bresenham(x1, y1, x2, y2)
   for _, position in ipairs(line) do
      self:set(position[1], position[2], cellFactory())
   end
end

--- Draws a sequence of lines between given points.
--- @param cellFactory CellFactory The cell factory to draw the lines with.
--- @param ... integer Pairs of (x, y) coordinates given as a sequence of numbers.
function LevelBuilder:polygon(cellFactory, ...)
   --- @type integer[]
   local points = { ... }
   assert(#points % 2 == 0, "Invalid sequence of points given!")

   for i = 1, #points - 2, 2 do
      self:line(points[i], points[i + 1], points[i + 2], points[i + 3], cellFactory)
   end
end

--- Gets the value at the specified coordinates, or the initialValue if not set.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @return Cell -- The cell at the specified coordinates, or the initialValue if not set.
function LevelBuilder:get(x, y)
   local value = prism.SparseGrid.get(self, x, y)
   if value == nil then value = self.initialValue() end
   return value
end

--- Sets the cell at the specified coordinates.
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @param cell Cell The cell to set.
function LevelBuilder:set(x, y, cell)
   assert(cell:isInstance(), "set expects an instance, not a factory!")
   prism.SparseGrid.set(self, x, y, cell)
end

--- Adds padding around the map with a specified width and cell value.
--- @param width number The width of the padding to add.
--- @param cellFactory CellFactory The cell factory to use for padding.
function LevelBuilder:pad(width, cellFactory)
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

--- Blits the source LevelBuilder onto this LevelBuilder at the specified coordinates.
--- @param source LevelBuilder The source LevelBuilder to copy from.
--- @param destX number The x-coordinate of the top-left corner in the destination LevelBuilder.
--- @param destY number The y-coordinate of the top-left corner in the destination LevelBuilder.
--- @param maskFn fun(x: integer, y: integer, source: Cell, dest: Cell)|nil A callback function for masking. Should return true if the cell should be copied, false otherwise.
function LevelBuilder:blit(source, destX, destY, maskFn)
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

--- @private
--- @return Map
--- @return Actor[]
function LevelBuilder:getEntities()
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
   local difference = prism.Vector2(minX - 1, minY - 1)
   for actor in self.actors:query():iter() do
      local position = actor:getPosition()
      if position then actor:give(prism.components.Position(position - difference)) end
   end

   return map, self.actors:getAllActors()
end

--- @return Level
function LevelBuilder:build()
   return prism.Level(self)
end

function LevelBuilder:eachCell()
   return self:each()
end

-- Part of the interface that Level and LevelBuilder share
-- for use with geometer

--- Mirror set.
--- @param x any
--- @param y any
--- @param value Cell
function LevelBuilder:setCell(x, y, value)
   self:set(x, y, value)
end

function LevelBuilder:getCell(x, y)
   return self:get(x, y)
end

function LevelBuilder:inBounds(x, y)
   return true
end

function LevelBuilder:query(...)
   return self.actors:query(...)
end

return LevelBuilder
