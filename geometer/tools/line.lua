-- TODO: Actually test and use this is an example.
local LineModification = geometer.require "modifications.line"

--- @class LineTool : Tool
--- @field origin Vector2
--- @field to Vector2
local Line = geometer.Tool:extend "LineTool"

function Line:__new()
   self.origin = nil
end

--- @param editor Editor
--- @param attachable SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function Line:mouseclicked(editor, attachable, x, y)
   if not attachable:inBounds(x, y) then return end
   self.origin = prism.Vector2(x, y)
end

--- @param editor Editor
function Line:mousereleased(editor)
   if not self.origin or not self.to then
      self.origin, self.to = nil, nil
      return
   end

   local fx, fy = self.origin.x, self.origin.y
   local x, y = self.to.x, self.to.y
   local modification =
      LineModification(editor.placeable, prism.Vector2(fx, fy), prism.Vector2(x, y))
   editor:execute(modification)

   self.origin = nil
end

--- @param dt number
---@param editor Editor
function Line:update(dt, editor)
   local x, y = editor.display:getCellUnderMouse()
   if not editor.attachable:inBounds(x, y) then return end

   self.to = prism.Vector2(x, y)
end

--- @param display Display
function Line:draw(editor, display)
   if not self.origin or not self.to then return end

   local path = prism.Bresenham(self.origin.x, self.origin.y, self.to.x, self.to.y)
   local drawable = self:getDrawable(editor.placeable)
   for _, point in ipairs(path:getPath()) do
      self:drawCell(display, drawable, point.x, point.y)
   end
end

return Line
