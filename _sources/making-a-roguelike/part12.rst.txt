Stashing treasure
=================

.. note::

   This section hasn't had a second pass! Some chests might be mimics!

In this chapter we'll add a drop table to the kobolds, and create chests the player can open like a
loot pinata. To do this we'll be making heavy use of the DropTable component included in
``extra/droptable``. How to write your own drop tables will be covered in a future how-to.

Getting the drop on it
----------------------

Let's head over to ``main.lua`` where you'll add the following line to your module loading before
``modules/game``.

.. code-block:: lua

   prism.loadModule("prism/extra/droptable")

Now let's make our way over to ``modules/game/actors/kobold.lua`` and add the droptable component.

.. code-block:: lua

   prism.components.DropTable{
      chance = 0.3,
      entry = prism.actors.MeatBrick,
   }

This is a really simple drop table, and it just says there's a 30% chance for the kobold to drop a
meat brick. If you were to go into the game and kick a few kobolds now you'd notice nothing is
happening! That's because the drop table needs to be hooked into the game logic. Let's head over to
``modules/game/actions/die.lua`` where we'll change the beginning the Die action.

.. code-block:: lua

   local walkmask = prism.Collision.createBitmaskFromMovetypes{"walk"}
   function Die:perform(level)
      local x, y = self.owner:getPosition():decompose()
      local dropTable = self.owner:get(prism.components.DropTable)
      local cellmask = level:getCell(x, y):getCollisionMask()

      if prism.Collision.checkBitmaskOverlap(walkmask, cellmask) and dropTable then
         local drops = dropTable:getDrops(level.RNG)
         for _, drop in ipairs(drops) do
            level:addActor(drop, x, y)
         end
      end

      -- rest of Die:perform
   end

First we make our walkmask, a simple collision mask saying an actor with the walk movetype can move
onto this tile. Then within perform we'll get the Die'ers position, drop table, and the cell they're
standing on's mask.

If the cell is walkable and they have a drop table we roll on the table and then add all of the
results to the the level at the tile which they died. We check walkability so we don't spawn items
over a pit. Now if you boot up the game and kick a few kobolds around you should start getting some
meat bricks as drops, success!

Creating containers
-------------------

Many games won't settle just for drop tables. You might want a zelda style chest the player can
crack open and get some goodies! So let's add that. The first step we'll need to take is adding a
new tag component. Navigate to ``modules/game/components`` and create a new file there called
``container.lua``.

.. code-block:: lua

   --- @class Container : Component
   --- @overload fun(): Container
   local Container = prism.Component:extend "Container"

   function Container:getRequirements()
      return prism.components.Inventory
   end

   return Container

This is a really simple component that just marks an actor with an inventory as a container that can
be opened. Next up let's head over to ``modules/game/actions`` where we'll create a new file called
``opencontainer.lua``.

.. code-block:: lua

   local sf = string.format
   local Name = prism.components.Name
   local Log = prism.components.Log

   local OpenContainerTarget = prism.Target()
      :with(prism.components.Container)
      :range(1)
      :sensed()

Let's start with our target. We specify it must be a container, at range 1, and sensed by the actor.

.. code-block:: lua

   --- @class OpenContainer : Action
   local OpenContainer = prism.Action:extend "OpenContainer"
   OpenContainer.targets = { OpenContainerTarget }
   OpenContainer.name = "Open"

   --- @param level Level
   --- @param container Actor
   function OpenContainer:perform(level, container)
      local inventory = container:expect(prism.components.Inventory)
      local items = inventory:query():gather()

      local x, y = container:expectPosition():decompose()
      for _, item in ipairs(items) do
         inventory:removeItem(item)
         level:addActor(item, x, y)
      end

      level:removeActor(container)

      local containerName = Name.get(container)
      Log.addMessage(self.owner, sf("You open the %s.", containerName))
      Log.addMessageSensed(level, self, sf("The %s opens the %s.", Name.get(self.owner), containerName))
   end

   return OpenContainer

Then we get to the perform action. We know that the container has to have an inventory because it's
required by the container component. So we grab the inventory and get a list of the items it
contains. Then we loop through that list and remove them from the container's inventory while adding
them to the level. Finally, we remove the container itself from the level.

Now that we're all set up with our container logic we need to actually make a container to try this
with. Let's create a new file in ``modules/game/actors`` called ``chest.lua``.

.. code-block:: lua

   prism.registerActor("Chest", function(contents)
   return prism.Actor.fromComponents {
       prism.components.Name("Chest"),
       prism.components.Position(),
       prism.components.Inventory{items = contents},
       prism.components.Drawable("(", prism.Color4.YELLOW),
       prism.components.Container(),
       prism.components.Collider()
   }
   end)

Let's break this down a little since this is the first time we're really making use of the factory
to take optional parameters for an actor. We accept a contents argument to the Chest constructor.
All parameters to the factory function MUST be optional! In this case it'd set items = nil and
inventory wouldn't see the field. If this parameter is not optional Geometer will crash on startup!

Cracking a cold one
-------------------

If you go ingame now and bump the chest you'll notice you kick it, that's definitely not what we
want. We'll have to change to logic in ``GameLevelState``. Let's find out way to
``GameLevelState:keypressed`` and add the following right above where we try to kick:

.. code-block:: lua

   function GameLevelState:keypressed(key, scancode)
      -- yada yada
      if keybindOffsets[action] then
         -- blah blah

         local openable = self.level
            :query(prism.components.Container)
            :at(destination:decompose())
            :first()

         local openContainer = prism.actions.OpenContainer(owner, openable)
         if self.level:canPerform(openContainer) then
            decision:setAction(openContainer)
            return
         end

         -- kick stuff
      end
   end

Okay! When you walk into a chest now you should pop that sucker open! Congratulations! Wait, nothing
was inside the chest though. That's not very fun. Let's take care of that.

Spicing up level generation
---------------------------

Let's first create a new top level folder, ``loot`` and within that folder a new file ``chest.lua``.
Let's keep it really simple for now.

.. code-block:: lua

   return {
      {
         entry = prism.actors.MeatBrick
      }
   }

This defines a single gauranteed drop of a meatbrick. We'll flesh this out a lot more when we create
more stuff for chests to drop. Next let's head over to ``levelgen.lua`` and let's spawn a chest
using this level generation.

At the end of the anonymous function we return in this file just above ``return builder`` let's add
the following.

.. code-block:: lua

   local chestRoom = availableRooms[rng:random(1, #availableRooms)]
   local center = chestRoom:center()
   local drops = prism.components.DropTable(chestloot):getDrops(rng)

   local mf = math.floor
   builder:addActor(prism.actors.Chest(drops), mf(center.x), mf(center.y))

   return builder

The chest will overlap with a kobold which we're also spawning in the center of the room, but that's
fine we'll deal with that when we revisit the level generation in the future. You'll see now that
when we open the chest we get a meat brick!

In the next chapter
-------------------

In the next chapter we'll create some more items to add to our loot tables and make the game more
interesting. We'll add a potion and go over making buffs using the StatusEffect component included
in /extra!
