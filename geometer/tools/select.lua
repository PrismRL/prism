---@type PasteModification
local PasteModification = geometer.require "modifications.paste"

---@class SelectTool : Tool
---@field cells Grid the copied cells from the attachable
---@field actors SparseMap the copied actors from the attachable
---@field origin Vector2 location of the first point in a selection (creating or pasted)
---@field second Vector2 location of the other point in a selection (creating or pasted)
---@field pasted boolean whether a selection is currently pasted/active
---@field dragging boolean whether we're dragging, either actively creating a selection or pasting one
---@field dragOrigin Vector2 where we started dragging from when moving a pasted selection
local Select = geometer.Tool:extend "SelectTool"

function Select:__new()
   self.pasted = false
   self.dragging = false
end

--- @param editor Editor
--- @param attachable SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function Select:mouseclicked(editor, attachable, x, y)
   if not attachable:inBounds(x, y) then return end

   if self.pasted then
      local lx, ly, rx, ry = self:getCurrentRect()
      if x >= lx and x <= rx and y >= ly and y <= ry then
         self.dragging = true
         self.dragOrigin = prism.Vector2(x, y)
      else
         self.pasted = false
         self.origin = nil
         self.second = nil
      end
      return
   end

   if self.origin then
      self.origin = nil
      self.second = nil
      return
   end

   self.dragging = true
   self.origin = prism.Vector2(x, y)
end

function Select:update(dt, editor)
   local x, y = editor.levelDisplay:getCellUnderMouse()
   if not x or not y then return end
   if not editor.attachable:inBounds(x, y) then return end

   if self.pasted and self.dragging then
      local dx, dy = x - self.dragOrigin.x, y - self.dragOrigin.y
      if dx == 0 and dy == 0 then return end

      self.dragOrigin = prism.Vector2(x, y)
      self.origin = self.origin + prism.Vector2(dx, dy)
      self.second = self.second + prism.Vector2(dx, dy)
   elseif self.dragging then
      self.second = prism.Vector2(x, y)
   end
end

--- @param editor Editor
--- @param attachable SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function Select:mousereleased(editor, attachable, x, y)
   local lx, ly, rx, ry = self:getCurrentRect()
   if not (lx and ly and rx and ry) then return end

   if self.pasted then
      local modification = PasteModification(self.cells, self.actors, prism.Vector2(lx, ly))
      editor:execute(modification)
      self.pasted = false
      self.dragging = false
      self.origin = nil
      self.second = nil
   end

   self.dragging = false
end

--- Returns the four corners of the current rect.
--- @return number? topleftx
--- @return number? toplefty
--- @return number? bottomrightx
--- @return number? bottomrighty
function Select:getCurrentRect()
   if not self.origin or not self.second then return end

   local x, y = self.origin.x, self.origin.y
   local sx, sy = self.second.x, self.second.y

   local lx, ly = math.min(x, sx), math.min(y, sy)
   local rx, ry = math.max(x, sx), math.max(y, sy)

   return lx, ly, rx, ry
end

--- @param display Display
function Select:draw(editor, display)
   local lx, ly, rx, ry = self:getCurrentRect()
   if not (lx and ly and rx and ry) then return end

   if self.pasted then
      for x, y, cell in self.cells:each() do
         local drawable = cell:get(prism.components.Drawable)
         self:drawCell(display, drawable, lx + x - 1, ly + y - 1)
      end
   end

   love.graphics.push("all")
   love.graphics.setColor(0.1725, 0.909, 0.960)
   love.graphics.rectangle(
      "line",
      (lx + display.camera.x - 1) * display.cellSize.x,
      (ly + display.camera.y - 1) * display.cellSize.y,
      (rx - lx) * display.cellSize.x + display.cellSize.x,
      (ry - ly) * display.cellSize.y + display.cellSize.y
   )
   love.graphics.pop()
end

--- @param attachable SpectrumAttachable
function Select:copy(attachable)
   local lx, ly, rx, ry = self:getCurrentRect()
   if not (lx and ly and rx and ry) then return end

   ---@type Grid
   local newCells = prism.Grid(rx - lx + 1, ry - ly + 1)

   local copyX, copyY = 1, 1
   for x = lx, rx do
      for y = ly, ry do
         local cell = attachable:getCell(x, y)
         if cell then newCells:set(copyX, copyY, cell) end
         copyY = copyY + 1
      end
      copyX = copyX + 1
      copyY = 1
   end

   self.cells = newCells
end

function Select:paste()
   if not self.cells then return end

   self.pasted = true
   self.origin = prism.Vector2(1, 1)
   self.second = prism.Vector2(self.cells.w, self.cells.h)
end

return Select
