--- @class AnimatedState : GameState
--- @field level Level
--- @field previous GameState
--- @field display AnimatedDisplay
local AnimatedState = spectrum.GameState:extend("AnimatedState")

function AnimatedState:__new(display, level)
   self.display = display
   self.level = level
end

function AnimatedState:load(previous)
   self.previous = previous
end

function AnimatedState:draw()
   self.previous:draw()
end

function AnimatedState:update(dt)
   self.display:update(self.level, dt)
   if not self.display.blocking then self.manager:pop() end
end

return AnimatedState
