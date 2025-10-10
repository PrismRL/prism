--- @param self UI
--- @param name string
--- @param items string[]|table[]              -- string or {label=...}
--- @param selected integer|nil                -- 1-based
--- @param w integer                           -- container width
--- @param h integer                           -- container height
--- @param opts { style: Style }
local function list(self, name, items, selected, w, h, opts)
   if opts and opts.style then
      self:pushStyle(opts.style)
   end
   
   local style = self:getStyle()
   local rowH   = style.layout.itemH
   local padX   = style.layout.padX
   local fg     = style.list.fg
   local selBg  = style.list.selBg
   local hotBg  = style.list.hotBg
   local rowBgA = style.list.rowBgA
   local rowBgB = style.list.rowBgB

   if selected and (#items == 0 or selected < 1) then selected = nil end
   if selected and selected > #items then selected = #items end

   self:beginContainer("list:" .. name, w, h)

   local scope             = self:_currentScope()
   local baseZ             = scope and scope.z or 0
   local iw                = scope.innerW
   local x, y              = self:getCursor()

   local newSel, activated = selected, false

   for i = 1, #items do
      local label = items[i]
      if type(label) == "table" then label = label.label or tostring(items[i]) end
      label = tostring(label or "")

      local ry = y + (i - 1) * rowH

      self:_text(x + padX, ry, label, fg, "left", iw - padX)


      local rowHovered = self:_scopeAcceptsMouse() and self:_mouseOver(x, ry, iw, rowH)
      local isSel      = (newSel == i)
      
      -- Overlays: selection beats hover
      if isSel then
         self:_bgRect(x, ry, iw, rowH, selBg)
      elseif rowHovered then
         self:_bgRect(x, ry, iw, rowH, hotBg)
      end

      -- Base checkered row background first (so highlights overlay cleanly)
      local baseRowBg = ((i % 2) == 1) and rowBgA or rowBgB
      if baseRowBg then
         self:_bgRect(x, ry, iw, rowH, baseRowBg)
      end

      if rowHovered then
         local rid = ("list@%s#row%d"):format(name, i)
         self.hot = rid
         if self.io.mpressed then self.active = rid end
         if self.active == rid and self.io.mreleased then
            newSel, activated, self.active = i, true, nil
         end
      end
   end

   scope:setContentSize(self, iw, #items * rowH)
   self:endContainer()

   if opts and opts.style then
      self:popStyle()
   end

   return newSel, activated
end

return list