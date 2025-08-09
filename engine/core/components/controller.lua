--- Defines what an actor does on its turn.
--- @class Controller : Component
--- @field blackboard table|nil
--- @overload fun(): Controller
local Controller = prism.Component:extend "Controller"

--- Returns the :lua:class:`Action` that the actor will take on its turn.
--- This should not modify the :lua:class:`Level` directly.
--- @param level Level The level the actor is in.
--- @param actor Actor The actor currently acting.
--- @return Action -- The action the actor will perform.
function Controller:act(level, actor)
   error("Controller is an abstract class and must have act overwritten!")
end

--- Returns a boolean indiciating if this actor is currently player controlled.
--- This is used by displays to indicate whether to draw this actor's perspective.
--- @return boolean isPlayerControlled
function Controller:isPlayerControlled()
   return false
end

return Controller
