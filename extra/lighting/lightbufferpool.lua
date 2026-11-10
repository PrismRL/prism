--- @class LightBufferPool : Object
--- @field private pool LightBuffer[]
local LightBufferPool = prism.Object:extend "LightBufferPool"

function LightBufferPool:__new()
   self.pool = {}
end

--- @param color Color4
--- @param effect? LightEffect
--- @return LightBuffer
function LightBufferPool:acquire(color, effect)
   local buffer = table.remove(self.pool)
   if buffer then return buffer:reset(color, effect) end
   return prism.lighting.LightBuffer(color, effect)
end

--- @param buffer LightBuffer
function LightBufferPool:release(buffer)
   buffer:reset()
   table.insert(self.pool, buffer)
end

return LightBufferPool
