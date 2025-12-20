--- A modifier that runs on every cell/actor during Display rendering.
--- @class DisplayPass : Object
--- @overload fun(self: DisplayPass, entity: Entity, x: integer, y: integer, drawable: Drawable): DisplayPass
local DisplayPass = prism.Object:extend "DisplayPass"

--- @param run fun(self: DisplayPass, entity: Entity, x: integer, y: integer, drawable: Drawable)
function DisplayPass:__new(run)
   self.run = run
end

--- @param entity Entity
--- @param x integer
--- @param y integer
--- @param drawable Drawable
function DisplayPass:run(entity, x, y, drawable) end

return DisplayPass
