--- @meta

--- The actor registry.
prism.actors = {}

--- The actions registry.
prism.actions = {}

--- The component registry.
prism.components = {}

--- The component registry.
prism.cells = {}

--- The target registry.
prism.targets = {}

--- The message registry.
prism.messages = {}

--- The system registry.
prism.systems = {}

--- The decision registry.
prism.decisions = {}

--- THe relationships registry
prism.relationships = {}

--- Registers a CellFactory in the cells registry.
--- @param name string
--- @param factory CellFactory
function prism.registerCell(name, factory) end

--- Registers an ActorFactory in the actors registry.
--- @param name string
--- @param factory ActorFactory
function prism.registerActor(name, factory) end

--- Registers a TargetFactory in the targets registry.
--- @param name string
--- @param factory TargetFactory
function prism.registerTarget(name, factory) end
