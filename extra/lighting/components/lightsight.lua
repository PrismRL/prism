--- @class LightSightOptions : SightOptions
--- @field darkvision number

--- @class LightSight : Sight
local LightSight = prism.components.Sight:extend("LightSight")

--- @param options LightSightOptions
function LightSight:__new(options)
   self.super.__new(self, options)
   self.darkvision = options.darkvision
end

return LightSight
