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
   self.super.__new(self, prism.LevelBuilder(), display)
   self.onFinish = onFinish
   self.co = coroutine.create(generator)
end

function MapGeneratorState:update(dt)
   self.editor:update(dt)

   if not self.editor.active then
      local success, builder = coroutine.resume(self.co)
      if not success then error(builder .. "\n" .. debug.traceback(self.co)) end

      if not builder and self.onFinish then self.onFinish(builder) end

      self.editor:setAttachable(builder)
      self.editor.active = true
   end
end

return MapGeneratorState
