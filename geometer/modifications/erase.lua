--- @class EraseModification : Modification
--- @field placeable Placeable
--- @field placed Placeable[]|nil
--- @field replaced SparseGrid
--- @field topleft Vector2
--- @field bottomright Vector2
local EraseModification = geometer.Modification:extend "EraseModification"

---@param placeable Placeable
---@param topleft Vector2
---@param bottomright Vector2
function EraseModification:__new(placeable, topleft, bottomright)
   self.placeable = placeable
   self.topleft = topleft
   self.bottomright = bottomright
end

--- @param attachable SpectrumAttachable
function EraseModification:execute(attachable)
   local i, j = self.topleft.x, self.topleft.y
   local k, l = self.bottomright.x, self.bottomright.y

   for x = i, k do
      for y = j, l do
         if prism.LevelBuilder:is(attachable) then self:placeCell(attachable, x, y, nil) end
         for actor in attachable:query():at(x, y):iter() do
            self:removeActor(attachable, actor)
         end
      end
   end
end

return EraseModification
