Creating continuity
===================

In this chapter, we'll create a Game object and store it in a global called GAME to track
the overall state of the game. This includes managing a random number generator (RNG) that
we'll use to seed level generation, as well as keeping track of the dungeon depth the player
is currently exploring.

Getting the message
-------------------

First, let's update our ``DescendMessage`` to include the actor that's descending.

.. code:: lua

   --- @class DescendMessage : Message
   --- @field descender Actor
   --- @overload fun(descender: Actor): DescendMessage
   local DescendMessage = prism.Object:extend("DescendMessage")

   --- @param descender Actor
   function DescendMessage:__new(descender)
      self.descender = descender
   end

   return DescendMessage

Next, let's modify the ``Descend`` action so that it populates the message with the descending actor.

.. code:: lua

   function Descend:perform(level)
      level:removeActor(self.owner)
      level:yield(prism.messages.Descend(self.owner))
   end

Creating the game
-----------------

Now we'll create a new class ``Game``. This will hold an :lua:class:`RNG` and the current depth, and handle our
level generation. Having a centralized :lua:class:`RNG` for generating seeds for level generation ensures
that the game will be repeatable given the same seed.

.. code:: lua

   local levelgen = require "levelgen"

   --- @class Game : Object
   --- @field depth integer
   --- @field rng RNG
   --- @overload fun(seed: string): Game
   local Game = prism.Object:extend("Game")

   --- @param seed string
   function Game:__new(seed)
      self.depth = 0
      self.rng = prism.RNG(seed)
   end

   --- @return string
   function Game:getLevelSeed()
      return tostring(self.rng:random())
   end

   --- @param player Actor
   --- @return MapBuilder builder
   function Game:generateNextFloor(player)
      self.depth = self.depth + 1

      local genRNG = prism.RNG(self:getLevelSeed())
      return levelgen(genRNG, player, 60, 30)
   end

   return Game(tostring(os.time()))

This class will eventually track everything we need for the overall game.  There should only
be one instance of a ``Game``, so we return a seeded ``Game`` instance rather than the prototype.

Modifying the levelstate
------------------------

The first thing we’ll do is remove the levelgen require:

.. code:: diff

   -local levelgen = require "levelgen"

Next we'll change ``GameLevelState``'s constructor.

.. code:: lua

   --- @param display Display
   --- @param builder MapBuilder
   --- @param seed string
   function GameLevelState:__new(display, builder, seed)
      -- Build the map and instantiate the level with systems
      local map, actors = builder:build()
      local level = prism.Level(map, actors, {
         prism.systems.Senses(),
         prism.systems.Sight(),
         prism.systems.Fall(),
      }, nil, seed)

      -- Initialize with the created level and display, the heavy lifting is done by
      -- the parent class.
      spectrum.LevelState.__new(self, level, display)
   end

This sets up our level with the map we build and the seed we'll pass from the ``Game``.
Let's change our overload here as well to reflect the new arguments.

.. code:: lua

   --- @overload fun(display: Display, builder: MapBuilder, seed: string): GameLevelState
   local GameLevelState = spectrum.LevelState:extend "GameLevelState"

Now modify our message handler so it passes the player into the next level:

.. code:: lua

   if prism.messages.Descend:is(message) then
      --- @cast message DescendMessage
      self.manager:enter(GameLevelState(self.display, Game:generateNextFloor(message.descender), Game:getLevelSeed()))
   end

To indicate what level we're on, add another call to :lua:func:`Display.putString` below our health display:

.. code:: lua

   if health then self.display:putString(1, 1, "HP: " .. health.hp .. "/" .. health.maxHP) end

   self.display:putString(1, 2, "Depth: " .. Game.depth)

Finally, head over to main.lua and ``require`` the class right below where we’re loading all our modules.

.. code:: lua

   ...
   prism.loadModule("modules/game")

   local Game = require("game")

In ``love.load()``, we'll generate the first level and pass a seed for the level to our ``GameLevelState``.

.. code:: lua

   local builder = Game:generateNextFloor(prism.actors.Player())
   manager:push(GameLevelState(display, builder, Game:getLevelSeed()))

Launch the game, and your health should be maintained between floors!

Moving along
------------

We've created a ``Game`` class to maintain some global game state and now pass our player to the next level.
In the next section, we'll start working on an inventory system, along with a few items.
