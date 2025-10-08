--- Checkbox widget (immediate-mode)
--- @param self UI
--- @param label string               -- text shown to the right of the box
--- @param value boolean|nil          -- current state (nil treated as false)
--- @param opts { style?: Style }|nil
--- @return boolean newValue          -- possibly-toggled value
--- @return boolean changed           -- true iff value changed this frame
local function checkbox(self, label, value, opts)
   label = tostring(label or "")
   value = not not value

   if opts and opts.style then
      self:pushStyle(opts.style)
   end

   local style = self:getStyle()
   local itemH = style.layout.itemH
   local boxSize = 1
   local spacing = style.checkbox.spacing
   local mark = style.checkbox.mark

   local minW = boxSize + spacing + #label
   local x, y, iw, ih = self:_itemRect(minW, itemH)

   self:pushID(("checkbox@%d,%d:%s"):format(x, y, label))
   local id = self:makeID()
   local win = self:_currentScope()

   local hovered = false
   local clicked = false

   if self:_scopeAcceptsMouse() then
      hovered = self:_mouseOver(x, y, iw, ih)
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
   end

   local boxBg = style.button.bg
   local boxHotBg = style.button.hotBg
   local boxActiveBg = style.button.activeBg
   local boxFg = style.button.fg
   local labelFg = style.button.fg

   if self.active == id then
      boxBg = boxActiveBg
   elseif hovered then
      boxBg = boxHotBg
   end

   local bx = x
   local by = y + math.floor((ih - boxSize) / 2)

   if value then
      local mx = bx + math.max(0, math.floor((boxSize - #mark) / 2))
      local my = by + math.floor((boxSize - 1) / 2)
      self:_text(mx, my, mark, boxFg)
   end

   self:_bgRect(bx, by, boxSize, boxSize, boxBg)

   if label ~= "" then
      local lx = bx + boxSize + spacing
      self:_text(lx, y, label, labelFg, style.button.align)
   end

   local newValue = value
   local changed = false
   if clicked then
      newValue = not value
      changed = true
   end

   self:_advanceCursor(iw, ih)
   self:popID()

   if opts and opts.style then
      self:popStyle()
   end

   return newValue, changed
end

return checkbox
