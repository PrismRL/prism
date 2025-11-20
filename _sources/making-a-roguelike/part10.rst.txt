Stashing treasure
=================

In this chapter we'll use the optional :lua:class:`DropTable` component to implement chests and have
kobolds drop items.

Creating an item
----------------

Our kobold kicking hero needs something to chew on, and a way to regain health! Let's add a Meat
Brick that they can pick up and eat to restore their health.

First, register the inventory module in ``main.lua``. While we're here, register the drop table
module as well.

.. code-block:: lua

   prism.loadModule("prism/extra/inventory")
   prism.loadModule("prism/extra/droptable")

Then create a new file in ``modules/game/actors`` called ``meatbrick.lua`` and register the
following actor.

.. code-block:: lua

   prism.registerActor("MeatBrick", function ()
      return prism.Actor.fromComponents{
         prism.components.Name("Meat Brick"),
         prism.components.Position(),
         prism.components.Drawable { index = "%", color = prism.Color4.RED },
         prism.components.Item{
            stackable = "MeatBrick",
            stackLimit = 99
         }
      }
   end)

We give it the :lua:class:`Item` component to indicate it can be held in an :lua:class:`Inventory`.
We'll make it consumable in a future chapter!

Getting the drop on it
----------------------

Now we can give ``modules/game/actors/kobold.lua`` a ``DropTable``. We'll give them a 30% chance to
drop one of our meat bricks.

.. code-block:: lua

   prism.components.DropTable {
      chance = 0.3,
      entry = prism.actors.MeatBrick,
   }

If you were to kick a few kobolds you'd notice nothing is happening! That's because the drop table
needs to be hooked into the game logic. Open ``modules/game/actions/die.lua`` and we'll add drops to
the level when an actor dies.

.. code-block:: lua

   function Die:perform(level)
      local x, y = self.owner:getPosition():decompose()
      local dropTable = self.owner:get(prism.components.DropTable)

      if dropTable then
         local drops = dropTable:getDrops(level.rng)
         for _, drop in ipairs(drops) do
            level:addActor(drop, x, y)
         end
      end

      -- rest of Die:perform
   end

If they have a drop table, we use :lua:func:`DropTable.getDrops` to roll the drop table, and add
each item to the level at the actor's position.

To ensure dropped items don't float over pits, we can add the :lua:func:`System.onActorAdded`
callback to ``modules/game/systems/fallsystem.lua``.

.. code-block:: lua

   function FallSystem:onActorAdded(level, actor)
      level:tryPerform(prism.actions.Fall(actor))
   end

Boot up the game and kick a few kobolds around. They should start dropping meat!

Creating containers
-------------------

For chests, we'll start with a new tag. Navigate ``modules/game/components`` and create a new file
there called ``container.lua``.

.. code-block:: lua

   --- @class Container : Component
   --- @overload fun(): Container
   local Container = prism.Component:extend "Container"

   function Container:getRequirements()
      return prism.components.Inventory
   end

   return Container

Next we'll define a new action for opening these. Head over to ``modules/game/actions`` and create a
new file called ``opencontainer.lua``. For our target, we want a container within range 1 that we
can see.

.. code-block:: lua

   local Name = prism.components.Name
   local Log = prism.components.Log

   local OpenContainerTarget = prism.Target()
      :with(prism.components.Container)
      :range(1)
      :sensed()

In ``perform``, we grab every item in the target container's inventory and dump them on the ground,
before removing the container and logging messages.

.. code-block:: lua

   --- @class OpenContainer : Action
   local OpenContainer = prism.Action:extend "OpenContainer"
   OpenContainer.targets = { OpenContainerTarget }
   OpenContainer.name = "Open"

   --- @param level Level
   --- @param container Actor
   function OpenContainer:perform(level, container)
      local inventory = container:expect(prism.components.Inventory)
      local x, y = container:expectPosition():decompose()

      inventory:query():each(function(item)
         inventory:removeItem(item)
         level:addActor(item, x, y)
      end)

      level:removeActor(container)

      local containerName = Name.get(container)
      Log.addMessage(self.owner, "You kick open the %s.", containerName)
      Log.addMessageSensed(level, self, "The %s kicks open the %s.", Name.get(self.owner), containerName)
   end

   return OpenContainer

Now that we're all set up with our container logic we need to actually make a container to try this
with. Let's create a new file in ``modules/game/actors`` called ``chest.lua``. We'll accept a
``contents`` parameter to define the items in the chest and use :lua:func:`Inventory.addItems`.

.. code-block:: lua

   prism.registerActor("Chest", function(contents)
      local inventory = prism.components.Inventory()
      local chest = prism.Actor.fromComponents {
          prism.components.Name("Chest"),
          prism.components.Position(),
          inventory,
          prism.components.Drawable("(", prism.Color4.YELLOW),
          prism.components.Container(),
          prism.components.Collider()
      }
      --- @cast contents Actor[]
      inventory:addItems(contents or {})
      return chest
   end)

.. note::

   To support Geometer, parameters passed to actor and cell factories must be optional.

Cracking a cold one
-------------------

If you launch the game and bump into a chest you'll notice you kick it, which is fun but not exactly
what we want. We'll have to change to logic in ``GameLevelState``. In
``GameLevelState:updateDecision`` add the following right above where we try to kick:

.. code-block:: lua

   function GameLevelState:updateDecision(dt, owner, decision)
      -- yada yada
      if controls.move.pressed then
         -- blah blah

         local openable = self.level
            :query(prism.components.Container)
            :at(destination:decompose())
            :first()

         local openContainer = prism.actions.OpenContainer(owner, openable)
         if self:setAction(openContainer) then return end

         -- kick stuff
      end
   end

Okay! When you walk into a chest now you should pop that sucker open! Congratulations! Wait, nothing
was inside the chest though. That's not very fun. Let's take care of that.

Spicing up level generation
---------------------------

Let's first create a new top level folder, ``loot`` and within that folder a new file ``chest.lua``.
Let's keep it simple for now and give chests a guaranteed drop of meat.

.. code-block:: lua

   --- @type DropTableOptions
   return {
      {
         entry = "MeatBrick"
      }
   }

At the end of ``levelgen.lua``, we'll spawn a chest in the middle of a random room.

.. code-block:: lua

   local chestRoom = availableRooms[rng:random(1, #availableRooms)]
   local center = chestRoom:center():floor()
   local drops = prism.components.DropTable(chestloot):getDrops(rng)

   builder:addActor(prism.actors.Chest(drops), center:decompose())

   return builder

The chest will overlap with a kobold, but we'll deal with that when we revisit level generation.
You'll see now that when we open the chest we get a meat brick!

In the next chapter
-------------------

We've used the :lua:class:`DropTable` component to add drops to kobolds and added chests. In the
:doc:`next chapter <part11>` we'll start on an inventory system.
