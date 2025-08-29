local Inky = geometer.require "inky"

---@class TextInputProps : Inky.Props
---@field font love.Font
---@field content string
---@field overlay love.Texture
---@field size Vector2
---@field focused boolean
---@field onEdit function?
---@field placeholder string
---@field limit number the number of characters before we start panning

---@class TextInput : Inky.Element
---@field props TextInputProps

---@param self TextInput
---@param scene Inky.Scene
local function TextInput(self, scene)
   self.props.content = ""
   self.props.focused = false

   ---@param focused boolean
   ---@param pointer Inky.Pointer
   local function focus(focused, pointer)
      self.props.focused = focused
      pointer:captureElement(self, focused)
      scene:raise("focus", focused)
   end

   self:useEffect(function()
      self.props.onEdit(self.props.content)
   end, "content")

   self:onPointer("press", function(_, pointer)
      focus(pointer:doesOverlapElement(self), pointer)
   end)

   self:onPointerEnter(function(element, pointer)
      love.mouse.setCursor(love.mouse.getSystemCursor("ibeam"))
   end)

   self:onPointerExit(function(element, pointer)
      love.mouse.setCursor()
   end)

   self:onPointer("textinput", function(_, pointer, text)
      if self.props.focused then self.props.content = self.props.content .. text end
   end)

   local blink = true
   local timer = 0
   self:on("update", function(_, dt)
      timer = timer + dt
      if timer >= 0.5 then
         timer = 0
         blink = not blink
      end
   end)

   self:onPointer("update", function(_, pointer)
      if spectrum.Input.key.backspace.pressed then
         local content = self.props.content
         if string.len(content) > 0 then
            content = string.sub(content, 1, string.len(content) - 1)
         end
         self.props.content = content
      elseif spectrum.Input.key["return"].pressed or spectrum.Input.key.escape.pressed then
         focus(false, pointer)
      end
   end)

   local placeholderColor = prism.Color4.fromHex(0x5a6988)

   return function(_, x, y, w, h)
      x = (x / 8) * self.props.size.x
      y = (y / 8) * self.props.size.y
      local length = self.props.content:len()
      local offset = 0
      if length > self.props.limit then
         offset = (length - self.props.limit) * self.props.font:getHeight()
      end

      love.graphics.push("all")
      love.graphics.setScissor(x, y, (w / 8) * self.props.size.x, (h / 8) * self.props.size.y)
      love.graphics.translate(-offset, 0)
      love.graphics.setFont(self.props.font)
      love.graphics.setCanvas(self.props.overlay)
      love.graphics.scale(1, 1)
      if self.props.content == "" and not self.props.focused then
         love.graphics.setColor(placeholderColor:decompose())
         love.graphics.print(self.props.placeholder, x, y + self.props.size.y / 8)
      end
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(
         self.props.content .. ((blink and self.props.focused) and "Σ" or ""),
         x,
         y
      )
      love.graphics.pop()
   end
end

---@alias TextInputInit fun(scene: Inky.Scene): TextInput
---@type TextInputInit
local TextInputElement = Inky.defineElement(TextInput)
return TextInputElement
