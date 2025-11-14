--- Represents the visual for an actor. Used by Spectrum and Geometer to render actors.
--- @class Drawable : Component, Sprite
--- @field color Color4
--- @field background Color4
--- @field size integer
--- @field indices? Sprite[]
--- @overload fun(sprite: Sprite): Drawable
local Drawable = prism.Component:extend "Drawable"

--- @param sprite Sprite
function Drawable:__new(sprite)
   self.index = sprite.index
   self.color = sprite.color or prism.Color4.WHITE
   self.background = sprite.background or prism.Color4.TRANSPARENT
   self.layer = sprite.layer or 1
   self.size = sprite.size or 1
   self.indices = sprite.indices
end

return Drawable
