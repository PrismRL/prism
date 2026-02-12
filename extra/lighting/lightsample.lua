--- @class LightSample
--- @field x integer
--- @field y integer
--- @field color Color4
local LightSample = prism.Object:extend "LightSample"

--- @param x integer
---@param y integer
---@param depth integer
function LightSample:__new(x, y, depth)
   assert(x and y and depth)
   self.x = x
   self.y = y
   self.depth = depth
end

function LightSample:set(x, y, depth)
   self.x = x
   self.y = y
   self.depth = depth
   return self
end

return LightSample
