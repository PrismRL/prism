Prism
=====

The prism module contains the core engine and commonly used utilities. Its classes and functions can
be accessed from the ``prism`` global, e.g. ``prism.Level``.

**Registries**

Registries get automatically loaded by :lua:func:`prism.loadModule`. They hold all of the game
objects, making them easy to access, e.g. ``prism.actors.Player()``.

- .. lua:data:: prism.actors: table<string, Actor>

     The actor registry.
- .. lua:data:: prism.actions: table<string, Action>

     The actions registry.
- .. lua:data:: prism.components: table<string, Component>

     The component registry.
- .. lua:data:: prism.cells: table<string, Cell>

     The cell registry.
- .. lua:data:: prism.targets: table<string, Target>

     The target registry.
- .. lua:data:: prism.messages: table<string, Message>

     The message registry.
- .. lua:data:: prism.systems: table<string, System>

     The system registry.
- .. lua:data:: prism.decisions: table<string, Decision>

     The decision registry.
- .. lua:data:: prism.schedulers: table<string, Scheduler>

     The scheduler registry.

.. toctree::
   :caption: Core
   :glob:
   :maxdepth: 1

   core/*
   core/scheduler/scheduler
   core/scheduler/simple_scheduler

**Functions**

- .. lua:function:: prism.loadModule(directory: string)

     Loads a module into prism, automatically loading objects based on directory.
     Will also run ``module/module.lua`` or ``module/init.lua`` for any other set up.

     :param string directory: The root directory of the module.
- .. lua:function:: prism.registerActor(name: string, factory: fun(...): Actor)

     Registers an actor factory into the actors registry.
- .. lua:function:: prism.registerCell(name: string, factory: fun(...): Cell)

     Registers a cell factory into the cells registry.
- .. lua:function:: prism.registerTarget(name: string, factory: fun(...): Target)

     Registers a target factory into the targets.
- .. lua:function:: prism.register(object: Object)

     Registers an object into its registry. Errors if the object has no registry.
- .. lua:function:: prism.advanceCoroutine()

     Runs the level coroutine and returns the next message, or nil if the coroutine has halted.

.. toctree::
   :caption: Core components
   :glob:
   :maxdepth: 1

   core/components/*

.. toctree::
   :caption: Core systems
   :glob:
   :maxdepth: 1

   core/systems/*
   core/collision

.. toctree::
   :caption: Core relations
   :glob:
   :maxdepth: 1

   core/relations/*

.. toctree::
   :caption: Messages & decisions
   :glob:
   :maxdepth: 1

   core/messages/*
   core/decisions/*

.. toctree::
   :caption: Behavior trees
   :glob:
   :maxdepth: 1

   core/behavior_tree/*

.. toctree::
   :caption: Structures
   :glob:
   :maxdepth: 1

   structures/*

.. toctree::
   :caption: Math & algorithms
   :glob:
   :maxdepth: 1

   math/*
   algorithms/astar/path

- .. lua:alias:: PassableCallback = fun(x: integer, y: integer, mask: Bitmask)

**Functions**

- .. lua:function:: prism.Ellipse(mode: ("fill" | "line"), center: Vector2, rx: integer, ry: integer, callback: PassableCallback?)

     Generates points for an ellipse on a grid using the Vector2 class.

     :param ("fill" | "line") mode: Whether to fill the ellipse or just an outline.
     :param Vector2 center: The center of the ellipse.
     :param integer rx: The radius on the x axis.
     :param integer ry: The radius on the y axis.
     :param PassableCallback? callback: An optional callback to determine passability.
- .. lua:function:: prism.Bresenham(x0: integer, y0: integer, x1: integer, y1: integer, callback: PassableCallback)

     Generates points for an ellipse on a grid using the Vector2 class.

     :param integer x0: The x coordinate of the first point.
     :param integer y0: The y coordinate of the first point.
     :param integer x1: The x coordinate of the second point.
     :param integer y1: The y coordinate of the second point.
     :param PassableCallback? callback: An optional callback to determine passability.
