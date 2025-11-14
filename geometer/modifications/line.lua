--- @class LineModification : Modification
--- @field placeable Placeable
--- @field placed Placeable[]|nil
--- @field replaced SparseGrid
--- @field topleft Vector2
--- @field bottomright Vector2
local LineModification = geometer.Modification:extend "LineModification"

---@param placeable Placeable
---@param topleft Vector2
---@param bottomright Vector2
function LineModification:__new(placeable, topleft, bottomright)
   self.placeable = placeable
   self.topleft = topleft
   self.bottomright = bottomright
end

--- @param attachable SpectrumAttachable
function LineModification:execute(attachable)
   local i, j = self.topleft.x, self.topleft.y
   local k, l = self.bottomright.x, self.bottomright.y

   local path = prism.Bresenham(i, j, k, l)

   for _, point in ipairs(path:getPath()) do
      self:place(attachable, point.x, point.y, self.placeable)
   end
end

return LineModification
