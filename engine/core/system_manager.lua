--- @class prism.SystemManager : prism.Object
--- @field systems prism.System[]
--- @overload fun(owner: prism.Level): prism.SystemManager
--- @type prism.SystemManager
local SystemManager = prism.Object:extend("SystemManager")

--- @param owner prism.Level
function SystemManager:__new(owner)
   self.systems = {}
   self.owner = owner
end

--- Adds a system to the manager.
--- @param system prism.System The system to add.
function SystemManager:addSystem(system)
   assert(system.name, "System must have a name.")
   assert(
      not self.systems[system.name],
      "System with name " .. system.name .. " already exists. System names must be unique."
   )

   -- Check our requirements and make sure we have all the systems we need
   if system.requirements and #system.requirements > 1 then
      for _, requirement in ipairs(system.requirements) do
         assert(
            self.systems[requirement],
            "System "
            .. system.name
            .. " requires system "
            .. requirement
            .. " but it is not present."
         )
      end
   end

   -- Check the soft requirements of all previous systems and make sure we don't have any out
   -- of order systems
   for _, existingSystem in pairs(self.systems) do
      if existingSystem.softRequirements and #existingSystem.softRequirements > 0 then
         for _, softRequirement in ipairs(existingSystem.softRequirements) do
            if softRequirement == system.name then
               error(
                  "System "
                  .. system.name
                  .. " is out of order. It must be added before "
                  .. existingSystem.name
                  .. " because it is a soft requirement."
               )
            end
         end
      end
   end

   -- We've succeeded and we insert the system into our systems table
   system.owner = self.owner
   table.insert(self.systems, system)
end

--- Gets a system by name.
--- @param systemName string The name of the system to get.
--- @return prism.System? The system with the given name, or nil if not found.
function SystemManager:getSystem(systemName)
   for _, system in ipairs(self.systems) do
      if system.name == systemName then return system end
   end

   return nil
end

--- Initializes all systems attached to the manager.
--- @param level prism.Level The level to initialize the systems for.
function SystemManager:initialize(level)
   for _, system in pairs(self.systems) do
      system:initialize(level)
   end
end

--- Post-initializes all systems after the level has been populated.
--- @param level prism.Level The level to post-initialize the systems for.
function SystemManager:postInitialize(level)
   for _, system in ipairs(self.systems) do
      system:postInitialize(level)
   end
end

--- Calls the onTick method for all systems.
--- @param level prism.Level The level to call onTick for.
function SystemManager:onTick(level)
   for _, system in ipairs(self.systems) do
      system:onTick(level)
   end
end

--- Calls the onTurn method for all systems.
--- @param level prism.Level The level to call onTurn for.
--- @param actor prism.Actor The actor taking its turn.
function SystemManager:onTurn(level, actor)
   for _, system in ipairs(self.systems) do
      system:onTurn(level, actor)
   end
end

--- Calls the onTurn method for all systems.
--- @param level prism.Level The level to call onTurn for.
--- @param actor prism.Actor The actor taking its turn.
function SystemManager:onTurnEnd(level, actor)
   for _, system in ipairs(self.systems) do
      system:onTurnEnd(level, actor)
   end
end

--- Calls the onActorAdded method for all systems.
--- @param level prism.Level The level to call onActorAdded for.
--- @param actor prism.Actor The actor that has been added.
function SystemManager:onActorAdded(level, actor)
   for _, system in ipairs(self.systems) do
      system:onActorAdded(level, actor)
   end
end

--- Calls the onActorRemoved method for all systems.
--- @param level prism.Level The level to call onActorRemoved for.
--- @param actor prism.Actor The actor that has been removed.
function SystemManager:onActorRemoved(level, actor)
   for _, system in ipairs(self.systems) do
      system:onActorRemoved(level, actor)
   end
end

--- Calls the beforeMove method for all systems.
--- @param level prism.Level The level to call beforeMove for.
--- @param actor prism.Actor The actor that is moving.
--- @param from prism.Vector2 The position the actor is moving from.
--- @param to prism.Vector2 The position the actor is moving to.
function SystemManager:beforeMove(level, actor, from, to)
   for _, system in ipairs(self.systems) do
      system:beforeMove(level, actor, from, to)
   end
end

--- Calls the onMove method for all systems.
--- @param level prism.Level The level to call onMove for.
--- @param actor prism.Actor The actor that has moved.
--- @param from prism.Vector2 The position the actor moved from.
--- @param to prism.Vector2 The position the actor moved to.
function SystemManager:onMove(level, actor, from, to)
   for _, system in ipairs(self.systems) do
      system:onMove(level, actor, from, to)
   end
end

--- Calls the beforeAction method for all systems.
--- @param level prism.Level The level to call beforeAction for.
--- @param actor prism.Actor The actor that has selected an action.
--- @param action prism.Action The action the actor has selected.
function SystemManager:beforeAction(level, actor, action)
   for _, system in ipairs(self.systems) do
      system:beforeAction(level, actor, action)
   end
end

--- Calls the afterAction method for all systems.
--- @param level prism.Level The level to call afterAction for.
--- @param actor prism.Actor The actor that has taken an action.
--- @param action prism.Action The action the actor has executed.
function SystemManager:afterAction(level, actor, action)
   for _, system in ipairs(self.systems) do
      system:afterAction(level, actor, action)
   end
end

--- Calls the afterOpacityChanged method for all systems.
--- @param level prism.Level The level to call afterOpacityChanged for.
--- @param x number The x coordinate of the tile.
--- @param y number The y coordinate of the tile.
function SystemManager:afterOpacityChanged(level, x, y)
   for _, system in ipairs(self.systems) do
      system:afterOpacityChanged(level, x, y)
   end
end

--- Calls the on yield method for each system right before
--- the level hands a Decision back to the interface. Used by the Sight
--- system to ensure that the player's fov is always updated when we yield
--- even if it's not their turn.
--- @param level prism.Level The level to call onYield for.
--- @param event prism.Message The event data that caused the yield.
function SystemManager:onYield(level, event)
   for _, system in ipairs(self.systems) do
      system:onYield(level, event)
   end
end

--- This is useful for calling custom events you define in your Actions, Systems, etc.
--- An example usage of this can be found in the Sight system.
--- @param eventString string The key of the event handler method into the system.
---@param ... any The arguments to be passed to the event handler method.
function SystemManager:trigger(eventString, ...)
   for _, system in ipairs(self.systems) do
      if system[eventString] then
         system[eventString](system, ...)
      end
   end
end

return SystemManager
