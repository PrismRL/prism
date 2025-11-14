--- The 'abstract class' that Schedulers should inherit from and implement.
--- @class Scheduler : Object
--- @overload fun(): Scheduler
local Scheduler = prism.Object:extend("Scheduler")

--- Constructor for the Scheduler class.
--- Initializes an empty queue and sets the actCount to 0.
function Scheduler:__new()
   error "Scheduler is an abstract base class for the schedulers in prism! Try SimpleScheduler instead."
end

--- Adds an actor to the scheduler.
--- @param actor Actor|string The actor, or special tick, to add.
function Scheduler:add(actor)
   error "You must override the add method in your custom scheduler implementation!"
end

--- Removes an actor from the scheduler.
--- @param actor Actor The actor to remove.
function Scheduler:remove(actor)
   error "You must override the remove method in your custom scheduler implementation!"
end

--- Checks if an actor is in the scheduler.
--- @param actor Actor The actor to check.
--- @return boolean hasActor True if the actor is in the scheduler, false otherwise.
function Scheduler:has(actor)
   error "You must override the remove method in your custom scheduler implementation!"
end

--- Returns the next actor to act.
--- @return Actor next The actor who is next to act.
function Scheduler:next()
   error "You must override the remove method in your custom scheduler implementation!"
end

function Scheduler:timestamp()
   error "You must override the remove method in your custom scheduler implementation!"
end

function Scheduler:empty()
   error "You must override the empty method in your custom scheduler implementation!"
end

return Scheduler
