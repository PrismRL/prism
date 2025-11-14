--- Represents a single game level, managing the map, actors, systems,
--- scheduling, and cached data for FOV and pathfinding. Also handles the
--- turn-based game loop via `run` and `step`.
--- @class Level : Object, IQueryable, SpectrumAttachable
---
--- @field actorStorage ActorStorage                    Stores all actors; supports lookup and indexing.
--- @field map Map                                      The static layout of terrain, walls, etc.
--- @field RNG RNG                                      Level-local RNG; supports deterministic behavior.
--- @field private systemManager SystemManager          Manages systems, dispatches events, controls lifecycle.
--- @field private scheduler Scheduler                  Controls actor turn order in the game loop.
--- @field private turnHandler TurnHandler                     Function to perform an actor's turn in the level.
--- @field private opacityCache BooleanBuffer           Cached opacity grid for FOV and lighting.
--- @field private passableCache CascadingBitmaskBuffer Cached passability grid for pathfinding.
--- @field private decision ActionDecision              Temporary storage for the current actor’s choice.
--- @field private _passabilityQuery Query?             A cache'd passability query to avoid garbage.
--- @field private _opacityQuery Query?                 A cache'd opacity query to avoid garbage.
--- @overload fun(builder: LevelBuilder): Level
local Level = prism.Object:extend("Level")

Level.serializationBlacklist = {
   opacityCache = true,
   passableCache = true,
}

--- Constructor for the Level class.
--- @param builder LevelBuilder A builder to construct the level from.
function Level:__new(builder)
   self.systemManager = prism.SystemManager(self)
   self.actorStorage = prism.ActorStorage(self:sparseMapCallback(), self:sparseMapCallback())
   self.scheduler = builder.scheduler or prism.schedulers.SimpleScheduler()
   self.turnHandler = builder.turnHandler or prism.TurnHandler()
   self.RNG = prism.RNG(builder.seed or love.timer.getTime())
   self.debug = false

   --- @diagnostic disable-next-line
   local map, actors = builder:getEntities()
   self.opacityCache = prism.BooleanBuffer(map.w, map.h) -- holds a cache of opacity to speed up fov calcs
   self.passableCache = prism.CascadingBitmaskBuffer(map.w, map.h, builder.maximumActorSize or 4) -- holds a cache of passability to speed up a* calcs
   self.map = map

   self:initialize(actors, builder.systems)
end

--- Initialize a builder for a Level.
--- @return LevelBuilder
function Level.builder()
   return prism.LevelBuilder()
end

--- @param actors Actor[]
--- @param systems System[]
--- @private
function Level:initialize(actors, systems)
   assert(#actors > 0, "A level must be initialized with at least one actor!")

   prism.logger.debug("Level is initializing with", #actors, "actors and", #systems, "systems...")

   self:initializeOpacityCache()
   self:initializePassabilityCache()

   for i = 1, #systems do
      self:addSystem(systems[i])
   end

   self.systemManager:initialize(self)

   local actor = table.remove(actors)
   while actor do
      self:addActor(actor)
      actor = table.remove(actors)
   end

   self.systemManager:postInitialize(self)
end

--- Runs the level by processing actors from the scheduler. :lua:class:`LevelState`
--- initializes a coroutine with this function to run the game loop.
function Level:run()
   -- TODO: Fix this
   if self.decision then
      local actor = self.decision.actor

      self.turnHandler:handleTurn(self, actor, actor:expect(prism.components.Controller))

      self.systemManager:onTurnEnd(self, actor)
   end

   while not self.scheduler:empty() do
      self:step()
   end
end

--- Steps through one turn. This is usually called by Level:run().
function Level:step()
   local schedNext = self.scheduler:next()

   assert(
      type(schedNext) == "string" or prism.Actor:is(schedNext),
      "Found a scheduler entry that wasn't an actor or string."
   )

   local actor = schedNext
   ---@cast actor Actor
   self.systemManager:onTurn(self, actor)
   self.turnHandler:handleTurn(self, actor, actor:expect(prism.components.Controller))
   self.systemManager:onTurnEnd(self, actor)
end

--- Yields to the main 'thread', a coroutine in this case. This is called in run, and a few systems. Any time you want
--- the interface to update you should call this. Avoid calling coroutine.yield directly,
--- as this function will call the onYield method on all systems.
--- @param message Message
--- @return Decision|nil
function Level:yield(message)
   self.systemManager:onYield(self, message)
   if prism.Decision:is(message) then
      ---@cast message ActionDecision
      self.decision = message
   end
   local _, ret = coroutine.yield(message)
   self.decision = nil
   return ret
end

--- Yields a debug message if debug is true.
function Level:debugYield(message)
   prism.logger.debug(message)
   if self.debug then self:yield(prism.messages.DebugMessage(message)) end
end

--- Trigger a custom event on systems in the level.
--- @param eventName string
--- @param ... any
function Level:trigger(eventName, ...)
   self.systemManager:trigger(eventName, ...)
end

--
-- Systems
--

--- Attaches a system to the level. Will error if the level already has the system, or if
--- the level is missing required systems for the given one.
--- @param system System The system to add.
function Level:addSystem(system)
   prism.logger.debug("System", system.className, "was added to level")
   self.systemManager:addSystem(system)
end

--- Gets a system by prototype.
--- @generic T
--- @param prototype T The prototype of the system to get.
--- @return T? system The system of the given prototype, or nil if not found.
function Level:getSystem(prototype)
   return self.systemManager:getSystem(prototype)
end

--
-- Actor
--

--- Retrieves the unique ID associated with the specified actor.
--- Note: IDs are unique to actors within the Level but may be reused
--- when indices are freed.
--- @param actor Actor The actor whose ID is to be retrieved.
--- @return integer? -- The unique ID of the actor, or nil if the actor is not found.
function Level:getID(actor)
   return self.actorStorage:getID(actor)
end

--- Adds an actor to the level. Handles updating the component cache and
--- inserting the actor into the sparse map. It will also add the actor to the
--- scheduler if it has a controller. Errors if the actor is already in a level.
--- @param actor Actor The actor to add.
--- @param x integer? The x coordinate to place the actor at.
--- @param y integer? The y coordinate to place the actor at.
function Level:addActor(actor, x, y)
   assert(not actor.level, "Actor is already in a level!")

   if x and y then
      if actor:getPosition() then
         actor:give(prism.components.Position(prism.Vector2(x, y)))
      else
         prism.logger.warn(
            "Attempted to add",
            actor:getName(),
            "to level",
            "at position",
            x,
            ",",
            y,
            "but it did not have a position component!"
         )
      end
   end

   prism.logger.debug("Actor", actor:getName(), "was added to level")
   actor.level = self

   self.actorStorage:addActor(actor)
   if actor:has(prism.components.Controller) then self.scheduler:add(actor) end

   self.systemManager:onActorAdded(self, actor)
end

--- Removes an actor from the level. Handles updating the component cache and
--- removing the actor from the sparse map. It will also remove the actor from
--- the scheduler if it has a controller.
--- @param actor Actor The actor to remove.
function Level:removeActor(actor)
   prism.logger.debug("Actor", actor:getName(), "was removed from level")
   actor.level = nil
   self.actorStorage:removeActor(actor)
   self.scheduler:remove(actor)
   self.systemManager:onActorRemoved(self, actor)
end

--- Removes a component from an actor. It handles
--- updating the component cache and the opacity cache.
--- @param actor Actor The actor to remove the component from.
--- @param component Component The component to remove.
--- @private
function Level:__removeComponent(actor, component)
   self.actorStorage:updateComponentCache(actor)
   self:_updateSparseMap(actor)
   if prism.components.Controller:is(component) then self.scheduler:remove(actor) end
end

--- Adds a component to an actor. It handles updating
--- the component cache and the opacity cache. You can do this manually, but
--- it's easier to use this function.
--- @param actor Actor The actor to add the component to.
--- @param component Component The component to add.
--- @private
function Level:__addComponent(actor, component)
   self.actorStorage:updateComponentCache(actor)
   self:_updateSparseMap(actor)
   if prism.components.Controller:is(component) then self.scheduler:add(actor) end
end

function Level:_updateSparseMap(actor)
   self.actorStorage:removeSparseMapEntries(actor)
   self.actorStorage:insertSparseMapEntries(actor)
end
--- Moves an actor to the given position. This function doesn't do any checking
--- for overlaps or collisions.
--- @param actor Actor The actor to move.
--- @param pos Vector2 The position to move the actor to.
function Level:moveActor(actor, pos)
   local curpos = actor:getPosition()
   if not curpos then return end -- warn here?

   assert(prism.Vector2:is(pos), "Expected a Vector2 for pos in Level:moveActor.")
   assert(
      math.floor(pos.x) == pos.x and math.floor(pos.y) == pos.y,
      "Expected integer values for pos in Level:moveActor."
   )

   -- if the actor isn't in the level, we don't do anything
   if not self:hasActor(actor) then return end

   self.systemManager:beforeMove(self, actor, curpos, pos)

   -- we copy the position here so that the caller doesn't have to worry about
   -- allocating a new table
   ---@diagnostic disable-next-line
   actor:expect(prism.components.Position)._position = pos:copy()
   self:_updateSparseMap(actor)

   self.systemManager:onMove(self, actor, curpos, pos)
end

--- Checks if the action is valid and can be executed.
--- @param action Action
--- @return boolean canPerform True if the action can be performed, false otherwise.
--- @return string? error An optional error message, if the action cannot be performed.
function Level:canPerform(action)
   --- @diagnostic disable-next-line
   if action.abstract then return false, "Action is an abstract action!" end
   if self.decision and action:isReaction() then
      return false, "Action is a reaction and can not be made as a decision!"
   end

   if not self:hasActor(action.owner) then return false, "Actor not inside the level!" end

   local success, err = action:hasRequisiteComponents(action.owner)
   if not success then return false, "Actor is missing requisite component: " .. err end

   --- @diagnostic disable-next-line
   success, err = action:__validateTargets(self)
   if not success then return success, err end

   --- @diagnostic disable-next-line
   return action:canPerform(self, unpack(action.targetObjects))
end

--- Executes an Action, updating the level's state and triggering any events through the systems
--- attached to the Actor or Level respectively. It also updates the 'Scheduler' if the action isn't
--- a reaction or free action. Lastly, it calls the 'onAction' method on the 'Cell' that the 'Actor' is
--- standing on.
--- @param action Action The action to perform.
--- @param silent boolean? If true this action emits no events.
function Level:perform(action, silent)
   -- this happens sometimes if one effect kills an entity and a second effect
   -- tries to damage it for instance.
   if not self:hasActor(action.owner) then return end

   assert(self:canPerform(action))
   local owner = action.owner

   prism.logger.debug("Actor", owner:getName(), "is about to perform", action.className)
   if not silent then self.systemManager:beforeAction(self, owner, action) end
   ---@diagnostic disable-next-line
   action:perform(self, unpack(action.targetObjects))
   self:yield(prism.messages.ActionMessage(action))
   if not silent then self.systemManager:afterAction(self, owner, action) end
end

--- Performs an action if Level:canPerform(action) is true.
--- @param action Action The action to perform.
--- @param silent boolean? If true this action emits no events.
--- @return boolean performed True if the action was performed.
--- @return string? err A string error message if the action was not performed.
function Level:tryPerform(action, silent)
   local can, err = self:canPerform(action)
   if can then self:perform(action, silent) end
   return can, err
end

--
-- ActorStorage Wrapper
--

--- Returns true if the level contains the given actor, false otherwise. A thin wrapper
--- over the inner ActorStorage.
--- @param actor Actor The actor to check for.
--- @return boolean hasActor True if the level contains the given actor, false otherwise.
function Level:hasActor(actor)
   return self.actorStorage:hasActor(actor)
end

--- This method returns an iterator that will return all actors in the level
--- that have the given components. If no components are given it iterate over
--- all actors. A thin wrapper over the inner ActorStorage.
--- @param ... any The components to filter by.
--- @return Query query An iterator that returns the next actor that matches the given components.
function Level:query(...)
   return self.actorStorage:query(...)
end

function Level:computeFOV(origin, maxDepth, callback)
   prism.computeFOV(self, origin, maxDepth, callback)
end

--- Sets the cell at the given position to the given cell.
--- @param x number The x component of the position to set.
--- @param y number The y component of the position to set.
--- @param cell Cell The cell to set.
function Level:setCell(x, y, cell)
   self.map:set(x, y, cell)
   self:updateCaches(x, y)
end

--- Gets the cell at the given position.
--- @param x number The x component of the position to get.
--- @param y number The y component of the position to get.
--- @return Cell -- The cell at the given position.
function Level:getCell(x, y)
   return self.map:get(x, y)
end

--- Gets the cell at an actor's position.
--- @param actor Actor An actor in the level.
--- @return Cell -- The cell at the actor's position.
function Level:getActorCell(actor)
   assert(actor.level == self, "Attempted to get the cell of an actor not in the level!")

   --- @diagnostic disable-next-line
   return self:getCell(actor:expectPosition():decompose())
end

--- Is there a cell at this x, y? Part of the interface with LevelBuilder
--- @param x integer The x component to check if in bounds.
--- @param y integer The x component to check if in bounds.
--- @return boolean
function Level:inBounds(x, y)
   return x > 0 and x <= self.map.w and y > 0 and y <= self.map.h
end

--- Iteration wrapper for the map.
--- @return fun(): number, number, Cell
function Level:eachCell()
   return self.map:each()
end

--- @param x integer
--- @param y integer
function Level:updateCaches(x, y)
   self:updateOpacityCache(x, y)
   self:updatePassabilityCache(x, y)
end

--- Returns true if the cell at the given position is passable, false otherwise. Considers
--- actors in the sparse map as well as the cell's passable property.
--- @param x number The x component of the position to check.
--- @param y number The y component of the position to check.
--- @param mask Bitmask The collision mask for checking passability.
--- @param size? integer The size of the actor.
function Level:getCellPassable(x, y, mask, size)
   local cellMask = self.passableCache:getMask(x, y, size or 1)
   return prism.Collision.checkBitmaskOverlap(mask, cellMask)
end

--- @param x integer
--- @param y integer
--- @param actor Actor
--- @param mask Bitmask
--- @return boolean -- True if the cell is passable, false otherwise.
function Level:getCellPassableByActor(x, y, actor, mask)
   local collider = actor:get(prism.components.Collider)
   if not collider then return true end

   self.actorStorage:removeSparseMapEntries(actor)
   local result = self:getCellPassable(x, y, mask, collider:getSize())
   self.actorStorage:insertSparseMapEntries(actor)

   return result
end

--- Initialize the passable cache. This should be called after the level is
--- created and before the game loop starts. It will initialize the passable
--- cache with the cell passable cache. This is handled automatically by the
--- Level class.
--- @private
function Level:initializePassabilityCache()
   for x = 1, self.map.w do
      for y = 1, self.map.h do
         self.passableCache:setMask(x, y, self.map.passableCache:getMask(x, y))
      end
   end
end

-- We reuse query objects in cases like this. This happens a lot and
-- creating a new query object each time is bad for the GC.
--- @type Query|nil
local passabilityQuery = nil

--- Updates the passability cache at the given position. This should be called
--- whenever an actor moves or a cell's passability changes. This is handled
--- automatically by the Level class.
--- @param x number The x component of the position to update.
--- @param y number The y component of the position to update.
--- @private
function Level:updatePassabilityCache(x, y)
   local mask = self.map.passableCache:getMask(x, y)

   self._passabilityQuery = self._passabilityQuery or self:query(prism.components.Collider)
   self._passabilityQuery:at(x, y)

   for _, collider in self._passabilityQuery:iter() do
      --- @cast collider Collider
      mask = bit.band(collider:getMask(), mask)
   end

   self.passableCache:setMask(x, y, mask)
end

--- Returns true if the cell at the given position is opaque, false otherwise.
--- @param x number The x component of the position to check.
--- @param y number The y component of the position to check.
--- @return boolean -- True if the cell is opaque, false otherwise.
function Level:getCellOpaque(x, y)
   return self.opacityCache:get(x, y)
end

--- Returns the opacity cache for the level. This generally shouldn't be used
--- outside of systems that need to know about opacity.
--- @return BooleanBuffer map The opacity cache for the level.
function Level:getOpacityCache()
   return self.opacityCache
end

--- Initialize the opacity cache. This should be called after the level is
--- created and before the game loop starts. It will initialize the opacity
--- cache with the cell opacity cache. This is handled automatically by the
--- Level class.
--- @private
function Level:initializeOpacityCache()
   for x = 1, self.map.w do
      for y = 1, self.map.h do
         local opaque = self.map.opacityCache:get(x, y)
         self.opacityCache:set(x, y, opaque)
      end
   end
end

--- Updates the opacity cache at the given position. This should be called
--- whenever an actor moves or a cell's opacity changes. This is handled
--- automatically by the Level class.
--- @param x number The x component of the position to update.
--- @param y number The y component of the position to update.
--- @private
function Level:updateOpacityCache(x, y)
   self._opacityQuery = self._opacityQuery or self:query(prism.components.Opaque)
   self._opacityQuery:at(x, y)

   local opaque = false
   for _ in self._opacityQuery:iter() do
      opaque = true
      break
   end

   opaque = opaque or self.map.opacityCache:get(x, y)
   self.opacityCache:set(x, y, opaque)
   self.systemManager:afterOpacityChanged(self, x, y)
end

--- Finds a path between two positions.
---@param start Vector2 The starting position.
---@param goal Vector2 The goal position.
---@param actor Actor The actor to find a path for.
---@param mask Bitmask
---@param minDistance? integer The minimum distance away to pathfind to.
---@param distanceType? DistanceType An optional distance type to use for calculating the minimum distance. Defaults to prism._defaultDistance.
---@return Path? path A path to the goal, or nil if a path could not be found or the start is already at the minimum distance.
function Level:findPath(start, goal, actor, mask, minDistance, distanceType)
   if not self.map:isInBounds(start.x, start.y) or not self.map:isInBounds(goal.x, goal.y) then
      return
   end

   local collider = actor:get(prism.components.Collider)
   local size = collider and collider:getSize() or 1
   local function passableCallback(x, y)
      return self:getCellPassable(x, y, mask, size)
   end

   self.actorStorage:removeSparseMapEntries(actor)
   local path = prism.astar(start, goal, passableCallback, nil, minDistance, distanceType)
   self.actorStorage:insertSparseMapEntries(actor)

   return path
end

--- Returns a list of all actors that are within the given range of the given
--- position. The type parameter determines the type of range to use. Currently
--- only "fov" and "box" are supported. The fov type uses a field of view
--- algorithm to determine what actors are visible from the given position. The
--- box type uses a simple box around the given position.
--- @param self Level
--- @param type "box"|"fov" The type of range to use.
--- @param position Vector2 The position to check from.
--- @param range number The range to check.
--- @return SparseGrid? fov
--- @return Actor[]? actors A list of actors within the given range.
function Level:getAOE(type, position, range)
   local seenActors = {}

   local tempv = prism.Vector2()
   if type == "fov" then
      local fov = prism.SparseGrid()

      prism.computeFOV(self, position, range, function(x, y)
         fov:set(x, y, true)
      end)

      for actorInAOE in self:query():iter() do
         local pos = actorInAOE:getPosition(tempv)
         if pos then
            local x, y = pos:decompose()
            if fov:get(x, y) then table.insert(seenActors, actorInAOE) end
         end
      end

      return fov, seenActors
   elseif type == "box" then
      for actorInAOE in self:query():iter() do
         if actorInAOE:getPosition(tempv) then
            if actorInAOE:getRangeVec(position) <= range then
               table.insert(seenActors, actorInAOE)
            end
         end
      end

      return nil, seenActors
   end
end

--- @private
function Level:sparseMapCallback()
   return function(x, y, actor)
      self:updateCaches(x, y)
   end
end

function Level:__finalize()
   self.actorStorage:setCallbacks(self:sparseMapCallback(), self:sparseMapCallback())

   local w, h = self.map.w, self.map.h
   self.opacityCache = prism.BooleanBuffer(w, h)
   self.passableCache = prism.CascadingBitmaskBuffer(w, h, 4)

   for x, y, _ in self.map:each() do
      self:updateCaches(x, y)
   end
end

return Level
