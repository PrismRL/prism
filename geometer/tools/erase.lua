-- TODO: Actually test and use this is an example.
local EraseModification = geometer.require "modifications.erase"

--- @class EraseTool : Tool
--- @field origin Vector2
local Erase = geometer.Tool:extend "EraseTool"

function Erase:__new()
   self.origin = nil
end

--- @param editor Editor
--- @param attached SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function Erase:mouseclicked(editor, attached, x, y)
   if not attached:inBounds(x, y) then return end

   self.origin = prism.Vector2(x, y)
end

--- @param editor Editor
--- @param attached SpectrumAttachable
--- @param x integer The cell coordinate clicked.
--- @param y integer The cell coordinate clicked.
function Erase:mousereleased(editor, attached, x, y)
   if not self.origin or not self.second then return nil end

   local lx, ly, rx, ry = self:getCurrentRect()
   local modification =
      EraseModification(editor.placeable, prism.Vector2(lx, ly), prism.Vector2(rx, ry))
   editor:execute(modification)

   self.origin = nil
end

--- Returns the four corners of the current rect.
--- @return number? topleftx
--- @return number? toplefy
--- @return number? bottomrightx
--- @return number? bottomrighty
function Erase:getCurrentRect()
   if not self.origin or not self.second then return end

   local x, y = self.origin.x, self.origin.y
   local sx, sy = self.second.x, self.second.y

   local lx, ly = math.min(x, sx), math.min(y, sy)
   local rx, ry = math.max(x, sx), math.max(y, sy)

   return lx, ly, rx, ry
end

local background = prism.Color4.fromHex(0xe43b44)

--- @param display Display
function Erase:draw(editor, display)
   if not self.origin then return end

   local lx, ly, rx, ry = self:getCurrentRect()

   display:push()
   for x = lx, rx do
      for y = ly, ry do
         display:putBG(x, y, background, math.huge)
      end
   end
   display:pop()
end

function Erase:update(dt, editor)
   local x, y = editor.display:getCellUnderMouse()
   if not editor.attachable:inBounds(x, y) then return end

   self.second = prism.Vector2(x, y)
end

return Erase
