--- @class LightSightOptions : SightOptions
--- @field darkvision number The light level an entity can see in.

--- An extension of sight to represent an actor sensing via light.
--- @class LightSight : Sight
local LightSight = prism.components.Sight:extend("LightSight")

--- @param options LightSightOptions
function LightSight:__new(options)
   self.super.__new(self, options)
   self.darkvision = options.darkvision
end

return LightSight
