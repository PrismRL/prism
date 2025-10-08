--- @param self UI
--- @param text string
--- @param w integer
--- @param h integer
--- @param opts any
local function button(self, text, w, h, opts)
   text = tostring(text or "")

   if opts and opts.style then
      self:pushStyle(opts.style)
   end

   local style = self:getStyle()
   local calcW = math.max(style.layout.itemW, (text ~= "" and (#text + 2) or 2))
   local x, y, iw, ih = self:_itemRect(w or calcW, h or style.layout.itemH)

   self:pushID(("button@%d,%d:%s"):format(x, y, text))
   local id = self:makeID()

   local win = self:_currentScope()
   local bg = style.button.bg
   local clicked = false
   if self:_scopeAcceptsMouse() then
      local hovered = self:_mouseOver(x, y, iw, ih)

      if hovered then
         self.hot = id
         if self.io.mpressed then
            self.active = id
         end
      end

      if self.active == id and self.io.mreleased then
         if hovered then clicked = true end
         self.active = nil
      end


      if self.active == id then
         bg = style.button.activeBg
      elseif hovered then
         bg = style.button.hotBg
      end
   end

   self:_text(x, y, text, style.button.fg, style.button.align, iw)
   self:_bgRect(x, y, iw, ih, bg)

   self:_advanceCursor(iw, ih)
   self:popID()

   if opts and opts.style then
      self:popStyle()
   end

   return clicked
end

return button