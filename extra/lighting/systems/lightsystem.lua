--- @type LightSamplePool
local samplePool = prism.lighting.LightSamplePool()

--- Handles lighting calculations for the level. LightSystem:update must be called every frame.
--- @class LightSystem : System
--- @field lightBuffers table<Actor, LightBuffer>
--- @field buffer Grid<Color4>
--- @field rtBuffer Grid<Color4>
--- @field tileInfluence Grid<table<Actor, number>>
local LightSystem = prism.System:extend "LightSystem"
LightSystem.MINIMUM_LUMINANCE = 1 / 16

--- @param level Level
function LightSystem:initialize(level)
   self.lightBuffers = {}
   self.needsRebuild = false
   self.buffer = prism.Grid(level:getSize())
   self.rtBuffer = prism.Grid(level:getSize())
   self.tileInfluence = prism.Grid(level:getSize())
end

--- @param actor Actor
function LightSystem:setDirty(actor)
   if self.lightBuffers[actor] or actor:has(prism.components.Light) then
      self.needsRebuild = true
      self.lightBuffers[actor] = nil
   end

   for litby, _ in pairs(actor:getRelations(prism.relations.LitByRelation)) do
      self:setDirty(litby)
   end
end

function LightSystem:onComponentAdded(_, actor, _)
   self:setDirty(actor)
end
function LightSystem:onComponentRemoved(_, actor, _)
   self:setDirty(actor)
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
   for actor, buffer in pairs(self.lightBuffers) do
      if buffer:get(x, y) then self:setDirty(actor) end
   end
end

local dummy = prism.Color4()
function LightSystem:rebuild()
   for actor, light in self.owner:query(prism.components.Light):iter() do
      --- @cast light Light

      if not self.lightBuffers[actor] then
         local x, y
         if actor:getPosition() then
            x, y = actor:expectPosition():decompose()
         else
            local related = actor:getRelation(prism.relations.LightsRelation)
            x, y = related:expectPosition():decompose()
         end

         if x and y then self.lightBuffers[actor] = self:cast(x, y, light) end
      end
   end

   self.buffer:clear()
   for _, buffer in pairs(self.lightBuffers) do
      for x, y, luminance in buffer.grid:each() do
         local c = buffer.color
         local cur = self.buffer:get(x, y) or dummy
         self.buffer:set(x, y, cur + c * luminance)
      end
   end

   self.needsRebuild = false
end

function LightSystem:update()
   self.time = love.timer.getTime()

   -- Ensure static lighting is valid
   if self.needsRebuild then self:rebuild() end

   self.rtBuffer:clear()

   for _, buffer in pairs(self.lightBuffers) do
      for x, y, luminance in buffer.grid:each() do
         local c = buffer.color
         if buffer.effect then c = buffer.effect:effect(self.time, c, x, y) end
         local cur = self.rtBuffer:get(x, y) or dummy
         self.rtBuffer:set(x, y, cur + c * luminance)
      end
   end
end

--- @return Grid<Color4>
--- @param x integer
--- @param y integer
--- @param lightComponent Light
function LightSystem:cast(x, y, lightComponent)
   local out = prism.lighting.LightBuffer(lightComponent:getColor(), lightComponent.lightEffect)
   local frontier = prism.Queue()

   frontier:push(samplePool:acquire(x, y, 0))
   out:set(x, y, 1)

   while not frontier:empty() do
      --- @type LightSample
      local current = frontier:pop()

      for _, neighborDir in ipairs(prism.neighborhood) do
         local nx, ny = current.x + neighborDir.x, current.y + neighborDir.y
         if nx >= 1 and nx <= self.owner.map.w and ny >= 1 and ny <= self.owner.map.h then
            if not out:get(nx, ny) and not self.owner:getOpacityCache():get(nx, ny) then
               local luminance = lightComponent:attenuate(current.depth + 1)
               out:set(nx, ny, luminance)
               if luminance >= self.MINIMUM_LUMINANCE then
                  frontier:push(samplePool:acquire(nx, ny, current.depth + 1))
               end
            end
         end
      end

      samplePool:release(current)
   end

   return out
end

--- @param self LightSystem
--- @param getValue fun(self: LightSystem, x: integer, y: integer): Color4?
--- @param x integer
--- @param y integer
--- @param actor Actor
--- @return Color4?
local function getValuePerspectiveImpl(self, getValue, x, y, actor)
   local senses = actor:get(prism.components.Senses)
   if not senses then return nil end

   -- Actor cannot perceive this cell at all
   if not senses.cells:get(x, y) then return nil end

   if getValue(self, x, y) then return getValue(self, x, y) end

   local accum = prism.Color4(0, 0, 0, 1)
   local count = 0

   for _, dir in ipairs(prism.neighborhood) do
      local nx, ny = x + dir.x, y + dir.y

      if senses.cells:get(nx, ny) and not self.owner:getCellOpaque(nx, ny) then
         local c = getValue(self, nx, ny)
         if c then
            accum = accum + c
            count = count + 1
         end
      end
   end

   if count > 0 then return accum / count end

   return prism.Color4(0, 0, 0, 1)
end

function LightSystem:getValue(x, y)
   if self.needsRebuild then self:rebuild() end

   return self.buffer:get(x, y)
end

--- @param x integer
--- @param y integer
--- @param actor Actor
--- @return Color4?
function LightSystem:getValuePerspective(x, y, actor)
   return getValuePerspectiveImpl(self, LightSystem.getValue, x, y, actor)
end

function LightSystem:getRTValue(x, y)
   return self.rtBuffer:get(x, y)
end

function LightSystem:getRTValuePerspective(x, y, actor)
   return getValuePerspectiveImpl(self, LightSystem.getRTValue, x, y, actor)
end

return LightSystem
