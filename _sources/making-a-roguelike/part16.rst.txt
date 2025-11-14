Saving the game
===============

In this tutorial we're going to get the game saving and loading. We'll introduce a new game startup screen
for choosing between continuing and a new game, and we'll hook into love.quit to save the game when we quit.


Introductions
-------------

Head to ``modules/game/gamestates`` and create a new file ``gamestartstate.lua``.

.. code:: lua
    local controls = require "controls"

    --- @class GameStartState : GameState
    --- @field display Display
    --- @overload fun(display: Display): GameStartState
    local GameStartState = spectrum.GameState:extend("GameStartState")

    function GameStartState:__new(display)
        self.display = display
        self.save = love.filesystem.read("save.lz4")
    end

We import controls, because we'll use that a little later. All we do here is keep track of the display, and try to
read the savegame from disk. We're not saving it yet, so it won't exist and that's okay!

.. code:: lua

    function GameStartState:draw()
        local midpoint = math.floor(self.display.height / 2)

        self.display:clear()
        self.display:print(1, midpoint, "Kicking Kobolds", nil, nil, nil, "center", self.display.width)

        self.display:print(1, midpoint + 3, "[n] for new game", nil, nil, nil, "center", self.display.width)

        local i = 0
        if self.save then
            i = i + 1
            self.display:print(1, midpoint + 3 + i, "[l] to load game", nil, nil, nil, "center", self.display.width)
        end

        self.display:print(1, midpoint + 4 + i, "[q] to quit", nil, nil, nil, "center", self.display.width)
        self.display:draw()
    end

Now we draw a really simple newgame screen. We put the title of the game and a few options below.

.. code:: lua

    function GameStartState:update(dt)
        controls:update()

        if controls.newgame.pressed then
            love.filesystem.remove("save.lz4")
            local builder = Game:generateNextFloor(prism.actors.Player())
            self.manager:enter(
                spectrum.gamestates.GameLevelState(self.display, builder, Game:getLevelSeed())
            )
        elseif controls.loadgame.pressed and self.save then
            local mp = love.data.decompress("string", "lz4", self.save)
            local save = prism.Object.deserialize(prism.messagepack.unpack(mp))
            Game = save
            self.manager:enter(spectrum.gamestates.GameLevelState(self.display, Game.level))
        elseif controls.quit.pressed then
            love.quit()
        end
    end

    return GameStartState

Lastly we'll wire up our options to controls. New game will delete the old save and restart the game anew.
Load will restore the save from disk and send us to our previous game. Quit quits the game.

One minor problem! We haven't actually defined these controls yet, so let's do that!

Controls
--------

Head over to ``controls.lua`` and add the following controls.

.. code:: lua
    newgame        = "n",
    loadgame       = "l",

Cleaning up main
----------------

Okay we've got our start screen and new controls defined. Let's get this actually showing up! Navigate
over to ``main.lua``.

Let's replace our love.load() function with the following:

.. code:: lua

    function love.load(args)
        if args[1] == "--debug" then
            local builder = prism.LevelBuilder()
            local function generator()
                Game:generateNegamextFloor(prism.actors.Player(), builder)
            end

            manager:push(spectrum.gamestates.MapGeneratorState(generator, builder, display))
        else
            manager:push(spectrum.gamestates.GameStartState(display))
        end
        
        manager:hook()
        spectrum.Input:hook()
    end

This will push our start screen to the stack when the game loads up. Now we need to modify Game a bit to track a bit
more state when saving/loading.

Modifying Game
--------------

Let's modify the class definition and constructor of Game.

.. code:: lua
    --- @class Game : Object
    --- @field depth integer
    --- @field lost boolean
    --- @field level Level?
    --- @overload fun(seed: string): Game
    local Game = prism.Object:extend("Game")

    --- @param seed string
    function Game:__new(seed)
        self.depth = 0
        self.rng = prism.RNG(seed)
        self.lost = false
    end

We're also going to modify how we expose Game. At the bottom of the file replace the line where we return Game
with the following:

.. code:: lua

    _G.Game = Game(tostring(os.time()))

Next, find any instances of ``require("game")`` in your code and remove it. Here we're creating a global variable that
contains the gamestate and can be easily replaced during serialization.


Losing and levels
-----------------

Now, let's make a few changes to GameLevelState and GameOverState. We need them to track what level we're on,
and if we've lost the game.

First let's head over to ``modules/game/gamestates/gameoverstate.lua```. 

Add the following line to the top of GameOverState:update:

.. code:: lua

    function GameOverState:update(dt)
        Game.lost = true
        ...
    end

Now let's head over to ``modules/game/gamestates/gamelevelstate.lua``.

Add the following line to the top of GameLevelState:updateDecision:

.. code:: lua
    function GameLevelState:updateDecision(dt, owner, decision)
        Game.level = self.level
        ...
    end

Saving the game
---------------

We're finally read to wire everything up. It's time to save the game. Head back over to ``main.lua``.

Add a ``require "game"`` to the top of the file.

.. code:: lua

    require "debugger"
    require "prism"
    require "game"

Now let's define a ``love.quit`` hook that will run when the game is stopped. We'll check if we lost, and if so we'll
delete any existing save and return. If we haven't lost we'll save the current state of the game for the user's next session.

.. code:: lua

    function love.quit()
        if Game.lost then love.filesystem.remove("save.lz4") return end
        local save = Game:serialize()
        local mp = prism.messagepack.pack(save)
        local lz = love.data.compress("string", "lz4", mp)
        love.filesystem.write("save.lz4", lz)
    end

In the next chapter
-------------------

We'll use serialization in a different way, creating prefabs and using them to spice up level generation!