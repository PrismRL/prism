--- Represents an animation to be played.
--- @class AnimationMessage : Message
--- @field animation Animation|fun(dt: number): boolean
--- @field actor? Actor An optional actor to play the animation relative to.
--- @field x? integer An x position to play the animation at. If an actor is given, this is relative to their position.
--- @field y? integer A y position to play the animation at. If an actor is given, this is relative to their position.
--- @field blocking boolean Whether to block other processes while the animation plays.
--- @field skippable boolean Whether the animation can be skipped with input.
--- @overload fun(options: AnimationMessageOptions): AnimationMessage
local AnimationMessage = prism.Message:extend "AnimationMessage"

--- @class AnimationMessageOptions
--- @field animation Animation | fun(dt: number): boolean
--- @field actor? Actor
--- @field x? integer
--- @field y? integer
--- @field blocking? boolean
--- @field skippable? boolean

--- @param options AnimationMessageOptions
function AnimationMessage:__new(options)
   self.animation = options.animation
   self.actor = options.actor
   self.x = options.x or 0
   self.y = options.y or 0
   self.blocking = options.blocking or false
   self.skippable = options.skippable or false
end

return AnimationMessage
