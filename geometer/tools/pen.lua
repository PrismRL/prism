local PenModification = geometer.require "modifications.pen"

---@class PenTool : Tool
---@field locations SparseGrid
local Pen = geometer.Tool:extend "PenTool"

Pen.dragging = false

function Pen:mouseclicked(editor, level, x, y)
   self.dragging = true
   self.locations = prism.SparseGrid()

   if not editor.attachable:inBounds(x, y) then return end
   self.locations:set(x, y, true)
end

---@param dt number
---@param editor Editor
function Pen:update(dt, editor)
   if not self.locations then return end

   local x, y = editor.levelDisplay:getCellUnderMouse()
   if not editor.attachable:inBounds(x, y) then return end

   self.locations:set(x, y, true)
end

---@param editor Editor
---@param display Display
function Pen:draw(editor, display)
   local x, y = editor.levelDisplay:getCellUnderMouse()
   local drawable = self:getDrawable(editor.placeable)

   self:drawCell(display, drawable, x, y)

   if not self.locations then return end

   for x, y in self.locations:each() do
      self:drawCell(display, drawable, x, y)
   end
end

function Pen:mousereleased(editor, level, x, y)
   if not self.locations then return end

   local modification = PenModification(editor.placeable, self.locations)
   editor:execute(modification)

   self.locations = nil
end

return Pen
