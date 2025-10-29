--- A game state used to organize different screens of a game in conjunction with a manager.
--- @class GameState : Object
--- @field manager? GameStateManager The state's manager or nil if the state is not in a manager's stack.
local GameState = prism.Object:extend("GameState")

--- Called when this state is pushed or switched to.
--- @param previous? GameState
--- @vararg any Additional parameters passed to the state.
function GameState:load(previous, ...) end

--- Called when the manager switches away from or pops this state off.
--- @param next GameState
--- @vararg any Additional parameters passed to the state.
function GameState:unload(next, ...) end

--- Called when a state is popped and this one becomes active.
--- @param previous? GameState
--- @vararg any Additional parameters passed to the state.
function GameState:resume(previous, ...) end

--- Called when a state is pushed on top of this one.
--- @param next GameState
--- @vararg any Additional parameters passed to the state.
function GameState:pause(next, ...) end

function GameState:getManager()
   return self.manager
end

return GameState
