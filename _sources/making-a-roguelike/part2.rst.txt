Taking flight
=============

Unfortunately for kobolds, they can't fly. In this section we're going to create a
:lua:class:`System` that plunges actors into the abyss if they're unable to fly.

.. video:: ../_static/part2.mp4
   :caption: Kicking kobolds into the abyss
   :align: center

Creating the void component
---------------------------

First we'll need to create a component we'll put on cells to indicate they're a place you can fall.

1. Navigate to ``modules/game/components``
2. Create a new file called ``void.lua``

Put the following into ``void.lua``:

.. code-block:: lua

   --- @class Void : Component
   local Void = prism.Component:extend "Void"

   return Void

This is a simple tag component that we'll use to mark tiles where actors can fall if they don’t have
an allowed movement type.

Adding void to our pit
----------------------

1. Navigate to ``modules/game/cells/pit.lua``

Add the following line to its components:

.. code-block:: lua

   prism.components.Void()

Creating the fall action
------------------------

Next we're going to create an lua:class:`Action` to represent an actor falling.

1. Navigate to the ``modules/game/actions`` directory.
2. Create a new file called ``fall.lua``.
3. Define the ``Fall`` action:

.. code-block:: lua

   --- @class Fall : Action
   --- @overload fun(owner: Actor): Fall
   local Fall = prism.Action:extend "Fall"

   return Fall

To perform the fall itself, all we're going to do is remove the actor:

.. code-block:: lua

   function Fall:perform(level)
      level:removeActor(self.owner) -- into the depths with you!
   end

Determining whether we `should` fall is a bit more complex. We need the following to be true:

The cell we're standing on has the void component, which we can check simply:

.. code-block:: lua

   function Fall:canPerform(level)
      local x, y = self.owner:getPosition():decompose()
      local cell = level:getCell(x, y)

      -- We can only fall on cells that are voids.
      if not cell:has(prism.components.Void) then return false end

And that we can't move through the cell. We can get the cell's collision mask and compare it with
our own with :lua:func:`Collision.checkBitmaskOverlap` to accomplish that check. If the actor
doesn't have a ``Mover`` component we'll default to falling.

.. code-block:: lua

      local cellMask = cell:getCollisionMask()
      local mover = self.owner:get(prism.components.Mover)
      if mover then
         -- We have a Void component on the cell. If the actor CAN'T move here
         -- then they fall.
         return not prism.Collision.checkBitmaskOverlap(cellMask, mover.mask)
      end

      return true
   end

   return Fall

.. dropdown:: Complete fall.lua

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part2/modules/game/actions/fall.lua>`_

   .. code:: lua

      --- @class Fall : Action
      --- @overload fun(owner: Actor): Fall
      local Fall = prism.Action:extend "Fall"

      function Fall:canPerform(level)
         local x, y = self.owner:getPosition():decompose()
         local cell = level:getCell(x, y)

         -- We can only fall on cells that are voids.
         if not cell:has(prism.components.Void) then return false end

         local cellMask = cell:getCollisionMask()
         local mover = self.owner:get(prism.components.Mover)
         if mover then
            -- We have a Void component on the cell. If the actor CAN'T move here
            -- then they fall.
            return not prism.Collision.checkBitmaskOverlap(cellMask, mover.mask)
         end

         return true
      end

      function Fall:perform(level)
         level:perform(prism.actions.Die(self.owner))
      end

      return Fall

Triggering fall with a system
-----------------------------

We've defined a fall action, but kobolds aren’t exactly volunteering to fall into the void. Let's
create a :lua:class:`System` to make sure things fall when they ought to. Create a new directory
``modules/game/systems`` and a new file ``fallsystem.lua``.

We want the actor to fall immediately when they land on a valid tile, so we'll use the
:lua:func:`System.onMove` callback to apply the fall action whenever valid.
:lua:func:`Level.tryPerform` will perform the action if it's valid, but won't error if it's not.

.. code-block:: lua

   --- @class FallSystem : System
   local FallSystem = prism.System:extend "FallSystem"

   function FallSystem:onMove(level, actor)
      level:tryPerform(prism.actions.Fall(actor))
   end

   return FallSystem

.. note::

   See :lua:class:`System` for a listing of events you can hook into!

Registering the Fall system
---------------------------

Navigate back to ``gamelevelstate.lua`` and on line 32 you'll see where we register systems. Go
ahead and add ``prism.systems.Fall()`` to the bottom of the list like so.

.. code-block:: lua

   local level = prism.Level(map, actors, {
      prism.systems.Senses(),
      prism.systems.Sight(),
      prism.systems.Fall(),
   })

Wrapping up
-----------

With our ``FallSystem`` in place, kobolds and other unfortunate creatures will now tumble into the
void if they end their turn standing on a pit they can’t fly over. We’ve used a component to tag
dangerous tiles, an action to represent involuntary movement, and a system to enforce game logic
based on actor movement.

In the :doc:`next section <part3>` of the tutorial, we’ll dive into something a little more active:
combat. We’ll set up a health component, and teach actors how to attack.
