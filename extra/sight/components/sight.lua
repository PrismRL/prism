--- @class SightOptions
--- @field range integer
--- @field fov boolean

--- @class Sight : Component
--- @field private range integer How many tiles can this actor see?
--- @field private fov boolean
--- @overload fun(options: SightOptions): Sight
local Sight = prism.Component:extend("Sight")
Sight.requirements = { "Senses" }

function Sight:getRequirements()
   return prism.components.Senses
end

--- @param options SightOptions
function Sight:__new(options)
   self.range = options.range
   self.fov = options.fov
end

function Sight:getRange()
   return self.range
end

function Sight:hasFov()
   return self.fov
end

return Sight
