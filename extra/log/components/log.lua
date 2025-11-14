--- A component that stores a queue of recent log messages.
--- @class Log : Component
--- @field messages Queue
--- @field messageLimit integer
--- @overload fun(size?: number): Log
local Log = prism.Component:extend("Log")

--- Initializes a new Log component instance.
--- @param size? integer An optional size limit for the log. Defaults to 32. Oldest messages are removed first.
function Log:__new(size)
   self.messages = prism.Queue()
   self.messageLimit = size or 32
end

--- Returns an iterator over the last `n` log messages, most recent first.
--- @param n integer The maximum number of messages to return.
--- @return fun(): string? iterator A function that returns each log message or nil when done.
function Log:iterLast(n)
   local q = self.messages
   local startIndex = q.last
   local endIndex = math.max(q.first, q.last - n + 1)
   local i = startIndex + 1

   return function()
      i = i - 1
      if i >= endIndex then return q.queue[i] end
   end
end

--- Adds a message to an actor's log component, if it exists.
--- @param actor Actor The actor.
--- @param message string The message, optionally with string.format characters.
--- @param ... any Additional parameters passed to message:format().
function Log.addMessage(actor, message, ...)
   --- @type Log
   local log = actor:get(Log)
   if not log then return end

   message = message:format(...)

   log.messages:push(message)

   if log.messages:size() > log.messageLimit then log.messages:pop() end
end

--- Adds a message to all actors who sensed the source actor at the time the message was generated.
--- @param level Level The level.
--- @param action Action The action.
--- @param message string The message, optionally with string.format characters.
--- @param ... any Additional parameters passed to message:format().
function Log.addMessageSensed(level, action, message, ...)
   local query = level
      :query(prism.components.Senses, prism.components.Log)
      :relation(action.owner, prism.relations.SensesRelation)

   for actor, _ in query:iter() do
      --- @cast actor Actor
      local valid = true
      if action.owner == actor then valid = false end
      for i = 1, action:getNumTargets() do
         if action:getTargeted(i) == actor then valid = false end
      end
      if valid then Log.addMessage(actor, message, ...) end
   end
end

function Log:clone()
   return Log(self.messageLimit)
end

return Log
