--- A relation representing that an entity has another entity in its inventory.
--- This is the inverse of the HeldByRelation.
--- @class InventoryRelation : Relation
--- @overload fun(): InventoryRelation
local InventoryRelation = prism.Relation:extend "InventoryRelation"

--- @return Relation sensedby inverse `HeldByRelation`.
function InventoryRelation:generateInverse()
   return prism.relations.HeldByRelation
end

return InventoryRelation
