-- TODO: Actually test and use this is an example.
local RectModification = require "geometer/modifications/rect"

--- @class RectTool : Tool
--- @field origin Vector2
RectTool = geometer.Tool:extend "RectTool"
geometer.RectTool = RectTool

function RectTool:__new()
   self.topleft = nil
end

--- @param geometer Geometer
---@param level Level
---@param x integer The cell coordinate clicked.
---@param y integer The cell coordinate clicked.
function RectTool:mouseclicked(geometer, level, x, y)
   if not self.topleft then
      self.topleft = prism.Vector2(x, y)
      return
   end

   local modification = RectModification(prism.cells.Wall, self.topleft, prism.Vector2(x, y))
   geometer:execute(modification)
   self.topleft = nil
end

--- @param display Display
function RectTool:draw(display)
   if not self.topleft then return end
   
   local x, y = self.topleft.x, self.topleft.y
   local x2, y2 = display:getCellUnderMouse()
   local csx, csy = display.cellSize.x, display.cellSize.y

   --love.graphics.rectangle("fill", x, y, x2, y2 )
end