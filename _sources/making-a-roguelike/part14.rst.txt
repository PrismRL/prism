Zapping wands
=============

.. note::

   This chapter is very work in progress, beware! Don't procede yet adventurer!

In this chapter we'll add wands and a generalized targetting system for actions. We'll add a Wand of
Hurt to zap a creatures with.

Creating a base module
----------------------

The load order for a given type within a module is random, so let's start by creating a "base"
module that our other content can depend on. Head to ``modules`` and create a new folder there
called ``base``. Now go ahead and add an ``actions`` and ``components`` folder.

Let's head to ``modules/base/components`` and create a new component in ``zappable.lua``. This will
be the base component for our wand components. It implements a few utility functions for managing
charges and checking if we have charges left to zap.

.. code-block:: lua

   --- @class ZappableOptions
   --- @field charges integer
   --- @field cost integer

   --- @class Zappable : Component
   --- @overload fun(): Zappable
   local Zappable = prism.Component:extend "Zappable"

   function Zappable:__new(options)
       self.charges = options.charges
       self.cost = options.cost
   end

   function Zappable:canZap(cost)
       cost = cost or self.cost
       return self.charges >= cost
   end

   function Zappable:reduceCharges(cost)
       cost = cost or self.cost
       self.charges = self.charges - self.cost
   end

   return Zappable

Now let's head to ``modules/basegame/actions`` and create a new action in ``zap.lua``. We implement
a :lua:func:`Action.canPerform` that checks if the wand has enough charges to zap. Then we implement
a ``perform`` action that reduces the wand's charges.

.. code-block:: lua

   local Log = prism.components.Log

   local ZappableTarget = prism.targets.InventoryTarget(prism.components.Zappable)

   --- @class Zap : Action
   local Zap = prism.Action:extend "Zap"
   Zap.abstract = true
   Zap.targets = { ZappableTarget }
   Zap.ZappableTarget = ZappableTarget

   --- @param zappable Actor
   function Zap:canPerform(level, zappable)
       return zappable:expect(prism.components.Zappable):canZap()
   end

   --- @param zappable Actor
   function Zap:perform(level, zappable)
       zappable:expect(prism.components.Zappable):reduceCharges()
   end

   return Zap

Making a wand
-------------

Let's head to ``/modules/game/components`` and create a new folder called ``zappable``. Then let's
create a new file named ``hurtzappable.lua``.

.. code-block:: lua

   --- @class HurtZappableOptions : ZappableOptions
   --- @field damage integer

   --- @class HurtZappable : Zappable
   --- @overload fun(options: HurtZappableOptions): HurtZappable
   local HurtZappable = prism.components.Zappable:extend "HurtZappable"

   --- @param options HurtZappableOptions
   function HurtZappable:__new(options)
       prism.components.Zappable.__new(self, options)
       self.damage = options.damage
   end

   return HurtZappable

This is pretty much the base Zappable component, but we've added a damage amount to it. Now let's
head to ``modules/game/actors`` and create a new file named ``wandofhurt.lua``.

.. code-block:: lua

   prism.registerActor("WandofHurt", function()
      return prism.Actor.fromComponents {
          prism.components.Name("Wand of Hurt"),
          prism.components.Drawable {
              index = "/",
              color = prism.Color4.LIME
          },
          prism.components.HurtZappable {
              charges = 3,
              cost = 1,
              damage = 3,
          },
          prism.components.Item(),
          prism.components.Position()
      }
   end)

We can edit our ``loot/chest.lua`` file to add wands to the drop pool. We have to switch from a
single entry to a list of weighted entries, and we'll give the wands half the weight of potions,
making them drop 33% of the time.

.. code-block:: lua

   --- @type DropTableOptions
   return {
      entries = {
         {
            entry = "VitalityPotion",
            weight = 100,
         },
         {
            entry = "WandofHurt",
            weight = 50,
         },
      }
   }

Great, now we've got to implement the zap. Head over to ``modules/game/actions`` and create a new
folder called ``zaps``. Inside create a new file called ``hurtzap.lua``. We're going to extend the
base zap to add a tiny bit of behavior to it. We'll add a target, anything with health, and try to
deal damage to it.

.. code-block:: lua

   local WandTarget = prism.targets.InventoryTarget(prism.components.HurtZappable)

   local HurtTarget = prism.Target(prism.components.Health)
      :range(5)
      :sensed()

   --- @class HurtZap : Zap
   local HurtZap = prism.actions.Zap:extend "HurtZap"
   HurtZap.name = "Zap"
   HurtZap.abstract = false
   HurtZap.targets = {
      HurtZappableTarget,
      HurtTarget
   }

   --- @param level Level
   function HurtZap:perform(level, zappable, hurtable)
      prism.actions.Zap.perform(self, level, zappable)
      local zappableComponent = zappable:expect(prism.components.HurtZappable)
      local damage = prism.actions.Damage(hurtable, zappableComponent.damage)
      level:tryPerform(damage)

      local dealt = damage.dealt or 0

      local zapName = Name.lower(hurtable)
      local ownerName = Name.lower(self.owner)

      Log.addMessage(self.owner, "You zap the %s for %i damage!", zapName, dealt)
      Log.addMessage(hurtable, "The %s zaps you for %i damage!", ownerName, dealt)
      Log.addMessageSensed(
         level,
         self,
         "The %s kicks the %s for %i damage.",
         ownerName,
         zapName,
         dealt
      )
   end

   return HurtZap

Okay now if you go in game there's a bit of an issue! You can't actually zap anything with this wand
yet, just drop it! We'll have to modify the user interface to add some proper targetting to let us
select who we'd like to zap.

Handling targets
----------------

Let's head over to ``modules/base/gamestates`` and create a new :lua:class:`GameState` in
``targethandler.lua``. We'll accept a display, the base :lua:class:`LevelState`, a target list, and
the current target we're handling and initializes a few fields for convenience.

.. code-block:: lua

   --- @class TargetHandler : GameState
   --- @field display Display
   --- @field levelState LevelState
   --- @field validTargets any
   --- @field curTarget any
   --- @field target Target
   --- @field level Level
   --- @field targetList any[]
   --- @overload fun(display: Display, levelState: LevelState, targetList: any[], target: Target): self
   local TargetHandler = spectrum.GameState:extend("TargetHandler")

   ---@param display Display
   ---@param levelState LevelState
   ---@param targetList any[]
   ---@param target Target
   function TargetHandler:__new(display, levelState, targetList, target)
      self.display = display
      self.levelState = levelState
      self.owner = self.levelState.decision.actor
      self.level = self.levelState.level
      self.targetList = targetList
      self.target = target
      self.index = nil
   end

.. code-block:: lua

   function TargetHandler:getValidTargets()
      error("Method 'getValidTargets' must be implemented in subclass")
   end

   function TargetHandler:init()
      self.validTargets = self:getValidTargets()
      if #self.validTargets == 0 then self.manager:pop("poprecursive") end
   end

   function TargetHandler:resume(previous, shouldPop)
      if shouldPop then
         self.manager:pop(shouldPop == "poprecursive" and shouldPop or nil)
      end

      self:init()
   end

   function TargetHandler:load()
      self:init()
   end

   return TargetHandler

The first method, ``getValidTargets()`` is defined in the base class because we use it in the
following methods to see if we have a target and start popping states back to the inventory if we
don't.

The init function is called in both resume and load and primes the target handler with all of the
valid targets, and pops back to the inventory if not. We pass "poprecursive" up the chain of states
to indicate we should keep popping until we reach the inventory again.

Creating our concrete target handler
------------------------------------

Let's head over to ``modules/game/gamestates/`` and create a new file called
``generaltargethandler.lua``.

.. code-block:: lua

   local controls = require "controls"
   local Name = prism.components.Name

   --- @class GeneralTargetHandler : TargetHandler
   --- @field selectorPosition Vector2
   local GeneralTargetHandler = prism.gamestates.TargetHandler:extend("GeneralTargetHandler")

We create a new target handler derived from the ``TargetHandler`` gamestate. Next we move on to
``getValidTargets``, where we'll query the level for valid targets to our action and collect them.
We can query directly for actors using :lua:func:`Query.target`, or if the target is ``Vector2`` we
validate against the entire map.

.. code-block:: lua

   function GeneralTargetHandler:getValidTargets()
      local valid = {}

      for foundTarget in self.level:query():target(self.target, self.level, self.owner, self.targetList):iter() do
         table.insert(valid, foundTarget)
      end

      if self.target.type and self.target.type == prism.Vector2 then
         for x, y in self.level.map:each() do
            local vec = prism.Vector2(x, y)
            if self.target:validate(self.level, self.owner, vec, self.targetList) then
               table.insert(valid, vec)
            end
         end
      end

      return valid
   end

We check if the current target is a Vector2 or an Actor and we'll set the selectorPosition based on
the current target that we chose arbitrarily.

.. code-block:: lua

   function GeneralTargetHandler:setSelectorPosition()
      if prism.Vector2.is(self.curTarget) then
         self.selectorPosition = self.curTarget
      elseif self.curTarget then
         self.selectorPosition = self.curTarget:getPosition()
      end
   end

Next we'll redefine the init function to set the selector position.

.. code-block:: lua

   function GeneralTargetHandler:init()
      self.super.init(self)
      self.curTarget = self.validTargets[1]
      self:setSelectorPosition()
   end

Then we'll implement a draw function that draws this state. Like our other states, we draw the base
state and then draw on top of it. We'll put a red "X" over our selected position, and next to it
their name, if they are ``Entity``.

.. code-block:: lua

   function GeneralTargetHandler:draw()
      self.levelState:draw()

      self.display:clear()
      -- set the camera position on the display
      local x, y = self.selectorPosition:decompose()

      -- put a string to let the player know what's happening
      self.display:print(1, 1, "Select a target!")
      self.display:beginCamera()
      self.display:print(x, y, "X", prism.Color4.RED, prism.Color4.BLACK)

      -- if there's a target then we should draw its name!
      if prism.Entity:is(self.curTarget) then
         self.display:print(x + 1, y, Name.get(self.curTarget))
      end
      self.display:endCamera()
      self.display:draw()
   end

Finally, we'll handle input. Add the following controls in ``controls.lua``.

.. code-block:: lua

   tab            = "tab",
   select         = "return"

Then we'll check if the user hit the tab keybind, and if so we'll use :lua:func:`next` to cycle
through our valid targets table.

.. code-block:: lua

   function GeneralTargetHandler:update(dt)
      controls:update()
      if controls.tab.pressed then
         local lastTarget = self.curTarget
         self.index, self.curTarget = next(self.validTargets, self.index)

         while
            (not self.index and #self.validTargets > 0) or
            (lastTarget == self.curTarget and #self.validTargets > 1)
         do
            self.index, self.curTarget = next(self.validTargets, self.index)
         end

         self:setSelectorPosition()
      end

Then if the user hits the select keybind we add this target to the overall target list we're
building and pop this instance of the target handler off of the gamestate stack.

.. code-block:: lua

   if controls.select.pressed and self.curTarget then
      table.insert(self.targetList, self.curTarget)
      self.manager:pop()
   end

If the user hits the return keybind we'll pop this state and pass "pop" to indicate to the other
states that we should pop all the way back to the inventory.

.. code-block:: Lua

   if controls.back.pressed then
      self.manager:pop("pop")
   end

Next we'll handle moving the selector. When the user hits a movement key we move the selector, check
for a valid target on that tile, and if it exists we'll set that as the current target.

.. code-block:: lua

      if controls.move.pressed then
         self.selectorPosition = self.selectorPosition + controls.move.vector
         self.curTarget = nil

         -- Check if the position is valid
         if self.target:validate(self.level, self.owner, self.selectorPosition, self.targetList) then
            self.curTarget = self.selectorPosition
         end

         -- Check if any actors at the position are valid
         local validTarget = self.level:query()
            :at(self.selectorPosition:decompose())
            :target(self.target, self.level, self.owner, self.targetList)
            :first()

         if validTarget then
            self.curTarget = validTarget
         end
      end
   end

   return GeneralTargetHandler

Modifying InventoryActionState
------------------------------

Okay with our target handler out of the way we're going to have to make some changes to the
InventoryActionState. Navigate to ``modules/game/gamestates/inventoryactionstate.lua``. First we're
going to make a small change to the constructor.

Instead of validating if the action is valid with its only target being the item we'll instead
validate if its first target is the item. The actions table notably now holds prototypes instead of
instances of actions.

.. code-block:: lua

   function InventoryActionState:__new(display, decision, level, item)
      -- ...

      for _, Action in ipairs(self.decision.actor:getActions()) do
         if Action:validateTarget(1, level, self.decision.actor, item) and not Action:isAbstract() then
            table.insert(self.actions, Action)
         end
      end
   end

Next we'll make a small modification to ``draw``. We'll use the action's :lua:func:`Action.getName`
method so our zaps display as "Zap" and not "HurtZap".

.. code-block:: lua
   :emphasize-lines: 3

   for i, Action in ipairs(self.actions) do
      local letter = string.char(96 + i)
      local name = string.gsub(Action:getName(), "Action", "")
      self.display:print(1, 1 + i, string.format("[%s] %s", letter, name), nil, nil, nil, "right")
   end

Now we'll modify the ``update`` function. Instead of simply executing the action the user selects
we'll now check if the action is valid with just the item as the first target.

.. code-block:: lua
   :emphasize-lines: 5

   function InventoryActionState:update(dt)
      controls:update()
      for i, Action in ipairs(self.actions) do
         if spectrum.Input.key[string.char(i + 96)].pressed then
            if self.decision:setAction(Action(self.decision.actor, self.item), self.level) then
               self.manager:pop()
               return
            end

If it wasn't valid, we'll push instances of our ``GeneralTargetHandler`` in reverse order, so the
second target (whatever is after the item) is on the top of the stack.

.. code-block:: lua

            self.selectedAction = Action
            self.targets = { self.item }
            for j = Action:getNumTargets(), 2, -1 do
               self.manager:push(
                  spectrum.gamestates.GeneralTargetHandler(
                     self.display,
                     self.previousState,
                     self.targets,
                     Action:getTarget(j),
                     self.targets
                  )
               )
            end
         end
      end

      if controls.inventory.pressed or controls.back.pressed then self.manager:pop() end
   end

And to wrap things up we'll change ``InventoryActionState``'s resume. We'll check if we're handling
targets for an action, and if we are we check if we succeeded. If we succeeded we set the action and
then pop the state. If not we display a message to the user explaining why their action didn't work.

.. code-block:: lua

   function InventoryActionState:resume()
      if self.targets then
         local action = self.selectedAction(self.decision.actor, unpack(self.targets))
         local success, err = self.level:canPerform(action)
         if success then
            self.decision:setAction(action)
         else
            prism.components.Log.addMessage(self.decision.actor, err)
         end

         self.manager:pop()
      end
   end

.. note::

   :lua:func:`unpack` expands a table into separate values.

Wrapping it up
--------------

That one was a doozy, but we layed the ground work for making adding new ways to target really easy
in the future! In the next section we'll go over equipment, and modify InventoryActionState a little
bit more to handle non-standard targets like inventory slots.
