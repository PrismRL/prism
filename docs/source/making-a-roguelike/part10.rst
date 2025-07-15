Packing your bags
=================

.. note::

   This chapter is a work in progress! It's subject to change! Continue at your own risk adventurer!

In this chapter we'll go over how to use the inventory included in prism/extra. For more information
on how this is implemented make sure to check out the (TODO) how-to on inventory where we go over making a simple
inventory from scratch. The inventory from prism/extra provides most of what a classic roguelike needs
including weight, volume, and count limits along with stacking functionality.

Head over to main.lua and add the inventory module from extra.

.. code:: lua

   prism.loadModule("prism/extra/inventory")

Giving the player an inventory
------------------------------

Let's head over to ``modules/game/actors/player.lua`` and add our inventory component.

.. code:: lua

   prism.components.Inventory{
      limitCount = 26,
   },

For our game we're not going to use the weight or volume limits, we'll just limi the count to the number
of letters in the alphabet.

Adding a keybinding
-------------------

Let's head to ``keybindingschema.lua`` and add a new entry.

.. code:: lua

   -- inventory
   { key = "tab", action = "inventory", description = "Opens the inventory screen." },
   { key = "backspace", action = "return", description = "Moves back a level in a substate." },
   { key = "p", action = "pickup", description = "Picks up an inventory item." },

We'll use this a little later in the tutorial to open the inventory and return to the main
game state.

Creating an inventory screen
----------------------------

Navigate to ``gamestates`` and create a new file ``inventorystate.lua``.

Let's start with the constructor.

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

Here we create a new class based off GameState and we pass in the display, decision, level,
and the inventory. We get all the items at the time of instantiation and store them into the items field for convenience.
Finally we create a mapping of letters from 1-26 corresponding to a-z which we'll use during input handling.

.. code:: lua

   function InventoryState:draw()
      self.display:clear()
      self.display:putString(1, 1, "Inventory:")

      for i, actor in ipairs(self.items) do
         local name = actor:getName()
         local letter = self.letters[i]

         local item = actor:expect(prism.components.Item)
         local countstr = ""
         if item.stackCount and item.stackCount > 1 then
            countstr = ("%sx "):format(item.stackCount)
         end

         local itemstr = ("[%s] %s%s"):format(letter, countstr, name)
         self.display:putString(1, 1 + i, itemstr)
      end
      self.display:draw()
   end

Now we'll draw the inventory. We clear the display and draw a simple header. Then we loop through
each item in our inventory, assign it a letter based on it's index, and draw it to the screen.

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

      if binding == "inventory" or binding == "return" then
         self.manager:pop()
      end
   end

   return InventoryState

Now we handle keypresses. For the items we loop through our letters to find which one matches our keypress
and for now we just try to drop the item when we hit that button. We don't need to worry about if there's an
item actually assigned to that letter because drop will simply return false from canPerform if given a nil
target.

Then we check if the user hit the inventory or return key, and if so we pop the inventory from the statemanager,
returning us to the gamestate.

Opening the inventory
---------------------

Now with the inventory state done it's time to glue things together. Head back to ``gamelevelstate.lua`` and
let's add some input handling to get the InventoryState to pop up.

First thing we're going to need to do is add a require to acces our InventoryState at the top of the file.

.. code:: lua

   local InventoryState = require "gamestates.InventoryState"

Then at the bottom of ``GameLevelState:keypressed`` just above the wait action check let's add the following.

.. code:: lua

   function MyGameLevelState:keypressed(key, scancode)
      -- ...

      if action == "inventory" then
         local inventory = decision.actor:get(prism.components.Inventory)
         if inventory then
            local inventoryState = InventoryState(self.display, decision, self.level, inventory)
            self.manager:push(inventoryState)
         end
      end

      -- Handle waiting
      if action == "wait" then decision:setAction(prism.actions.Wait(self.decision.actor)) end
   end

Okay now we can run the game and hit tab. The inventory screen will show up! That's great but we can't actually do anything
with it yet.

Creating an item
----------------

Our kobold kicking hero needs something to chew on, and a way to regain health! Let's add a Meat Brick that they
can pick up and eat to restore their health!

Create a new file in ``modules/game/actors`` called ``meatbrick.lua`` and add the following.

.. code:: lua

   prism.registerActor("MeatBrick", function ()
      return prism.Actor.fromComponents{
         prism.components.Name("Meat Brick"),
         prism.components.Drawable("%", prism.Color4.RED),
         prism.components.Item{
            stackable = true,
            stackLimit = 99
         }
      }
   end)

Picking things up
-----------------

Now to be able to pick these things up we'll need to hook up the PickUp action provided by ``extra/inventory`` to the user interface.

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

When the user hits the pickup binding we grab the first item we can find on the tile, and generate a pickup action for it
placing it in the inventory. Go ahead and boot up the game and draw in a few meat bricks with Geometer. You should be able to
pick up and drop them now!

Fixing the draw order
---------------------

You might notice that now when the player moves on top of the food sometimes the player is drawn underneath the food.
We can fix this by changing the depth or 'layer' the player's drawable is drawn at. Go ahead and navigate back to ``modules/game/actors/player.lua``
and change the following line from

.. code:: lua

   prism.components.Drawable("@", prism.Color4.GREEN),

to

.. code:: lua

   prism.components.Drawable("@", prism.Color4.GREEN, nil, math.huge),

We're setting the background color to nil so that it still defaults to trasnparent, but we're setting our draw priority
to the highest number a Lua number can represent so that the player will always draw on top of everything else.

In the next chapter
-------------------

In the next chapter we'll add eating the meat bricks to heal the player, spawning them into the game world, and adding the requiredComponents
user interface elements for the user to choose between dropping and eating the meat. See you next time!
