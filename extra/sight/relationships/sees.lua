--- A relationship representing that an entity sees another entity.
--- This is the inverse of the `SeenBy` relationship
--- @class Sees : Relationship
--- @overload fun(): Sees
local Sees = prism.Relationship:extend "Sees"

--- Generates the inverse relationship of this one.
--- @return Relationship seenby inverse `SeenBy` relationship.
function Sees:generateInverse()
   return prism.relationships.SeenBy
end

return Sees