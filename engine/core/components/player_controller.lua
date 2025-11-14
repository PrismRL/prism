--- A controller component that stops to wait for input to receive its action.
--- @class PlayerController : Controller
--- @overload fun(): PlayerController
--- @type PlayerController
local PlayerController = prism.components.Controller:extend "PlayerController"

function PlayerController:decide(level, _, decision)
   return level:yield(decision)
end

return PlayerController
