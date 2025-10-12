--- @param self UI
--- @param text string
--- @param w integer
--- @param h integer
--- @param opts any
local function textInput(self, text, w, h, opts)
   opts = opts or {}
   text = tostring(text or "")

   local style = self:getStyle()

   local iw = math.max(style.layout.itemW, w or 4)
   local ih = h or style.layout.itemH
   local x, y = self:getCursor()

   self:pushID(("textinput@%d,%d"):format(x, y))
   local id = self:makeID()

   self._editors = self._editors or {}
   local st = self._editors[id] or { caret = #text }
   self._editors[id] = st
   if st.caret > #text then st.caret = #text end

   -- Hover/focus
   local hovered = self:_scopeAcceptsMouse() and self:_mouseOver(x, y, iw, ih)
   if hovered then self:setMouseCursor("ibeam") end
   if hovered and self.io.mpressed then
      self.active, self.focus = id, id
      st._wantClickCol = math.max(0, self.io.mx - (x + style.textinput.pad))
   end
   if self.active == id and self.io.mreleased then self.active = nil end
   local focused = (self.focus == id)

   local submitted, changed = false, false
   local curText = text

   -- Editing
   if focused then
      if #self.io.textInput >= 1 then
         curText = curText:sub(1, st.caret) .. self.io.textInput .. curText:sub(st.caret + 1)
         st.caret = st.caret + #self.io.textInput
         changed = true
      end
      local keys = self.io.keysDown
      if keys["backspace"] and st.caret > 0 then
         curText = curText:sub(1, st.caret - 1) .. curText:sub(st.caret + 1)
         st.caret, changed = st.caret - 1, true
      end
      if keys["left"] then st.caret = math.max(0, st.caret - 1) end
      if keys["right"] then st.caret = math.min(#curText, st.caret + 1) end
      if keys["enter"] or keys["kp_enter"] or keys["return"] then
         submitted, self.focus = true, nil
      end
   end

   local innerCols  = math.max(1, iw - 2 * style.textinput.pad)  -- text area width in cells
   local windowCols = math.max(1, innerCols - 1) -- glyph cols; 1 col reserved for caret
   local n          = #curText
   local c0         = st.caret
   local half       = math.floor(windowCols / 2)

   local maxStart0  = math.max(0, n - windowCols)
   local start0     = math.max(0, math.min(maxStart0, c0 - half))
   local start1     = start0 + 1

   if st._wantClickCol ~= nil then
      local clickCol = math.max(0, math.min(st._wantClickCol, windowCols))
      st._wantClickCol = nil
      st.caret = math.max(0, math.min(n, start0 + clickCol))
      c0 = st.caret
      start0 = math.max(0, math.min(maxStart0, c0 - half))
      start1 = start0 + 1
   end

   local end1 = math.min(n, start1 + windowCols - 1)
   local visibleText = (n == 0) and "" or curText:sub(start1, end1)

   -- Placeholder (only when unfocused and empty)
   if visibleText == "" and not focused and opts.placeholder then
      self:_text(x + style.textinput.pad, y, opts.placeholder, style.colors.textDim, "left")
   else
      self:_text(x + style.textinput.pad, y, visibleText, style.colors.text, "left")
   end

   if focused and (self.frame % 180) < 90 then
      local caretColLocal = c0 - start0 

      -- Make sure caret is inside the padded box:
      caretColLocal = math.max(0, math.min(caretColLocal, windowCols))
      self:_text(x + style.textinput.pad + caretColLocal, y, style.textinput.caretGlyph, style.textinput.caretColor, "left")
   end

   self:_bgRect(x, y, iw, ih, style.textinput.bg)

   self:_advanceCursor(iw, ih)
   self:popID()
   return curText, submitted, changed
end

return textInput