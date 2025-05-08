Prism
=====
The prism module contains the core engine and commonly used utilities. Its classes and 
functions can be accessed from the ``prism`` global, e.g. ``prism.Level``.

**Registries**

Registries get automatically loaded by :lua:func:`loadModule`. They hold all
of the game objects, making them easy to access, e.g. ``prism.actors.Player()``.

- .. lua:data:: actors table<string, Actor>

   The actor registry.

- .. lua:data:: actions table<string, Action>

   The actions registry.

- .. lua:data:: components table<string, Component>

   The component registry.

- .. lua:data:: cells table<string, Cell>

   The cell registry.

- .. lua:data:: targets table<string, Target>

   The target registry.

- .. lua:data:: messages table<string, Message>

   The message registry.

- .. lua:data:: systems table<string, System>

   The system registry.

- .. lua:data:: decisions table<string, Decision>

   The decision registry.

.. toctree::
   :caption: Core
   :glob:
   :maxdepth: 1

   core/*
   core/scheduler/scheduler
   core/scheduler/simple_scheduler

**Functions**

- .. lua:function:: loadModule(directory: string)

   Loads a module into prism, automatically loading objects based on directory, e.g. everything in
   ``module/actors`` would get loaded into :lua:data:`actors`. Will also run ``module/module.lua``
   for any other set up.

   :param string directory: The root directory of the module.

- .. lua:function:: turn(level: Level, actor: Actor, controller: Controller)

   This is the core turn logic, and if you need to use a different scheduler or 
   want a different turn structure you should override this. 

   :param Level level: The current level.
   :param Actor actor: The actor taking their turn.
   :param Controller controller: The actor's controller, for convenience.

- .. lua:function:: advanceCoroutine()

   Runs the level coroutine and returns the next message, or nil if the coroutine has halted.

.. toctree::
   :caption: Basic components
   :glob:
   :maxdepth: 1

   core/components/*

.. toctree::
   :caption: Basic systems
   :glob:
   :maxdepth: 1

   core/systems/*
   core/collision

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


- .. lua:function:: Ellipse(mode: ("fill" | "line"), center: Vector2, rx: integer, ry: integer, callback: PassableCallback?)

   Generates points for an ellipse on a grid using the Vector2 class.

   :param ("fill" | "line") mode: Whether to fill the ellipse or just an outline.
   :param Vector2 center: The center of the ellipse.
   :param integer rx: The radius on the x axis.
   :param integer ry: The radius on the y axis.
   :param PassableCallback? callback: An optional callback to determine passability.

- .. lua:function:: Bresenham(x0: integer, y0: integer, x1: integer, y1: integer, callback: PassableCallback)

   Generates points for an ellipse on a grid using the Vector2 class.

   :param integer x0: The x coordinate of the first point.
   :param integer y0: The y coordinate of the first point.
   :param integer x1: The x coordinate of the second point.
   :param integer y1: The y coordinate of the second point.
   :param PassableCallback? callback: An optional callback to determine passability.

