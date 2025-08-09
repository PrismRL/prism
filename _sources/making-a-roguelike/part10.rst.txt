Packing your bags
=================

In this chapter we'll implement a simple inventory with the :doc:`optional module <../reference/extra/inventory/index>`.

..
   TODO: Write a how-to on the inventory module

Head over to main.lua and add the inventory module from extra.

.. code:: lua

   prism.loadModule("prism/extra/inventory")

Giving the player an inventory
------------------------------

Let's head over to ``modules/game/actors/player.lua`` and add our inventory component.
We'll limit the size to the alphabet.

.. code:: lua

   prism.components.Inventory{
      limitCount = 26,
   },

Adding a keybinding
-------------------

Let's head to ``keybindingschema.lua`` and add a few entries.

.. code:: lua

   -- inventory
   { key = "tab", action = "inventory", description = "Opens the inventory screen." },
   { key = "backspace", action = "return", description = "Moves back a level in a substate." },
   { key = "p", action = "pickup", description = "Picks up an inventory item." },

We'll use these later in the tutorial to open the inventory and return to the main
game state.

Creating an inventory screen
----------------------------

Navigate to ``gamestates`` and create a new file ``inventorystate.lua``.

We create a new :lua:class:`GameState` and we pass in the display, decision, level,
and the inventory. We get all the items at the time of instantiation and store them in the items field for convenience.
Finally we create a mapping of letters from 1-26 corresponding to a-z which we'll use during input handling.

.. code:: lua

   local utf8 = require "utf8"
   local keybindings = require "keybindingschema"

   --- @class InventoryState : GameState
   --- @overload fun(display: Display, decision: ActionDecision, level: Level, inventory: Inventory)
   local InventoryState = spectrum.GameState:extend "InventoryState"

   --- @param display Display
   --- @param decision ActionDecision
   --- @param level Level
   --- @param inventory Inventory
   function InventoryState:__new(display, decision, level, inventory)
      self.display = display
      self.decision = decision
      self.level = level
      self.inventory = inventory
      self.items = inventory.inventory:getAllActors()
      self.letters = {}
      for i = 1, #self.items do
         self.letters[i] = utf8.char(96 + i) -- a, b, c, ...
      end
   end

We also want to keep a reference to the previous ``GameState``, so we'll use :lua:func:`GameState.load` to capture it.

.. code:: lua

   function InventoryState:load(previous)
      self.previousState = previous
   end

Now we'll draw the inventory. To show the inventory on top of the level, we'll first draw the previous state.
Then we clear the display and draw a simple header, aligned to the right side of the screen. Finally, we loop through
each item in our inventory, assign it a letter based on its index, and draw it to the screen.

.. code:: lua

   function InventoryState:draw()
      self.previousState:draw()
      self.display:clear()
      self.display:putString(1, 1, "Inventory", nil, nil, 2, "right")

      for i, actor in ipairs(self.items) do
         local name = actor:getName()
         local letter = self.letters[i]

         local item = actor:expect(prism.components.Item)
         local countstr = ""
         if item.stackCount and item.stackCount > 1 then
            countstr = ("%sx "):format(item.stackCount)
         end

         local itemstr = ("[%s] %s%s"):format(letter, countstr, name)
         self.display:putString(1, 1 + i, itemstr, nil, nil, 2, "right")
      end
      self.display:draw()
   end

Now we handle keypresses. For the items we loop through our letters to find which one matches our keypress
and for now we just try to drop the item when we hit that button. ``Drop``'s :lua:class:`canPerform() <Action.canPerform>` will return false
if given a ``nil`` target.

.. code:: lua

   function InventoryState:keypressed(key)
      for i, letter in ipairs(self.letters) do
         if key == letter then
            local pressedItem = self.items[i]
            local drop = prism.actions.Drop(self.decision.actor, pressedItem)
            if drop:canPerform(self.level) then
               self.decision:setAction(drop)
            end

            self.manager:pop()
            return
         end
      end

Then we check if the user hit the inventory or return key, and if so we call :lua:func:`GameStateManager.pop`,
returning us to the previous state.

.. code:: lua

      local binding = keybindings:keypressed(key)
      if binding == "inventory" or binding == "return" then
         self.manager:pop()
      end
   end

   return InventoryState

.. dropdown:: Complete inventorystate.lua

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part10/gamestates/inventorystate.lua>`_

   .. code:: lua

      local keybindings = require "keybindingschema"

      --- @class InventoryState : GameState
      --- @field previousState GameState
      --- @overload fun(display: Display, decision: ActionDecision, level: Level, inventory: Inventory)
      local InventoryState = spectrum.GameState:extend "InventoryState"

      --- @param display Display
      --- @param decision ActionDecision
      --- @param level Level
      --- @param inventory Inventory
      function InventoryState:__new(display, decision, level, inventory)
         self.display = display
         self.decision = decision
         self.level = level
         self.inventory = inventory
         self.items = inventory.inventory:getAllActors()
         self.letters = {}
         for i = 1, #self.items do
            self.letters[i] = string.char(96 + i) -- a, b, c, ...
         end
      end

      function InventoryState:load(previous)
         self.previousState = previous
      end

      function InventoryState:draw()
         self.previousState:draw()
         self.display:clear()
         self.display:putString(1, 1, "Inventory", nil, nil, 2, "right")

         for i, actor in ipairs(self.items) do
            local name = actor:getName()
            local letter = self.letters[i]

            local item = actor:expect(prism.components.Item)
            local countstr = ""
            if item.stackCount and item.stackCount > 1 then countstr = ("%sx "):format(item.stackCount) end

            local itemstr = ("[%s] %s%s"):format(letter, countstr, name)
            self.display:putString(1, 1 + i, itemstr, nil, nil, 2, "right")
         end

         self.display:draw()
      end

      function InventoryState:keypressed(key)
         for i, letter in ipairs(self.letters) do
            if key == letter then
               local pressedItem = self.items[i]
               local drop = prism.actions.Drop(self.decision.actor, pressedItem)
               if drop:canPerform(self.level) then self.decision:setAction(drop) end

               self.manager:pop()
               return
            end
         end

         local binding = keybindings:keypressed(key)
         if binding == "inventory" or binding == "return" then self.manager:pop() end
      end

      return InventoryState

Opening the inventory
---------------------

With the inventory state complete it's time to glue things together. Head back to ``gamelevelstate.lua`` and
let's add some input handling to get the ``InventoryState`` to pop up.

First :lua:func:`require` access our ``InventoryState`` at the top of the file.

.. code:: lua

   local InventoryState = require "gamestates.inventorystate"

Then at the bottom of ``GameLevelState:keypressed``, just above the wait action, we'll check for the inventory key
and push the ``InventoryState``, if the current actor (``owner``) has an inventory.

.. code:: lua

   function GameLevelState:keypressed(key, scancode)
      -- ...

      if action == "inventory" then
         local inventory = owner:get(prism.components.Inventory)
         if inventory then
            local inventoryState = InventoryState(self.display, decision, self.level, inventory)
            self.manager:push(inventoryState)
         end
      end

      -- Handle waiting
      if action == "wait" then decision:setAction(prism.actions.Wait(self.decision.actor)) end
   end

Now we can run the game and hit tab. The inventory menu will show up (but won't do anything)!

Creating an item
----------------

Our kobold kicking hero needs something to chew on, and a way to regain health! Let's add a Meat Brick that they
can pick up and eat to restore their health.

Create a new file in ``modules/game/actors`` called ``meatbrick.lua`` and register the following actor.

.. code:: lua

   prism.registerActor("MeatBrick", function ()
      return prism.Actor.fromComponents{
         prism.components.Name("Meat Brick"),
         prism.components.Position(),
         prism.components.Drawable { char = "%", color=prism.Color4.RED },
         prism.components.Item{
            stackable = prism.actors.MeatBrick,
            stackLimit = 99
         }
      }
   end)

We give it the :lua:class:`Item` component to indicate it can be held in an :lua:class:`Inventory`.
We'll make it consumable in the next chapter!

Picking things up
-----------------

Now to be able to pick these things up we'll need to hook up the :lua:class:`Pickup` action.

.. code:: lua

   if action == "pickup" then
      local target = self.level:query(prism.components.Item)
         :at(owner:getPosition():decompose())
         :first()

      local pickup = prism.actions.Pickup(owner, target)
      if self.level:canPerform(pickup) then
         decision:setAction(pickup)
         return
      end
   end

We grab the first item on the tile and use it as the target for ``Pickup``.
Boot up the game and draw in a few meat bricks with Geometer. You should be able to
pick up and drop them now! In a future chapter, we'll hook up the `Die` action to sometimes
create a new `MeatBrick`.

Fixing the draw order
---------------------

You might notice that now when the player moves on top of the food sometimes the player is drawn underneath the food.
We can fix this by changing the depth or 'layer' the player's drawable is drawn at.
Go ahead and navigate back to ``modules/game/actors/player.lua``
and change the following line from

.. code:: lua

   prism.components.Drawable{ char = "@", color = prism.Color4.GREEN },

to

.. code:: lua

   prism.components.Drawable { char = "@", color = prism.Color4.GREEN, layer = math.huge },

We're setting the background color to ``nil`` so that it still defaults to transparent, but we're setting our draw priority
to :lua:data:`math.huge` so the player will always draw on top of everything else.

In the next chapter
-------------------

We've implemented a simple inventory with the provided inventory module.
In the next chapter we'll make the bricks consumable, get them to drop from kobolds, and add
user interface elements to allow the user a choice between dropping and eating the meat.
