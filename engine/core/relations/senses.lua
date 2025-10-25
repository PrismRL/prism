--- A relation representing that an entity senses another entity.
--- This is the inverse of the `SensedBy` relation.
--- @class SensesRelation : Relation
--- @overload fun(): SensesRelation
local SensesRelation = prism.Relation:extend "SensesRelation"

--- @return Relation sensedby inverse `SensedBy` relation.
function SensesRelation:generateInverse()
   return prism.relations.SensedByRelation
end

return SensesRelation
