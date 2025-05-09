--- The superclass of entitys and cells, holding their components.
--- @class Entity : Object
--- @field components Component[] A table containing all of the entity's component instances. Generated at runtime.
--- @field componentCache table This is a cache for component queries, reducing most queries to a hashmap lookup.
--- @overload fun(): Entity
local Entity = prism.Object:extend("Entity")

--- Constructor for an entity.
--- Initializes and copies the entity's fields from its prototype.
--- @param self Entity
function Entity:__new()
   self.position = prism.Vector2(1, 1)

   local components = self:initialize()
   self.components = {}
   self.componentCache = {}
   self.componentClassNames = {}
   if components then
      for _, component in ipairs(components) do
         component.owner = self
         self:addComponent(component)
      end
   end
end

--
--- Components
--

--- Creates the components for the entity. Override this.
--- @return Component[]
function Entity:initialize()
   return {}
end

--- Adds a component to the entity. This function will check if the component's
--- prerequisites are met and will throw an error if they are not, or if the entity already has the component.
--- @param component Component The component to add to the entity.
function Entity:addComponent(component)
   assert(type(component) == "table", "Expected component got " .. type(component))
   assert(component.is and component:is(prism.Component), "Expected argument component to be of type Component, was " .. (component.className or "table"))
   assert(component:checkRequirements(self), "Unsupported component " .. component.className .. " added to entity!")
   assert(not self:hasComponent(component), "Entity already has component " .. component.className .. "!")

   for _, v in pairs(prism.components) do
      if component:is(v) then
         if self.componentCache[v] then error("Entity already has component " .. v.className .. "!") end
         self.componentCache[v] = component
      end
   end

   component.owner = self
   table.insert(self.components, component)
   self.componentClassNames[component.className] = true
end

--- Removes a component from the entity. This function will throw an error if the
--- component is not present on the entity.
--- @param component Component The component to remove from the entity.
function Entity:removeComponent(component)
   assert(component:is(prism.Component), "Expected argument component to be of type Component!")

   for _, componentPrototype in pairs(prism.components) do
      if component:is(componentPrototype) then
         if not self.componentCache[componentPrototype] then
            error("Entity does not have component " .. componentPrototype.className .. "!")
         end

         for cachedComponent, _ in pairs(self.componentCache) do
            if cachedComponent:is(componentPrototype) then self.componentCache[cachedComponent] = nil end
         end
      end
   end

   for i = 1, #self.components do
      if self.components[i]:is(getmetatable(component)) then
         local component = table.remove(self.components, i)
         component.owner = nil
         return component
      end
   end
end

--- Returns a bool indicating whether the entity has a component of the given type.
--- @param prototype any The prototype of the component to check for.
--- @return boolean hasComponent
function Entity:hasComponent(prototype)
   assert(prototype:is(prism.Component), "Expected argument type to be inherited from Component!")

   return self.componentCache[prototype] ~= nil
end

--- Searches for a component that inherits from the supplied prototype.
--- @generic T
--- @param prototype T The type of the component to return.
--- @return T?
function Entity:getComponent(prototype) return self.componentCache[prototype] end


--- Expects a component, returning it or erroring on nil.
--- @generic T
--- @param prototype T The type of the component to return.
--- @return T
function Entity:expectComponent(prototype)
   ---@diagnostic disable-next-line
   return self.componentCache[prototype] or error("Expected component " .. prototype.className .. "!")
end

return Entity
