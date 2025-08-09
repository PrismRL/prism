Taking licks
============

It's time to make kobolds a little dangerous! In this chapter we're going
to give the player health and have the kobolds attack them!

Giving the player HP
--------------------

The first thing we're going to do is give the player a ``Health`` component.

.. code:: lua

    prism.components.Health(10),

Creating the attack component
-----------------------------

We need a component to hold information about attackers. For now, it will just hold how
much damage they deal.

.. code:: lua

    --- @class Attacker : Component
    --- @field damage integer
    --- @overload fun(damage: integer)
    local Attacker = prism.Component:extend("Attacker")

    --- @param damage integer
    function Attacker:__new(damage)
        self.damage = damage
    end

    return Attacker

In ``kobold.lua``, add our new ``Attacker`` component to the list.

.. code:: lua

   prism.components.Attacker(1)


The attack action
-----------------

Now let's make an attack action that the kobolds can use on the player. This is
pretty straightforward. Anything with health is attackable, and we apply our ``Damage`` action
based on the ``Attacker`` component.

Note that here, ``AttackTarget`` is an Actor with a Health component, and is passed into ``perform`` as ``attacked.`` This is more commonly how Targets are used, versus enforcing basic types like "number".

.. code:: lua

   local AttackTarget = prism.Target()
      :isPrototype(prism.Actor)
      :with(prism.components.Health)

   ---@class Attack : Action
   ---@overload fun(owner: Actor, attacked: Actor): Attack
   local Attack = prism.Action:extend "Attack"
   Attack.name = "Attack"
   Attack.targets = { AttackTarget }
   Attack.requiredComponents = { prism.components.Attacker }

   --- @param level Level
   --- @param attacked Actor
   function Attack:perform(level, attacked)
      local attacker = self.owner:expect(prism.components.Attacker)

      local damage = prism.actions.Damage(attacked, attacker.damage)
      if level:canPerform(damage) then
         level:perform(damage)
      end
   end

   return Attack

Next we need to make kobolds actually use the attack action. We will simply attempt to attack regardless of the situation, and assume that ``canPerform`` will reject the attempt if the circumstances are wrong (e.g. out of range).

Navigate to ``modules/game/components/koboldcontroller.lua``
and right above the final return we're going to add the following:

.. code:: lua

   function KoboldController:act(level, actor)
      ...

      local attack = prism.actions.Attack(actor, player)
      if level:canPerform(attack) then
         level:perform(attack)
      end

      return prism.actions.Wait(actor)
   end

Sending a message
-----------------

If you play the game now and let yourself get beat up by kobolds you'll find something unfortunate:
the game crashes when you die! To solve this we'll send a :lua:class:`Message` to the user interface with :lua:func:`Level.yield`
when the last player controlled actor dies.

.. note::

   You can read more about the game loop and why this happens :doc:`here <../explainers/game-loop>`.

1. Create a new folder in ``modules/game/`` called ``messages``.
2. Create a new file called ``lose.lua``

.. code:: lua

   --- @class LoseMessage : Message
   --- @overload fun(): LoseMessage
   local LoseMessage = prism.Object:extend("LoseMessage")
   return LoseMessage

This message just indicates that the game is over, so it doesn't need to hold any data. Next
head back over to the Die action. Let's change its ``perform`` to the following:

.. code:: lua

   function Die:perform(level)
      level:removeActor(self.owner)

      if not level:query(prism.components.PlayerController):first() then
         level:yield(prism.messages.Lose())
      end
   end

And finally we're going to handle this message in the user interface. Head back over to
``gamestates/gamelevelstate.lua`` and let's modify ``GameLevelState:handleMessage``.

.. code:: lua

   function GameLevelState:handleMessage(message)
      spectrum.LevelState.handleMessage(self, message)

      if prism.messages.Lose:is(message) then
         self.manager:pop()
         love.event.quit()
      end
   end

If we receive our ``LoseMessage``, we simply close the game. We'll improve on this in the next chapter.

Wrapping up
-----------

That's it for this chapter. Kobolds now wield an ``Attack`` action and we've handled
a fatal game crash by using a :lua:class:`Message`. In the :doc:`next section <part5>` we'll focus on
the user interface with stuff like adding a game over screen and a message log.
