--- Represents an action to be taken, generally by the player.
--- :lua:class:`PlayerController` yields one to decide what action to perform.
--- @class ActionDecision : Decision
--- @field actor Actor The actor making the decision.
--- @field action Action|nil The action to perform.
--- @overload fun(actor: Actor): ActionDecision
local ActionDecision = prism.Decision:extend("ActionDecision")

--- @param actor Actor
function ActionDecision:__new(actor)
   self.actor = actor
end

function ActionDecision:validateResponse()
   return self.action ~= nil
end

--- Sets an action if it can be performed and there is not an action set already.
--- @param action Action An action to try setting.
--- @param level Level The level.
--- @return boolean set True if the action was set, false otherwise.
--- @return string? err An error message if setting the action failed.
function ActionDecision:setAction(action, level)
   if self.action then return false, "ActionDecision already has an action!" end

   local can, err = level:canPerform(action)
   if can then self.action = action end

   return can, err
end

return ActionDecision
