Losing the game
===============

Right now the game simply quits when we hit zero hit points, but that's a bit unusual to say the
least. In this chapter we're going to create a new :lua:class:`GameState` to represent our game over
screen.

Making a gamestate
------------------

Navigate to the ``modules/game/gamestates`` folder and create a new file called
``gameoverstate.lua`` with the following contents:

.. code-block:: lua

   --- @class GameOverState : GameState
   --- @field display Display
   --- @overload fun(display: Display): GameOverState
   local GameOverState = spectrum.GameState:extend("GameOverState")

   function GameOverState:__new(display)
      self.display = display
   end

   function GameOverState:draw()
      local midpoint = math.floor(self.display.height / 2)

      self.display:clear()
      self.display:print(
         1, midpoint,
         "Game over!",
         nil, nil, nil,
         "center", self.display.width
      )
      self.display:draw()
   end

   return GameOverState

We extend the :lua:class:`GameState` class and accept a :lua:class:`Display` in our constructor. For
now, we just draw "Game over!" centered on the screen by using :lua:func:`Display.print`'s alignment
parameters.

Replacing the exit
------------------

Let's head over to ``gamelevelstate.lua``, and in the ``handleMessage`` function replace our current
handling of ``LoseMessage`` with the following.

.. code-block:: lua

   if prism.messages.LoseMessage:is(message) then
      self.manager:enter(spectrum.gamestates.GameOverState(self.display))
   end

Let's boot up the game and spawn in a few kobolds. Let yourself get slapped around and you should
see our new game over screen when you die!

A couple keybinds
-----------------

Our game state still forces you to close the game manually, so let's add a couple keybinds to
restart or close the game. In ``controls.lua``, add a couple entries:

.. code-block:: lua

   restart        = "r",
   quit           = "q",

Back in ``gameoverstate.lua``, we'll add a ``update`` callback to handle these. Don't forget to
``require`` our controls.

.. code-block:: lua

   local controls = require "controls"
   ...

   function GameOverState:draw()
      ...
   end

   function GameOverState:update(dt)
      controls:update()

      if controls.quit.pressed then
         love.event.quit()
      elseif controls.restart.pressed then
         love.event.restart()
      end
   end

.. note::

   See :doc:`../how-tos/controls` for a guide on input and controls.

Finally, let's add some instructions.

.. code-block:: lua

   self.display:print(
      1, midpoint + 3,
      "[r] to restart",
      nil, nil, nil,
      "center", self.display.width
   )
   self.display:print(
      1, midpoint + 4,
      "[q] to quit",
      nil, nil, nil,
      "center", self.display.width
   )
   self.display:draw()

Next up
-------

We've improved our death handling by using a new :lua:class:`GameState`. In the :doc:`next chapter
<part7>` we'll be getting into map generation, and finally turn this into a real roguelike. The
following chapters will take you through generating a map and descending through the dungeon.
