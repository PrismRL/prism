local PenModification = geometer.require "modifications.pen"
---@class Fill : Tool
---@field locations SparseGrid
---Represents a tool with update, draw, and mouse interaction functionalities.
---Tools can respond to user inputs and render visual elements.
local Fill = geometer.Tool:extend("FillTool")

--- Begins a paint drag.
---@param editor Editor
---@param attachable SpectrumAttachable
---@param cellx number The x-coordinate of the cell clicked.
---@param celly number The y-coordinate of the cell clicked.
function Fill:mouseclicked(editor, attachable, cellx, celly)
   if prism.Actor:is(editor.placeable) then return end
   if not attachable:inBounds(cellx, celly) then return end

   self.locations = prism.SparseGrid()
   self:bucket(attachable, cellx, celly)
   editor:execute(PenModification(editor.placeable, self.locations))
end

--- @param attachable SpectrumAttachable
---@param x any
---@param y any
function Fill:bucket(attachable, x, y)
   local cell = attachable:getCell(x, y)

   prism.BreadthFirstSearch(prism.Vector2(x, y), function(searchX, searchY)
      if prism.LevelBuilder:is(attachable) then
         --- @cast attachable LevelBuilder
         -- get the raw value, since LevelBuilder returns the default cell
         local cellAt = prism.SparseGrid.get(attachable, searchX, searchY)
         if not cellAt then return false end
      else
         --- @cast attachable Level
         local cellAt = attachable:getCell(searchX, searchY)
         if not cellAt then return false end
      end

      local cellAt = attachable:getCell(searchX, searchY)
      return cellAt:getName() == cell:getName()
   end, function(setX, setY)
      self.locations:set(setX, setY, true)
   end)
end

return Fill
