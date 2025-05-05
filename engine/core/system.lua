--- A 'System' is a class representing a level-wide event handler that can be attached to a Level object.
--- It listens to events such as an actor taking an action, moving, or a tick of time.
--- This should be used for mechanics that affect the entire level; such as hunger, fov, or lighting.
--- For event handlers that apply to a single actor, use a Condition instead. If you want a system that
--- receives all messages from all levels, like tracking the player's favor with a god attach it to
--- the game instead. A system's methods should never be mutated at run time, the SystemManager does
--- cacheing on the event handlers here to improve performance.
--- @class System : Object
--- @field global boolean A system defined global can only be attached to the Game object. It will see all events from all levels.
--- @field name string A system must define a name that is unique to the System.
--- @field requirements string[] A table of requirements that must be met for the System to be attached to a Level.
--- @field softRequirements string[] A table of optional requirements that ensure proper order if both Systems are attached.
--- @field owner Level? The level that holds this system.
--- @field beforeActions table<Action, fun(level: Level, actor: Actor, action: Action)> A table mapping specific actions to event hooks.
--- @field afterActions table<Action, fun(level: Level, actor: Actor, action: Action)> A table mapping specific actions to event hooks.
--- @overload fun(): System
local System = prism.Object:extend("System")
System.global = false
System.name = nil
System.requirements = nil
System.softRequirements = nil
System.beforeActions = {}
System.afterActions = {}

--- This method is called when the Level is initialized. It is called after all of the Systems have been attached.
--- @param level Level The Level object this System is attached to.
function System:initialize(level) end

--- This method is called after the Level is initialized. It is called after all of the Systems have been initialized.
--- @param level Level The Level object this System is attached to.
function System:postInitialize(level) end

--- This method is called after an actor has selected an action, but before it is executed.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that has selected an action.
--- @param action Action The Action object that the Actor has selected to execute.
function System:beforeAction(level, actor, action) end

--- This method is called after an actor has taken an action.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that has taken an action.
--- @param action Action The Action object that the Actor has executed.
function System:afterAction(level, actor, action) end

--- This method is called before an actor moves.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that is moving.
--- @param from Vector2 The position the Actor is moving from.
--- @param to Vector2 The position the Actor is moving to.
function System:beforeMove(level, actor, from, to) end

--- This method is called after an actor has moved.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that has moved.
--- @param from Vector2 The position the Actor moved from.
--- @param to Vector2 The position the Actor moved to.
function System:onMove(level, actor, from, to) end

--- This method is called after an actor has been added to the Level.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that has been added.
function System:onActorAdded(level, actor) end

--- This method is called after an actor has been removed from the Level.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that has been removed.
function System:onActorRemoved(level, actor) end

--- Called when an actor or tile has its opacity changed.
--- @param level Level The Level object this System is attached to.
--- @param x number The x coordinate of the tile.
--- @param y number The y coordinate of the tile.
function System:afterOpacityChanged(level, x, y) end

--- This method is called every 100 units of time, a second, and can be used for mechanics such as hunger and fire spreading.
--- @param level Level The Level object this System is attached to.
function System:onTick(level) end

--- This method is called when a new turn begins. The actor is the actor that is about to take their turn.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that is about to take its turn.
function System:onTurn(level, actor) end

--- This method is called when a new turn ends.
--- @param level Level The Level object this System is attached to.
--- @param actor Actor The Actor object that is about to take its turn.
function System:onTurnEnd(level, actor) end

--- This method is called whenever the level yields back to the interface.
--- The most common usage for this right now is updating the sight component of any
--- input controlled actors in the Sight system.
--- @param level Level The Level object this System is attached to.
--- @param event Message The event data that caused the yield.
function System:onYield(level, event) end

return System
