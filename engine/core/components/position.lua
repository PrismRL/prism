--- Defines a position for the actor. You should avoid
--- directly manipulating this and instead use level:moveActor
--- and actor:getPosition or actor:expectPosition.
--- @class Position : Component
--- @field private _position Vector2
--- @overload fun(pos: Vector2?): Position
local Position = prism.Component:extend "Position"

function Position:__new(pos)
   self._position = pos or prism.Vector2(1, 1)
end

--- Gets a reference to the inner vector. Don't pass this around
--- or modify this! Treat it as immutable!
function Position:getVector()
   return self._position
end

return Position
