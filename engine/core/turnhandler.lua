--- Handles running turns in a level.
--- Extend this class and pass it to LevelBuilder.addTurnHandler to override.
--- @class TurnHandler : Object
local TurnHandler = prism.Object:extend("TurnHandler")

--- Runs a single actor's turn in a level.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
function TurnHandler:handleTurn(level, actor, controller)
   local action

   local activity = actor:get(prism.components.Activity)
   if activity and (not activity.cancellable or controller:decideContinue(level, actor, activity)) then
      action = activity:next()
   end
   if not action then actor:remove(prism.components.Activity) end

   action = action or controller:decide(level, actor, prism.decisions.ActionDecision(actor)).action
   -- we make sure we got an action back from the controller for sanity's sake
   assert(action, "Actor " .. actor:getName() .. " returned nil from decide/act.")
   level:perform(action)
end

return TurnHandler
