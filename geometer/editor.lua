local PenTool = geometer.require "tools.pen"
local style = geometer.require "style"

--- @type UI
local UI = spectrum.UI(style.default)

---@alias Placeable { entity: Entity, factory: fun(): Entity }

---@class Editor : Object
---@field attachable SpectrumAttachable
---@field levelDisplay Display
---@field pickerOpen boolean
---@field display Display
---@field camera Camera
---@field active boolean
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

love.graphics.setDefaultFilter("nearest", "nearest")
local spriteAtlas =
   spectrum.SpriteAtlas.fromASCIIGrid(geometer.assetPath .. "/assets/tileset.png", 8, 8)

function Editor:__new(attachable, display, fileEnabled)
   self.attachable = attachable
   self.levelDisplay = display
   self.display = spectrum.Display(display.width, display.height, spriteAtlas, prism.Vector2(8, 8))
   -- self.levelDisplay.spriteAtlas = spriteAtlas
   self.active = false
   for _, v in pairs(prism.cells) do
      self.placeable = { entity = v(), factory = v }
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

local scaler = math.floor(math.min(love.graphics.getWidth() / 320, love.graphics.getHeight() / 200))
local scale = prism.Vector2(scaler, scaler)

function Editor:isActive()
   return self.active
end

function Editor:startEditing()
   self.active = true

   self.undoStack = {}
   self.redoStack = {}

   self.tool = getmetatable(self.tool)()

   self.attachable.debug = false
end

---@param attachable SpectrumAttachable
function Editor:setAttachable(attachable)
   self.attachable = attachable
end

--- @param controls Controls
function Editor:update(dt, controls)
   self.tool:update(dt, self)
   local cx, cy = self.display:getCellUnderMouseRaw(controls.get:mouse())
   local levelX, levelY = self.display:getCellUnderMouseRaw()

   if spectrum.Input.mouse[1].pressed then
      self.tool:mouseclicked(self, self.attachable, levelX, levelY)
   end

   if spectrum.Input.mouse[1].released then
      self.tool:mousereleased(self, self.attachable, levelX, levelY)
   end

   self.tool:update(dt, self)

   -- self.levelDisplay:setCamera(cx, cy)
   UI:feedMouse(
      cx,
      cy,
      spectrum.Input.mouse["1"].down,
      spectrum.Input.mouse["1"].pressed,
      spectrum.Input.mouse["1"].released
   )
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
   self.display:clear()
   self.levelDisplay:clear()

   self.levelDisplay:putLevel(self.attachable)
   self.tool:draw(self, self.levelDisplay)
   self:ui()

   self.levelDisplay:draw()
   love.graphics.scale(2)
   self.display:draw()
end

local totalPlaceables = {}
local totalPlaceablesMap = {}

local placeables = totalPlaceables
local placeablesMap = {}
local function filter(str)
   if str == "" then
      placeables = totalPlaceables
      placeablesMap = totalPlaceablesMap
   end

   local filtered = {}
   local map = {}

   for k, v in pairs(totalPlaceables) do
      if string.match(v, str) then
         table.insert(filtered, v)
         map[#filtered] = totalPlaceablesMap[k]
      end
   end

   placeables = filtered
   placeablesMap = map
end

local selection, yes = nil, false
function Editor:placeableInit()
   if self.placeableInited then return end

   for k, v in pairs(prism.actors) do
      table.insert(totalPlaceables, k)
      totalPlaceablesMap[#totalPlaceables] = v
   end

   for k, v in pairs(prism.cells) do
      table.insert(totalPlaceables, k)
      totalPlaceablesMap[#totalPlaceables] = v
   end

   self.placeableInited = true
end

local searchText = ""
function Editor:placeableSelection()
   self:placeableInit()

   local dh = self.display.height
   local dw = self.display.width
   local w = math.floor(dw / 4)
   UI:beginWindow("Select Placeable:", dw - w + 2, 0, w, dh + 2, {
      resizable = false,
      moveable = false,
      title = false,
   })
   searchText = UI:textInput(searchText, w - 3)
   filter(searchText)
   UI:newLine(1)

   selection, yes = UI:list("placeables", placeables, selection, w - 3, dh - 1)

   if yes and placeablesMap[selection] then
      self.placeable = { factory = placeablesMap[selection], entity = placeablesMap[selection]() }
   end
   UI:endWindow()
end

local pressed
function Editor:ui()
   -- stylua: ignore start
   UI:beginFrame(self.display)
      UI:pushStyle(style.mainPanel)
      UI:beginWindow(
         "",
         1,
         self.display.height - 2,
         self.display.width - 15,
         3,
         { moveable = false, title = false, resizable = false }
      )
         UI:pushStyle(style.playButton)
         if UI:button(string.char(26), 3, 1, pressed == ) then self.active = false end
         UI:popStyle()
         UI:sameLine()
         if UI:button("B", 3, 1, pressed == "B") then pressed = "B" end
         UI:sameLine()
         UI:button("C", 3, 1)
      UI:endWindow()
      UI:popStyle()
      self:placeableSelection()
   UI:endFrame()
   -- stylua: ignore end
end

function Editor:toolbar() end

function Editor:mousereleased(x, y, button) end

function Editor:mousepressed(x, y, button)
   local x, y = self.display:getCellUnderMouse(x, y)
end

function Editor:mousemoved(x, y, dx, dy, istouch)
   local x, y = self.levelDisplay:getCellUnderMouse(x, y)
   --self.tool:mousereleased(self, self.attachable, x, y)
end

function Editor:keypressed(key)
   UI:feedKey(key, true)
end

function Editor:textinput(text)
   UI:feedText(text)
end

function Editor:wheelmoved(dx, dy) end

return Editor
