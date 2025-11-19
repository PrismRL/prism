Carving out caverns
===================

In this section of the tutorial we'll create a more interesting place to kick kobolds, and put some
in the game world to start.

.. video:: ../_static/part7.mp4
   :autoplay:
   :nocontrols:
   :loop:
   :muted:
   :width: 100%

Getting started on a map
------------------------

Let's create a new file in the root of the project called ``levelgen.lua``. We'll return a function
from this module that takes a few parameters.

.. code-block:: lua

   local PARTITIONS = 3

   --- @param rng RNG
   --- @param player Actor
   --- @param width integer
   --- @param height integer
   --- @param builder? LevelBuilder
   return function(rng, player, width, height, builder)
      builder = builder or prism.LevelBuilder(prism.cells.Pit)

      -- world building code goes here!

      return builder
   end

We give the level building function an :lua:class:`RNG` which will be exclusive to it, the player we
want to place, and the width and height of the map we want generated. Inside we create a
:lua:class:`LevelBuilder` and return it. The constant ``PARTITIONS`` will define the grid size of
the rooms.

Debugging
---------

Before we begin filling up the level, let's set up a :lua:class:`MapGeneratorState` so we can see
how the level looks as it generates. In ``main.lua``, we'll check for an argument passed to decide
whether we preview the level or not. Rather than loading our regular state, we'll load a
:lua:class:`MapGeneratorState`, passing it a function used to generate the level, the
``LevelBuilder``, and the ``Display``.

.. code-block:: lua

   function love.load(args)
      if args[1] == "--debug" then
         local levelgen = require "levelgen"
         local builder = prism.LevelBuilder()
         local seed = prism.RNG(love.timer.getTime())
         local function generator()
            levelgen(seed, prism.actors.Player(), 60, 30, builder)
         end

         manager:push(spectrum.gamestates.MapGeneratorState(generator, builder, display)
      else
         manager:push(GameLevelState(display))
      end

Populating the void
-------------------

The first step is filling the void with a ``width`` * ``height`` initialization of pits and walls.
To decide where to put which we'll use `love.math.perlinNoise
<https://www.love2d.org/wiki/love.math.perlinNoise>`_. We'll offset the Perlin noise to a random
point and set a ``Wall`` for values greater than ``0.5``.

.. note::

   Perlin noise is deterministic and returns the same value for the same point, so offsetting where
   we start guarantees a random pattern.

.. code-block:: lua

    -- Fill the map with random noise of pits and walls.
   local nox, noy = rng:random(1, 10000), rng:random(1, 10000)
   for x = 1, width do
      for y = 1, height do
         local noise = love.math.perlinNoise(x / 5 + nox, y / 5 + noy)
         local cell = noise > 0.5 and prism.cells.Wall or prism.cells.Pit
         builder:set(x, y, cell())
      end
   end

Run the game with ``--debug``, e.g. ``love . --debug`` and hit the play button (or press ``\```).
You should see the noise get filled out!

Making room
-----------

Next, we'll generate rooms in a grid, where the width and height are determined by our
``PARTITIONS`` constant. First, create a table of :lua:class:`Rectangles <Rectangle>` to hold our
rooms.

.. code-block:: lua

   -- Create rooms in each of the partitions.
   --- @type table<number, Rectangle>
   local rooms = {}

We're going to omit one of the rooms to introduce some variance.

.. code-block:: lua

   local missing = prism.Vector2(
      rng:random(0, PARTITIONS - 1),
      rng:random(0, PARTITIONS - 1)
   )

Then we're going to calculate the total width and height of our patitions.

.. code-block:: lua

   local pw, ph = math.floor(width / PARTITIONS), math.floor(height / PARTITIONS)

After that let's set some reasonable limits on the minimum and maximum room width and height.

.. code-block:: lua

   local minrw, minrh = math.floor(pw / 3), math.floor(ph / 3)
   local maxrw, maxrh = pw - 2, ph - 2 -- Subtract 2 to ensure there's a margin.

Next we loop through each of our partitions and build a room so long as it's not the one we're
omitting. We create a :lua:class:`Rectangle`, hash its partition coordinates, and put it into our
table of rooms. Finally we draw the room onto our map with :lua:func:`LevelBuilder.drawRectangle`.
We use ``coroutine.yield()`` to return control back to Geometer, so we can see each rectangle get
drawn.

.. code-block:: lua

   for px = 0, PARTITIONS - 1 do
      for py = 0, PARTITIONS - 1 do
         if not missing:equals(px, py) then
            local rw = rng:random(minrw, maxrw)
            local rh = rng:random(minrh, maxrh)
            local x = rng:random(px * pw + 1, (px + 1) * pw - rw - 1)
            local y = rng:random(py * ph + 1, (py + 1) * ph - rh - 1)

            local roomRect = prism.Rectangle(x, y, rw, rh)
            rooms[prism.Vector2._hash(px, py)] = roomRect

            coroutine.yield()
            builder:drawRectangle(x, y, x + rw, y + rh, prism.cells.Floor)
         end
      end
   end

Carving hallways
----------------

Next we'll define a local function to draw the classic Rogue style L shaped hallways between rooms.
It accepts two :lua:class:`Rectangles <Rectangle>` representing the rooms, and if both ``a`` and
``b`` exist we draw a hallway between them. We use the level generator's RNG to determine if we
should start vertically or horizontally for a little bit of spice.

.. code-block:: lua

   -- Helper function to connect two points with an L-shaped hallway.
   --- @param a Rectangle
   --- @param b Rectangle
   local function createLShapedHallway(a, b)
      if not a or not b then return end

      local ax, ay = a:center():floor():decompose()
      local bx, by = b:center():floor():decompose()
      -- Randomly choose one of two L-shaped tunnel patterns for variety.
      if rng:random() > 0.5 then
         builder:line(ax, ay, bx, ay, prism.cells.Floor)
         builder:line(bx, ay, bx, by, prism.cells.Floor)
      else
         builder:line(ax, ay, ax, by, prism.cells.Floor)
         builder:line(ax, by, bx, by, prism.cells.Floor)
      end
   end

Now we'll go through each room and try to connect it to the one to the right, and the one to the
bottom. If either doesn't exist the hallway helper won't get past the guard and nothing will happen.

.. code-block:: lua

   for hash, currentRoom in pairs(rooms) do
      local px, py = prism.Vector2._unhash(hash)

      coroutine.yield()
      createLShapedHallway(currentRoom, rooms[prism.Vector2._hash(px + 1, py)])
      createLShapedHallway(currentRoom, rooms[prism.Vector2._hash(px, py + 1)])
   end

Spawning people
---------------

Now to place the player. We'll select a random room and put the player on the center tile.

.. code-block:: lua

   local startRoom
   while not startRoom do
      local x, y = rng:random(0, PARTITIONS - 1), rng:random(0, PARTITIONS - 1)
      startRoom = rooms[prism.Vector2._hash(x, y)]
   end

   local playerPos = startRoom:center():floor()
   coroutine.yield()
   builder:addActor(player, playerPos.x, playerPos.y)

We're getting close now, but we need some kobolds to kick. Let's go through every room that's not
the starting room and spawn a kobold there.

.. code-block:: lua

   for _, room in pairs(rooms) do
      if room ~= startRoom then
         local cx, cy = room:center():floor():decompose()

         coroutine.yield()
         builder:addActor(prism.actors.Kobold(), cx, cy)
      end
   end

Sending it back
---------------

Finally we'll pad the entire map in some walls and return the finished :lua:class:`LevelBuilder`.

.. code-block:: lua

   builder:addPadding(1, prism.cells.Wall)

   return builder

.. dropdown:: Complete levelgen.lua

   .. code:: lua

      local PARTITIONS = 3

      --- @param rng RNG
      --- @param player Actor
      --- @param width integer
      --- @param height integer
      return function(rng, player, width, height)
         local builder = prism.LevelBuilder(prism.cells.Wall)

         -- Fill the map with random noise of pits and walls.
         local nox, noy = rng:random(1, 10000), rng:random(1, 10000)
         for x = 1, width do
            for y = 1, height do
               local noise = love.math.perlinNoise(x / 5 + nox, y / 5 + noy)
               local cell = noise > 0.5 and prism.cells.Wall or prism.cells.Pit
               builder:set(x, y, cell())
            end
         end

         -- Create rooms in each of the partitions.
         --- @type table<number, Rectangle>
         local rooms = {}

         local missing = prism.Vector2(rng:random(0, PARTITIONS - 1), rng:random(0, PARTITIONS - 1))
         local pw, ph = math.floor(width / PARTITIONS), math.floor(height / PARTITIONS)
         local minrw, minrh = math.floor(pw / 3), math.floor(ph / 3)
         local maxrw, maxrh = pw - 2, ph - 2 -- Subtract 2 to ensure there's a margin.
         for px = 0, PARTITIONS - 1 do
            for py = 0, PARTITIONS - 1 do
               if not missing:equals(px, py) then
                  local rw, rh = rng:random(minrw, maxrw), rng:random(minrh, maxrh)
                  local x = rng:random(px * pw + 1, (px + 1) * pw - rw - 1)
                  local y = rng:random(py * ph + 1, (py + 1) * ph - rh - 1)

                  local roomRect = prism.Rectangle(x, y, rw, rh)
                  rooms[prism.Vector2._hash(px, py)] = roomRect

                  builder:drawRectangle(x, y, x + rw, y + rh, prism.cells.Floor)
               end
            end
         end

         -- Helper function to connect two points with an L-shaped hallway.
         --- @param a Rectangle
         --- @param b Rectangle
         local function createLShapedHallway(a, b)
            if not a or not b then return end

            local ax, ay = a:center():floor():decompose()
            local bx, by = b:center():floor():decompose()
            -- Randomly choose one of two L-shaped tunnel patterns for variety.
            if rng:random() > 0.5 then
               builder:line(ax, ay, bx, ay, prism.cells.Floor)
               builder:line(bx, ay, bx, by, prism.cells.Floor)
            else
               builder:line(ax, ay, ax, by, prism.cells.Floor)
               builder:line(ax, by, bx, by, prism.cells.Floor)
            end
         end

         for hash, currentRoom in pairs(rooms) do
            local px, py = prism.Vector2._unhash(hash)

            createLShapedHallway(currentRoom, rooms[prism.Vector2._hash(px + 1, py)])
            createLShapedHallway(currentRoom, rooms[prism.Vector2._hash(px, py + 1)])
         end

         -- Choose the first room (top-left partition) to place the player.
         local startRoom
         while not startRoom do
            local x, y = rng:random(0, PARTITIONS - 1), rng:random(0, PARTITIONS - 1)
            startRoom = rooms[prism.Vector2._hash(x, y)]
         end

         local playerPos = startRoom:center():floor()
         builder:addActor(player, playerPos.x, playerPos.y)

         for _, room in pairs(rooms) do
            if room ~= startRoom then
               local cx, cy = room:center():floor():decompose()

               builder:addActor(prism.actors.Kobold(), cx, cy)
            end
         end

         builder:addPadding(1, prism.cells.Wall)

         return builder
      end

Updating GameLevelState
-----------------------

Head back to ``modules/game/gamestates/gamelevelstate.lua`` and add the following line to the top of
the file.

.. code-block:: lua

   local levelgen = require "levelgen"

Then we're going to change its constructor. Head to ``GameLevelState:__new`` and let's replace the
map builder code there with this:

.. code-block:: lua

   local seed = love.timer.getTime()
   local builder = levelgen(prism.RNG(seed), prism.actors.Player(), 60, 30)

Now run the game! You'll be exploring a map reminiscent of Rogue but with a lot more pits to kick
kobolds into.

Descending to the next part
---------------------------

We've developed a simple level generation algorithm using :lua:class:`RNG` and
:lua:class:`LevelBuilder`. In the :doc:`next section <part8>` of the tutorial we'll add a set of
stairs and let the player descend deeper into the dungeon!
