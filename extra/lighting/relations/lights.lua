--- Represents an entity lighting another entity.
--- @class LightsRelation : Relation
--- @overload fun(): LightsRelation
local LightsRelation = prism.Relation:extend "LightsRelation"

function LightsRelation:generateInverse()
   return prism.relations.LitByRelation
end

return LightsRelation
