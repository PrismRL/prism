Releases
========

Past releases and future plans for prism. Open an issue on `GitHub
<https://github.com/PrismRL/prism/issues>`_ or talk to us on `Discord
<https://discord.gg/9YpsH4hYVF>`_ to give input on priorities!

.. timeline::
   :no-padding:

   .. timeline-card:: 1.1
      :released:

      .. dropdown:: Release notes

         **Added**

         - Compatibility for Lua 5.1, enabling web builds via love.js
         - Tests for all of the data structure classes
         - Better dark mode syntax highlighting in the documentation
         - A how-to on ``SpriteAtlas``

         **Fixed**

         - Geometer fill tool crashing when used on the edge of a level
         - A bug with ``SparseArray:remove()``
         - ``SparseMap:removeAll`` not keeping track of count
         - ``SparseMap:remove`` not completely removing the object
         - Many missed API changes in the tutorial, thank you to new users for reporting them!

   .. timeline-card:: 1.1.1
      :released:

      .. dropdown:: Release notes

         **Fixed**

         - Targets not validating when ``false`` was the actual value passed in
         - Systems actually checking their requirements


   .. timeline-card:: 2.0
      :released:

      .. dropdown:: Release notes

         **Breaking**

         - ``prism.Ellipse`` renamed to ``prism.ellipse``
         - ``prism.BreadthFirstSearch`` renamed to ``prism.breadthFirstSearch``
         - ``prism.Bresenham`` renamed to ``prism.bresenham``

         **Added**

         - The lighting extra module
         - ``onComponentAdded`` and ``onComponentRemoved`` system hooks
         - Geometer can now use a display separate from the level state / game
         - Exposed ``prism.djikstra``
         - ``Display:putFG`` @drewww
         - ``ConditionHolder:has`` to easily check for condition types
         - Render passes to ``Display``, motivated by the lighting module
         - Non-idle animations can now respect senses
         - Cost callbacks to algorithms

         **Fixed**

         - Targets not validating when ``false`` was the actual value passed in
         - Systems actually checking their requirements
         - Throw an error when ``Object:is`` is called with an instance
         - ``Target:optional()`` checking was reversed
         - ``Display:rectangle()`` line/fill mode was reversed
         - Sight is now computed from each tile in a multi-tile actor


   .. timeline-card:: Future

      - Unify querying for actors and cells
      - Unify the :lua:class:`Controller` and :lua:class:`Decision` API
      - Rework targets to be named rather than positional
      - Rewrite Geometer and support live component modification
      - Expand the ``extra`` module library with lighting, sound, smell, and auto tiling modules
