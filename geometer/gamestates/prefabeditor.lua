---@class PrefabEditorState : EditorState
local PrefabEditorState = geometer.EditorState:extend "PrefabEditorState"

function PrefabEditorState:__new(attachable, display)
   geometer.EditorState.__new(self, attachable, display)
end

function PrefabEditorState:update(dt)
   self.editor.active = true
   geometer.EditorState.update(self, dt)
end

return PrefabEditorState
