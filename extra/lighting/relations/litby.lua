--- A relation representing that an entity is held by another entity.
--- This is the inverse of `InventoryRelation`.
--- @class LitByRelation : Relation
--- @overload fun(): LitByRelation
local LitByRelation = prism.Relation:extend "LitByRelation"

--- @return Relation senses inverse `InventoryRelation` relation.
function LitByRelation:generateInverse()
   return prism.relations.LightsRelation
end

return LitByRelation
