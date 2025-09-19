--- @class IdleAnimation : Component
--- @field animationName string
--- @field animation Animation
--- @overload fun(animationName: string): IdleAnimation
local IdleAnimation = prism.Component:extend "IdleAnimation"

function IdleAnimation:__new(animationName)
   self.animationName = animationName
   self.animation = spectrum.animations[animationName]()
end

function IdleAnimation:onDeserialize()
   self.animation = spectrum.animations[self.animationName]()
end

return IdleAnimation
