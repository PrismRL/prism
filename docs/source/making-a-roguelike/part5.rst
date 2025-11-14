Writing things down
===================

In this chapter we're going to focus on exposing information to the player like their HP and the
most recent actions that happened to them to make the flow of the game more clear.

Keeping tabs on your health
---------------------------

Head on over to ``gamelevelstate.lua`` and in draw replace the following line:

.. code-block:: lua

   self.display:print(1, 1, "Hello prism!")

with:

.. code-block:: lua

   local health = player:get(prism.components.Health)
   if health then
      self.display:print(1, 1, "HP:" .. health.hp .. "/" .. health.maxHP)
   end

Now we have a primitive HP display.

Logging messages
----------------

Fortunately, prism provides a :lua:class:`Log` component in an optional module. Load it before the
``game`` module in ``main.lua``:

.. code-block:: lua
   :emphasize-lines: 3

   prism.loadModule("prism/spectrum")
   prism.loadModule("prism/extra/sight")
   prism.loadModule("prism/extra/log")
   prism.loadModule("modules/game")

Now head over to ``player.lua`` and give them a ``Log`` component.

.. code-block:: lua

   prism.components.Log()

.. TODO: #136 Write a how-to on logging and link it here

Logging kick
------------

Head to ``modules/game/actions/kick.lua`` and at the top of the file we'll define some shorthands:

.. code-block:: lua

   local Log = prism.components.Log
   local Name = prism.components.Name

These are mainly for convenience and brevity. Now head to the bottom of ``perform`` and add the
following.

.. code-block:: lua

   local kickName = Name.lower(kicked)
   local ownerName = Name.lower(self.owner)

   Log.addMessage(self.owner, "You kick the %s.", kickName)
   Log.addMessage(kicked, "The %s kicks you!", ownerName)
   Log.addMessageSensed(level, self, "The %s kicks the %s.", ownerName, kickName)

We use the convenience methods :lua:func:`Log.addMessage` and :lua:func:`Log.addMessageSensed` to
add messages to the affected and nearby actors.

Drawing logs
------------

Back in ``gamelevelstate.lua``, we'll draw the message log by grabbing the last 5 messages with
:lua:func:`Log.iterLast` and writing them to the screen.

.. code-block:: lua

   local log = player:get(prism.components.Log)
   if log then
      local offset = 0
      for line in log:iterLast(5) do
         self.display:print(1, self.display.height - offset, line)
         offset = offset + 1
      end
   end

This gives us a really basic message log at the bottom of the screen.

Adding damage
-------------

The kick message is nice, but wouldn't it be better if we could see how much damage we're doing?
Let's head to ``modules/game/actions/damage.lua`` and make a small change.

.. code-block:: lua

   function Damage:perform(level, damage)
      local health = self.owner:expect(prism.components.Health)
      health.hp = health.hp - damage
      self.dealt = damage -- add this!

      ...
   end

We store the damage that was dealt in the ``Damage`` action so that we can inspect it in kick. We
generate back to ``kick.lua``.

.. code-block:: lua

   function Kick:perform(level, kicked)
      ...
      local kickName = Name.lower(kicked)
      local ownerName = Name.lower(self.owner)
      local dealt = damage.dealt or 0

      Log.addMessage(self.owner, "You kick the %s for %i damage!", kickName, dealt)
      Log.addMessage(kicked, "The %s kicks you for %i damage!", ownerName, dealt)
      Log.addMessageSensed(level, self, "The %s kicks the %s for %i damage!", ownerName, kickName, dealt)
   end

Giving attack the same treatment
--------------------------------

Head over to ``modules/game/actions/attack.lua`` and add the same shorthands as before.

.. code-block:: lua

   local Log = prism.components.Log
   local Name = prism.components.Name

Then give the same treatment to ``Attack``.

.. code-block:: lua

   function Attack:perform(level, attacked)
      ...
      local attackName = Name.lower(attacked)
      local ownerName = Name.lower(self.owner)
      local dealt = damage.dealt or 0

      Log.addMessage(self.owner, "You attack the %s for %i damage!", attackName, dealt)
      Log.addMessage(attacked, "The %s attacks you for %i damage!", ownerName, dealt)
      Log.addMessageSensed(level, self, "The %s attacks the %s for %i damage!", ownerName, attackName, dealt)
   end

And we're done! You should now see messages for when you kick kobolds and they strike back.

Wrapping up
-----------

We now render the player's health and use the :lua:class:`Log` component to display a combat log. In
the :doc:`next section <part6>` we'll add a game over screen so that the game doesn't simply quit
when we lose.
