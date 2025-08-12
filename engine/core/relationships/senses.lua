--- A relationship representing that an entity senses another entity.
--- This is the inverse of the `SensedBy` relationship.
--- @class Senses : Relationship
--- @overload fun(): Senses
local Senses = prism.Relationship:extend "SensesRelationship"

--- @return Relationship sensedby inverse `SensedBy` relationship.
function Senses:generateInverse()
   return prism.relationships.SensedBy
end

return Senses