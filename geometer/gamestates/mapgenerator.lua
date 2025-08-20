--- A wrapper around Geometer's EditorState meant for stepping through map generation.
--- @class MapGeneratorState : EditorState
--- @overload fun(generator: function, builder: LevelBuilder, display: Display): MapGeneratorState
local MapGeneratorState = geometer.EditorState:extend "MapGeneratorState"

--- @param generator function
--- @param builder LevelBuilder
--- @param display Display
function MapGeneratorState:__new(generator, builder, display)
   geometer.EditorState.__new(self, builder, display)
   self.co = coroutine.create(generator)
end

function MapGeneratorState:update(dt)
   if not self.editor.active then
      coroutine.resume(self.co)
      self.editor.active = true
   end

   self.editor:update(dt)
end

return MapGeneratorState
