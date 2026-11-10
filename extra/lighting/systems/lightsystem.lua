--- @type LightSamplePool
local samplePool = prism.lighting.LightSamplePool()

--- Handles lighting calculations for the level. LightSystem:update must be called every frame.
--- @class LightSystem : System
--- @field lightBuffers table<Actor, LightBuffer>
--- @field private bufferPool LightBufferPool
--- @field buffer Grid<Color4>
--- @field rtBuffer Grid<Color4>
--- @field staticBuffer Grid<Color4>
--- @field animatedBuffers table<Actor, LightBuffer>
--- @field animatedInfluence Grid<table<Actor, number>>
--- @field opacityInfluence Grid<table<Actor, boolean>>
--- @field dirtyTiles table<integer, boolean>
--- @field rtDirtyTiles table<integer, boolean>
--- @field effectColor Color4
--- @field tileInfluence Grid<table<Actor, number>>
local LightSystem = prism.System:extend "LightSystem"
LightSystem.MINIMUM_LUMINANCE = 1 / 16

--- @param level Level
function LightSystem:initialize(level)
   self.lightBuffers = {}
   self.bufferPool = prism.lighting.LightBufferPool()
   self.needsRebuild = true
   self.buffer = prism.Grid(level:getSize())
   self.staticBuffer = prism.Grid(level:getSize())
   self.rtBuffer = prism.Grid(level:getSize())
   self.tileInfluence = prism.Grid(level:getSize())
   self.animatedInfluence = prism.Grid(level:getSize())
   self.opacityInfluence = prism.Grid(level:getSize())
   self.animatedBuffers = {}
   self.dirtyTiles = {}
   self.rtDirtyTiles = {}
   self.effectColor = prism.Color4()
end

local function addInfluence(grid, x, y, actor, value)
   local index = grid:getIndex(x, y)
   local influences = grid.data[index]
   if not influences then
      influences = {}
      grid.data[index] = influences
   end
   influences[actor] = value
end

local function removeInfluence(grid, x, y, actor)
   local index = grid:getIndex(x, y)
   local influences = grid.data[index]
   if influences then
      influences[actor] = nil
      if not next(influences) then grid.data[index] = nil end
   end
end

--- Invalidate after changing a light's color, radius or effect settings.
--- @param actor Actor
--- @param visited? table<Actor, boolean>
function LightSystem:setDirty(actor, visited)
   visited = visited or {}
   if visited[actor] then return end
   visited[actor] = true

   local buffer = self.lightBuffers[actor]
   if buffer or actor:has(prism.components.Light) then
      self.needsRebuild = true
      if buffer then
         -- Remove the old footprint now, retaining its tiles for recomposition.
         for x, y in buffer.grid:each() do
            self.dirtyTiles[self.buffer:getIndex(x, y)] = true
            removeInfluence(self.tileInfluence, x, y, actor)
            removeInfluence(self.animatedInfluence, x, y, actor)
            removeInfluence(self.opacityInfluence, x, y, actor)
         end
         for x, y in buffer.blockers:each() do
            removeInfluence(self.opacityInfluence, x, y, actor)
         end
         self.animatedBuffers[actor] = nil
         self.lightBuffers[actor] = nil
         self.bufferPool:release(buffer)
      end
   end

   for litby in pairs(actor:getRelations(prism.relations.LitByRelation)) do
      self:setDirty(litby, visited)
   end
end

function LightSystem:onComponentAdded(_, actor, component)
   if prism.components.Light:is(component) or prism.components.Position:is(component) then
      self:setDirty(actor)
   end
end
function LightSystem:onComponentRemoved(_, actor, component)
   if prism.components.Light:is(component) or prism.components.Position:is(component) then
      self:setDirty(actor)
   end
end
function LightSystem:onActorAdded(_, actor)
   self:setDirty(actor)
end
function LightSystem:onActorRemoved(_, actor)
   self:setDirty(actor)
end
function LightSystem:beforeMove(_, actor, _, _)
   self:setDirty(actor)
end

function LightSystem:afterOpacityChanged(level, x, y)
   local influences = self.opacityInfluence:get(x, y)
   if not influences then return end
   -- setDirty removes entries from the index, including related lights.
   local affected = {}
   for actor in pairs(influences) do
      affected[#affected + 1] = actor
   end
   for _, actor in ipairs(affected) do
      self:setDirty(actor)
   end
end

-- All compositors own their output colors; never mutate a light's source color
-- or alias the gameplay, static and animated buffers. Alpha retains the original
-- compositor's initial value of one plus the weighted contributions.
local function resetColor(grid, index)
   local color = grid.data[index]
   if not color then
      color = prism.Color4()
      grid.data[index] = color
   end
   return prism.Color4.compose(color, 0, 0, 0, 1)
end

--- @private
--- @param actor Actor
--- @param light Light
function LightSystem:registerLight(actor, light)
   local position = actor:getPosition()
   if not position then
      local related = actor:getRelation(prism.relations.LightsRelation)
      position = related and related:getPosition()
   end
   if not position then return end

   local x, y = position:decompose()
   local buffer = self:cast(x, y, light)
   self.lightBuffers[actor] = buffer
   if buffer.effect then self.animatedBuffers[actor] = buffer end
   for bx, by, luminance in buffer.grid:each() do
      self.dirtyTiles[self.buffer:getIndex(bx, by)] = true
      addInfluence(self.tileInfluence, bx, by, actor, luminance)
      addInfluence(self.opacityInfluence, bx, by, actor, true)
      if buffer.effect then addInfluence(self.animatedInfluence, bx, by, actor, luminance) end
   end
   for bx, by in buffer.blockers:each() do
      addInfluence(self.opacityInfluence, bx, by, actor, true)
   end
end

function LightSystem:rebuild()
   for actor, light in self.owner:query(prism.components.Light):iter() do
      if not self.lightBuffers[actor] then self:registerLight(actor, light) end
   end

   for index in pairs(self.dirtyTiles) do
      local influences = self.tileInfluence.data[index]
      if influences then
         local total = resetColor(self.buffer, index)
         local static
         for actor, luminance in pairs(influences) do
            local buffer = self.lightBuffers[actor]
            total:addScaled(buffer.color, luminance, total)
            if not buffer.effect then
               static = static or resetColor(self.staticBuffer, index)
               static:addScaled(buffer.color, luminance, static)
            end
         end
         if not static then self.staticBuffer.data[index] = nil end
      else
         self.buffer.data[index] = nil
         self.staticBuffer.data[index] = nil
      end
      self.rtDirtyTiles[index] = true
      self.dirtyTiles[index] = nil
   end
   self.needsRebuild = false
end

function LightSystem:updateTile(index, influences)
   if not self.tileInfluence.data[index] then
      self.rtBuffer.data[index] = nil
      return
   end
   local out = resetColor(self.rtBuffer, index)
   local static = self.staticBuffer.data[index]
   if static then prism.Color4.copy(static, out) end

   if influences then
      local x = ((index - 1) % self.rtBuffer.w) + 1
      local y = math.floor((index - 1) / self.rtBuffer.w) + 1
      for actor, luminance in pairs(influences) do
         local buffer = self.lightBuffers[actor]
         local color = buffer:getColorAt(self.time, x, y, self.effectColor)
         out:addScaled(color, luminance, out)
      end
   end
end

function LightSystem:update()
   self.time = love.timer.getTime()
   if self.needsRebuild then self:rebuild() end

   for _, buffer in pairs(self.animatedBuffers) do
      buffer:update(self.time)
   end

   -- Static tiles only change when their footprint is dirtied. Animated tiles
   -- start from the cached static contribution on every frame.
   for index, influences in pairs(self.animatedInfluence.data) do
      self:updateTile(index, influences)
      self.rtDirtyTiles[index] = nil
   end
   for index in pairs(self.rtDirtyTiles) do
      self:updateTile(index)
      self.rtDirtyTiles[index] = nil
   end
end

--- @return LightBuffer
--- @param x integer
--- @param y integer
--- @param lightComponent Light
function LightSystem:cast(x, y, lightComponent)
   local out = self.bufferPool:acquire(lightComponent:getColor(), lightComponent.lightEffect)
   local frontier = prism.Queue()
   local attenuation = {}
   local opacity = self.owner:getOpacityCache()
   local w, h = self.owner.map.w, self.owner.map.h

   frontier:push(samplePool:acquire(x, y, 0))
   out:set(x, y, 1)

   while not frontier:empty() do
      --- @type LightSample
      local current = frontier:pop()

      for _, neighborDir in ipairs(prism.neighborhood) do
         local nx, ny = current.x + neighborDir.x, current.y + neighborDir.y
         if nx >= 1 and nx <= w and ny >= 1 and ny <= h and not out:get(nx, ny) then
            if opacity:get(nx, ny) then
               -- Closed doors/walls must invalidate this cast when they open.
               out.blockers:set(nx, ny, true)
            else
               local depth = current.depth + 1
               local luminance = attenuation[depth]
               if luminance == nil then
                  luminance = lightComponent:attenuate(depth)
                  attenuation[depth] = luminance
               end
               out:set(nx, ny, luminance)
               if luminance >= self.MINIMUM_LUMINANCE then
                  frontier:push(samplePool:acquire(nx, ny, depth))
               end
            end
         end
      end

      samplePool:release(current)
   end

   return out
end

--- @private
--- @param getValue fun(self: LightSystem, x: integer, y: integer): Color4?
--- @param x integer
--- @param y integer
--- @param actor Actor
--- @param out? Color4 Caller-owned output; avoids allocation for wall lighting.
--- @return Color4?
function LightSystem:getPerspectiveValue(getValue, x, y, actor, out)
   local senses = actor:get(prism.components.Senses)
   if not senses then return nil end

   -- Actor cannot perceive this cell at all
   if not senses.cells:get(x, y) then return nil end

   local value = getValue(self, x, y)
   if value then return out and value:copy(out) or value end

   local accum = out or prism.Color4()
   accum:compose(0, 0, 0, 1)
   local count = 0

   for _, dir in ipairs(prism.neighborhood) do
      local nx, ny = x + dir.x, y + dir.y

      if senses.cells:get(nx, ny) and not self.owner:getCellOpaque(nx, ny) then
         local c = getValue(self, nx, ny)
         if c then
            accum:add(c, accum)
            count = count + 1
         end
      end
   end

   if count > 0 then accum:div(count, accum) end
   return accum
end

function LightSystem:getValue(x, y)
   if self.needsRebuild then self:rebuild() end

   return self.buffer:get(x, y)
end

--- @param x integer
--- @param y integer
--- @param actor Actor
--- @param out? Color4 Caller-owned output, written only for perceived cells.
--- @return Color4?
function LightSystem:getValuePerspective(x, y, actor, out)
   return self:getPerspectiveValue(LightSystem.getValue, x, y, actor, out)
end

function LightSystem:getRTValue(x, y)
   return self.rtBuffer:get(x, y)
end

--- @param x integer
--- @param y integer
--- @param actor Actor
--- @param out? Color4 Caller-owned output, written only for perceived cells.
--- @return Color4?
function LightSystem:getRTValuePerspective(x, y, actor, out)
   return self:getPerspectiveValue(LightSystem.getRTValue, x, y, actor, out)
end

return LightSystem
