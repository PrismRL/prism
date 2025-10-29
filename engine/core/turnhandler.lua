--- Handles running turns in a level.
--- Extend this class and pass it to LevelBuilder.addTurnHandler to override.
--- @class TurnHandler : Object
local TurnHandler = prism.Object:extend("TurnHandler")

--- Runs a single actor's turn in a level.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
function TurnHandler:handleTurn(level, actor, controller)
   local action = controller:act(level, actor)

   -- we make sure we got an action back from the controller for sanity's sake
   assert(action, "Actor " .. actor:getName() .. " returned nil from act()")

   level:perform(action)
end

return TurnHandler
