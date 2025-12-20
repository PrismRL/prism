--- @class LightSamplePool
--- @field pool LightSample[]
local LightSamplePool = prism.Object:extend "LightSamplePool"

function LightSamplePool:__new()
   self.pool = {}
end

--- Get a LightSample from the pool
--- @return LightSample
function LightSamplePool:acquire(x, y, depth)
   local obj = table.remove(self.pool)
   if obj then return obj:set(x, y, depth) end

   return prism.lighting.LightSample(x, y, depth)
end

--- Return a LightSample to the pool
function LightSamplePool:release(obj)
   table.insert(self.pool, obj)
end

return LightSamplePool
