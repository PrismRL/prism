--- @class IdleAnimation : Component
--- @field animation Animation
--- @overload fun(animation: Animation): IdleAnimation
local IdleAnimation = prism.Component:extend "IdleAnimation"

function IdleAnimation:__new(animation)
   self.animation = animation
end

return IdleAnimation
