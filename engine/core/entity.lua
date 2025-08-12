--- The superclass of entitys and cells, holding their components.
--- @class Entity : Object
--- @field components Component[] A table containing all of the entity's component instances. Generated at runtime.
--- @field relationships table<Relationship, table<Entity, Relationship>>
--- @field componentCache table<Component, Component> This is a cache of prototype -> component for component queries, reducing most queries to a hashmap lookup.
--- @overload fun(): Entity
local Entity = prism.Object:extend("Entity")

--- Constructor for an entity.
--- Initializes and copies the entity's fields from its prototype.
--- @param self Entity
function Entity:__new()
   self.relationships = {}
   self.components = {}
   self.componentCache = {}
end

--
--- Components
--

--- Adds a component to the entity, replacing any existing component of the same type. Will check if the component's
--- prerequisites are met and will throw an error if they are not.
--- @param component Component The component to add to the entity.
--- @return Entity -- The entity, for chaining purposes.
function Entity:give(component)
   -- stylua: ignore start
   assert(prism.Component:is(component), "Component must be Component!")
   assert(component:isInstance(), "Expected an instance of a Component!")

   local requirementsMet, missingComponent = component:checkRequirements(self)
   if not requirementsMet then
      --- @cast missingComponent Component
      local err = "%s was missing requirement %s for %s"
      error(err:format(self.className, missingComponent.className, component.className))
   end

   local base = component:getBase()
   if self:has(base) then
      self:remove(base)
   end

   local proto = getmetatable(component)
   while proto and proto ~= prism.Component do
      self.componentCache[proto] = component
      proto = getmetatable(proto)
   end
   -- stylua: ignore end

   component.owner = self
   table.insert(self.components, component)
   return self
end

--- Removes a component from the entity.
--- @param component Component The component to remove from the entity.
--- @return Entity -- The entity, for chaining purposes.
function Entity:remove(component)
   if component:isInstance() then component = getmetatable(component) end

   if not self:has(component) then
      -- stylua: ignore
      prism.logger.warn("Tried to remove " .. component.className .. " from " .. self:getName() .. " but they didn't have it.")
      return self
   end

   local instance = self:get(component)
   instance.owner = nil
   for i = 1, #self.components do
      if instance == self.components[i] then table.remove(self.components, i) end
   end

   for prototype, cachedInstance in pairs(self.componentCache) do
      if instance == cachedInstance then self.componentCache[prototype] = nil end
   end

   return self
end

--- Gives the component, but only if the entity doesn't already have it.
--- @param component Component The component to ensure.
--- @return Entity -- The entity, for chaining.
function Entity:ensure(component)
   assert(component:isInstance(), "Expected an instance of a Component!")

   if not self:has(getmetatable(component)) then self:give(component) end

   return self
end

--- Checks whether the entity has all of the components given.
--- @param ... Component The list of component prototypes.
--- @return boolean has True if the entity has all of the components given.
function Entity:has(...)
   for _, prototype in ipairs({ ... }) do
      -- stylua: ignore
      prism.Object.assertType(prototype, prism.Component)
      if not self.componentCache[prototype] then return false end
   end

   return true
end

--- Returns the components for the prototypes given, or nil if the entity does not have it.
--- @generic T
--- @param prototype T The type of the component to return.
--- @return T?
--- @return Component? ...
function Entity:get(prototype, ...)
   if prototype == nil then return nil end

   return self.componentCache[prototype], self:get(...)
end

--- Returns the entity's name from their Name component, or the className if it doesn't have one.
--- @return string
function Entity:getName()
   local name = self:get(prism.components.Name)
   return name and name.name or self.className
end

--- Expects a component, returning it or erroring if the entity does not have the component.
--- @generic T
--- @param prototype T The type of the component to return.
--- @return T
function Entity:expect(prototype)
   prism.Object.assertType(prototype, prism.Component)
   --- @cast prototype Object
   return self.componentCache[prototype]
      or error("Expected component " .. prototype.className .. " but it was not present!")
end

--
--- Relationships
--

--- Adds a relationship between this entity and another.
--- Enforces cardinality, symmetry, and exclusivity rules.
--- @param relationship Relationship The relationship instance to add.
--- @param target Entity The target entity of the relationship.
--- @param final boolean? If true this add is part of a symmetry and we shouldn't attempt again.
--- @return Entity
function Entity:addRelationship(relationship, target, final)
   assert(prism.Entity:is(target), "Target must be an Entity!")

   local relType = relationship:getBase()
   self.relationships = self.relationships or {}

   -- Get or create relationship map for this type
   if not self.relationships[relType] then
      self.relationships[relType] = {}
   end

   -- Enforce exclusivity: remove all others of this type
   if relationship.exclusive then
      for other in pairs(self.relationships[relType]) do
         self:removeRelationship(relType, other)
      end
   end

   -- Add the relationship
   self.relationships[relType][target] = relationship

   -- Add symmetric inverse if applicable
   local symmetricRelationship = relationship:generateSymmetric()
   if symmetricRelationship and not final then
      target:addRelationship(symmetricRelationship, self, true)
   end

   local inverseRelationship = relationship:generateInverse()
   if inverseRelationship and not final then
      target:addRelationship(inverseRelationship, self, true)
   end

   return self
end

--- Removes a relationship of a given type with a specific target.
--- @param relationshipType Relationship The relationship type/class (not an instance).
--- @param target Entity The target entity of the relationship.
--- @return Entity
function Entity:removeRelationship(relationshipType, target)
   self.relationships = self.relationships or {}
   if not self.relationships[relationshipType] then return self end

   local relationship
   if self.relationships[relationshipType][target] then
      relationship = self.relationships[relationshipType][target]
      self.relationships[relationshipType][target] = nil
   else
      return self
   end

   -- Remove symmetric inverse if needed
   local symmetric = relationship:generateSymmetric()
   if symmetric then
      target:removeRelationship(symmetric:getBase(), self)
   end

   local inverse = relationship:generateInverse()
   if inverse then
      target:removeRelationship(inverse:getBase(), self)
   end

   return self
end

--- @param relationshipType Relationship
function Entity:removeAllRelationships(relationshipType)
   if not self.relationships[relationshipType] then return self end

   for entity in pairs(self.relationships[relationshipType]) do
      self:removeRelationship(relationshipType, entity)
   end
end

--- Checks whether this entity has a relationship of a given type with a specific target.
--- @param relationshipType Relationship The relationship type/class.
--- @param target Entity The target entity to check for.
--- @return boolean
function Entity:hasRelationship(relationshipType, target)
   self.relationships = self.relationships or {}
   if not self.relationships[relationshipType] then return false end
   return self.relationships[relationshipType][target] ~= nil
end

--- Gets all relationships of a given type.
--- @param relationshipType Relationship The relationship type/class.
--- @return table<Entity, Relationship>
function Entity:getRelationships(relationshipType)
   return self.relationships[relationshipType] or {}
end

return Entity