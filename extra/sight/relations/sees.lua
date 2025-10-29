--- A relation representing that an entity sees another entity.
--- This is the inverse of the `SeenBy` relation
--- @class SeesRelation : Relation
--- @overload fun(): SeesRelation
local SeesRelation = prism.Relation:extend "SeesRelation"

--- Generates the inverse relation of this one.
--- @return Relation seenby inverse `SeenBy` relation.
function SeesRelation:generateInverse()
   return prism.relations.SeenByRelation
end

return SeesRelation
