--- A relationship representing that an entity is sensed by another entity.
--- This is the inverse of the `Senses` relationship.
--- @class SensedBy : Relationship
--- @overload fun(): SensedBy
local SensedBy = prism.Relationship:extend "SensedBy"

--- @return Relationship senses inverse `Senses` relationship.
function SensedBy:generateInverse()
   return prism.relationships.Senses
end

return SensedBy