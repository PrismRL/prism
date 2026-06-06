--- @class StackedDisplay : Display
--- @field passes DisplayPass[]
--- @overload fun(width: integer, height: integer, spriteAtlas: SpriteAtlas, cellSize: Vector2): StackedDisplay
local StackedDisplay = spectrum.Display:extend("StackedDisplay")

--- @param width integer
--- @param height integer
--- @param spriteAtlas SpriteAtlas
--- @param cellSize Vector2
function StackedDisplay:__new(width, height, spriteAtlas, cellSize)
   self.super.__new(self, width, height, spriteAtlas, cellSize)
   self.passes = {}

   for x = 1, self.width do
      for y = 1, self.height do
         self.cells[x][y].sprites = {}
         self.cells[x][y].bgDepth = -math.huge
      end
   end
end

local function sortByDepth(a, b)
   return a.depth < b.depth
end

--- Draws backgrounds, then every sprite in each cell from lowest to highest depth.
function StackedDisplay:draw()
   local cSx, cSy = self.cellSize.x, self.cellSize.y

   for x = 1, self.width do
      for y = 1, self.height do
         local cell = self.cells[x][y]

         if cell.bg.a ~= 0 then
            local dx, dy = x - 1, y - 1
            love.graphics.setColor(cell.bg:decompose())
            love.graphics.rectangle("fill", dx * cSx, dy * cSy, cSx, cSy)
         end
      end
   end

   for x = 1, self.width do
      for y = 1, self.height do
         local cell = self.cells[x][y]
         local dx, dy = x - 1, y - 1

         if #cell.sprites > 1 then table.sort(cell.sprites, sortByDepth) end

         for _, sprite in ipairs(cell.sprites) do
            local quad = self:getQuad(sprite.char)

            if quad then
               love.graphics.setColor(sprite.fg:decompose())
               love.graphics.draw(self.spriteAtlas.image, quad, dx * cSx, dy * cSy)
            end
         end
      end
   end

   love.graphics.setColor(1, 1, 1, 1)
end



local tempColor = prism.Color4()
local tmpFG = prism.Color4()
local tmpBG = prism.Color4()
local tmpDrawable

local function copytemp(drawable)
   if not tmpDrawable then tmpDrawable = prism.components.Drawable {} end

   for k in pairs(tmpDrawable) do
      tmpDrawable[k] = nil
   end

   for k, v in pairs(drawable) do
      tmpDrawable[k] = v
   end

   tmpDrawable.color = drawable.color:copy(tmpFG)
   tmpDrawable.background = drawable.background:copy(tmpBG)

   return tmpDrawable
end

--- Applies the display pass stack without mutating the source drawable.
--- @param entity Entity
--- @param x integer
--- @param y integer
--- @param drawable Drawable
--- @param alpha number
--- @param callbackType "cell"|"actor"?
--- @return Drawable
--- @return Color4
function StackedDisplay:applyPasses(entity, x, y, drawable, alpha, callbackType)
   local passedDrawable = copytemp(drawable)

   for _, pass in ipairs(self.passes) do
      pass:run(entity, x, y, passedDrawable)
   end

   tempColor = passedDrawable.color:copy(tempColor)
   tempColor.a = tempColor.a * alpha
   if self.fgCallback then self.fgCallback(callbackType or "cell", tempColor) end

   return passedDrawable, tempColor
end

--- @private
--- @param drawnCells SparseGrid
--- @param cellMap table
--- @param alpha number
function StackedDisplay:_drawCells(drawnCells, cellMap, alpha)
   for cx, cy, cell in cellMap:each() do
      if not drawnCells:get(cx, cy) then
         drawnCells:set(cx, cy, true)
         --- @cast cell Cell
         local drawable = cell:expect(prism.components.Drawable)
         local passedDrawable, color = self:applyPasses(cell, cx, cy, drawable, alpha, "cell")
         self:putDrawable(cx, cy, passedDrawable, color)
      end
   end
end

--- @private
--- @param drawnActors table
--- @param senses Senses
--- @param level Level
--- @param alpha number
function StackedDisplay:_drawActors(drawnActors, senses, level, alpha)
   for actor, position, drawable in
      senses:query(level, prism.components.Position, prism.components.Drawable):iter()
   do
      --- @cast drawable Drawable
      if not drawnActors[actor] and not self.overridenActors[actor] then
         drawnActors[actor] = true

         --- @cast position Position
         local ax, ay = position:getVector():decompose()
         local passedDrawable, color = self:applyPasses(actor, ax, ay, drawable, alpha, "actor")
         self:putDrawable(ax, ay, passedDrawable, color)
      end
   end
end

--- Pushes a pass onto display pass stack.
--- @param pass DisplayPass
function StackedDisplay:pushPass(pass)
   table.insert(self.passes, pass)
end

--- Pops a display pass off of the stack.
function StackedDisplay:popPass()
   table.remove(self.passes, #self.passes)
end

--- @private
--- @param drawnActors table
--- @param grid SparseGrid
--- @param alpha number
function StackedDisplay:_drawRemembered(drawnActors, grid, alpha)
   for x, y, actor in grid:each() do
      if not drawnActors[actor] then
         drawnActors[actor] = true

         local drawable = actor:expect(prism.components.Drawable)
         tempColor = drawable.color:copy(tempColor)
         tempColor.a = tempColor.a * alpha

         self:putDrawable(x, y, drawable, tempColor)
      end
   end
end

--- @param primary Senses[]
--- @param secondary Senses[]
--- @param level Level
function StackedDisplay:putSenses(primary, secondary, level)
   local drawnCells = prism.SparseGrid()

   for _, senses in ipairs(primary) do
      self:_drawCells(drawnCells, senses.cells, 1)
   end

   for _, senses in ipairs(secondary) do
      self:_drawCells(drawnCells, senses.cells, 0.7)
   end

   for _, senses in ipairs(primary) do
      self:_drawCells(drawnCells, senses.explored, 0.3)
   end

   for _, senses in ipairs(secondary) do
      if senses.explored then self:_drawCells(drawnCells, senses.explored, 0.3) end
   end

   local drawnActors = {}

   for _, senses in ipairs(primary) do
      self:_drawActors(drawnActors, senses, level, 1)
   end

   for _, senses in ipairs(secondary) do
      self:_drawActors(drawnActors, senses, level, 0.7)
   end

   for _, senses in ipairs(primary) do
      self:_drawRemembered(drawnActors, senses.remembered, 0.3)
   end

   for _, senses in ipairs(secondary) do
      if senses.remembered then self:_drawRemembered(drawnActors, senses.remembered, 0.3) end
   end

   self:putAnimations(level, unpack(primary), unpack(secondary))
end

--- @param x integer
--- @param y integer
--- @param index? string|integer
--- @param fg? Color4
--- @param bg? Color4
--- @param layer? number
function StackedDisplay:put(x, y, index, fg, bg, layer)
   local cell = self:getCell(x, y)

   if not cell then return end

   fg = fg or prism.Color4.WHITE
   bg = bg or prism.Color4.TRANSPARENT
   local depth = layer or math.huge

   if bg.a ~= 0 and depth >= cell.bgDepth then
      bg:copy(cell.bg)
      cell.bgDepth = depth
   end

   if index == nil then return end

   cell.sprites[#cell.sprites + 1] = {
      char = index,
      fg = prism.Color4.copy(fg),
      depth = depth,
   }

   if depth >= cell.depth then
      cell.char = index
      fg:copy(cell.fg)
      cell.depth = depth
   end
end

--- @param x integer
--- @param y integer
--- @param fg Color4
--- @param layer number?
function StackedDisplay:putFG(x, y, fg, layer)
   local cell = self:getCell(x, y)
   if not cell then return end

   local depth = layer or math.huge
   if depth >= cell.depth then
      fg:copy(cell.fg)
      for i = #cell.sprites, 1, -1 do
         if cell.sprites[i].char == cell.char then
            fg:copy(cell.sprites[i].fg)
            return
         end
      end
   end
end

--- @param x integer
--- @param y integer
--- @param bg Color4
--- @param layer number?
function StackedDisplay:putBG(x, y, bg, layer)
   local cell = self:getCell(x, y)
   if not cell then return end

   local depth = layer or -math.huge
   if depth >= cell.bgDepth then
      bg:copy(cell.bg)
      cell.bgDepth = depth
   end
end

--- @param bg Color4?
function StackedDisplay:clear(bg)
   bg = bg or prism.Color4.TRANSPARENT

   for x = 1, self.width do
      for y = 1, self.height do
         local cell = self.cells[x][y]
         cell.char = nil
         bg:copy(cell.bg)
         cell.bgDepth = -math.huge
         cell.depth = -math.huge
         for i = #cell.sprites, 1, -1 do
            cell.sprites[i] = nil
         end
      end
   end
end

return StackedDisplay
