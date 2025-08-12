Zapping wands
=============

.. note:: 

    This chapter is very work in progress, beware! Don't procede yet adventurer!

In this chapter we'll add wands and a generalized targetting system for actions. We'll add a Wand of Hurt which you can
zap a creature with to hurt them, and a Wand of Swapping which you can use to swap positions with another actor.

Creating a base module
----------------------

We're going to be creating a base module where we can put components, actions, and actors we want to reference in the main
module so they're available at load time.

Head to ``modules`` and create a new folder there called ``basegame``. Now go ahead and add an ``actions`` and ``components``
folder.

Let's head to ``modules/basegame/components`` and create a new file ``zappable.lua``.

.. code:: lua

    --- @class ZappableOptions
    --- @field charges integer
    --- @field cost integer

    --- @class Zappable : Component
    --- @overload fun(): Zappable
    local Zappable = prism.Component:extend "Zappable"

    function Zappable:__new(options)
        self.charges = options.charges
        self.cost = options.cost
    end

    function Zappable:canZap(cost)
        cost = cost or self.cost
        return self.charges >= cost
    end

    function Zappable:reduceCharges(cost)
        cost = cost or self.cost
        self.charges = self.charges - self.cost
    end

    return Zappable

This component is going to be the base Zappable component all of our wand components derive from. It implements a few utility functions
for managing charges and checking if we have charges left to zap.

Now let's head to ``modules/basegame/actions`` and create a new file ``zap.lua``.

.. code:: lua

    local Log = prism.components.Log

    local ZappableTarget = prism.InventoryTarget()
        :inInventory()
        :with(prism.components.Zappable)

    --- @class Zap : Action
    local Zap = prism.Action:extend "Zap"
    Zap.name = "Zap"
    Zap.abstract = true
    Zap.targets = { ZappableTarget }
    Zap.ZappableTarget = ZappableTarget

    --- @param level Level
    --- @param zappable Actor
    function Zap:canPerform(level, zappable)
        return zappable:expect(prism.components.Zappable):canZap()
    end

    --- @param level Level
    --- @param zappable Actor
    function Zap:perform(level, zappable)
        local zappableComponent = zappable:expect(prism.components.Zappable):reduceCharges()
        Log.addMessage(self.owner, "You zap the wand!")
    end

    return Zap

Now we implement a zap action. We implement a canPerform that checks if the wand has enough charges to zap. Then we
implement a perform action that reduces the wand's charges and logs a message.

Making a wand
-------------

Let's head to ``/modules/game/components`` and create a new folder called ``zappable``. Then let's create a new file
named ``hurtzappable.lua``.

.. code:: lua

    --- @class HurtZappableOptions : ZappableOptions
    --- @field damage integer

    --- @class HurtZappable : Zappable
    --- @overload fun(options: HurtZappableOptions): HurtZappable
    local HurtZappable = prism.components.Zappable:extend "HurtZappable"

    --- @param options HurtZappableOptions
    function HurtZappable:__new(options)
        prism.components.Zappable.__new(self, options)
        self.damage = options.damage
    end

    return HurtZappable

This is pretty much the base Zappable component, but we've added a damage amount to it. Now let's head to
``modules/game/actors`` and create a new file named ``wandofhurt.lua``.

.. code:: lua

    prism.registerActor("WandofHurt", function()
    return prism.Actor.fromComponents {
        prism.components.Name("Wand of Hurt"),
        prism.components.Drawable{
            char = "/"
        },
        prism.components.HurtZappable{
            charges = 3,
            cost = 1,
            damage = 3,
        },
        prism.components.Item(),
    }
    end)

Great, now we've got to implement the zap. Head over to ``modules/game/actions`` and create a new file folder called
``zaps``. Inside create a new file called ``hurtzap.lua``.

.. code:: lua

    local HurtZappableTarget = prism.InventoryTarget(prism.components.HurtZappable)
        :inInventory()

    local HurtTarget = prism.Target(prism.components.Health)
        :range(5)
        :sensed()

    --- @class HurtZap : Zap
    local HurtZap = prism.actions.Zap:extend "HurtZap"
    HurtZap.abstract = false
    HurtZap.targets = { 
        HurtZappableTarget,
        HurtTarget
    }

    --- @param level Level
    function HurtZap:perform(level, zappable, hurtable)
        prism.actions.Zap.perform(self, level, zappable)
        local zappableComponent = zappable:expect(prism.components.HurtZappable)
        level:tryPerform(prism.actions.Damage(hurtable, zappableComponent.damage))
    end

    return HurtZap

We're going to extend the base zap to add a tiny bit of behavior to it. We'll add a target, anything with health, and
try to deal damage to it.

Okay now if you go in game there's a bit of an issue! You can't actually zap anything with this wand yet, just drop it!
We'll have to modify the user interface to add some proper targetting to let us select who we'd like to zap.

Handling targets
----------------

Let's head over ``gamestates`` and create a new folder called ``targethandlers``. Inside let's create a new file called
``targethandler.lua``.

Let's walk through step by step. We're going to create a new base class we'll use for all our target handlers.

.. code:: lua

    --- @class TargetHandler : GameState
    --- @field display Display
    --- @field levelState LevelState
    --- @field validTargets any
    --- @field curTarget any
    --- @field target Target
    --- @field level Level
    --- @field targetList any[]
    --- @overload fun(display: Display, levelState: LevelState, targetList: any[], target: Target): self
    local TargetHandler = spectrum.GameState:extend("TargetHandler")

    ---@param display Display
    ---@param levelState LevelState
    ---@param targetList any[]
    ---@param target Target
    function TargetHandler:__new(display, levelState, targetList, target)
        self.display = display
        self.levelState = levelState
        self.owner = self.levelState.decision.actor
        self.level = self.levelState.level
        self.targetList = targetList
        self.target = target
        self.index = nil
    end

This accepts a display, the base levelstate, a target list, and the current target we're handling and initializes
a few fields for convenience.

.. code:: lua

    function TargetHandler:getValidTargets()
        error("Method 'getValidTargets' must be implemented in subclass")
    end

    function TargetHandler:init()
        self.validTargets = self:getValidTargets()
        if #self.validTargets == 0 then self.manager:pop("poprecursive") end
    end

    function TargetHandler:resume(previous, shouldPop)
        if shouldPop == "poprecursive" then self.manager:pop("poprecursive") return end
        if shouldPop then self.manager:pop() return end

        self:init()
    end

    function TargetHandler:load()
        self:init()
    end

    return TargetHandler

The first method, ``getValidTargets()`` is defined in the base class because we use it in the following methods to see if we
have a target and start popping states back to the inventory if we don't.

The init function is called in both resume and load and primes the target handler with all of the valid targets, and pops
back to the inventory if not. We pass "poprecursive" up the chain of states to indicate we should keep popping until we
reach the inventory again.

Creating our concrete target handler
------------------------------------

Let's head over to ``gamestates/targethandlers`` and create a new file called ``generaltargethandler.lua``.

.. code:: lua

    local keybindings = require "keybindingschema"
    local Name = prism.components.Name
    local TargetHandler = require "gamestates.targethandlers.targethandler"

    --- @class GeneralTargetHandler : TargetHandler
    --- @field selectorPosition Vector2
    local GeneralTargetHandler = TargetHandler:extend("GeneralTargetHandler")

We create a new target handler derived from the TargetHandler gamestate. Next we move on to getValidTargets. Where we'll
query the level for valid targets to our action and collect them.

.. code:: lua

    function GeneralTargetHandler:getValidTargets()
        local valid = {}


        for foundTarget in self.level:query():target(self.target, self.level, self.owner, self.targetList):iter() do
            table.insert(valid, foundTarget)
        end

        if not (self.target.type and self.target.type ~= prism.Vector2) then
            for x, y in self.level.map:each() do
                local vec = prism.Vector2(x, y)
                if self.target:validate(self.level, self.owner, vec, self.targetList) then
                    table.insert(valid, vec)
                end
            end
        end

        return valid
    end

We check if the current target is a Vector or an Actor and we'll set the selectorPosition based on the current target that we chose
arbitrarily.

.. code:: lua

    function GeneralTargetHandler:setSelectorPosition()
        if prism.Vector2.is(self.curTarget) then
            self.selectorPosition = self.curTarget
        elseif self.curTarget then
            self.selectorPosition = self.curTarget:getPosition()
        end
    end

Next we'll redefine the init function to set the selector position.

.. code:: lua

    function GeneralTargetHandler:init()
        TargetHandler.init(self)
        self.curTarget = self.validTargets[1]
        self:setSelectorPosition()
    end

Then we'll implement a draw function that draws this state. You'll recognize a lot of this code it's very similar to the code found in
``GameLevelState``. The main difference between this and the drawing code in GameLevelState is that we'll center the camera on the selector's position.

.. code:: lua

    function GeneralTargetHandler:draw()
        local cameraPos = self.selectorPosition

        self.display:clear()
        -- set the camera position on the display
        local ox, oy = self.display:getCenterOffset(cameraPos:decompose())
        self.display:setCamera(ox, oy)

        -- draw the level
        local primary, secondary = self.levelState:getSenses()
        self.display:putSenses(primary, secondary)
        
        -- put a string to let the player know what's happening
        self.display:putString(1, 1, "Select a target!")
        self.display:putString(self.selectorPosition.x + ox, self.selectorPosition.y + oy, "X", prism.Color4.RED)
        
        -- if there's a target then we should draw it's name!
        if self.curTarget then
            local x, y = cameraPos:decompose()
            self.display:putString(x + ox + 1, y + oy, Name.get(self.curTarget))
        end
        self.display:draw()
    end

Now finally we'll handle keypresses. Let's walk through it. First let's define a map and the keypressed function.

.. code:: lua

    local keybindOffsets = {
        ["move up"] = prism.Vector2.UP,
        ["move left"] = prism.Vector2.LEFT,
        ["move down"] = prism.Vector2.DOWN,
        ["move right"] = prism.Vector2.RIGHT,
        ["move up-left"] = prism.Vector2.UP_LEFT,
        ["move up-right"] = prism.Vector2.UP_RIGHT,
        ["move down-left"] = prism.Vector2.DOWN_LEFT,
        ["move down-right"] = prism.Vector2.DOWN_RIGHT,
    }

    function GeneralTargetHandler:keypressed(key)
        local action = keybindings:keypressed(key)

First we'll check if the user hit the tab keybind, and if so we'll use Lua's next function to cycle through our valid targets table.

.. code:: lua
        if action == "tab" then
            local lastTarget = self.curTarget
            self.index, self.curTarget = next(self.validTargets, self.index)

            while 
                (not self.index and #self.validTargets > 0) or
                (lastTarget == self.curTarget and #self.validTargets > 1)
            do
                self.index, self.curTarget = next(self.validTargets, self.index)
            end

            self:setSelectorPosition()
        end

Then if the user hits the select keybind we add this target to the overall target list we're building and pop this instance of the target handler
off of the gamestate stack.

.. code:: lua

        if action == "select" and self.curTarget then
            table.insert(self.targetList, self.curTarget)
            self.manager:pop()
        end

If the user hits the return keybind we'll pop this state and pass "poprecursive" to indicate to the other states that we should pop all the way
back to the inventory.

.. code:: Lua

        if action == "return" then
            self.manager:pop("pop")
        end

Next we'll handle moving the selector. When the user hits a movement key we move the selector, check for a valid target on that tile, and if it exists
we'll set that as the current target.

.. code:: lua

        if keybindOffsets[action] then
            self.selectorPosition = self.selectorPosition + keybindOffsets[action]
            self.curTarget = nil

            if self.target:validate(self.level, self.owner, self.selectorPosition, self.targetList) then
                self.curTarget = self.selectorPosition
            end

            local validTarget = self.level:query()
                :at(self.selectorPosition:decompose())
                :target(self.target, self.level, self.owner, self.targetList)
                :first()

            if validTarget then
                self.curTarget = validTarget
            end
        end
    end

    return GeneralTargetHandler

Modifying InventoryActionState
------------------------------

Okay with our target handler out of the way we're going to have to make some changes to the InventoryActionState. Navigate to ``/gamestates/inventoryactionstate.lua``.
First we're going to make a small change to the constructor.

Instead of validating if the action is valid with it's only target being the item we'll instead validate if it's first target is
the item. The actions table notably now holds prototypes instead of instances of actions.

.. code:: lua

    function InventoryActionState:__new(display, decision, level, item)
        self.display = display
        self.decision = decision
        self.level = level
        self.item = item

        self.actions = {}

        for _, Action in ipairs(self.decision.actor:getActions()) do
            if Action:validateTarget(1, level, self.decision.actor, item) and not Action:isAbstract() then
                table.insert(self.actions, Action)
            end
        end
    end

Next we'll make a small modification to draw. We'll use the action's name field and fallback to the className if it doesn't exist. This is so our
zaps display as "Zap" and not "HurtZap".

.. code:: lua

    function InventoryActionState:draw()
        self.previousState:draw()
        self.display:clear()
        self.display:putString(1, 1, Name.get(self.item), nil, nil, 2, "right")

        for i, action in ipairs(self.actions) do
            local letter = string.char(96 + i)
            local name = string.gsub(action.name or action.className, "Action", "")
            self.display:putString(1, 1 + i, string.format("[%s] %s", letter, name), nil, nil, nil, "right")
        end

        self.display:draw()
    end

Now we'll modify the keypressed function. Instead of simply executing the action the user selects we'll know check if the action is valid with just the
item as the first target, and if not we'll push GeneralTargetHandler states to handle the rest of the targets.

.. code:: lua

    function InventoryActionState:keypressed(key)
        for i, Action in ipairs(self.actions) do
            if key == string.char(i + 96) then
                self.decision:trySetAction(Action(self.decision.actor, self.item), self.level)
                
                if self.decision:validateResponse() then
                    self.manager:pop()
                    return
                end

                self.selectedAction = Action
                self.targets = { self.item }
                for i = Action:getNumTargets(), 2, -1 do
                    self.manager:push(GeneralTargetHandler(
                    self.display,
                    self.previousState,
                    self.targets,
                    Action:getTargetObject(i),
                    self.targets
                    ))
                end
            end
        end

        local binding = keybindings:keypressed(key)
        if binding == "inventory" or binding == "return" then self.manager:pop() end
    end

And to wrap things up we'll change InventoryActionState's resume. When it resumes we'll check if we're handling targets for an action, adn if we are we check if we
succeeded. If we succeeded we set the action and then pop the state. If not we display a message to the user explaining why their action didn't work.

.. code:: lua

    function InventoryActionState:resume()
        if self.targets then
            local action = self.selectedAction(self.decision.actor, unpack(self.targets))
            local success, err = self.level:canPerform(action)
            if success then
                self.decision:setAction(action)
            else
                prism.components.Log.addMessage(self.decision.actor, err)
            end

            self.manager:pop()
        end
    end

Wrapping it up
--------------

That one was a doozy, but we layed the ground work for making adding new ways to target really easy in the future! In the next section we'll go over equipment, and modify InventoryActionState
a little bit more to handle non-standard targets like inventory slots.