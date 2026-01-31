--- @class LightBuffer
--- @field effect? LightEffect
--- @field private grid SparseGrid
--- @field private minX integer?
--- @field private minY integer?
--- @field private maxX integer?
--- @field private maxY integer?
local LightBuffer = prism.Object:extend "LightBuffer"

function LightBuffer:__new(color, effect)
   self.grid = prism.SparseGrid()

   self.color = color
   self.effect = effect

   -- bounding box (nil until first write)
   self.minX = nil
   self.minY = nil
   self.maxX = nil
   self.maxY = nil
end

--- @param x integer
--- @param y integer
--- @return integer
function LightBuffer:get(x, y)
   return self.grid:get(x, y)
end

--- @param x integer
--- @param y integer
--- @param luminance integer
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
   self.minX = nil
   self.minY = nil
   self.maxX = nil
   self.maxY = nil
end

return LightBuffer
