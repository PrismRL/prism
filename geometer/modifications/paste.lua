---@class PasteModification : Modification
---@field cells SparseGrid
---@field actors SparseMap
---@field topLeft Vector2
---@overload fun(cells: SparseGrid, actors: SparseMap, topLeft: Vector2): PasteModification
local PasteModification = geometer.Modification:extend "PasteModification"

---@param cells SparseGrid
---@param actors SparseMap
---@param topLeft Vector2
function PasteModification:__new(cells, actors, topLeft)
   self.cells = cells
   self.actors = actors
   self.topLeft = topLeft
end

function PasteModification:execute(attachable, editor)
   for x, y, cell in self.cells:each() do
      self:placeCell(attachable, x + self.topLeft.x - 1, y + self.topLeft.y - 1, cell)
   end
end

return PasteModification
