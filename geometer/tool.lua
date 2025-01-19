---@class Tool : Object
---Represents a tool with update, draw, and mouse interaction functionalities.
---Tools can respond to user inputs and render visual elements.
local Tool = prism.Object:extend("Tool")

---Updates the tool state.
---@param dt number The time delta since the last update.
function Tool:update(dt, editor)
   -- Update logic.
end

---Draws the tool visuals.
---@param display Display
---@param editor Editor
function Tool:draw(editor, display)
   -- Draw visuals.
end

---Handles mouse click events.
---@param editor Editor
---@param cellx number The x-coordinate of the cell clicked.
---@param celly number The y-coordinate of the cell clicked.
function Tool:mouseclicked(editor, level, cellx, celly)
   -- Handle mouse clicks.
end

---Handles mouse release events.
---@param editor Editor
---@param cellx number The x-coordinate of the cell release.
---@param celly number The y-coordinate of the cell release.
function Tool:mousereleased(editor, level, cellx, celly) end

--- @param editor Editor
---@param level Level
---@param cellx integer
---@param celly integer
function Tool:overrideCellDraw(editor, level, cellx, celly) end

return Tool
