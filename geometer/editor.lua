--- @type Controls
local controls = geometer.require "controls"
local PenTool = geometer.require "tools.pen"

--- @type UI
local UI = spectrum.UI()

---@alias Placeable { entity: Entity, factory: fun(): Entity }

---@class Editor : Object
---@field attachable SpectrumAttachable
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

function Editor:update(dt)
   self.tool:update(dt, self)
   local cx, cy = self.display:getCellUnderMouseRaw()
   UI:feedMouse(cx, cy, spectrum.Input.mouse["1"].down, spectrum.Input.mouse["1"].pressed,
   spectrum.Input.mouse["1"].released)
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
   self.display:putLevel(self.attachable)
   self:ui()
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
         self.placeable = {factory = placeablesMap[selection], entity = placeablesMap[selection]()}
      end
   UI:endWindow()
end

local maxHP = 100
local hp = 75
local damage = 5
local speed = 3
local range = 1.5

function Editor:ui()
   UI:beginFrame(self.display)
      self:placeableSelection()
      UI:beginWindow("Actor", 1, 1, 30, 20)

         -- Health component
         if UI:beginCollapsibleCategory("Health") then
            local numMaxHP = tonumber(maxHP) or 0
            hp, _ = UI:slider("hp", hp, 0, numMaxHP, 10)

            UI:endCollapsibleCategory()
         end

         -- Attacker component
         if UI:beginCollapsibleCategory("Attacker") then
            damage, _ = UI:slider("damage", damage, 1, 10, 10)
            UI:endCollapsibleCategory()
         end

         -- Movement component
         if UI:beginCollapsibleCategory("Movement") then
            speed, _ = UI:slider("speed", speed, 0, 10, 10)
            range, _ = UI:slider("range", range, 0, 5, 10)

            UI:endCollapsibleCategory()
         end

      UI:endWindow()
   UI:endFrame()
end


function Editor:toolbar()
end

function Editor:mousereleased(x, y, button)
end

function Editor:mousepressed(x, y, button)
   local x, y = self.display:getCellUnderMouse(x, y)
   --self.tool:mouseclicked(self, self.attachable, x, y)
end

function Editor:mousemoved(x, y, dx, dy, istouch)
   local x, y = self.display:getCellUnderMouse(x, y)
   --self.tool:mousereleased(self, self.attachable, x, y)
end

function Editor:keypressed(key)
   UI:feedKey(key, true)
end

function Editor:textinput(text)
   UI:feedText(text)
end

function Editor:wheelmoved(dx, dy)
end

return Editor
