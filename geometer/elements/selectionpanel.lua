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
   for _, cellFactory in pairs(prism.cells) do
      table.insert(t, { entity = cellFactory(), factory = cellFactory })
   end

   for _, actorFactory in pairs(prism.actors) do
      table.insert(t, { entity = actorFactory(), factory = actorFactory })
   end

   return t
end

---@class SelectionPanelProps : Inky.Props
---@field placeables Placeable[]
---@field selected Placeable
---@field selectedText love.TextBatch
---@field filtered number[]
---@field display Display
---@field size Vector2
---@field editor Editor
---@field overlay love.Texture

---@class SelectionPanel : Inky.Element
---@field props SelectionPanelProps

---@param self SelectionPanel
---@param scene Inky.Scene
---@return function
local function SelectionPanel(self, scene)
   ---@param index integer
   local function onSelect(index)
      local placeable = self.props.placeables[index]
      self.props.selected = placeable
      self.props.selectedText:set(placeable.entity:getName())

      -- We use the prototype so we can instantiate them into the level
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

   local font = love.graphics.newFont(
      geometer.assetPath .. "/assets/FROGBLOCK-Polyducks.ttf",
      self.props.size.x
   )
   local textInput = TextInput(scene)
   textInput.props.font = font
   textInput.props.overlay = self.props.overlay
   textInput.props.size = self.props.size
   textInput.props.placeholder = "SEARCH"
   textInput.props.limit = 7
   textInput.props.onEdit = function(content)
      local filtered = {}
      for i, placeable in ipairs(self.props.placeables) do
         local upper = string.upper(content)
         if placeable.entity:getName():upper():find(upper) then table.insert(filtered, i) end
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
   local selectionFont =
      love.graphics.newFont(geometer.assetPath .. "/assets/FROGBLOCK-Polyducks.ttf", fontSize)
   self.props.selectedText = love.graphics.newText(selectionFont, "")

   return function(_, x, y, w, h, depth)
      local offsetY = love.graphics.getCanvas():getHeight() - background:getHeight()
      love.graphics.draw(background, x, offsetY)
      love.graphics.draw(panelTop, x)

      textInput:render(x + 8 * 3, y + 2 * 8, 8 * 8, 8, depth + 1)
      clearButton:render(x + 8 * 11, y + 2 * 8, 8, 8, depth + 2)
      grid:render(x, y + 5 * 8, w, 8 * 12, depth + 1)

      local drawable = self.props.selected.entity:expect(prism.components.Drawable)
      local quad = self.props.display:getQuad(drawable.index)
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
      love.graphics.setColor(drawable.background:decompose())

      local spriteOffSetX = (x / 8 + 3) * self.props.size.x
      local spriteOffSetY = (y / 8 + 17) * self.props.size.y

      love.graphics.rectangle(
         "fill",
         spriteOffSetX,
         spriteOffSetY,
         self.props.size.x,
         self.props.size.y
      )
      love.graphics.setColor(drawable.color:decompose())
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
