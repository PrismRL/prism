--- @type Controls
local controls = geometer.require "controls"

--- The game state for Geometer. This should be the only thing you have to interface with
--- to use Geometer in a game.
--- @class EditorState : GameState
--- @field private textInput boolean The state of text input on load.
--- @field private keyRepeat boolean The state of key repeat on load.
--- @field private camera Vector2 The display's camera on load.
--- @field editor Editor
local EditorState = spectrum.GameState:extend "EditorState"

--- Create a new Editor managing gamestate, attached to a
--- SpectrumAttachable, this is a Level|LevelBuilder interface.
--- @param attachable SpectrumAttachable
function EditorState:__new(attachable, display, fileEnabled)
   self.editor = geometer.Editor(attachable, display, fileEnabled)
end

function EditorState:load()
   self.textInput = love.keyboard.hasTextInput()
   self.keyRepeat = love.keyboard.hasKeyRepeat()
   self.camera = self.editor.display.camera:copy()
   love.keyboard.setTextInput(true)
   love.keyboard.setKeyRepeat(true)

   self.editor:startEditing()
end

function EditorState:update(dt)
   controls:update()
   if not self.editor.active or controls.close.pressed then self.manager:pop() end

   self.editor:update(dt)
end

function EditorState:draw()
   self.editor:draw()
end

function EditorState:mousemoved(x, y, dx, dy, istouch)
   self.editor:mousemoved(x, y, dx, dy, istouch)
end

function EditorState:wheelmoved(dx, dy)
   self.editor:wheelmoved(dx, dy)
end

function EditorState:mousepressed(x, y, button)
   self.editor:mousepressed(x, y, button)
end

function EditorState:mousereleased(x, y, button)
   self.editor:mousereleased(x, y, button)
end

function EditorState:textinput(text)
   self.editor:textinput(text)
end

function EditorState:unload()
   love.keyboard.setKeyRepeat(self.keyRepeat)
   love.keyboard.setTextInput(self.textInput)
   self.editor.display:setCamera(self.camera:decompose())
end

return EditorState
