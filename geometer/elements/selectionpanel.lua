local Inky = geometer.require "inky"
---@type TextInputInit
local TextInput = geometer.require "elements.textinput"
---@type SelectionGridInit
local SelectionGrid = geometer.require "elements.selectiongrid"
---@type ButtonInit
local Button = geometer.require "elements.button"

---@return Placeable[]
local function initialElements()
   local t = {}
   for _, cell in pairs(prism.cells) do
      table.insert(t, cell)
   end

   for _, actor in pairs(prism.actors) do
      table.insert(t, actor())
   end

   return t
end

---@class SelectionPanelProps : Inky.Props
---@field placeables Placeable[]
---@field selected Placeable
---@field selectedText love.Text
---@field filtered number[]
---@field display Display
---@field size Vector2
---@field editor Editor
---@field overlay love.Canvas

---@class SelectionPanel : Inky.Element
---@field props SelectionPanelProps

---@param self SelectionPanel
---@param scene Inky.Scene
---@return function
local function SelectionPanel(self, scene)
   ---@param placeable Placeable
   local function onSelect(placeable)
      self.props.selected = placeable
      self.props.selectedText:set(placeable.name)

      if placeable:is(prism.Actor) then placeable = getmetatable(placeable) end

      self.props.editor.placeable = placeable
   end

   -- We capture and consume pointer events to avoid the editor grid consuming them,
   -- since the grid overlaps with the panel
   self:onPointerEnter(function(_, pointer)
      pointer:captureElement(self)
   end)

   self:onPointerExit(function(_, pointer)
      pointer:captureElement(self, false)
   end)

   self:onPointer("press", function() end)

   self:onPointer("scroll", function() end)

   self.props.placeables = initialElements()
   self.props.filtered = {}
   for i = 1, #self.props.placeables do
      self.props.filtered[i] = i
   end

   local grid = SelectionGrid(scene)
   grid.props.placeables = self.props.placeables
   grid.props.filtered = self.props.filtered
   grid.props.display = self.props.display
   grid.props.overlay = self.props.overlay
   grid.props.onSelect = onSelect
   grid.props.size = self.props.size

   local font = love.graphics.newFont(geometer.assetPath .. "/assets/FROGBLOCK-Polyducks.ttf", self.props.size.x - 8)
   local textInput = TextInput(scene)
   textInput.props.font = font
   textInput.props.overlay = self.props.overlay
   textInput.props.size = self.props.size
   textInput.props.placeholder = "SEARCH"
   textInput.props.onEdit = function(content)
      local filtered = {}
      for i, placeable in ipairs(self.props.placeables) do
         if placeable.name:find(content) then table.insert(filtered, i) end
      end
      self.props.filtered = filtered
      grid.props.filtered = filtered
   end

   local clearButton = Button(scene)
   clearButton.props.onPress = function()
      textInput.props.content = ""
   end

   local background = love.graphics.newImage(geometer.assetPath .. "/assets/panel.png")
   local panelTop = love.graphics.newImage(geometer.assetPath .. "/assets/panel_top.png")
   local highlight = prism.Color4.fromHex(0x2ce8f5)
   local fontSize = self.props.size.x - (self.props.size.x > 48 and 24 or 8)
   local selectionFont = love.graphics.newFont(geometer.assetPath .. "/assets/FROGBLOCK-Polyducks.ttf", fontSize)
   self.props.selectedText = love.graphics.newText(selectionFont, "")

   return function(_, x, y, w, h, depth)
      local offsetY = love.graphics.getCanvas():getHeight() - background:getHeight()
      love.graphics.draw(background, x, offsetY)
      love.graphics.draw(panelTop, x)

      textInput:render(x + 8 * 3, y + 2 * 8, 8 * 8, 8, depth + 1)
      clearButton:render(x + 8 * 11, y + 2 * 8, 8, 8, depth + 2)
      grid:render(x, y + 5 * 8, w, 8 * 12, depth + 1)

      local drawable = self.props.selected:getComponent(prism.components.Drawable)
      local color = drawable.color or prism.Color4.WHITE
      local quad = spectrum.Display.getQuad(self.props.display.spriteAtlas, drawable)
      local scale = prism.Vector2(
         self.props.size.x / self.props.display.cellSize.x,
         self.props.size.y / self.props.display.cellSize.y
      )

      love.graphics.push("all")
      love.graphics.setCanvas(self.props.overlay)
      love.graphics.setFont(selectionFont)
      love.graphics.setColor(highlight:decompose())
      love.graphics.draw(
         self.props.selectedText,
         (x / 8 + 5) * self.props.size.x,
         (y / 8 + 17) * self.props.size.y + self.props.size.y / 4
      )
      love.graphics.setColor(color:decompose())
      love.graphics.draw(
         self.props.display.spriteAtlas.image,
         quad,
         (x / 8 + 3) * self.props.size.x,
         (y / 8 + 17) * self.props.size.y,
         nil,
         scale.x,
         scale.y
      )
      love.graphics.pop()
   end
end

---@alias SelectionPanelInit fun(scene: Inky.Scene): SelectionPanel
---@type SelectionPanelInit
local SelectionPanelElement = Inky.defineElement(SelectionPanel)
return SelectionPanelElement
