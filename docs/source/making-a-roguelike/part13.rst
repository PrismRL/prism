Brewing potions
===============

In this chapter we'll use the :lua:class:`ConditionHolder` component included in ``prism/extra`` to
create a potion that heals the drinker and increases their health temporarily. We'll go over
creating a buff, making our Health component respect it, and ticking down the duration on status
effects.

Setting up
----------

First, load the conditions module.

.. code-block:: lua

   prism.loadModule("prism/extra/condition")

Then make your way to ``modules/game/actors/player.lua`` and add the following component.

.. code-block:: lua

   prism.components.ConditionHolder(),

Modifying health
----------------

Let's head back to ``modules/game/components/health.lua`` and define a new
:lua:class:`ConditionModifier` to represent a change to our max health.

.. code-block:: lua

   --- @class HealthModifier : ConditionModifier
   --- @field maxHP integer
   --- @overload fun(delta: integer): HealthModifier
   local HealthModifier = prism.condition.Modifier:extend "HealthModifier"

   function HealthModifier:__new(delta)
      self.maxHP = delta
   end

   prism.register(HealthModifier)

.. tip::

   Every object with a registry can be registered manually with :lua:func:`prism.register`!

On the ``Health`` component we'll set maxHP to private, since we won't want to access it directly
now.

.. code-block:: lua

   --- @class Health : Component
   --- @field private maxHP integer
   --- @field hp integer
   --- @overload fun(maxHP: integer)

Next let's create a ``getMaxHP`` function that will take our new modifier into account. We use
:lua:func:`ConditionHolder.getActorModifiers` to retrieve all health modifiers and apply each of
them to our maxHP.

.. code-block:: lua

   --- @return integer maxHP
   function Health:getMaxHP()
      local modifiers = ConditionHolder.getActorModifiers(self.owner, HealthModifier)

      local modifiedMaxHP = self.maxHP
      for _, modifier in ipairs(modifiers) do
         modifiedMaxHP = modifiedMaxHP + modifier.maxHP
      end

      return modifiedMaxHP
   end

We change ``heal`` to use our new function.

.. code-block:: lua

   --- @param amount integer
   function Health:heal(amount)
      self.hp = math.min(self.hp + amount, self:getMaxHP())
   end

We'll add a small function that to clamp our health to the maximum. We'll use this later.

.. code-block:: lua

   function Health:enforceBounds()
      self.hp = math.min(self.hp, self:getMaxHP())
   end

In ``gamelevelstate.lua`` we'll make sure to draw our health with the new function as well. Change
the following line:

.. code-block:: lua

   if health then self.display:print(1, 1, "HP: " .. health.hp .. "/" .. health.maxHP) end

To use the new getter:

.. code-block:: lua

   if health then self.display:print(1, 1, "HP: " .. health.hp .. "/" .. health:getMaxHP()) end

Drinking
--------

Let's create a new component in ``modules/game/components/drinkable.lua`` that we'll give to our
potions. For now, let's give it an optional healing amount and an optional condition.

.. code-block:: lua

   --- @class DrinkableOptions
   --- @field healing integer?
   --- @field condition Condition?

   --- @class Drinkable : Component
   --- @field healing integer?
   --- @field condition Condition?
   --- @overload fun(options: DrinkableOptions): Drinkable
   local Drinkable = prism.Component:extend "Drinkable"

   function Drinkable:__new(options)
      self.healing = options.healing
      self.condition = options.condition
   end

   return Drinkable

Now let's create a new action in ``modules/game/actions/drink.lua``. First we define our target to
be an item in the actor's inventory with a ``Drinkable`` component.

.. code-block:: lua

   local DrinkTarget = prism.targets.InventoryTarget(prism.components.Drinkable)

Then if we have a condition holder and our drink applies a condition we add that condition.

.. code-block:: lua

   --- @class Drink : Action
   local Drink = prism.Action:extend "Drink"
   Drink.targets = {
      DrinkTarget
   }

   --- @param drink Actor
   function Drink:perform(level, drink)
      self.owner:expect(prism.components.Inventory):removeItem(drink)
      local drinkable = drink:expect(prism.components.Drinkable)

      local conditions = self.owner:get(prism.components.ConditionHolder)
      if conditions and drinkable.condition then
         conditions:add(drinkable.condition)
      end

Finally we'll heal the actor for the amount of the drinkable's healing, if there is any.

.. code-block:: lua

      local health = self.owner:get(prism.components.Health)
      if health and drinkable.healing then
         health:heal(drinkable.healing)
      end
   end

   return Drink

Brewing the potion
------------------

Create a new file in ``modules/game/actors`` called ``vitalitypotion.lua``. We register a new item
with our new ``Drinkable`` component. We'll make it heal for 5 and apply a health bonus of 5 as
well.

.. code-block:: lua

   prism.registerActor("VitalityPotion", function()
      return prism.Actor.fromComponents {
         prism.components.Name("Potion of Vitality"),
         prism.components.Drawable("!", prism.Color4.RED),
         prism.components.Item(),
         prism.components.Position(),
         prism.components.Drinkable {
            healing = 5,
            condition = prism.condition.Condition(prism.modifiers.Health(5))
         }
      }
   end)

To have it appear in game, let's include it in ``loot/chest.lua``.

.. code-block:: lua

   --- @type DropTableOptions
   return {
      {
         entry = "VitalityPotion"
      }
   }

Start the game and try drinking a potion. It should heal us for 5 points and increase our maximum
health by 5!

Ticking down durations
----------------------

To make our health bonus a temporary effect, we'll extend :lua:class:`Condition` to include a
duration.

Create a new directory ``modules/game/conditions/`` and create a new file named
``tickedcondition.lua``. We're just adding a ``duration`` field to indicate how many turns the
condition lasts.

.. code-block:: lua

   --- @class TickedCondition : Condition
   --- @field duration integer
   --- @overload fun(duration: integer, ...: ConditionModifier): TickedCondition
   local TickedCondition = prism.condition.Condition:extend "TickedCondition"

   function TickedCondition:__new(duration, ...)
      self.super.__new(self, { ... })
      self.duration = duration
   end

   return TickedCondition

To use it, edit ``vitalitypotion.lua`` to the following.

.. code-block:: lua

   prism.components.Drinkable {
      healing = 5,
      condition = prism.conditions.TickedCondition(10, prism.modifiers.HealthModifier(5))
   },

Head over to ``modules/game/actions`` and create a new file called ``tick.lua``. Our tick action can
only be taken by actors who have a condition holder.

.. code-block:: lua

   --- @class Tick : Action
   local Tick = prism.Action:extend "Tick"
   Tick.requiredComponents = { prism.components.ConditionHolder }

Next, we want to iterate over all of the performer's timed conditions and tick them down by 1. We
can use :lua:func:`ConditionHolder.each` to simplify this.

.. code-block:: lua

   --- @param level Level
   function Tick:perform(level)
      -- Handle status effect durations
      self.owner
         :expect(prism.components.ConditionHolder)
         :each(function(condition)
            if prism.conditions.TickedCondition:is(condition) then
               --- @cast condition TickedCondition
               condition.duration = condition.duration - 1
            end
         end)

Then we want to remove any that have expired. We can similarly use
:lua:func:`ConditionHolder.removeIf`.

.. code-block:: lua

   :removeIf(function(condition)
      --- @cast condition TickedCondition
      return prism.conditions.TickedCondition:is(condition)
         and condition.duration <= 0
   end)

Finally we clamp our hp to maxHP by calling ``enforceBounds`` from earlier. This is where you'd
enforce minimums or maximums that might change. Without this if the player ends the duration of the
buff with 15 health they'd end up keeping that health total and only see a reduction in their
maximum.

.. code-block:: lua

      -- Validate components
      local health = self.owner:get(prism.components.Health)
      if health then health:enforceBounds() end
   end

   return Tick

Now head over to ``modules/game/systems`` and create a new file called ``tick.lua``. Each turn we
try to perform ``Tick`` on the actor.

.. code-block:: lua

   --- @class TickSystem : System
   local TickSystem = prism.System:extend "TickSystem"

   function TickSystem:onTurn(level, actor)
      level:tryPerform(prism.actions.Tick(actor))
   end

   return TickSystem

Don't forget to add our system to the level in ``gamelevelstate.lua``:

.. code-block:: lua

   builder:addSystems(
      prism.systems.SensesSystem(),
      prism.systems.SightSystem(),
      prism.systems.FallSystem(),
      prism.systems.TickSystem()
   )

Head back into the game and quaff some more potions. The maximum health increase should now end
after 10 turns!

Wrapping up
-----------

In the :doc:`next chapter <part14>` we'll make a wand and write some targetting code.
