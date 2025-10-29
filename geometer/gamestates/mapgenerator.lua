--- @type Controls
local controls = geometer.require "controls"
local EditorState = geometer.require "gamestates.editorstate"

--- A wrapper around Geometer's EditorState meant for stepping through map generation.
--- @class MapGeneratorState : EditorState
--- @field onFinish? fun(builder: LevelBuilder)
--- @overload fun(generator: function, builder: LevelBuilder, display: Display, onFinish?: fun(builder: LevelBuilder)): MapGeneratorState
local MapGeneratorState = EditorState:extend "MapGeneratorState"

--- @param generator function
--- @param builder LevelBuilder
--- @param display Display
--- @param onFinish? fun(builder: LevelBuilder)
function MapGeneratorState:__new(generator, builder, display, onFinish)
   self.super.__new(self, builder, display)
   self.onFinish = onFinish
   self.co = coroutine.create(generator)
end

function MapGeneratorState:update(dt)
   controls:update()

   if not self.editor.active then
      if not coroutine.resume(self.co) and self.onFinish then
         self.onFinish(self.editor.attachable)
      end
      self.editor.active = true
   end

   if controls.close.pressed then self.editor.active = false end

   self.editor:update(dt)
end

return MapGeneratorState
