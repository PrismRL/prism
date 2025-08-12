--- The `Relationship` class represents a typed relationship between entities.
--- Relationships describe social, hierarchical, or functional connections.
--- For example, the `Marriage` relationship may enforce a 1-to-1 bond.
--- Relationships are usually attached via the `relationships` field of an entity
--- as sparse maps of other entities to Relationship instances.
--- @class Relationship : Object
--- @field exclusive boolean (static) Whether the relationship excludes other relationship types of the same kind.
--- @field owner Entity The source entity holding this relationship instance.
--- @field target Entity The other entity involved in this relationship instance.
--- @overload fun(): Relationship
local Relationship = prism.Object:extend("Relationship")
Relationship.exclusive = false

--- Generates the inverse relationship to this one. Parent -> Child for instance.
--- @return Relationship?
function Relationship:generateInverse()
   return nil
end

--- Generates a symetric relationship to this one. Marriage -> Marraige for the other entity.
--- @return Relationship?
function Relationship:generateSymmetric()
   return nil
end

--- Gets the base prototype of this relationship type.
--- Used to compare or check type consistency.
--- @return Relationship
function Relationship:getBase()
   local proto = self:isInstance() and getmetatable(self) or self
   while proto and getmetatable(proto) ~= prism.Relationship do
      proto = getmetatable(proto)
   end
   return proto
end

return Relationship
