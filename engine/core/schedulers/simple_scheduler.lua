--- The 'SimpleScheduler' manages a queue of actors and schedules their actions.
--- This implementation of the base 'Scheduler' class uses a simple round-robin system,
--- where each actor takes its turn in order. It tracks the global round count and can be
--- customized according to the needs of your game.
--- @class SimpleScheduler : Scheduler
--- @overload fun(): SimpleScheduler
local SimpleScheduler = prism.Scheduler:extend("SimpleScheduler")

--- Constructor for the SimpleScheduler class.
--- Initializes an empty queue and sets the round count to 0.
function SimpleScheduler:__new()
   self.currentQueue = prism.Queue()
   self.nextQueue = prism.Queue()
   self.roundCount = 0
end

--- Adds an actor to the scheduler.
--- @param actor Actor|string The actor, or special tick, to add.
function SimpleScheduler:add(actor)
   self.currentQueue:push(actor)
end

--- Removes an actor from the scheduler.
--- @param actor Actor The actor to remove.
function SimpleScheduler:remove(actor)
   self.currentQueue:remove(actor)
   self.nextQueue:remove(actor)
end

--- Checks if an actor is in the scheduler.
--- @param actor Actor The actor to check.
--- @return boolean True if the actor is in the scheduler, false otherwise.
function SimpleScheduler:has(actor)
   return self.currentQueue:contains(actor)
end

--- Returns the next actor to act.
--- Moves the actor to the next queue and returns the actor.
--- If the current queue is empty, it swaps the current and next queues and increments the round count.
--- @return Actor The actor who is next to act.
function SimpleScheduler:next()
   if self.currentQueue:empty() then
      self:swapQueues()
      self.roundCount = self.roundCount + 1
   end

   local nextActor = self.currentQueue:pop()
   self.nextQueue:push(nextActor)

   return nextActor
end

function SimpleScheduler:empty()
   return self.currentQueue:empty() and self.nextQueue:empty()
end

--- Swaps the current and next queues.
function SimpleScheduler:swapQueues()
   local tempQueue = self.currentQueue
   self.currentQueue = self.nextQueue
   self.nextQueue = tempQueue
end

--- Returns the current round count as a timestamp.
--- @return number -- The current round count.
function SimpleScheduler:timestamp()
   return self.roundCount
end

return SimpleScheduler
