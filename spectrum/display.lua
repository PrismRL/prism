--- @class SpectrumAttachable : Object, IQueryable
--- @field getCell fun(self, x:integer, y:integer): Cell
--- @field setCell fun(self, x:integer, y:integer, cell: Cell|nil)
--- @field addActor fun(self, actor: Actor)
--- @field removeActor fun(self, actor: Actor)
--- @field inBounds fun(self, x: integer, y:integer)
--- @field getSize fun(): Vector2
--- @field eachCell fun(self): fun(): integer, integer, Cell
--- @field debug boolean

--- @class Sprite
--- @field index? string|integer
--- @field indices? (Sprite|string|integer)[]
--- @field color? Color4
--- @field background? Color4
--- @field layer? integer
--- @field size? integer

--- @alias DisplayCell {char: (string|integer)?, fg: Color4, bg: Color4, depth: number}
--- @class Display : Object
--- @field width integer The width of the display in cells.
--- @field height integer The height of the display in cells.
--- @field cells table<number, table<number, DisplayCell>>
--- @field camera Vector2 The offset to draw the display at.
--- @field pushed boolean Whether to draw with the camera offset applied or not.
--- @field overridenActors table<Actor, boolean> A set of actors that are being manually drawn to the display.
--- @field animations AnimationMessage[]
--- @overload fun(width: integer, heigh: integer, spriteAtlas: SpriteAtlas, cellSize: Vector2): Display
local Display = prism.Object:extend("Display")

--- Initializes the terminal display.
--- @param width integer The width of the display in cells.
--- @param height integer The height of the display in cells.
--- @param spriteAtlas SpriteAtlas The sprite atlas used for drawing characters.
--- @param cellSize Vector2 The size of each cell in pixels.
function Display:__new(width, height, spriteAtlas, cellSize)
   self.spriteAtlas = spriteAtlas
   self.cellSize = cellSize
   self.width = width
   self.height = height
   self.camera = prism.Vector2()
   self.pushed = false
   self.overridenActors = {}
   self.animations = {}

   self.cells = { {} }

   -- Initialize the grid with empty cells
   for x = 1, self.width do
      self.cells[x] = {}
      for y = 1, self.height do
         self.cells[x][y] = {
            char = nil,
            fg = prism.Color4(1, 1, 1, 1),
            bg = prism.Color4(0, 0, 0, 0),
            depth = -math.huge, -- Lowest possible depth
         }
      end
   end
end

--- Updates animations in the display.
--- @param level Level
--- @param dt number
function Display:update(level, dt)
   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      animation.animation:update(dt)

      if animation.animation.status == "paused" then self:removeAnimation(i) end
   end

   for _, _, animation in
      level:query(prism.components.Position, prism.components.IdleAnimation):iter()
   do
      --- @cast animation IdleAnimation
      animation.animation:update(dt)
   end
end

function Display:removeAnimation(index)
   local animation = self.animations[index]
   if animation.actor and animation.override then self:unoverrideActor(animation.actor) end
   table.remove(self.animations, index)
   if animation.blocking then self.blocking = false end
end

--- Draws the entire display to the screen. This function iterates through all cells
--- and draws their background colors and then their characters.
function Display:draw()
   local cSx, cSy = self.cellSize.x, self.cellSize.y

   -- draw bgs
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

   -- Draw characters
   for x = 1, self.width do
      for y = 1, self.height do
         local cell = self.cells[x][y]
         local dx, dy = x - 1, y - 1
         local quad = self:getQuad(cell.char)

         if quad then
            love.graphics.setColor(cell.fg:decompose())
            love.graphics.draw(self.spriteAtlas.image, quad, dx * cSx, dy * cSy)
         end
      end
   end

   love.graphics.setColor(1, 1, 1, 1)
end

--- Puts the drawable components of a level (cells and actors) onto the display.
--- This function uses the current camera position to determine what part of the level to draw.
--- @param attachable SpectrumAttachable An object representing the level, capable of providing cell and actor information.
function Display:putLevel(attachable)
   local camX, camY = self.camera:decompose()

   for x = 1, self.width do
      for y = 1, self.height do
         local cell = attachable:getCell(x - camX, y - camY)
         if cell then
            local drawable = cell:expect(prism.components.Drawable)
            self:putDrawable(x, y, drawable, nil, 0)
         end
      end
   end

   for actor, position, drawable in
      attachable:query(prism.components.Position, prism.components.Drawable):iter()
   do
      if not self.overridenActors[actor] then
         --- @cast drawable Drawable
         --- @cast position Position
         local ax, ay = position:getVector():decompose()
         self:putDrawable(ax + camX, ay + camY, drawable)
      end
   end
end

local reusedPosition = prism.Vector2()
--- Puts animations to the display.
--- @param level Level
--- @param ... Senses
function Display:putAnimations(level, ...)
   local drawnActors = {}
   local senses = { ... }

   for _, sense in ipairs(senses) do
      for actor, position, idleAnimation in
         sense:query(level, prism.components.Position, prism.components.IdleAnimation):iter()
      do
         if not drawnActors[actor] and not self.overridenActors[actor] then
            --- @cast idleAnimation IdleAnimation
            --- @cast position Position
            local x, y = position:getVector():decompose()
            local animation = idleAnimation.animation

            animation:draw(self, x, y)
            drawnActors[actor] = true
         end
      end
   end

   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      if animation.animation:isCustom() then
         animation.animation:draw(self)
      else
         local x, y = animation.x, animation.y
         if animation.actor then
            animation.actor:getPosition(reusedPosition)
            x = x + (reusedPosition and reusedPosition.x or 0)
            y = y + (reusedPosition and reusedPosition.y or 0)
         end

         animation.animation:draw(self, x, y)
      end
   end
end

--- Removes any animations that are skippable.
function Display:skipAnimations()
   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      if animation.skippable then self:removeAnimation(i) end
   end
end

--- Adds an animation to the display.
--- @param message AnimationMessage
function Display:yieldAnimation(message)
   table.insert(self.animations, message)
   -- We override the actor immediately to prevent flickering

   if message.actor and message.override then self:overrideActor(message.actor) end
   if message.blocking then self.blocking = true end
end

--- Marks an actor as being manually drawn, preventing it from being drawn
--- automatically by putLevel or putSenses methods.
--- @param actor Actor The actor to override.
function Display:overrideActor(actor)
   self.overridenActors[actor] = true
end

--- Clears the override on an actor, allowing it to be drawn automatically again.
--- @param actor Actor The actor to clear.
function Display:unoverrideActor(actor)
   self.overridenActors[actor] = nil
end

local tempColor = prism.Color4()

--- Draws cells from a given cell map onto the display, handling depth and transparency.
--- @private
--- @param drawnCells SparseGrid A sparse grid to keep track of already drawn cells to prevent overdrawing.
--- @param cellMap table A map of cells to draw.
--- @param alpha number The transparency level for the drawn cells (0.0 to 1.0).
function Display:_drawCells(drawnCells, cellMap, alpha)
   for cx, cy, cell in cellMap:each() do
      if not drawnCells:get(cx, cy) then
         drawnCells:set(cx, cy, true)
         --- @cast cell Cell

         local drawable = cell:expect(prism.components.Drawable)
         tempColor = drawable.color:copy(tempColor)
         tempColor.a = tempColor.a * alpha
         self:putDrawable(cx, cy, drawable, tempColor)
      end
   end
end

--- Draws actors from a Senses component onto the display, handling depth and transparency.
--- @private
--- @param drawnActors table A table to keep track of already drawn actors to prevent overdrawing.
--- @param senses Senses An object capable of being queried for actors with drawable components.
--- @param level Level
--- @param alpha number The transparency level for the drawn actors (0.0 to 1.0).
function Display:_drawActors(drawnActors, senses, level, alpha)
   for actor, position, drawable in
      senses:query(level, prism.components.Position, prism.components.Drawable):iter()
   do
      --- @cast drawable Drawable
      if not drawnActors[actor] and not self.overridenActors[actor] then
         drawnActors[actor] = true
         tempColor = drawable.color:copy(tempColor)
         tempColor.a = tempColor.a * alpha

         --- @cast position Position
         local ax, ay = position:getVector():decompose()
         self:putDrawable(ax, ay, drawable, tempColor)
      end
   end
end

--- @param drawnActors table
---@param grid SparseGrid
---@param alpha number
function Display:_drawRemembered(drawnActors, grid, alpha)
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

--- Puts vision and explored areas from primary and secondary senses onto the display.
--- Cells and actors from primary senses are drawn fully opaque, while those from secondary
--- senses are drawn with reduced opacity. Explored areas are drawn with even lower opacity.
--- @param primary Senses[] A list of primary Senses objects.
--- @param secondary Senses[] A list of secondary Senses objects.
--- @param level Level The level.
function Display:putSenses(primary, secondary, level)
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

--- Puts a Sprite onto the display grid at specified coordinates, considering its depth.
--- If a `color` or `layer` is provided, they will override the drawable's default values.
--- @param x integer The X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param sprite Sprite The drawable object to put.
--- @param color Color4? An optional color to use for the drawable.
--- @param layer number? An optional layer to use for depth sorting.
function Display:putSprite(x, y, sprite, color, layer)
   local size = sprite.size or 1
   if size > 1 and sprite.indices then
      local i = 1
      for y = y, y + size - 1 do
         for x = x, x + size - 1 do
            local isSprite = type(sprite.indices[i]) == "table"
            self:put(
               x,
               y,
               isSprite and sprite.indices[i].index or sprite.indices[i],
               color or (isSprite and sprite.indices[i].color or sprite.color),
               isSprite and sprite.indices[i].background or sprite.background,
               layer or (isSprite and sprite.indices[i].layer or sprite.layer)
            )
            i = i + 1
         end
      end
   else
      for ox = 1, size do
         for oy = 1, size do
            self:put(
               x + ox - 1,
               y + oy - 1,
               sprite.index,
               color or sprite.color,
               sprite.background,
               layer or sprite.layer
            )
         end
      end
   end
end

--- Puts a Drawable onto the display grid at specified coordinates, considering its depth.
--- If a `color` or `layer` is provided, they will override the drawable's default values.
--- @param x integer The X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param drawable Drawable The drawable object to put.
--- @param color Color4? An optional color to use for the drawable.
--- @param layer number? An optional layer to use for depth sorting.
function Display:putDrawable(x, y, drawable, color, layer)
   self:putSprite(x, y, drawable, color, layer)
end

--- Puts an Actor onto the display grid at specified coordinates, considering its depth.
--- If a `color` or `layer` is provided, they will override the drawable's default values.
--- Will error if the actor has no Drawable.
--- @param x integer The X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param actor Actor The actor to put.
--- @param color Color4? An optional color to use for the drawable.
--- @param layer number? An optional layer to use for depth sorting.
function Display:putActor(x, y, actor, color, layer)
   self:putSprite(x, y, actor:expect(prism.components.Drawable), color, layer)
end

--- Puts a character, foreground color, and background color at a specific grid position.
--- This function respects drawing layers, so higher layer values will overwrite lower ones.
--- @param x integer The X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param char string|integer The character or index to draw.
--- @param fg? Color4 The foreground color. Defaults to white.
--- @param bg? Color4 The background color. Defaults to transparent.
--- @param layer number? The draw layer (higher numbers draw on top). Defaults to -math.huge.
function Display:put(x, y, char, fg, bg, layer)
   if self.pushed then
      x = x + self.camera.x
      y = y + self.camera.y
   end
   if x < 1 or x > self.width or y < 1 or y > self.height then return end

   fg = fg or prism.Color4.WHITE
   bg = bg or prism.Color4.TRANSPARENT

   local cell = self.cells[x][y]

   if not layer or layer >= cell.depth then
      cell.char = char
      fg:copy(cell.fg)
      bg:copy(cell.bg)
      cell.depth = layer or -math.huge
   end
end

--- Sets only the background color of a cell at a specific grid position, with depth checking.
--- @param x integer The X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param bg Color4 The background color to set.
--- @param layer number? The draw layer (optional, higher numbers draw on top). Defaults to -math.huge.
function Display:putBG(x, y, bg, layer)
   if self.pushed then
      x = x + self.camera.x
      y = y + self.camera.y
   end

   if x < 1 or x > self.width or y < 1 or y > self.height then return end

   bg = bg or prism.Color4.TRANSPARENT

   local cell = self.cells[x][y]

   if not layer or layer >= cell.depth then
      bg:copy(cell.bg)
      cell.depth = layer or -math.huge
   end
end

--- Draws a string of characters at a grid position, with optional alignment.
--- @param x integer The starting X grid coordinate.
--- @param y integer The Y grid coordinate.
--- @param str string The string to draw.
--- @param fg Color4? The foreground color (defaults to white).
--- @param bg Color4? The background color (defaults to transparent).
--- @param layer number? The draw layer (optional).
--- @param align "left"|"center"|"right"? The alignment of the string within the specified width.
--- @param width integer? The width within which to align the string.
function Display:print(x, y, str, fg, bg, layer, align, width)
   local strLen = #str
   width = width or self.width

   if align == "center" then
      x = x + math.floor((width - strLen) / 2)
   elseif align == "right" then
      x = x + width - strLen
   elseif align ~= "left" and align ~= nil then -- Added check for nil as default for "left"
      error("Invalid alignment: " .. tostring(align))
   end

   fg = fg or prism.Color4.WHITE
   bg = bg or prism.Color4.TRANSPARENT
   for i = 1, #str do
      local char = str:sub(i, i)
      self:put(x + i - 1, y, char, fg, bg, layer)
   end
end

--- Retrieves the appropriate sprite atlas quad based on an index (number) or name (string).
--- @param index string|integer The index (number) or name (string) of the quad to retrieve.
--- @return love.graphics.Quad? optquad The quad object, or nil if not found.
function Display:getQuad(index)
   if type(index) == "number" then
      return self.spriteAtlas:getQuadByIndex(index)
   elseif type(index) == "string" then
      return self.spriteAtlas:getQuadByName(index)
   end
end

--- Clears the entire display grid, resetting all cell characters to nil,
--- setting backgrounds to a specified color (or transparent), and resetting depth.
--- @param bg Color4? Optional background color to clear to (defaults to transparent).
function Display:clear(bg)
   bg = bg or prism.Color4.TRANSPARENT

   for x = 1, self.width do
      for y = 1, self.height do
         local cell = self.cells[x][y]
         cell.char = nil
         bg:copy(cell.bg)
         cell.depth = -math.huge
      end
   end
end

--- Adjusts the Love2D window size to perfectly fit the terminal display's dimensions,
--- considering cell size.
function Display:fitWindowToTerminal()
   local cellWidth, cellHeight = self.cellSize.x, self.cellSize.y
   local windowWidth = self.width * cellWidth
   local windowHeight = self.height * cellHeight
   love.window.updateMode(windowWidth, windowHeight, { resizable = true, usedpiscale = false })
end

--- Calculates the top-left offset needed to center a given position on the display.
--- @param x integer The X coordinate to center.
--- @param y integer The Y coordinate to center.
--- @return integer offsetx The calculated X offset.
--- @return integer offsety The calculated Y offset.
function Display:getCenterOffset(x, y)
   local centerX = math.floor(self.width / 2)
   local centerY = math.floor(self.height / 2)
   local offsetX = centerX - x
   local offsetY = centerY - y
   return offsetX, offsetY
end

--- Draws a Drawable object directly at pixel coordinates on the screen,
--- without considering the grid or camera, and handling multi-cell drawables.
--- @param x number The pixel X coordinate of the top-left corner.
--- @param y number The pixel Y coordinate of the top-left corner.
--- @param drawable Drawable The drawable object to render.
function Display:drawDrawable(x, y, drawable)
   local quad = self:getQuad(drawable.index)
   if quad then
      love.graphics.setColor(drawable.color:decompose())
      love.graphics.draw(self.spriteAtlas.image, quad, x, y)
   end
end

--- Returns the grid cell under the current mouse position, adjusted by optional grid offsets.
--- @param mx? number A custom X coordinate to use for the mouse position.
--- @param my? number A custom Y coordinate to use for the mouse position.
--- @return integer? x The X grid coordinate, or nil if out of bounds.
--- @return integer? y The X grid coordinate, or nil if out of bounds.
function Display:getCellUnderMouse(mx, my)
   local x, y = self.camera:decompose()
   local mmx, mmy = love.mouse.getPosition()

   local gx = math.floor((mx or mmx) / self.cellSize.x) - x + 1
   local gy = math.floor((my or mmy) / self.cellSize.y) - y + 1

   return gx, gy
end

--- Sets the camera's position. This position acts as an offset for drawing
--- elements from the level or other world-space coordinates onto the display.
--- @param x integer The X coordinate for the camera.
--- @param y integer The Y coordinate for the camera.
function Display:setCamera(x, y)
   self.camera:compose(x, y)
end

--- Moves the camera by a specified delta.
--- @param dx integer The change in the camera's X position.
--- @param dy integer The change in the camera's Y position.
function Display:moveCamera(dx, dy)
   self.camera.x = self.camera.x + dx
   self.camera.y = self.camera.y + dy
end

--- Push the camera offset, so everything drawn will get the camera applied.
function Display:beginCamera()
   self.pushed = true
end

--- Pop the camera offset, so everything drawn will not get the camera applied.
function Display:endCamera()
   self.pushed = false
end

--- Draws a hollow rectangle on the display grid using specified characters and colors.
--- @param mode "fill"|"line" The mode to draw the rectangle in.
--- @param x integer The starting X grid coordinate of the rectangle.
--- @param y integer The starting Y grid coordinate of the rectangle.
--- @param w integer The width of the rectangle.
--- @param h integer The height of the rectangle.
--- @param char string|integer The character or index to draw the rectangle with.
--- @param fg Color4? The foreground color.
--- @param bg Color4? The background color.
--- @param layer number? The draw layer.
function Display:rectangle(mode, x, y, w, h, char, fg, bg, layer)
   if mode == "fill" then
      for dx = 0, w - 1 do
         self:put(x + dx, y, char, fg, bg, layer)
         self:put(x + dx, y + h - 1, char, fg, bg, layer)
      end
      for dy = 1, h - 2 do
         self:put(x, y + dy, char, fg, bg, layer)
         self:put(x + w - 1, y + dy, char, fg, bg, layer)
      end
   else
      for dx = 0, w - 1 do
         for dy = 0, h - 1 do
            self:put(x + dx, y + dy, char, fg, bg, layer)
         end
      end
   end
end

--- Draws a line between two grid points using Bresenham's line algorithm.
--- @param x0 integer The starting X grid coordinate.
--- @param y0 integer The starting Y grid coordinate.
--- @param x1 integer The ending X grid coordinate.
--- @param y1 integer The ending Y grid coordinate.
--- @param char string|integer The character or index to draw the line with.
--- @param fg Color4? The foreground color.
--- @param bg Color4? The background color.
--- @param layer number? The draw layer.
function Display:line(x0, y0, x1, y1, char, fg, bg, layer)
   local path = prism.Bresenham(x0, y0, x1, y1)
   for _, position in ipairs(path:getPath()) do
      self:put(position.x, position.y, char, fg, bg, layer)
   end
end

return Display
