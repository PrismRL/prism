Collision
=========

Most roguelikes require some kind of collision, so we've provided a collision system built in to
Prism. Here's how it works:

First, register any "layers" or types of movement you want to use, usually in your module's
``module.lua``:

.. code-block:: lua

   prism.Collision.assignNextAvailableMovetype("walk")
   prism.Collision.assignNextAvailableMovetype("fly")

Then, use a :lua:class:`Collider` to define collision for actors and cells. If no move types are
supplied, nothing will be able to pass. A ``size`` parameter can also be passed to define a ``size x
size`` actor; it has no effect on cells.

.. code-block:: lua

   prism.components.Collider{ allowedMovetypes = { "fly" }, size = 2 }

   prism.components.Collider() -- impassable

.. caution::

   Cells are required to define a collider!

For movement, you can define a component yourself by using
:lua:func:`Collision.createBitmaskFromMovetypes` to create a collision mask. Here's an example from
the `template <https://github.com/prismrl/prism-template>`_:

.. code-block:: lua

   --- @class Mover : Component
   --- @field mask integer
   local Mover = prism.Component:extend "Mover"
   Mover.name = "Mover"

   --- @param movetypes string[]
   function Mover:__new(movetypes)
      self.mask = prism.Collision.createBitmaskFromMovetypes(movetypes)
   end

   return Mover

   ...

   prism.components.Mover{ "walk" }

Then you can use it whenever a function expects a mask, like in :lua:func:`Level.findPath` or
:lua:func:`Level.getCellPassable`. You could use the same function to create a custom mask for a
specific action, such as throwing an item over a pit.
