--- A relation representing that an entity is sensed by another entity.
--- This is the inverse of the `Senses` relation.
--- @class SensedByRelation : Relation
--- @overload fun(): SensedByRelation
local SensedByRelation = prism.Relation:extend "SensedByRelation"

--- @return Relation senses inverse `Senses` relation.
function SensedByRelation:generateInverse()
   return prism.relations.SensesRelation
end

return SensedByRelation
