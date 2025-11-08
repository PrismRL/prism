--- The superclass of entitys and cells, holding their components.
--- @class Entity : Object
--- @field components Component[] A table containing all of the entity's component instances. Generated at runtime.
--- @field relations table<Relation, table<Entity, Relation>>
--- @field componentCache table<Component, Component> This is a cache of prototype -> component for component queries, reducing most queries to a hashmap lookup.
--- @field protected __factory function The factory this entity was initialized from.
--- @field private __diff table A diff from the factory this entity was initialized from, only used during serialization.
--- @overload fun(): Entity
local Entity = prism.Object:extend("Entity")

--- Constructor for an entity.
--- Initializes and copies the entity's fields from its prototype.
--- @param self Entity
function Entity:__new()
   self.relations = {}
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
--- Relations
--

--- Adds a relation between this entity and another.
--- Enforces cardinality, symmetry, and exclusivity rules.
--- @param relation Relation The relation instance to add.
--- @param target Entity The target entity of the relation.
--- @param final boolean? If true this add is part of a symmetry and we shouldn't attempt again.
--- @return Entity -- self, for chaining.
function Entity:addRelation(relation, target, final)
   assert(prism.Entity:is(target), "Target must be an Entity!")

   local relType = relation:getBase()
   self.relations = self.relations or {}

   -- Get or create relation map for this type
   if not self.relations[relType] then self.relations[relType] = {} end

   -- Enforce exclusivity: remove all others of this type
   if relation.exclusive then
      for other in pairs(self.relations[relType]) do
         self:removeRelation(relType, other)
      end
   end

   -- Add the relation
   self.relations[relType][target] = relation

   -- Add symmetric inverse if applicable
   local symmetricRelation = relation:generateSymmetric()
   if symmetricRelation and not final then
      target:addRelation(symmetricRelation, self, true)
   end

   local inverseRelation = relation:generateInverse()
   if inverseRelation and not final then
      target:addRelation(inverseRelation, self, true)
   end

   return self
end

--- Removes a relation of a given type with a specific target.
--- @param relationType Relation The relation type/class (not an instance).
--- @param target Entity The target entity of the relation.
--- @return Entity -- self, for chaining.
function Entity:removeRelation(relationType, target)
   self.relations = self.relations or {}
   if not self.relations[relationType] then return self end

   local relation
   if self.relations[relationType][target] then
      relation = self.relations[relationType][target]
      self.relations[relationType][target] = nil
   else
      return self
   end

   -- Remove symmetric inverse if needed
   local symmetric = relation:generateSymmetric()
   if symmetric then target:removeRelation(symmetric:getBase(), self) end

   local inverse = relation:generateInverse()
   if inverse then target:removeRelation(inverse:getBase(), self) end

   return self
end

--- Removes all relations with the given type.
--- @param relationType Relation
function Entity:removeAllRelations(relationType)
   if not self.relations[relationType] then return self end

   for entity in pairs(self.relations[relationType]) do
      self:removeRelation(relationType, entity)
   end

   return self
end

--- Checks whether this entity has a relation.
--- @param relationType Relation The relation prototype.
--- @param target? Entity An optional entity to check. If nil, will check if the entity has any relation with the type.
--- @return boolean -- True if the entity has the relation.
function Entity:hasRelation(relationType, target)
   self.relations = self.relations or {}
   if not self.relations[relationType] then return false end
   return (target and self.relations[relationType][target] ~= nil)
      or next(self.relations[relationType]) ~= nil
end

--- Gets all relations of a given type.
--- @param relationType Relation The relation type/class.
--- @return table<Entity, Relation>
function Entity:getRelations(relationType)
   return self.relations[relationType] or {}
end

--- Gets the first/random entity with the given relation. This is mostly useful for exclusive relations.
--- @param relationType Relation The relation prototype.
--- @return Entity?
function Entity:getRelation(relationType)
   local entity = next(self.relations[relationType] or {})
   return entity
end

function Entity:clone()
   local clone = getmetatable(self)()

   for _, comp in pairs(self.components) do
      print(comp.className)
      --- @cast comp Component
      clone:give(comp:clone())
   end

   clone.__factory = self.__factory
   return clone
end

return Entity
