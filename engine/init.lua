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
--- @module "engine.core.map_builder"
prism.MapBuilder = prism.require "core.map_builder"
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

prism.behaviors = {}

--- @module "engine.core.systems.senses"
prism.systems.Senses = prism.require "core.systems.senses"

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

prism._items = {
   "components",
   "targets",
   "cells",
   "actions",
   --"behaviors",
   "actors",
   "messages",
   "decisions",
   "systems",
}

prism._itemPatterns = {
   components = "[cC][oO][mM][pP][oO][nN][eE][nN][tT]",
   actors = "[aA][cC][tT][oO][rR]",
   actions = "[aA][cC][tT][iI][oO][nN]",
   cells = "[cC][eE][lL][lL]",
   targets = "[tT][aA][rR][gG][eE][tT]",
   messages = "[mM][eE][sS][sS][aA][gG][eE]",
   systems = "[sS][yY][sS][tT][eE][mM]",
   decisions = "[dD][eE][cC][iI][sS][iI][oO][nN]",
   behaviors = "[bB][eE][hH][aA][vV][iI][oO][rR]",
}

--- @param name string
--- @param factory CellFactory
function prism.registerCell(name, factory)
   assert(prism.cells[name] == nil, "Cell " .. name .. " is already registered!")
   prism.cells[name] = factory

   if prism._currentDefinitions then
      table.insert(prism._currentDefinitions, "--- @type fun(...): Cell")
      table.insert(prism._currentDefinitions, "prism.cells." .. name .. " = nil")
   end
end

--- @param name string
--- @param factory ActorFactory
function prism.registerActor(name, factory)
   assert(prism.actors[name] == nil, "Actor " .. name .. " is already registered!")
   prism.actors[name] = factory

   if prism._currentDefinitions then
      table.insert(prism._currentDefinitions, "--- @type fun(...): Actor")
      table.insert(prism._currentDefinitions, "prism.actors." .. name .. " = nil")
   end
end

--- @param name string
--- @param target TargetFactory
function prism.registerTarget(name, target)
   assert(prism.targets[name] == nil, "Target " .. name .. " is already registered!")
   prism.targets[name] = target

   if prism._currentDefinitions then
      table.insert(prism._currentDefinitions, "--- @type fun(...): Target")
      table.insert(prism._currentDefinitions, "prism.targets." .. name .. " = nil")
   end
end

local function loadItems(path, itemType, recurse, definitions)
   local info = {}
   local items = prism[itemType]

   for _, itemPath in pairs(love.filesystem.getDirectoryItems(path)) do
      local fileName = path .. "/" .. itemPath
      love.filesystem.getInfo(fileName, info)
      if info.type == "file" then
         local requireName = string.gsub(fileName, ".lua", "")
         requireName = string.gsub(requireName, "/", ".")

         local item = require(requireName)

         if itemType == "actors" or itemType == "cells" or itemType == "targets" then
            goto continue
         end

         assert(
            type(item) == "table",
            "Expected a table from " .. fileName .. " but received a " .. type(item) .. "!"
         )
         local name = string.gsub(item.className, prism._itemPatterns[itemType], "")
         if not item.stripName then name = item.className end

         assert(
            name ~= "",
            "File "
               .. fileName
               .. " contains type "
               .. itemType
               .. " without a valid stripped name!"
         )
         assert(
            items[name] == nil,
            "File " .. fileName .. " contains type " .. itemType .. " with duplicate name!"
         )
         items[name] = item

         table.insert(definitions, "--- @module " .. '"' .. requireName .. '"')
         table.insert(definitions, "prism." .. itemType .. "." .. name .. " = nil")

         ::continue::
      elseif info.type == "directory" and recurse then
         loadItems(fileName, itemType, recurse, definitions)
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

   if love.filesystem.read(directory .. "/module.lua") then
      local filename = directory:gsub("/", ".") .. ".module"
      require(filename)
   end

   local sourceDir = love.filesystem.getSource() -- Get the source directory
   local definitions = { "---@meta " .. string.lower(directory) }
   prism._currentDefinitions = definitions

   for _, item in ipairs(prism._items) do
      loadItems(directory .. "/" .. item, item, true, definitions)
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
      print("Failed to open file for writing: " .. (err or "Unknown error"))
      return
   end

   file:write(table.concat(definitions, "\n"))
   file:close()
end

function prism.hotload() end

--- This is the core turn logic, and if you need to use a different scheduler or want a different turn structure you should override this.
--- There is a version of this provided for time-based
---@param level Level
---@param actor Actor
---@param controller Controller
---@diagnostic disable-next-line
function prism.turn(level, actor, controller)
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
