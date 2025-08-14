Losing the game
===============

Right now the game simply quits when we hit zero hit points, but that's a bit unusual to say the
least. In this chapter we're going to create a new :lua:class:`GameState` to represent our game over
screen.

Making a gamestate
------------------

Navigate to the ``gamestates`` folder and create a new file called ``gameoverstate.lua`` with the
following contents:

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
      self.display:putString(
         1, midpoint,
         "Game over!",
         nil, nil, nil,
         "center", self.display.width
      )
      self.display:draw()
   end

   return GameOverState

We extend the :lua:class:`GameState` class and accept a :lua:class:`Display` in our constructor. For
now, we just draw "Game over!" centered on the screen by using :lua:func:`Display.putString`'s
alignment parameters.

Replacing the exit
------------------

Let's head over to ``gamelevelstate.lua``. First we're going to require our new state at the top of
the file.

.. code-block:: lua

   local GameOverState = require "gamestates.gameoverstate"

Then we'll head back to the ``handleMessage`` function. Replace our current handling of the ``Lose``
message with the following.

.. code-block:: lua

   if prism.messages.Lose:is(message) then
      self.manager:enter(GameOverState(self.display))
   end

Let's boot up the game and spawn in a few kobolds. Let yourself get slapped around and you should
see our new game over screen when you die!

A couple keybinds
-----------------

Our game state still forces you to close the game manually, so let's add a couple keybinds to
restart or close the game. In ``keybindingschema.lua``, add a couple entries:

.. code-block:: lua

   { key = "r", mode = "game-over", action = "restart", description = "Restarts the game." },
   { key = "q", mode = "game-over", action = "quit", description = "Quits the game." },

Back in ``gameoverstate.lua``, we'll add a ``keypressed`` callback to handle these:

.. code-block:: lua

   local keybindings = require "keybindingschema"

   function GameOverState:draw()
      ...
   end

   function GameOverState:keypressed(key, scancode, isrepeat)
      local action = keybindings:keypressed(key, "game-over")

      if action == "restart" then
         love.event.restart()
      elseif action == "quit" then
         love.event.quit()
      end
   end

Don't forget to ``require`` our keybindings! We use a ``game-over`` mode to differentiate from the
main game's controls. Finally, add some instructions:

.. code-block:: lua

   self.display:putString(
      1, midpoint + 3,
      "[r] to restart",
      nil, nil, nil,
      "center", self.display.width
   )
   self.display:putString(
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
