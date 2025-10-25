--- This is the global entrypoint into Prism.
prism = {}
prism.path = ...

function prism.require(p)
   return require(table.concat({ prism.path, p }, "."))
end

--- @module "engine.lib.json"
prism.json = prism.require "lib.json"

--- @module "engine.lib.log"
prism.logger = prism.require "lib.log"

--- @type boolean
prism._initialized = false

---@type DistanceType
prism._defaultDistance = "8way"

-- Root object

--- @module "engine.core.object"
prism.Object = prism.require "core.object"

-- Colors
--- @module "engine.math.color"
prism.Color4 = prism.require "math.color"

-- Math
--- @module 'engine.math.vector'
prism.Vector2 = prism.require "math.vector"

--- @module "engine.math.bounding_box"
prism.Rectangle = prism.require "math.rectangle"

--- @module "engine.math.bresenham"
prism.Bresenham = prism.require "math.bresenham"

--- @module "engine.algorithms.ellipse"
prism.Ellipse = prism.require "algorithms.ellipse"

--- @module "engine.algorithms.bfs"
prism.BreadthFirstSearch = prism.require "algorithms.bfs"

prism.neighborhood = prism.Vector2.neighborhood8

--- @param neighborhood Neighborhood
function prism.setDefaultNeighborhood(neighborhood)
   prism.neighborhood = neighborhood
end

-- Structures
--- @module "engine.structures.sparsemap"
prism.SparseMap = prism.require "structures.sparsemap"

--- @module "engine.structures.sparsegrid"
prism.SparseGrid = prism.require "structures.sparsegrid"

--- @module "engine.structures.sparsearray"
prism.SparseArray = prism.require "structures.sparsearray"

--- @module "engine.structures.grid"
prism.Grid = prism.require "structures.grid"

--- @module "engine.structures.booleanbuffer"
prism.BooleanBuffer = prism.require "structures.booleanbuffer"

--- @module "engine.structures.bitmaskbuffer"
prism.BitmaskBuffer = prism.require "structures.bitmaskbuffer"

--- @module "engine.structures.cascadingbitmaskbuffer"
prism.CascadingBitmaskBuffer = prism.require "structures.cascadingbitmaskbuffer"

--- @module "engine.structures.queue"
prism.Queue = prism.require "structures.queue"

--- @module "engine.structures.priority_queue"
prism.PriorityQueue = prism.require "structures.priority_queue"

-- Algorithms
prism.FOV = {}
--- @module "engine.algorithms.fov.row"
prism.FOV.Row = prism.require "algorithms.fov.row"
--- @module "engine.algorithms.fov.quadrant"
prism.FOV.Quadrant = prism.require "algorithms.fov.quadrant"
--- @module "engine.algorithms.fov.fraction"
prism.FOV.Fraction = prism.require "algorithms.fov.fraction"
--- @module "engine.algorithms.fov.fov"
prism.computeFOV = prism.require "algorithms.fov.fov"

--- @alias PassableCallback fun(x: integer, y: integer): boolean
--- @alias CostCallback fun(x: integer, y: integer): integer

--- @module "engine.algorithms.astar.path"
prism.Path = prism.require "algorithms.astar.path"

--- @module "engine.algorithms.astar.astar"
prism.astar = prism.require "algorithms.astar.astar"

-- Core
--- @module "engine.core.query"
prism.Query = prism.require "core.query"
--- @module "engine.core.scheduler.scheduler"
prism.Scheduler = prism.require "core.scheduler.scheduler"
--- @module "engine.core.scheduler.simple_scheduler"
prism.SimpleScheduler = prism.require "core.scheduler.simple_scheduler"
--- @module "engine.core.action"
prism.Action = prism.require "core.action"
--- @module "engine.core.component"
prism.Component = prism.require "core.component"
--- @module "engine.core.relation"
prism.Relation = prism.require "core.relation"
--- @module "engine.core.entity"
prism.Entity = prism.require "core.entity"
--- @module "engine.core.actor"
prism.Actor = prism.require "core.actor"
--- @module "engine.core.actorstorage"
prism.ActorStorage = prism.require "core.actorstorage"
--- @module "engine.core.cell"
prism.Cell = prism.require "core.cell"
--- @module "engine.core.rng"
prism.RNG = prism.require "core.rng"
--- @module "engine.core.system"
prism.System = prism.require "core.system"
--- @module "engine.core.system_manager"
prism.SystemManager = prism.require "core.system_manager"
--- @module "engine.core.levelbuilder"
prism.LevelBuilder = prism.require "core.levelbuilder"
--- @module "engine.core.map"
prism.Map = prism.require "core.map"
--- @module "engine.core.message"
prism.Message = prism.require "core.message"
--- @module "engine.core.decision"
prism.Decision = prism.require "core.decision"
--- @module "engine.core.target"
prism.Target = prism.require "core.target"
--- @module "engine.core.level"
prism.Level = prism.require "core.level"
--- @module "engine.core.collision"
prism.Collision = prism.require "core.collision"
-- Behavior Tree

prism.BehaviorTree = {}

--- @module "engine.core.behavior_tree.btnode"
prism.BehaviorTree.Node = prism.require "core.behavior_tree.btnode"
--- @module "engine.core.behavior_tree.btroot"
prism.BehaviorTree.Root = prism.require "core.behavior_tree.btroot"
--- @module "engine.core.behavior_tree.btselector"
prism.BehaviorTree.Selector = prism.require "core.behavior_tree.btselector"
--- @module "engine.core.behavior_tree.btsequence"
prism.BehaviorTree.Sequence = prism.require "core.behavior_tree.btsequence"
--- @module "engine.core.behavior_tree.btsucceeder"
prism.BehaviorTree.Succeeder = prism.require "core.behavior_tree.btsucceeder"
--- @module "engine.core.behavior_tree.btconditional"
prism.BehaviorTree.Conditional = prism.require "core.behavior_tree.btconditional"

--- @class Registry
--- @field name string
--- @field class Object
--- @field manualRegistration boolean
--- @field module string

--- @type Registry[]
prism.registries = {}

local function writeDefinitions(...)
   if prism._currentDefinitions then
      for _, line in ipairs({ ... }) do
         table.insert(prism._currentDefinitions, line)
      end
   end
end

--- Registers a factory for a registry.
--- @param registry Registry
local function registerFactory(registry)
   local className = registry.class.className

   writeDefinitions(
      string.format("Registers a %s in the %s registry.", className, registry.name),
      "--- @param name string A name for the factory",
      string.format("--- @param factory %sFactory", className),
      string.format("function %s.register%s(name, factory) end", registry.module, className)
   )

   local registryList = _G[registry.module][registry.name]

   _G[registry.module]["register" .. className] = function(objectName, factory)
      assert(
         registryList[objectName] == nil,
         className .. " " .. objectName .. " is already registered!"
      )
      registryList[objectName] = factory

      writeDefinitions(
         "--- @type fun(...): " .. className,
         string.format("%s.%s.%s = nil", registry.module, registry.name, objectName)
      )
   end
end

--- @param registry Registry
local function registerRegistration(registry)
   --- @type any[]
   local registryList = _G[registry.module][registry.name]
   local className = registry.class.className

   writeDefinitions(
      string.format("--- Registers a %s in the %s registry.", className, registry.name),
      "--- @param prototype " .. className .. " A " .. className .. " prototype.",
      string.format("function %s.register%s(prototype) end", registry.module, className)
   )

   _G[registry.module]["register" .. className] = function(object, skipDefinitions)
      assert(
         registry.class:is(object),
         "Tried to register a " .. className .. " but got " .. tostring(object) .. "!"
      )
      local objectName = object.className

      assert(
         objectName ~= "",
         string.format("Tried to register a %s wihout a valid stripped name!", className)
      )
      assert(
         registryList[objectName] == nil,
         string.format("Tried to register duplicate %s (%s)", className, objectName)
      )

      registryList[objectName] = object

      if skipDefinitions then return end

      writeDefinitions(
         "--- @class " .. object.className,
         "local " .. object.className .. " = nil",
         registry.module .. "." .. registry.name .. "." .. objectName .. " = " .. object.className
      )
   end
end

--- Registers a registry, a global list of game objects.
--- @param name string The name of the registry, e.g. "components".
--- @param type Object The type of the object, e.g. "Component".
--- @param factory? boolean Whether objects in the registry are registered with a factory. Defaults to false.
--- @param module? string The table to assign the registry to. Defaults to the prism global.
function prism.registerRegistry(name, type, factory, module)
   for _, registry in ipairs(prism.registries) do
      if registry.name == name then
         error("A registry with name " .. name .. " is already registered!")
      end
   end

   local moduleTable = _G[module] or prism
   if moduleTable[name] then
      error("namespace for registry " .. name .. "already contains " .. name .. "!")
   end
   moduleTable[name] = {}

   --- @type Registry
   local registry = {
      name = name,
      class = type,
      manualRegistration = factory or false,
      module = module or "prism",
   }
   table.insert(prism.registries, registry)

   if factory then
      registerFactory(registry)
   else
      registerRegistration(registry)
   end
end

prism.registerRegistry("components", prism.Component)
prism.registerRegistry("relations", prism.Relation)
prism.registerRegistry("targets", prism.Target, true)
prism.registerRegistry("cells", prism.Cell, true)
prism.registerRegistry("actions", prism.Action)
prism.registerRegistry("actors", prism.Actor, true)
prism.registerRegistry("messages", prism.Message)
prism.registerRegistry("decisions", prism.Decision)
prism.registerRegistry("systems", prism.System)

--- @param component string|Component
--- @param fields table<string, string>
function prism.registerComponent(component, fields, skipDefinitions)
   if type(component) == "string" then
      component = prism.Component:extend(component)
      if fields then
         function component:__new(options)
            for k, _ in pairs(fields) do
               self[k] = options[k]
            end
         end
      end
   end
   --- @cast component Component

   local name = component.className

   assert(
      prism.components[name] == nil,
      string.format("A component with name %s is already registered!", name)
   )

   prism.components[name] = component

   if skipDefinitions then return end

   local class = "--- @class " .. component.className .. " : Component"
   local constructor = "--- @overload fun("
   if fields then
      local options = component.className .. "Options"
      writeDefinitions("--- @class " .. options)
      constructor = constructor .. "options: " .. options
      for field, type in pairs(fields) do
         writeDefinitions("--- @field " .. field .. " " .. type)
      end
      writeDefinitions(class .. ", " .. options)
   end

   writeDefinitions(
      constructor .. "): " .. component.className,
      "local " .. component.className .. " = nil",
      "prism." .. "components" .. "." .. name .. " = " .. component.className
   )
end

--- @module "engine.core.systems.senses"
prism.systems.SensesSystem = prism.require "core.systems.senses"

--- @module "engine.core.components.collider"
prism.components.Collider = prism.require "core.components.collider"

--- @module "engine.core.components.controller"
prism.components.Controller = prism.require "core.components.controller"

--- @module "engine.core.components.player_controller"
prism.components.PlayerController = prism.require "core.components.player_controller"

--- @module "engine.core.components.senses"
prism.components.Senses = prism.require "core.components.senses"

--- @module "engine.core.components.remembered"
prism.components.Remembered = prism.require "core.components.remembered"

--- @module "engine.core.components.opaque"
prism.components.Opaque = prism.require "core.components.opaque"

--- @module "engine.core.components.name"
prism.components.Name = prism.require "core.components.name"

--- @module "engine.core.components.position"
prism.components.Position = prism.require "core.components.position"

--- @module "engine.core.decisions.actiondecision"
prism.decisions.ActionDecision = prism.require "core.decisions.actiondecision"

--- @module "engine.core.messages.actionmessage"
prism.messages.ActionMessage = prism.require "core.messages.actionmessage"

--- @module "engine.core.messages.debugmessage"
prism.messages.DebugMessage = prism.require "core.messages.debugmessage"

--- @module "engine.core.relations.senses"
prism.relations.SensesRelation = prism.require "core.relations.senses"

--- @module "engine.core.relations.sensedby"
prism.relations.SensedByRelation = prism.require "core.relations.sensedby"

--- @param path string The path to load into the registry from.
--- @param registry Registry
--- @param recurse boolean
--- @param definitions string[]
local function loadRegistry(path, registry, recurse, definitions)
   local info = {}

   for _, itemPath in pairs(love.filesystem.getDirectoryItems(path)) do
      local fileName = path .. "/" .. itemPath
      love.filesystem.getInfo(fileName, info)

      if info.type == "file" then
         local requireName = string.gsub(fileName, ".lua", "")
         requireName = string.gsub(requireName, "/", ".")

         local item = require(requireName)

         if not registry.manualRegistration then
            prism["register" .. registry.class.className](item, true, true)
            table.insert(definitions, '--- @module "' .. requireName .. '"')
            local objectName = item.className
            table.insert(definitions, "prism." .. registry.name .. "." .. objectName .. " = nil")
         end
      elseif info.type == "directory" and recurse then
         loadRegistry(fileName, registry, recurse, definitions)
      end
   end
end

prism.modules = {}

--- Loads a module into prism, automatically loading objects based on directory, e.g. everything in
--- ``module/actors`` would get loaded into the Actor registry. Will also run ``module/module.lua``
--- for any other set up.
--- @param directory string The root directory of the module.
function prism.loadModule(directory)
   prism.logger.info("Loading module " .. directory)
   assert(
      love.filesystem.getInfo(directory, "directory"),
      "Tried to load module " .. directory .. " but the directory did not exist!"
   )
   table.insert(prism.modules, directory)

   local sourceDir = love.filesystem.getSource() -- Get the source directory
   local definitions = { "---@meta " .. string.lower(directory) }
   prism._currentDefinitions = definitions

   if love.filesystem.read(directory .. "/module.lua") then
      local filename = directory:gsub("/", ".") .. ".module"
      require(filename)
   end

   for _, registry in pairs(prism.registries) do
      loadRegistry(directory .. "/" .. registry.name, registry, true, definitions)
   end

   for _, component in pairs(prism.components) do
      --- @cast component Component
      component.requirements = { component:getRequirements() }
   end

   for _, system in ipairs(prism.systems) do
      --- @cast system System
      system.requirements = { system:getRequirements() }
   end

   local lastSubdir = directory:match("([^/\\]+)$")

   -- Define the output file path
   local outputFile = sourceDir .. "/definitions/" .. lastSubdir .. ".lua"

   -- Write the concatenated definitions to the file
   local file, err = io.open(outputFile, "w")
   if not file then
      prism.logger.error("Failed to open file for writing: " .. (err or "Unknown error"))
      return
   end

   file:write(table.concat(definitions, "\n"))
   file:close()
end

function prism.hotload() end

--- @alias TurnHandler fun(level: Level, actor: Actor, controller: Controller)

--- This is the default core turn logic. Use :lua:func:`LevelBuilder.addTurnHandler` to override this.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
function prism.defaultTurn(level, actor, controller)
   local action = controller:act(level, actor)

   -- we make sure we got an action back from the controller for sanity's sake
   assert(action, "Actor " .. actor:getName() .. " returned nil from act()")

   level:perform(action)
end

--- Runs the level coroutine and returns the next message, or nil if the coroutine has halted.
--- @return Message|nil
function prism.advanceCoroutine(updateCoroutine, level, decision)
   local success, ret = coroutine.resume(updateCoroutine, level, decision)

   if not success then error(ret .. "\n" .. debug.traceback(updateCoroutine)) end

   local coroutineStatus = coroutine.status(updateCoroutine)
   if coroutineStatus == "suspended" then return ret end
end
