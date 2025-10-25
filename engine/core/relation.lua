--- The `Relation` class represents a typed relation between entities.
--- Relations describe social, hierarchical, or functional connections.
--- For example, the `Marriage` relation may enforce a 1-to-1 bond.
--- Relations are usually attached via the `relations` field of an entity
--- as sparse maps of other entities to Relation instances.
--- @class Relation : Object
--- @field exclusive boolean (static) Whether the relation excludes other relation types of the same kind.
--- @field owner Entity The source entity holding this relation instance.
--- @field target Entity The other entity involved in this relation instance.
--- @overload fun(): Relation
local Relation = prism.Object:extend("Relation")
Relation.exclusive = false

--- Generates the inverse relation to this one. Parent -> Child for instance.
--- @return Relation?
function Relation:generateInverse()
   return nil
end

--- Generates a symetric relation to this one. Marriage -> Marraige for the other entity.
--- @return Relation?
function Relation:generateSymmetric()
   return nil
end

--- Gets the base prototype of this relation type.
--- Used to compare or check type consistency.
--- @return Relation
function Relation:getBase()
   local proto = self:isInstance() and getmetatable(self) or self
   while proto and getmetatable(proto) ~= Relation do
      proto = getmetatable(proto)
   end
   return proto
end

return Relation
