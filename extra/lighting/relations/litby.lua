--- Represents an entity being lit by another entity.
--- @class LitByRelation : Relation
--- @overload fun(): LitByRelation
local LitByRelation = prism.Relation:extend "LitByRelation"

function LitByRelation:generateInverse()
   return prism.relations.LightsRelation
end

return LitByRelation
