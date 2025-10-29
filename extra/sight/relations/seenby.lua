--- A relation representing that an entity has been seen by another entity.
--- This is the inverse of the `Sees` relation.
--- @class SeenByRelation : Relation
--- @overload fun(): SeenByRelation
local SeenByRelation = prism.Relation:extend "SeenByRelation"

--- Generates the inverse relation of this one.
--- @return Relation sees The inverse `Sees` relation.
function SeenByRelation:generateInverse()
   return prism.relations.SeesRelation
end

return SeenByRelation
