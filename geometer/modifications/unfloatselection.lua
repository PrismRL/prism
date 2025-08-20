--- @class UnfloatSelectionModification : Modification
--- @field placeable Placeable
--- @field position Vector2
--- @field floatingSelection LevelBuilder
--- @overload fun(placeable: Placeable, position: Vector2, floatingSelection: LevelBuilder)
--- @type UnfloatSelectionModification
local UnfloatSelection = geometer.Modification:extend "UnfloatSelectionModification"

function UnfloatSelection:__new(placeable, position, floatingSelection)
   self.placeable = placeable
   self.position = position
   self.floatingSelection = floatingSelection
end

function UnfloatSelection:execute(attachable)
   local map, actors = self.floatingSelection:build()

   for x = 1, map.w do
      for y = 1, map.h do
         self:placeCell(attachable, x, y, map:get(x, y))
      end
   end

   for _, actor in ipairs(actors) do
      local ax, ay = actor:getPosition():decompose()
      local x, y = self.position.x + ax, self.position.y + ay
      self:placeActor(attachable, x, y, actor)
   end
end
