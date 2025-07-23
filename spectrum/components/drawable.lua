--- Represents the visual for an actor. Used by Spectrum and Geometer to render actors.
--- @class Drawable : Component
--- @field index string|integer an index into a SpriteAtlas
--- @field color Color4
--- @field background Color4
--- @field size integer
--- @overload fun(index: string|integer|DrawableOptions, color: Color4?, background: Color4?, layer: number?, size: integer?): Drawable
local Drawable = prism.Component:extend "Drawable"

--- @class DrawableOptions
--- @field char string|integer
--- @field color Color4?
--- @field background Color4?
--- @field layer integer?
--- @field size integer?

local warned = false

--- Index needs to be a string associated with a sprite in the SpriteAtlas, or
--- an integer index associated with a sprite.
--- @param index string|integer|DrawableOptions
--- @param color Color4?
--- @param background Color4?
--- @param layer integer?
--- @param size integer?
function Drawable:__new(index, color, background, layer, size)
   if type(index) == "table" then
      local options = index
      self.index = options.char
      self.color = options.color or prism.Color4.WHITE
      self.background = options.background or prism.Color4.TRANSPARENT
      self.layer = options.layer or 1
      self.size = options.size or 1
      return
   elseif not warned then
      warned = true
      prism.logger.warn(
         "Drawable now uses an option table, the multi-argument constructor",
         "has been deprecated and will be removed upon release 1!"
      )
   end

   self.index = index
   self.color = color or prism.Color4.WHITE
   self.background = background or prism.Color4.TRANSPARENT
   self.layer = layer or 1
   self.size = size or 1
end

return Drawable
