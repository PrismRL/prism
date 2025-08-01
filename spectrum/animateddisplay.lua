--- @class AnimatedDisplay : Display
--- @field animations AnimationMessage[] The list of currently playing animations.
local AnimatedDisplay = spectrum.Display:extend("AnimatedDisplay")

--- @param width integer The width of the display in cells.
--- @param height integer The height of the display in cells.
--- @param spriteAtlas SpriteAtlas The sprite atlas used for drawing characters.
--- @param cellSize Vector2 The size of each cell in pixels.
function AnimatedDisplay:__new(width, height, spriteAtlas, cellSize)
   spectrum.Display.__new(self, width, height, spriteAtlas, cellSize)
   self.animations = {}
   self.blocking = false
end

--- @param level Level
--- @param dt number
function AnimatedDisplay:update(level, dt)
   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      if spectrum.Animation:is(animation.animation) then
         animation.animation:update(dt)

         if animation.animation.status == "paused" then
            table.remove(self.animations, i)
            if animation.blocking then self.blocking = false end
         end
      end
   end

   for _, _, animation in
      level:query(prism.components.Position, prism.components.IdleAnimation):iter()
   do
      --- @cast animation IdleAnimation
      animation.animation:update(dt)
   end
end

local reusedPosition = prism.Vector2()

--- @param queryable IQueryable
function AnimatedDisplay:drawAnimations(queryable)
   for actor, position, idleAnimation in
      queryable:query(prism.components.Position, prism.components.IdleAnimation):iter()
   do
      --- @cast idleAnimation IdleAnimation
      --- @cast position Position
      local x, y = position:getVector():decompose()
      local animation = idleAnimation.animation

      animation:draw(self, x, y)
   end

   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      if spectrum.Animation:is(animation.animation) then
         local x, y = animation.x, animation.y
         if animation.actor then
            animation.actor:getPosition(reusedPosition)
            x = x + (reusedPosition and reusedPosition.x or 0)
            y = y + (reusedPosition and reusedPosition.y or 0)
         end

         animation.animation:draw(self, x, y)
      else
         if animation.animation(love.timer.getDelta()) then table.remove(self.animations, i) end
      end
   end
end

function AnimatedDisplay:putSensed(senses, x, y, index, color, background, layer) end

--- Removes any animations that are skippable.
function AnimatedDisplay:skipAnimations()
   for i = #self.animations, 1, -1 do
      local animation = self.animations[i]
      if animation.skippable then table.remove(self.animations, i) end
   end
end

--- Adds an animation
--- @param message AnimationMessage
--- @param manager GameStateManager
--- @param level Level
function AnimatedDisplay:yieldAnimation(message, manager, level)
   table.insert(self.animations, message)
   if message.blocking then
      self.blocking = true
      manager:push(spectrum.AnimatedState(self, level))
   end
end

return AnimatedDisplay
