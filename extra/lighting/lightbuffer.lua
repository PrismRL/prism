--- @class LightBuffer
--- @field effect? LightEffect
--- @field color? Color4
--- @field private grid SparseGrid<number>
--- @field blockers SparseGrid<boolean>
--- @field private effectCache table
--- @field private frameColor? Color4
--- @field private currentColor? Color4
--- @field private minX integer?
--- @field private minY integer?
--- @field private maxX integer?
--- @field private maxY integer?
local LightBuffer = prism.Object:extend "LightBuffer"

function LightBuffer:__new(color, effect)
   self.grid = prism.SparseGrid()
   self.blockers = prism.SparseGrid()
   self.effectCache = {}
   self:reset(color, effect)
end

--- @param color? Color4 Nil when returned to the pool.
--- @param effect? LightEffect
--- @return LightBuffer
function LightBuffer:reset(color, effect)
   self:clear()
   self.color = color
   self.effect = effect
   if effect then self.frameColor = self.frameColor or prism.Color4() end
   return self
end

--- Prepare spatially uniform effects once before sampling this frame.
--- @param time number
function LightBuffer:update(time)
   if self.effect and self.effect.spatiallyUniform then
      self.currentColor = self.effect:effect(time, self.color, nil, nil, self.frameColor)
   end
end

--- Sample the visual color after update; gameplay uses the unmodified color.
--- @param time number
--- @param x integer
--- @param y integer
--- @param out? Color4
--- @return Color4
function LightBuffer:getColorAt(time, x, y, out)
   if not self.effect then return self.color end
   if self.effect.spatiallyUniform then return self.currentColor end
   return self.effect:effect(time, self.color, x, y, out, self.effectCache)
end

--- @param x integer
--- @param y integer
--- @return number?
function LightBuffer:get(x, y)
   return self.grid:get(x, y)
end

--- @param x integer
--- @param y integer
--- @param luminance number
function LightBuffer:set(x, y, luminance)
   self.grid:set(x, y, luminance)

   if not self.minX then
      -- first write initializes bounds
      self.minX = x
      self.maxX = x
      self.minY = y
      self.maxY = y
      return
   end

   if x < self.minX then self.minX = x end
   if x > self.maxX then self.maxX = x end
   if y < self.minY then self.minY = y end
   if y > self.maxY then self.maxY = y end
end

--- @return integer?, integer?, integer?, integer?
function LightBuffer:getBounds()
   return self.minX, self.minY, self.maxX, self.maxY
end

function LightBuffer:clear()
   self.grid:clear()
   self.blockers:clear()
   for key in pairs(self.effectCache) do
      self.effectCache[key] = nil
   end
   self.currentColor = nil
   self.minX = nil
   self.minY = nil
   self.maxX = nil
   self.maxY = nil
end

return LightBuffer
