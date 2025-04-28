--- @type Keybinding
local keybinds = geometer.require "keybindingschema"
local PenTool = geometer.require "tools.pen"

---@alias Placeable Actor|Cell

---@class Editor : Object
---@field attachable SpectrumAttachable
---@field display Display
---@field camera Camera
---@field active boolean
---@field editorRoot EditorRoot
---@field undoStack Modification[]
---@field redoStack Modification[]
---@field placeable Placeable|nil
---@field tool Tool
---@field selectorMode string
---@field selectorModes table<string, string>
---@field filepath string|nil
---@field fileEnabled boolean
---@field keybindsEnabled boolean
local Editor = prism.Object:extend("Geometer")

function Editor:__new(attachable, display, fileEnabled)
   self.attachable = attachable
   self.display = display
   self.active = false
   for _, v in pairs(prism.cells) do
      self.placeable = v()
      break
   end
   self.tool = PenTool()
   self.fillMode = true
   self.selectorMode = "any"
   self.fileEnabled = true --fileEnabled or false
   self.keybindsEnabled = true
   self.selectorModes = {
      ["any"] = "actor",
      ["actor"] = "tile",
      ["tile"] = "any",
   }
end

local Inky = geometer.require "inky"
local EditorRoot = geometer.require "elements.editorroot"

---@type Inky.Scene
local scene
---@type Inky.Pointer
local pointer

local scaler = math.floor(math.min(love.graphics.getWidth() / 348, love.graphics.getHeight() / 200))
local scale = prism.Vector2(scaler, scaler)

function Editor:isActive()
   return self.active
end

function Editor:startEditing()
   self.active = true
   scene = Inky.scene()
   pointer = Inky.pointer(scene)
   self.editorRoot = EditorRoot(scene)
   self.editorRoot.props.display = self.display
   self.editorRoot.props.attachable = self.attachable
   self.editorRoot.props.scale = scale
   self.editorRoot.props.editor = self

   self.undoStack = {}
   self.redoStack = {}

   self.tool = PenTool()

   self.attachable.debug = false
   love.keyboard.setKeyRepeat(true)
end

---@param attachable SpectrumAttachable
function Editor:setAttachable(attachable)
   self.attachable = attachable
   self.display.attachable = attachable
   self.editorRoot.props.attachable = attachable
   self.editorRoot.props.display = self.display
end

function Editor:update(dt)
   local mx, my = love.mouse.getX(), love.mouse.getY()
   pointer:setPosition(mx / scale.x, my / scale.y)

   if self.editorRoot.props.quit then
      self.active = false
      self.editorRoot.props.quit = false
   end

   scene:raise("update", dt)

   self.tool:update(dt, self)
end

--- @param modification Modification
function Editor:execute(modification)
   modification:execute(self.attachable, self)
   table.insert(self.undoStack, modification)
end

function Editor:undo()
   if #self.undoStack == 0 then return end

   local modification = table.remove(self.undoStack, #self.undoStack)
   modification:undo(self.attachable)
   table.insert(self.redoStack, modification)
end

function Editor:redo()
   if #self.redoStack == 0 then return end

   local modification = table.remove(self.redoStack, #self.redoStack)
   modification:execute(self.attachable)
   table.insert(self.undoStack, modification)
end

function Editor:draw()
   scene:beginFrame()

   self.editorRoot:render(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

   scene:finishFrame()
end

function Editor:mousereleased(x, y, button)
   if button == 1 then pointer:raise("release") end
end

function Editor:mousepressed(x, y, button)
   if button == 1 then pointer:raise("press") end
end

function Editor:mousemoved(x, y, dx, dy, istouch)
   if love.mouse.isDown(2) then
      pointer:setPosition(x, y)
      pointer:raise("drag", dx, dy)
   end
end

function Editor:keypressed(key, scancode)
   pointer:raise("keypressed", key)
   if not self.keybindsEnabled then return end

   local mode
   if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
      mode = "ctrl"
   end

   local action = keybinds:keypressed(key, mode)
   if action then scene:raise(action, pointer) end
   if action == "undo" then
      self:undo()
   elseif action == "redo" then
      self:redo()
   elseif action == "fill" then
      self.fillMode = not self.fillMode
      scene:raise("fillMode", self.fillMode)
   elseif action == "mode" then
      self.selectorMode = self.selectorModes[self.selectorMode]
   elseif action == "copy" then
      if self.tool.copy then self.tool:copy(self.attachable) end
   elseif action == "paste" then
      if self.tool.paste then self.tool:paste(self.attachable) end
   end
end

function Editor:textinput(text)
   pointer:raise("textinput", text)
end

function Editor:wheelmoved(dx, dy)
   pointer:raise("scroll", dx, dy)
end

return Editor
