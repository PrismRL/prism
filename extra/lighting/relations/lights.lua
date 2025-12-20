--- A relation representing that an entity is held by another entity.
--- This is the inverse of `InventoryRelation`.
--- @class LightsRelation : Relation
--- @overload fun(): LightsRelation
local LightsRelation = prism.Relation:extend "LightsRelation"

--- @return Relation senses inverse `InventoryRelation` relation.
function LightsRelation:generateInverse()
   return prism.relations.LitByRelation
end

return LightsRelation
