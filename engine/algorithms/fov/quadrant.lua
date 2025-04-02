--- @class prism.fov.Quadrant : prism.Object
--- @overload fun(cardinal: number, origin: prism.Vector2): prism.fov.Quadrant
local Quadrant = prism.Object:extend("Quadrant")

function Quadrant:__new(cardinal, origin)
   self.cardinal = cardinal
   self.ox = origin.x
   self.oy = origin.y
end

function Quadrant:transform(row, col)
   if self.cardinal == 0 then
      return self.ox + col, self.oy - row
   elseif self.cardinal == 1 then
      return self.ox + row, self.oy + col
   elseif self.cardinal == 2 then
      return self.ox + col, self.oy + row
   elseif self.cardinal == 3 then
      return self.ox - row, self.oy + col
   end
end

return Quadrant
