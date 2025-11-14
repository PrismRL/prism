--- A relation representing that an entity is held by another entity.
--- This is the inverse of `InventoryRelation`.
--- @class HeldByRelation : Relation
--- @overload fun(): HeldByRelation
local HeldByRelation = prism.Relation:extend "HeldByRelation"

--- @return Relation senses inverse `InventoryRelation` relation.
function HeldByRelation:generateInverse()
   return prism.relations.InventoryRelation
end

return HeldByRelation
