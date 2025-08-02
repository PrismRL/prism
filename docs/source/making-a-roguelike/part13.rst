Brewing potions
===============

.. note::

   This chapter hasn't had a second pass! Beware explosive brews!

In this chapter we'll use the StatusEffect component included in ``prism/extra`` to create a potion of vitality that heals the drinker
and increases their hitpoint maximum by 5, temporarily. We'll go over creating a buff, making our Health component respect it, and
ticking down the duration on status effects.

Adding status effects to the player
-----------------------------------

Make your way to ``modules/game/actors/player.lua`` and add the following component.

.. code:: lua

   prism.components.StatusEffects(),


Getting a brew going
--------------------

The first thing we're going to want to do is head over to ``main.lua`` and load the ``statuseffects`` module. Let's add this line
right above where we're loading our game module.

.. code:: lua

   prism.loadModule("prism/extra/statuseffects")

Okay with that done the next thing we're going to want to do is create a subclass of the StatusEffectInstance that will serve as a base
prototype for all of our buffs/debuffs in the game. This is where we'll define stuff that's game specific to our status effects like
durations.

Head over to ``modules/game`` and create a new file named ``statusinstance.lua``.

.. code:: lua

   --- @class GameStatusInstance : StatusEffectsInstance
   --- @field duration integer?
   local GameStatusInstance = prism.components.StatusEffects.Instance:extend "GameStatusInstance"

   --- @class GameStatusInstanceOptions : StatusEffectsInstanceOptions
   --- @field duration integer

   --- @param options GameStatusInstanceOptions
   function GameStatusInstance:__new(options)
      prism.components.StatusEffects.Instance.__new(self, options)
      self.duration = options.duration or nil
   end

   return GameStatusInstance

Our only addition for our usecase is going to be a duration since we'll want timed buffs. Now head over to ``module.lua`` in the same folder.
We're going to load this file and inject our status instance into the global namespace simply for convenience sake.

This Instance is a collection of Modifiers. A status effect instance might be the entire buff a potion gives you like +5 maxhp, +2 strength. A modifier is
the individual pieces like +5 maxhp. You can subclass this to define a new named instance or use it anonymously.

.. code::

   --- @module "modules.game.statusinstance"
   prism.GameStatusInstance = require ("modules.game.statusinstance")

Modifying health
----------------

Let's head back to ``modules/game/components/health.lua`` and take a look at our health component. At the top of the file let's add
the following code.

.. code:: lua

   local StatusEffects = prism.components.StatusEffects

Let's quickly alias the StatusEffects component, we're going to use one of it's static methods later in the file.

.. code:: lua

   --- @class HealthModifier : StatusEffectsModifier
   --- @field maxHP integer
   local HealthModifier = prism.components.StatusEffects.Modifier:extend "HealthModifier"

   function HealthModifier:__new(delta)
      self.maxHP = delta
   end

This defined a new StatusEffectsModifier. We'll leave the constructor as it is, but let's set maxHP to private.

.. code:: lua

   --- @class Health : Component
   --- @field private maxHP integer
   --- @field hp integer
   --- @overload fun(maxHP: integer)

Next let's create a getMaxHP function that will take our new modifier into account.

.. code:: lua

   --- @return integer maxHP
   function Health:getMaxHP()
      local modifiers = StatusEffects.getActorModifiers(self.owner, HealthModifier)

      local modifiedMaxHP = self.maxHP
      for _, modifier in ipairs(modifiers) do
         modifiedMaxHP = modifiedMaxHP + modifier.maxHP
      end

      return modifiedMaxHP
   end

We loop through each modifier, add it to our base maxHP, and return the modified value. While we're here we'll need to change a few
more things. First let's change heal to use our new getter function.

.. code:: lua

   --- @param amount integer
   function Health:heal(amount)
      self.hp = math.min(self.hp + amount, self:getMaxHP())
   end

Next we'll add a small function that will clamp hp to maxhp for a little bit later in the tutorial.

.. code:: lua

   function Health:enforceBounds()
      self.hp = math.min(self.hp, self:getMaxHP())
   end

And finally we'll set ``Health.Modifier`` to the modifier we've just created for this component so that we can access it from a convenient place.

.. code:: lua

   Health.Modifier = HealthModifier

Now in ``gamelevelstate.lua`` we'll have to make a small change. We're drawing maxHP, but we're accessing it directly let's change this line in ``draw``:

.. code:: lua

   if health then self.display:putString(1, 1, "HP: " .. health.hp .. "/" .. health.maxHP) end

To use the new getter:

.. code:: lua

   if health then self.display:putString(1, 1, "HP: " .. health.hp .. "/" .. health:getMaxHP()) end

Drinking
--------

Let's create a new file in ``modules/game/components`` called ``drinkable.lua``.

.. code:: lua

   --- @class DrinkableOptions
   --- @field healing integer?
   --- @field status StatusEffectsInstance?

   --- @class Drinkable : Component
   --- @field healing integer?
   --- @field status StatusEffectsInstance?
   --- @overload fun(options: DrinkableOptions): Drinkable
   local Drinkable = prism.Component:extend "Drinkable"

   function Drinkable:__new(options)
      self.healing = options.healing
      self.status = options.status
   end

   return Drinkable

We create a simple component with an optional healing value, and an optional status effect.

Now let's create a new file in ``modules/game/actions`` called ``drink.lua``.

.. code:: lua

   local DrinkTarget = prism.InventoryTarget()
      :inInventory()
      :with(prism.components.Drinkable)

First we define our target an item in the actor's inventory with the Drinkable component.

.. code:: lua

   --- @class Drink : Action
   local Drink = prism.Action:extend "Drink"
   Drink.targets = {
      DrinkTarget
   }

   --- @param level Level
   function Drink:perform(level, drink)
      local drinkable = drink:expect(prism.components.Drinkable)

      local statusComponent = self.owner:get(prism.components.StatusEffects)
      if statusComponent and drinkable.status then
         statusComponent:add(drinkable.status)
      end

Then if we've got a status effects component and our drink applies a status effect we add that to the status effects component.

.. code:: lua

      local health = self.owner:get(prism.components.Health)
      if health and drinkable.healing then
         health:heal(drinkable.healing)
      end
   end

   return Drink

Finally we'll heal the actor for the amount of the drinkable's healing, if any.

Brewing the potion
------------------

Create a new file in ``modules/game/actors`` called ``vitalitypotion.lua``.

.. code:: lua

   prism.registerActor("VitalityPotion", function()
      return prism.Actor.fromComponents {
         prism.components.Name("Potion of Vitality"),
         prism.components.Drawable("!", prism.Color4.RED),
         prism.components.Item(),
         prism.components.Drinkable{
            healing = 5,
            status = prism.GameStatusInstance{
               duration = 10,
               modifiers = {
                  prism.components.Health.Modifier(5)
               }
            }
         }
      }
   end)

You've seen most of this before, except the Drinkable component. Here we're saying that this potion should heal for 5 and modify the actor's maxHP
by +5 for 10 turns.

If we go into the game now and drink the potion everything should work, but you'll notice the buff doesn't expire after 10 turns! Let's fix that!

Ticking down durations
----------------------

Head over to ``modules/game/actions`` and create a new file called ``tick.lua``.

.. code:: lua

   --- @class Tick : Action
   local Tick = prism.Action:extend "Tick"
   Tick.requiredComponents = { prism.components.StatusEffects }

Our tick action can only be taken by actors who have a status effect component.

.. code:: lua

   --- @param level Level
   function Tick:perform(level)
      -- Handle status effect durations
      local statusComponent = self.owner:expect(prism.components.StatusEffects)

      local expired = {}
      for handle, status in statusComponent:pairs() do
         --- @cast status GameStatusInstance
         if status.duration then
            status.duration = status.duration - 1
            if status.duration <= 0 then
               table.insert(expired, handle)
            end
         end
      end

First we loop through all of the status effects currently applied to our actor, ticking down their durations and
keeping track of which ones have expired.

.. code:: lua

      for _, handle in ipairs(expired) do
         statusComponent:remove(handle)
      end

Then we remove the expired status effects.

.. code:: lua

      -- Validate components
      local health = self.owner:get(prism.components.Health)
      if health then health:enforceBounds() end
   end

   return Tick

Finally we clamp our hp to maxHP by calling ``enforceBounds`` from earlier. This is where you'd enforce minimums or maximums that might change.
Without this if the player ends the duration of the buff with 15 health they'd end up keeping that health total and only see a reduction in their
maximum.

Now head over to ``modules/game/systems`` and create a new file called ``tick.lua``.

.. code:: lua

   --- @class TickSystem : System
   local TickSystem = prism.System:extend "TickSystem"

   function TickSystem:onTurn(level, actor)
      level:tryPerform(prism.actions.Tick(actor))
   end

   return TickSystem

Each turn we try to perform tick action on the actor. If we head back into the game and spawn a new Potion of Vitality with Geometer and drink it
we'll see that our health and max health both go up by 5, and then after 10 turns our max health returns to it's original value, success!

Wrapping up
-----------

In the next chapter we'll make a wand and write some targetting code. 