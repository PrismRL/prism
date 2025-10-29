--- @class LevelState : GameState
--- Represents the state for running a level, including managing the game loop,
--- handling decisions, messages, and drawing the interface.
--- @field decision? ActionDecision The current decision being processed, if any.
--- @field level Level The level object representing the game environment.
--- @field display Display The display object used for rendering.
--- @field message ActionMessage The most recent action message.
--- @field editor EditorState An editor state for debugging or managing geometry.
local LevelState = spectrum.GameState:extend("LevelState")

--- Constructs a new LevelState.
--- Sets up the game loop, initializes decision handlers, and binds custom callbacks for drawing.
--- @param level Level The level object to be managed by this state.
--- @param display Display The display object for rendering the level.
function LevelState:__new(level, display)
   assert(level and display)
   self.level = level
   self.updateCoroutine = coroutine.create(level.run)
   self.decision = nil
   self.message = nil
   self.display = display
   if geometer then self.editor = spectrum.gamestates.EditorState(self.level, self.display) end
   self.time = 0
end

--- Determines if the coroutine should proceed to the next step.
--- @return boolean|nil shouldAdvance True if the coroutine should advance; false otherwise.
function LevelState:shouldAdvance()
   local hasDecision = self.decision ~= nil
   local decisionDone = hasDecision and self.decision:validateResponse()

   --- @diagnostic disable-next-line
   if not self.manager or self.manager.states[#self.manager.states] ~= self then return false end

   return (not hasDecision or decisionDone) and not self.display.blocking
end

--- Updates the state of the level.
--- Advances the coroutine and processes decisions or messages if necessary.
--- @param dt number The time delta since the last update.
function LevelState:update(dt)
   self.time = self.time + dt
   self.display:update(self.level, dt)

   while self:shouldAdvance() do
      local message = prism.advanceCoroutine(self.updateCoroutine, self.level, self.decision)
      self.decision, self.message = nil, nil
      if message then self:handleMessage(message) end
   end

   if self.decision then self:updateDecision(dt, self.decision.actor, self.decision) end

   if spectrum.Input.key["`"].pressed and self.editor then self.manager:push(self.editor) end
end

--- Sets the action for the current decision, if one exists.
--- @param action Action The action to set for the current decision.
--- @return boolean success True if the action was successfully set; false otherwise.
--- @return string? error An error message if the action could not be set.
function LevelState:setAction(action)
   if self.decision then return self.decision:setAction(action, self.level) end
   return false, "No decision to set action for."
end

--- Handles incoming messages from the coroutine.
--- Processes decisions, action messages, and debug messages as appropriate.
--- @param message Message The message to handle.
function LevelState:handleMessage(message)
   if prism.decisions.ActionDecision:is(message) then
      --- @cast message ActionDecision
      self.decision = message
   elseif prism.messages.DebugMessage:is(message) and self.editor then
      self.manager:push(self.editor)
   elseif prism.messages.AnimationMessage:is(message) then
      --- @cast message AnimationMessage
      self.display:yieldAnimation(message)
   end
end

--- Collects and returns all player controlled senses into a group of
--- primary (active turn) and secondary (other player controlled actors).
--- @return Senses[] primary, Senses[] secondary
function LevelState:getSenses()
   local curActor
   if self.decision then
      local actionDecision = self.decision
      ---@cast actionDecision ActionDecision
      curActor = actionDecision.actor
   elseif self.message then
      if self.message.action.owner:has(prism.components.PlayerController) then
         curActor = self.message.action.owner
      end
   end

   local sensesComponent = curActor and curActor:get(prism.components.Senses)
   local primary = { sensesComponent }
   local secondary = {}

   local query = self.level:query(prism.components.PlayerController, prism.components.Senses)
   for _, _, senses in query:iter() do
      table.insert(secondary, senses)
   end

   if #primary == 0 then
      primary = secondary
      secondary = {}
   end

   return primary, secondary
end

--- Draws the current state of the level, including the perspective of relevant actors.
function LevelState:draw()
   self.display:clear()

   local primary, secondary = self:getSenses()
   -- Render the level using the actor’s senses
   self.display:putSenses(primary, secondary, self.level)
   self.display:draw()
end

--- This method is invoked each update when a decision exists
--- and its response is not yet valid. Override this method in subclasses to implement
--- custom decision-handling logic.
--- @param dt number The time delta since the last update.
--- @param actor Actor The actor responsible for making the decision.
--- @param decision ActionDecision The decision being updated.
function LevelState:updateDecision(dt, actor, decision)
   -- override in subclasses
end

--- Compute a custom mouse transform for retrieving cells.
--- This should return the mouse coordinates transformed to the display's context.
--- e.g. if you scale the display by 3x, this should scale it back down by 3x.
--- @param mx number The X-coordinate of the mouse.
--- @param my number The Y-coordinate of the mouse.
--- @return number mx The transformed X-coordinate.
--- @return number my The transformed Y-coordinate.
function LevelState:transformMousePosition(mx, my)
   return mx, my
end

--- Returns the X-coordinate, Y-coordinate, and cell the mouse is over, if the mouse is over a cell.
--- @return integer? x
--- @return integer? y
--- @return Cell?
function LevelState:getCellUnderMouse()
   local mx, my = love.mouse.getPosition()
   local x, y = self.display:getCellUnderMouse(self:transformMousePosition(mx, my))
   return x, y, self.level:getCell(x, y)
end

--- Gets the actor waiting for an action. Usually the player.
--- @return Actor?
function LevelState:getCurrentActor()
   return self.decision and self.decision.actor or nil
end

return LevelState
