Object registration
===================

prism makes use of a number of registries both for ease of use and for some core functionality. The
primary interface for registering your own objects is :lua:func:`prism.loadModule`, which expects a
directory containing a module. Subdirectories are processed recursively.

An example module might look like this:

- module/

  - actors/

    - goblins.lua
    - items/

      - potion.lua
      - sword.lua

  - systems/

    - .lua

Below is a walk through of how and when each type of object is loaded.

.. timeline::

   .. timeline-card:: module.lua

     ``module.lua`` or ``init.lua`` is ran. You can use it to create move types with :lua:func:`Collision.assignNextAvailableMovetype`,
     or to perform other miscellaneous set up.

   .. timeline-card:: Components

     Files in ``module/components/`` are assumed to return a single :lua:class:`Component` each. These are loaded
     into :lua:data:`prism.components`.

   .. code-block:: lua
     :caption: modules/components/pushable.lua

     --- @class Pushable : Component
     --- @overload fun(): Pushable
     local Pushable = prism.Component:extend "Pushable"

     return Pushable

   .. timeline-card:: Targets

     All files in ``module/targets/`` are ran.
     :doc:`Targets <../reference/prism/core/target>` must be registered by providing a name and a
     factory function to :lua:func:`prism.registerTarget`; these are loaded into :lua:data:`prism.targets`.
     Factories can accept parameters.


   .. code-block:: lua
     :caption: module/targets/movetarget.lua

     prism.registerTarget("MoveTarget", function(range)
       return prism.Target():isPrototype(prism.Vector2):range(range)
     end)

   .. timeline-card:: Cells

     All files in ``module/cells/`` are ran.
     :doc:`Cells <../reference/prism/core/cell>` must be registered by providing a name and a
     factory function to :lua:func:`prism.registerCell`; these are loaded into :lua:data:`prism.cells`.
     :lua:func:`Cell.fromComponents` is useful here.

     .. caution::

       Factories for cells and actors can have parameters, but ensure they are optional!

   .. code-block:: lua
     :caption: module/cells/floor.lua

     prism.registerCell("Floor", function()
       return prism.Cell.fromComponents {
           prism.components.Name("Floor"),
           prism.components.Drawable(271),
           prism.components.Collider{ allowedMovetypes = { "walk" } },
       }
     end)

   .. timeline-card:: Actions

     Files in ``module/components/`` are assumed to return a single :lua:class:`Action` each.
     These are loaded into :lua:data:`prism.actions`.

   .. timeline-card:: Actors

     All files in ``module/actors/`` are ran.
     :doc:`Actors <../reference/prism/core/actor>` must be registered by providing a name and a factory
     function to :lua:func:`prism.registerActor`; these are loaded into :lua:data:`prism.actors`.
     :lua:func:`Actor.fromComponents` is useful here.

   .. code-block:: lua
     :caption: module/actors/goblins.lua

     prism.registerActor("Goblin", function(health)
       return prism.Actor.fromComponents {
         -- goblin stuff
         prism.components.Health(health or 10)
       end
     end)

     prism.registerActor("GoblinArcher", function()
       local goblin = prism.actors.Goblin()

       local inventory = goblin:expect(Inventory)
       inventory:addItem(prism.actors.Bow())

       return goblin
     end)

   .. timeline-card:: Messages

     Files in ``module/messages/`` are assumed to return a single :lua:class:`Message` each.
     These are loaded into :lua:data:`prism.messages`.

   .. timeline-card:: Decisions

     Files in ``module/decisions/`` are assumed to return a single :lua:class:`Decision` each.
     These are loaded into :lua:data:`prism.decisions`.

   .. timeline-card:: Systems

     Files in ``module/systems/`` are assumed to return a single :lua:class:`System` each.
     These are loaded into :lua:data:`prism.systems`.
