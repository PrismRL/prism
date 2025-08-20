--- An 'Action' is a command that affects a discrete change in the game state.
--- An Action consists of an owner, a name, a list of targets, and a list of target objects.
--- See Target for more.
--- !doc protected-members
--- @class Action : Object
--- @field owner Actor The actor taking the action.
--- @field protected targets Target[] (static) A list of targets to apply the action to.
--- @field protected targetObjects Object[] The objects that correspond to the targets.
--- @field protected requiredComponents Component[] (static) Components required for an actor to take this action.
--- @field protected reaction boolean
--- @field protected abstract boolean
--- @overload fun(owner: Actor, targets: Object[]): Action
local Action = prism.Object:extend("Action")
Action.targets = {}

--- Constructor for the Action class.
---@param owner Actor The actor that is performing the action.
---@param ... Object An optional list of target actors. Not all actions require targets.
function Action:__new(owner, ...)
   assert(owner, "Actions must have an owner!")

   self.owner = owner
   self.targets = self.targets or {}
   self.targetObjects = { ... }
end

function Action:isAbstract()
   return self.abstract
end

function Action:isReaction()
   return self.reaction
end

--- @private
function Action:__validateTargets(level)
   if #self.targets < #self.targetObjects then
      return false,
         string.format(
            "Expected %s targets got %s targets for action %s",
            #self.targets,
            #self.targetObjects,
            self.className
         )
   end

   local previousTargets = {}
   for i = 1, #self.targets do
      local target = self.targets[i]
      --- @diagnostic disable-next-line
      if not target:validate(level, self.owner, self.targetObjects[i], previousTargets) then
         return false, "Invalid target " .. i .. " for action " .. self.className
      end
      table.insert(previousTargets, self.targetObjects[i])
   end

   return true
end

--- Checks if the action is valid and can be executed in the given level. Override this.
--- @param level Level The level the action would be performed in.
--- @return boolean canPerform True if the action could be performed, false otherwise.
--- @return string? error An optional error message, if the action cannot be performed.
--- @protected
function Action:canPerform(level, ...)
   return true
end

--- Checks whether or not the actor has the required components to perform this action.
--- @param actor Actor The actor to check.
--- @return boolean hasRequisiteComponents True if the actor has the required components, false otherwise.
--- @return string? missingComponent The name of the first missing component, should any be missing.
function Action:hasRequisiteComponents(actor)
   if not self.requiredComponents then return true end

   for _, component in pairs(self.requiredComponents) do
      if not actor:has(component) then return false, component.className end
   end

   return true
end

--- Performs the action on the level. Override this.
--- @param level Level The level to perform the action in.
--- @protected
function Action:perform(level, ...)
   error("This is a virtual method and must be overriden by subclasses!")
end

--- Returns the targeted object at the specified index.
---@param n number The index of the targeted object to retrieve.
---@return any target The targeted object at the specified index.
function Action:getTargeted(n)
   if self.targetObjects[n] then return self.targetObjects[n] end
end

--- Returns the number of targets associated with this action.
--- @return number numTargets The number of targets associated with this action.
function Action:getNumTargets()
   if not self.targets then return 0 end
   return #self.targets
end

--- Returns the target at the specified index.
--- @param index number The index of the target to retrieve.
--- @return Target? targetObject
function Action:getTarget(index)
   return self.targets[index]
end

--- Determines if the specified actor is a target of this action.
--- @param actor Actor The actor to check if they are a target of this action.
--- @return boolean -- True if the specified actor is a target of this action, false otherwise.
function Action:hasTargeted(actor)
   for _, a in pairs(self.targetObjects) do
      if a == actor then return true end
   end

   return false
end

--- Validates the specified target for this action.
--- @param n number The index of the target object to validate.
--- @param owner Actor The actor that is performing the action.
--- @param toValidate any The target object to validate.
--- @param previousTargets? any[] The previously selected targets.
--- @return boolean -- True if the specified target actor is valid for this action, false otherwise.
function Action:validateTarget(n, level, owner, toValidate, previousTargets)
   --- @diagnostic disable-next-line
   return self.targets[n] and self.targets[n]:validate(level, owner, toValidate, previousTargets)
end

return Action
