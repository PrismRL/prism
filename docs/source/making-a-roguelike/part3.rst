Starting fights
===============

Kicking kobolds is fun. Let's make it so you can kick them to death!

Getting healthy
---------------

1. Navigate to ``modules/game/components``
2. Create a new file named ``health.lua``

.. code:: lua  

   --- @class Health : Component
   --- @field maxHP integer
   --- @field hp integer
   local Health = prism.Component:extend("Health")

   function Health:__new(maxHP)
      self.maxHP = maxHP
      self.hp = maxHP
   end

   return Health

In ``kobold.lua``, add our new ``Health`` component to the list.

.. code:: lua  

   prism.components.Health(3),

Implementing the die action
---------------------------

Next we'll create a ``Die`` action to encapsulate the removal of actors. Create a file called
``modules/game/actions/die.lua`` and enter the following:

.. code:: lua

   ---@class Die : Action
   ---@overload fun(owner: Actor): Die
   local Die = prism.Action:extend("Die")

   function Die:perform(level)
      level:removeActor(self.owner)
   end

   return Die

Now that we have the ``Die`` action, let's test it by changing the ``Fall`` action to use it instead of just removing
the actor from the level.

Navigate to ``modules/game/actions/fall.lua`` and replace the single line in its ``perform`` with the following:

.. code:: diff

  - level:removeActor(self.owner) -- into the depths with you!

.. code:: lua

    level:perform(prism.actions.Die(self.owner))

Doing damage
------------

Next we're going to add the Damage action. This accepts a single target: the amount of damage to be taken.
It modifies the health of the target and if it's at or below zero we trigger the Die action we just added.

An action's ``targets`` are the parameters passed into the ``perform`` method, in order. We use the :lua:class:`Target` to apply validation to ensure types within ``perform`` match our expectations. Typically, you will be passing in instances of actors, but in this case it's just a number representing the amount of damage we will apply.

.. code:: lua

   local DamageTarget = prism.Target()
      :isType("number")

   --- @class Damage : Action
   --- @overload fun(owner: Actor, damage: number): Damage
   local Damage = prism.Action:extend("Damage")
   Damage.name = "Damage"
   Damage.targets = { DamageTarget }
   Damage.requiredComponents = { prism.components.Health }

   function Damage:perform(level, damage)
      local health = self.owner:expect(prism.components.Health)
      health.hp = health.hp - damage

      if health.hp <= 0 then
         level:perform(prism.actions.Die(self.owner))
      end
   end

   return Damage

Let's head back to ``modules/game/actions/kick.lua`` and at the end of ``Kick:perform`` we're going to add the
following:

.. code:: lua

   function Kick:perform(level, kicked)
      ...

      local damage = prism.actions.Damage(kicked, 1)
      if level:canPerform(damage) then
         level:perform(damage)
      end
   end

That's all for now
------------------

We've started on a basic health system and made our ``Kick`` action deal damage. In the :doc:`next chapter <part4>` 
we'll implement the player health, make kobolds dangerous by giving them the attack action, and implement 
the required logic for the player dying.
