-- TODO: Actually test and use this as an example.
local RectModification = geometer.require "modifications.rect"

--- @class RectTool : Tool
--- @field origin Vector2
--- @field second Vector2
local RectTool = geometer.Tool:extend "RectTool"

function RectTool:__new()
   self.origin = nil
end

--- @param editor Editor
--- @param attachable SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function RectTool:mouseclicked(editor, attachable, x, y)
   if not attachable:inBounds(x, y) then return end

   self.origin = prism.Vector2(x, y)
end

function RectTool:update(dt, editor)
   local x, y = editor.levelDisplay:getCellUnderMouse()
   if not editor.attachable:inBounds(x, y) then return end

   self.second = prism.Vector2(x, y)
end

--- @param editor Editor
--- @param attachable SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function RectTool:mousereleased(editor, attachable, x, y)
   local lx, ly, rx, ry = self:getCurrentRect()
   if not lx then return end

   local modification = RectModification(
      editor.placeable,
      prism.Vector2(lx, ly),
      prism.Vector2(rx, ry),
      editor.fillMode
   )
   editor:execute(modification)

   self.origin = nil
   self.second = nil
end

--- Returns the four corners of the current rect.
--- @return number? topleftx
--- @return number? toplefty
--- @return number? bottomrightx
--- @return number? bottomrighty
function RectTool:getCurrentRect()
   if not self.origin or not self.second then return end

   local x, y = self.origin.x, self.origin.y
   local sx, sy = self.second.x, self.second.y

   local lx, ly = math.min(x, sx), math.min(y, sy)
   local rx, ry = math.max(x, sx), math.max(y, sy)

   return lx, ly, rx, ry
end

--- @param display Display
function RectTool:draw(editor, display)
   local lx, ly, rx, ry = self:getCurrentRect()
   if not (lx and ly and rx and ry) then return end

   local drawable = self:getDrawable(editor.placeable)
   if editor.fillMode then
      for x = lx, rx do
         for y = ly, ry do
            self:drawCell(display, drawable, x, y)
         end
      end
   else
      for x = lx, rx do
         self:drawCell(display, drawable, x, ly)
         self:drawCell(display, drawable, x, ry)
      end

      for y = ly, ry do
         self:drawCell(display, drawable, rx, y)
         self:drawCell(display, drawable, lx, y)
      end
   end
end

return RectTool
