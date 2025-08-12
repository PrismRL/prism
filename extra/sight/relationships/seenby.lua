--- A relationship representing that an entity has been seen by another entity.
--- This is the inverse of the `Sees` relationship.
--- @class SeenBy : Relationship
--- @overload fun(): SeenBy
--- Constructs a new SeenBy relationship instance.
local SeenBy = prism.Relationship:extend "SeenBy"

--- Generates the inverse relationship of this one.
--- @return Relationship sees The inverse `Sees` relationship.
function SeenBy:generateInverse()
   return prism.relationships.Sees
end

return SeenBy