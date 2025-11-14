--- @class IQueryable
--- @field query fun(self, ...:Component): Query

--- Represents a query over actors in an `ActorStorage`, filtering by required components and optionally by position.
--- Supports fluent chaining via `with()` and `at()` methods.
--- Provides `iter()`, `each()`, and `gather()` for iteration and retrieval.
--- @class Query : Object
--- @field private requiredComponents table<Component, boolean> A set of required component types.
--- @field private requiredComponentsList Component[] Ordered list of required component types.
--- @field private requiredComponentsCount integer The number of required component types.
--- @field private requiredPosition Vector2? Optional position filter.
local Query = prism.Object:extend "Query"

--- @param storage ActorStorage The storage system to query from.
--- @param ... Component A variable number of component types to require.
function Query:__new(storage, ...)
   self.storage = storage

   self.requiredComponents = {}
   self.requiredComponentsList = {}
   self.requiredComponentsCount = 0

   self:with(...)
   self.requiredPosition = nil

   self.relationInfo = {}
end

--- Adds required component types to the query.
--- Can be called multiple times to accumulate components.
--- @param ... Component A variable number of component types.
--- @return Query query Returns self to allow method chaining.
function Query:with(...)
   local req = { ... }

   for _, component in ipairs(req) do
      assert(
         not self.requiredComponents[component],
         "Multiple component of the same type added to query!"
      )

      self.requiredComponentsCount = self.requiredComponentsCount + 1
      table.insert(self.requiredComponentsList, component)

      self.requiredComponents[component] = true
   end

   return self
end

function Query:relation(owner, relationType)
   table.insert(self.relationInfo, {
      owner = owner,
      prototype = relationType,
   })

   return self
end

--- Restricts the query to actors at a specific position.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return Query query Returns self to allow method chaining.
function Query:at(x, y)
   self.requiredPosition = prism.Vector2(x, y)

   return self
end

--- Applies a Target filter to this query.
--- Automatically adds required components from the Target.
--- The query will only return actors that validate against this Target.
--- @param target Target
--- @param level Level
--- @param owner Actor
--- @param previousTargets any[]?
--- @return Query
function Query:target(target, level, owner, previousTargets)
   -- Merge Target's required components into the query
   for componentType in pairs(target.requiredComponents) do
      if not self.requiredComponents[componentType] then self:with(componentType) end
   end

   -- Set the validator
   self.targetValidator = function(actor)
      return target:validate(level, owner, actor, previousTargets)
   end

   return self
end

local components = {}

-- Helper function to get components for an actor
--- @param actor Actor
--- @param requiredComponentsList Component[]
--- @return ...:Component
local function getComponents(actor, requiredComponentsList)
   local n = 0
   for _, component in ipairs(requiredComponentsList) do
      n = n + 1
      components[n] = actor:get(component)
   end
   return unpack(components, 1, n)
end

local function lazyIntersectSets(sets, counts, requiredComponentsList)
   if #sets == 0 then
      return function()
         return nil
      end
   end

   -- Find smallest set by counts (counts[i] corresponds to sets[i])
   local smallestIndex = 1
   local smallestCount = counts[1]
   for i = 2, #sets do
      if counts[i] < smallestCount then
         smallestCount = counts[i]
         smallestIndex = i
      end
   end

   local smallestSet = sets[smallestIndex]

   local otherSets = {}
   for i = 1, #sets do
      if i ~= smallestIndex then table.insert(otherSets, sets[i]) end
   end

   local actor = nil
   return function()
      while true do
         actor = next(smallestSet, actor)
         if not actor then return nil end

         local inAll = true
         for _, set in ipairs(otherSets) do
            if not set[actor] then
               inAll = false
               break
            end
         end

         if inAll then return actor end
      end
   end
end

--- Returns an iterator function over all matching actors.
--- The iterator yields `(actor, ...components)` for each match.
--- Selection is optimized depending on number of required components and presence of position.
--- @return fun(): Actor?, ...:Component?
function Query:iter()
   local storage = self.storage
   local requiredComponents = self.requiredComponents

   local sets = {}
   local counts = {}

   -- Position filter — assign count=0 to prioritize as smallest
   if self.requiredPosition then
      local posSet = storage:getSparseMap():get(self.requiredPosition:decompose())
      if not posSet then
         return function()
            return nil
         end
      end
      table.insert(sets, posSet)
      table.insert(counts, 0)
   end

   -- Relations — also count=1 to prioritize
   for _, rel in ipairs(self.relationInfo) do
      local relSet = rel.owner:getRelations(rel.prototype)
      if not relSet then
         return function()
            return nil
         end
      end
      table.insert(sets, relSet)
      table.insert(counts, 0)
   end

   -- Component caches — use actual counts from storage
   for componentType in pairs(requiredComponents) do
      local cache = storage:getComponentCache(componentType)
      if not cache then
         return function()
            return nil
         end
      end
      table.insert(sets, cache)
      table.insert(counts, storage:getComponentCount(componentType))
   end

   -- Fallback: if no sets, include all actors
   if #sets == 0 then
      table.insert(sets, storage:getAllActorIDs())
      table.insert(counts, #storage:getAllActors()) -- or just use length
   end

   local intersectionIter = lazyIntersectSets(sets, counts, self.requiredComponentsList)

   return function()
      while true do
         local actor = intersectionIter()
         if not actor then return nil end

         if not self.targetValidator or self.targetValidator(actor) then
            return actor, getComponents(actor, self.requiredComponentsList)
         end
      end
   end
end

--- Gathers all matching results into a list.
--- @param results? Actor[] Optional table to insert results into.
--- @return Actor[] actors The populated list of results.
function Query:gather(results)
   local results = results or {}

   local iterator = self:iter()

   while true do
      local result = iterator()
      if not result then break end

      table.insert(results, result)
   end

   return results
end

local function eachBody(fn, ...)
   local first = ...
   if not first then return false end

   fn(...)
   return true
end

--- Applies a function to each matching actor and its components.
--- @param fn fun(actor: Actor, ...:Component) The function to apply to each result.
function Query:each(fn)
   local iter = self:iter()
   while eachBody(fn, iter()) do
   end
end

--- Returns the first matching actor and its components.
--- @return Actor? actor The first matching actor, or nil if no actor matches.
function Query:first()
   local iterator = self:iter()
   local actor = iterator() -- Get the first result from the iterator
   if actor then return actor end

   return nil -- Return nil if no actor was found
end

return Query
