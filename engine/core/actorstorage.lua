--- @alias ComponentCache table<Component, table<Actor, boolean>>

--- ActorStorage is a container class used to manage a collection of Actor objects.
--- It maintains internal structures for efficient lookup, spatial queries, and component caching.
---
--- This class is primarily used internally by the Level class, and most users will interact with
--- it through Level methods. However, it can also be used in other specialized contexts such as
--- inventory systems or sensory subsystems (e.g., tracking visible actors).
---
--- @class ActorStorage : Object, IQueryable
--- @field private actors                      Actor[]                     -- Ordered list of all actors.
--- @field private ids                         SparseArray                 -- Sparse array used to assign unique IDs to actors.
--- @field private actorToID                   table<Actor, integer?>      -- Map from actors to their assigned IDs, also useful as a set for quick membership checks.
--- @field private sparseMap                   SparseMap                   -- Spatial map storing actor positions.
--- @field private componentCache              ComponentCache              -- Cached map of actors per component.
--- @field private componentCounts             table<Component, number>    -- Count of actors per component.
--- @field private insertSparseMapCallback     function                    -- Optional callback for insert events.
--- @field private removeSparseMapCallback     function                    -- Optional callback for removal events.
--- @overload fun(insertSparseMapCallback?: function, removeSparseMapCallback?: function): ActorStorage
local ActorStorage = prism.Object:extend("ActorStorage")

--- The constructor for the 'ActorStorage' class.
--- Initializes the list, spatial map, and component cache.
function ActorStorage:__new(insertSparseMapCallback, removeSparseMapCallback)
   self.actors = {}
   self.ids = prism.SparseArray()
   self.actorToID = {}
   self.sparseMap = prism.SparseMap()
   self.componentCache = {}
   self.componentCounts = {}
   self:setCallbacks(insertSparseMapCallback, removeSparseMapCallback)
end

function ActorStorage:setCallbacks(insertCallback, removeCallback)
   self.insertSparseMapCallback = insertCallback or function() end
   self.removeSparseMapCallback = removeCallback or function() end
end

--- Adds an actor to the storage, updating the spatial map and component cache.
--- @param actor Actor The actor to add.
function ActorStorage:addActor(actor)
   assert(actor:is(prism.Actor), "Tried to add a non-actor object to actor storage!")
   if self.actorToID[actor] then return end

   table.insert(self.actors, actor) -- Main structure
   local id = self.ids:add(actor) -- Assign IDs
   self.actorToID[actor] = id
   self:updateComponentCache(actor) -- Accelerate component queries
   self:insertSparseMapEntries(actor) -- hashmap<(x,y)> change events through optional callbacks
end

--- Removes an actor from the storage, updating the spatial map and component cache.
--- @param actor Actor The actor to remove.
function ActorStorage:removeActor(actor)
   assert(actor:is(prism.Actor), "Tried to remove a non-actor object from actor storage!")
   if not self.actorToID[actor] then return end

   self:_removeComponentCache(actor)
   self:removeSparseMapEntries(actor)

   for k, v in ipairs(self.actors) do
      if v == actor then
         table.remove(self.actors, k)
         break
      end
   end

   self.ids:remove(self.actorToID[actor])
   self.actorToID[actor] = nil
end

--- Retrieves the unique ID associated with the specified actor.
--- Note: IDs are unique to actors within the ActorStorage but may be reused
--- when indices are freed.
--- @param actor Actor The actor whose ID is to be retrieved.
--- @return integer? The unique ID of the actor, or nil if the actor is not found.
function ActorStorage:getID(actor)
   return self.actorToID[actor]
end

--- Returns whether the storage contains the specified actor.
--- @param actor Actor The actor to check.
--- @return boolean True if the storage contains the actor, false otherwise.
function ActorStorage:hasActor(actor)
   return self.actorToID[actor] ~= nil
end

--- @param ... Component
--- @return Query
function ActorStorage:query(...)
   return prism.Query(self, ...)
end

--- Removes the specified actor from the spatial map.
--- @param actor Actor The actor to remove.
function ActorStorage:removeSparseMapEntries(actor)
   local pos = actor:getPosition()
   self.sparseMap:remove(pos.x, pos.y, actor)
   self.removeSparseMapCallback(pos.x, pos.y, actor)
end

--- Inserts the specified actor into the spatial map.
--- @param actor Actor The actor to insert.
function ActorStorage:insertSparseMapEntries(actor)
   local pos = actor:getPosition()
   self.sparseMap:insert(pos.x, pos.y, actor)
   self.insertSparseMapCallback(pos.x, pos.y, actor)
end

--- Updates the component cache for the specified actor.
--- @param actor Actor The actor to update the component cache for.
function ActorStorage:updateComponentCache(actor)
   for _, component in pairs(prism.components) do
      if not self.componentCache[component] then
         self.componentCache[component] = {}
         self.componentCounts[component] = 0
      end

      local hasComp = actor:hasComponent(component)
      local cached = self.componentCache[component][actor]

      if hasComp and not cached then
         self.componentCache[component][actor] = true
         self.componentCounts[component] = self.componentCounts[component] + 1
      elseif not hasComp and cached then
         self.componentCache[component][actor] = nil
         self.componentCounts[component] = self.componentCounts[component] - 1
      end
   end
end

--- Removes the specified actor from the component cache.
--- @param actor Actor The actor to remove from the component cache.
--- @private
function ActorStorage:_removeComponentCache(actor)
   for _, component in pairs(prism.components) do
      if self.componentCache[component] and self.componentCache[component][actor] then
         self.componentCache[component][actor] = nil
         self.componentCounts[component] = self.componentCounts[component] - 1
      end
   end
end

--- Merges another ActorStorage instance with this one.
--- @param other ActorStorage The other ActorStorage instance to merge with this one.
function ActorStorage:merge(other)
   assert(other:is(ActorStorage), "Tried to merge a non-ActorStorage object with actor storage!")

   for _, actor in ipairs(other.actors) do
      self:addActor(actor)
   end
end

function ActorStorage:onDeserialize()
   self:setCallbacks(self.insertSparseMapCallback, self.removeSparseMapCallback)
   for _, actor in pairs(self.actors) do
      self:insertSparseMapEntries(actor)
   end
end

--- Retrieves the component cache for a specific component.
--- This is a read-only operation, and the returned table should not be modified directly.
--- @param component Component The component to query.
--- @return table<Actor, boolean>|nil cache The component cache for the specified component.
function ActorStorage:getComponentCache(component)
   return self.componentCache[component]
end

--- Retrieves the sparse map.
--- This is a read-only operation. The returned SparseMap should not be modified directly.
--- @return SparseMap The sparse map of actor positions.
function ActorStorage:getSparseMap()
   return self.sparseMap
end

--- Retrieves all actors in the storage.
--- This is a read-only operation. The returned list of actors should not be modified directly.
--- @return Actor[] actors A list of all actors in the storage.
function ActorStorage:getAllActors()
   return self.actors
end

--- Retrieves the count of a specific component.
--- @param component Component The component to query.
--- @return integer The count of the specified component.
function ActorStorage:getComponentCount(component)
   return self.componentCounts[component] or 0
end

return ActorStorage
