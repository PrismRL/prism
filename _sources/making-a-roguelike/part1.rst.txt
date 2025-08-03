Getting started
===============

In this tutorial, we'll start with a project template and create an enemy that we
can kick around and get chased by.


.. video:: ../_static/part1.mp4
   :caption: Kicking a kobold
   :align: center

The following sections will expand this into a complete game.

.. note::

   We assume familiarity with Lua, but the language is simple enough that you could probably skirt by
   with only general programming experience.

Installation
------------

Follow the :doc:`installation guide <../installation>` to install LÖVE and set up the project template.

Creating an enemy
-----------------

To make the game more engaging, let’s introduce an enemy: the
**Kobold**.

1. Navigate to the ``/modules/game/actors/`` directory.
2. Create a new file named ``kobold.lua``.
3. Add the following code to define the Kobold actor:

.. code:: lua

   prism.registerActor("Kobold", function()
      return prism.Actor.fromComponents {
         prism.components.Position(),
         prism.components.Drawable("k", prism.Color4.RED),
      }
   end)

.. note::

   See :doc:`../how-tos/object-registration` for an overview on how to load objects in prism.

Let’s run the game again, and press ``~``. This opens Geometer, the editor.
Click on the k on the right hand side and use the pen tool to draw a
kobold in. Press the green button to resume the game.

You might notice that you can walk right through the kobold. We fix that by giving it a
:lua:class:`Collider`:

.. code:: lua

   prism.components.Collider()

.. note::

   See :doc:`../how-tos/collision` for more information on the collision system.

If we restart the game and spawn in another kobold, we shouldn't be able to walk
through kobolds anymore. We're also going to give the kobold a few more core components: a
:lua:class:`Senses`, ``SightComponent``, and ``MoverComponent``, so it can see and move:

.. code:: lua

   prism.components.Senses(),
   prism.components.Sight{ range = 12, fov = true },
   prism.components.Mover{ "walk" }

      

The kobold controller
---------------------

Now that the kobold exists in the world, you might notice something—it’s
not moving! To give it behavior, we need to implement a :lua:class:`Controller`.

A :lua:class:`Controller` (or one of its derivatives) defines the :lua:func:`Controller.act`
function, which takes the :lua:class:`Level` and the :lua:class:`Actor` as arguments and
returns a valid action.

.. caution::

   The ``act`` function **should not modify the level directly**--it should only use it to validate actions.

1. Navigate to ``modules/game/components/``.
2. Create a new file named ``koboldcontroller.lua``.
3. Add the following code:

.. code:: lua

   --- @class KoboldController : Controller
   --- @overload fun(): KoboldController
   local KoboldController = prism.components.Controller:extend("KoboldController")
   KoboldController.name = "KoboldController"

   function KoboldController:act(level, actor)
      local destination = actor:getPosition() + prism.Vector2.RIGHT
      local move = prism.actions.Move(actor, destination)
      if level:canPerform(move) then
         return move
      end

      return prism.actions.Wait(actor)
   end

   return KoboldController

.. tip::

   Always provide a default action to take in a controller.

Back in ``kobold.lua``, give it our new controller component:

.. code:: lua

   prism.components.KoboldController()

Our kobold should move right until they hit a wall now, but this
behaviour doesn't make for a great game. Let's make them follow the player around.

.. dropdown:: Complete kobold.lua

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part1/modules/game/actors/kobold.lua>`_

   .. code:: lua

      prism.registerActor("Kobold", function()
         return prism.Actor.fromComponents {
            prism.components.Name("Kobold"),
            prism.components.Position(),
            prism.components.Collider(),
            prism.components.Drawable{ char = "k", color = prism.Color4.RED },
            prism.components.Senses(),
            prism.components.Sight{ range = 12, fov = true },
            prism.components.Mover{ "walk" },
            prism.components.KoboldController()
         }
      end)

Pathfinding
-----------
To make our kobold follow the player, we need to do a few things:

1. See if the player is within range of the kobold.
2. Find a valid path to the player.
3. Move the kobold along that path.

We can find the player by grabbing the :lua:class:`Senses` from the kobold and
seeing if it contains the player. We should also ensure the kobold has the component in the first place.

.. code:: lua
   
   local senses = actor:get(prism.components.Senses)
   if not senses then return prism.actions.Wait(actor) end -- we can't see!

   local player = senses:query(prism.components.PlayerController):first()
   if not player then return prism.actions.Wait(actor) end

.. note::

   See :doc:`../how-tos/query` for more information on querying.

We can get a path to the player by using the :lua:func:`Level.findPath` method, passing the
positions and the kobold's collision mask.

.. code:: lua

   local mover = actor:get(prism.components.Mover)
   if not mover then return prism.actions.Wait(actor) end -- we can't move!

   local path = level:findPath(actor:getPosition(), player:getPosition(), actor, mover.mask, 1)

Then we check if there's a path and move the kobold along it, using :lua:func:`Path.pop` to get the first
position.

.. code:: lua

   if path then
      local move = prism.actions.Move(actor, path:pop())
      if level:canPerform(move) then
         return move
      end
   end

Jump back into the game and you should find kobolds chasing after you.

.. dropdown:: Complete koboldcontroller.lua

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part1/modules/game/components/koboldcontroller.lua>`_

   .. code:: lua

      --- @class KoboldController : Controller
      --- @overload fun(): KoboldController
      local KoboldController = prism.components.Controller:extend("KoboldController")
      KoboldController.name = "KoboldController"

      function KoboldController:act(level, actor)
         local senses = actor:get(prism.components.Senses)
         if not senses then return prism.actions.Wait(actor) end -- we can't see!

         local player = senses:query(prism.components.PlayerController):first()
         if not player then return prism.actions.Wait(actor) end

         local mover = actor:get(prism.components.Mover)
         if not mover then return prism.actions.Wait(actor) end

         local path = level:findPath(actor:getPosition(), player:getPosition(), actor, mover.mask, 1)

         if path then
            local move = prism.actions.Move(actor, path:pop())
            if level:canPerform(move) then
               return move
            end
         end

         return prism.actions.Wait(actor)
      end

      return KoboldController


Kicking kobolds
---------------

In this section we’ll give you something to do to these kobolds: kick them!
We’ll need to create our first action. Head over to ``/modules/game/actions`` and add kick.lua.

Let’s first create a target for our kick. Put this at the top of
kick.lua:

.. code:: lua

   local KickTarget = prism.Target()
      :with(prism.components.Collider)
      :range(1)
      :sensed()

With this target we’re saying you can only kick actors at range one with a collider 
component. Then we can define the kick action, including our target. We will also require
that any actor trying to perform the kick action have a controller.

.. code:: lua

   ---@class KickAction : Action
   local Kick = prism.Action:extend("KickAction")
   Kick.name = "Kick"
   Kick.targets = { KickTarget }
   Kick.requiredComponents = {
      prism.components.Controller
   }

   return Kick

For the logic, we'll define methods that validate and perform the kick. We don't have any
special conditions for kicking, so from :lua:func:`Action.canPerform` we'll just return true.
For the kick itself, we get the direction from the player to the target (kobold), and check passability
for three tiles in the direction before finally moving them. We also give the kobold flying movement by
checking passability with a custom collision mask.

.. code:: lua

   function Kick:canPerform(level)
      return true
   end

   local mask = prism.Collision.createBitmaskFromMovetypes{ "fly" }

   --- @param level Level
   --- @param kicked Actor
   function Kick:perform(level, kicked)
      local direction = (kicked:getPosition() - self.owner:getPosition())

      for _ = 1, 3 do
        local nextpos = kicked:getPosition() + direction

        if not level:getCellPassable(nextpos.x, nextpos.y, mask) then break end
        if not level:hasActor(kicked) then break end

        level:moveActor(kicked, nextpos)
      end
   end

.. dropdown:: Complete kick.lua

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part1/modules/game/actions/kick.lua>`_

   .. code:: lua

      local KickTarget = prism.Target()
         :with(prism.components.Collider)
         :range(1)
         :sensed()

      ---@class KickAction : Action
      local Kick = prism.Action:extend("KickAction")
      Kick.name = "Kick"
      Kick.targets = { KickTarget }
      Kick.requiredComponents = {
         prism.components.Controller
      }

      function Kick:canPerform(level)
         return true
      end

      --- @param level Level
      --- @param kicked Actor
      function Kick:perform(level, kicked)
         local direction = (kicked:getPosition() - self.owner:getPosition())

         local mask = prism.Collision.createBitmaskFromMovetypes{ "fly" }

         for _ = 1, 3 do
            local nextpos = kicked:getPosition() + direction

            if not level:getCellPassable(nextpos.x, nextpos.y, mask) then break end
            if not level:hasActor(kicked) then break end

            level:moveActor(kicked, nextpos)
         end
      end

      return Kick


Kicking kobolds, for real this time
-----------------------------------

We've added the kick action, but we don't use it anywhere. Let's fix that by performing the kick
when we bump into a kobold. Head over to ``gamestates/gamelevelstate.lua`` and find where the move action
is called. If the player doesn't move, we want to check if there's a valid actor to kick in front of us,
and then perform the kick action on them:

.. code:: lua

   if self.level:canPerform(move) then
   ...
   end

   local target = self.level:query() -- grab a query object
      :at(destination:decompose()) -- restrict the query to the destination
      :first() -- grab one of the kickable things, or nil

   local kick = prism.actions.Kick(owner, target)
   if self.level:canPerform(kick) then
      decision:setAction(kick)
   end

.. note::

   :lua:func:`Level.canPerform` will validate all targets in the action.

That's a wrap
-------------

That's all for part one. In conclusion, we've accomplished the following:

1. Added a kobold enemy with basic pathfinding.
2. Implemented a kick action to shove kobolds around.
3. Integrated the kick by performing it when bumping into a valid target.

You can find the code for this part at https://github.com/prismrl/Kicking-Kobolds on the ``part1`` branch. In the 
:doc:`next section <part2>`, we'll do some work with components and systems to flesh out the combat system.
