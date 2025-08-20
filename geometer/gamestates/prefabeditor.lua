---@class PrefabEditorState : EditorState
local PrefabEditorState = geometer.EditorState:extend "PrefabEditorState"

function PrefabEditorState:__new(mb)
   local attachable = mb or prism.LevelBuilder()
   local spriteAtlas =
      spectrum.SpriteAtlas.fromGrid("example_srd/display/wanderlust_16x16.png", 16, 16)
   local display = spectrum.Display(spriteAtlas, prism.Vector2(16, 16), attachable)

   geometer.EditorState.__new(self, attachable, display)
end

function PrefabEditorState:update(dt)
   self.editor.active = true
   self.editor:update(dt)
end

return PrefabEditorState
