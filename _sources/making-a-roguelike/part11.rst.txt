Having a snack
==============

In this section we'll make our food edible by presenting a simple menu for picking between dropping and eating.

Modifying health
----------------

Let's head over to ``module/game/components/health.lua`` and create a method to add health, so we don't
have to worry about going over the maximum.

.. code:: lua

   --- @param amount integer
   function Health:heal(amount)
      self.hp = math.min(self.hp + amount, self.maxHP)
   end

.. caution::

   This should only be called from actions because it modifies the component!

Making it edible
----------------

Let's create a new component to define what's edible. We'll take a single integer in
and set that to the component's ``healing`` field. Head over to ``module/game/components`` and
create a new file ``edible.lua``.

.. code:: lua

   --- @class Edible : Component
   --- @field healing integer
   --- @overload fun(healing: integer): Edible
   local Edible = prism.Component:extend("Edible")

   --- @param healing integer
   function Edible:__new(healing)
      self.healing = healing
   end

   return Edible

Now we'll create an action to use on the edible actor. Head to ``module/game/actions`` and
create a new file ``eat.lua``.

.. code:: lua
   local Log = prism.components.Log
   local Name = prism.components.Name
   local sf = string.format

   local EatTarget = prism.InventoryTarget(prism.components.Edible)
      :inInventory()

.. note::

   The inventory module injects :lua:class:`InventoryTarget`, a subclass of :lua:class:`Target` into 
   the ``prism`` namespace as a convenience. It includes extra filters for dealing with items.

Now we create our eat action. You need a health component to eat, and the target has to be something edible in your inventory
as we defined above.
   
.. code:: lua

   ---@class Eat : Action
   ---@overload fun(owner: Actor, food: Actor): Eat
   local Eat = prism.Action:extend("Eat")

   Eat.requiredComponents = {
      prism.components.Health
   }

   Eat.targets = {
      EatTarget
   }

To perform the action we just add to the owner's health with the ``heal()`` method we defined, making sure to remove the item 
with :lua:func:`Inventory.removeQuantity`.

.. code:: lua

   --- @param level Level
   --- @param food Actor
   function Eat:perform(level, food)
      local edible = food:expect(prism.components.Edible)
      local health = self.owner:expect(prism.components.Health)
      health:heal(edible.healing)

      local inventory = self.owner:expect(prism.components.Inventory)
      inventory:removeQuantity(food, 1)

      Log.addMessage(self.owner, sf("You eat the %s.", Name.get(food)))
      Log.addMessageSensed(level, self, sf("%s eats the %s.", Name.get(self.owner), Name.get(food)))
   end

   return Eat

.. dropdown:: Complete ``eat.lua``

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part11/modules/game/actions/eat.lua>`_

   .. code:: lua

      local Log = prism.components.Log
      local Name = prism.components.Name
      local sf = string.format

      local EatTarget = prism.InventoryTarget(prism.components.Edible):inInventory()

      ---@class Eat : Action
      ---@overload fun(owner: Actor, food: Actor): Eat
      local Eat = prism.Action:extend("Eat")

      Eat.requiredComponents = {
         prism.components.Health,
      }

      Eat.targets = {
         EatTarget,
      }

      --- @param level Level
      ---@param food Actor
      function Eat:perform(level, food)
         local edible = food:expect(prism.components.Edible)
         local health = self.owner:expect(prism.components.Health)
         health:heal(edible.healing)

         local inventory = self.owner:expect(prism.components.Inventory)
         inventory:removeQuantity(food, 1)

         Log.addMessage(self.owner, sf("You eat the %s.", Name.get(food)))
         Log.addMessageSensed(level, self, sf("%s eats the %s.", Name.get(self.owner), Name.get(food)))
      end

      return Eat

Now let's head back over to ``modules/game/actors/meat.lua`` and add the edible component to the meat actor.

.. code:: lua

   prism.components.Edible(1)

.. note::

   There's not much meat on kobold bones.

Modifying the interface
-----------------------

With the actual mechanics out of the way it's time to flesh out our inventory menu a little more. Create a new file called
``gamestates/inventoryactionstate.lua`` and let's create a new :lua:class:`GameState`. Load our :lua:class:`Keybinding`
and alias the name component at the top.

.. code:: lua

   local keybindings = require "keybindingschema"
   local Name = prism.components.Name

Next we'll create the new ``GameState`` and in the constructor we'll loop through all the actions 
the active actor can do, and assign those to a letter if the actor can take that action with 
the inventory item as the first target.

.. code:: lua

   --- @class InventoryActionState : GameState
   --- @field decision ActionDecision
   --- @field previousState GameState
   --- @overload fun(display: Display, decision: ActionDecision, level: Level, item: Actor)
   local InventoryActionState = spectrum.GameState:extend "InventoryActionState"

   --- @param display Display
   --- @param decision ActionDecision
   --- @param level Level
   --- @param item Actor
   function InventoryActionState:__new(display, decision, level, item)
      self.display = display
      self.decision = decision
      self.level = level
      self.item = item

      self.actions = {}

      for _, Action in ipairs(self.decision.actor:getActions()) do
         local action = Action(self.decision.actor, self.item)
         if self.level:canPerform(action) then
            table.insert(self.actions, action)
         end
      end
   end

Then we're going to store the :lua:class:`LevelState` in our ``previousState`` field so that we can draw the level under this menu.

.. code:: lua

   function InventoryActionState:load(previous)
      --- @cast previous InventoryState
      self.previousState = previous.previousState
   end

Then we can set up our draw function to loop through all of the possible actions and enumerate them 
to the user, drawing the letter used to take that action next to the item name.

.. code:: lua

   function InventoryActionState:draw()
      self.previousState:draw()
      self.display:clear()
      self.display:putString(1, 1, Name.get(self.item), nil, nil, 2, "right")

      for i, action in ipairs(self.actions) do
         local letter = string.char(96 + i)
         local name = string.gsub(action.className, "Action", "")
         self.display:putString(1, 1 + i, string.format("[%s] %s", letter, name), nil, nil, nil, "right")
      end

      self.display:draw()
   end

Then we'll handle the user selecting the action. If the user hits the letter that matches an
action we set the decision to that action.

.. code:: lua

   function InventoryActionState:keypressed(key)
      for i, action in ipairs(self.actions) do
         print(key, string.char(i + 96))
         if key == string.char(i + 96) then
            self.decision:setAction(action)
            self.manager:pop()
         end
      end

      local binding = keybindings:keypressed(key)
      if binding == "inventory" or binding == "return" then self.manager:pop() end
   end

Now we'll need to head over to ``gamestates/inventorystate.lua`` 
and push this new ``InventoryActionState`` onto the stack when a user selects an item instead of dropping it. 
Let's modify our ``InventoryState:keypressed`` to look like this:

.. code:: lua

   function InventoryState:keypressed(key)
      for i, letter in ipairs(self.letters) do
         if key == letter then
            self.manager:push(InventoryActionState(self.display, self.decision, self.level, self.items[i]))
            return
         end
      end

      local binding = keybindings:keypressed(key)
      if binding == "inventory" or binding == "return" then self.manager:pop() end
   end

We've got one last thing to handle. When we press a letter right now we just go back to the 
inventory screen and nothing happens until we leave that screen. A little strange to say the least! 
Let's :lua:func:`GameStateManager.pop` on :lua:func:`GameState.resume` if we have a valid decision.

.. code:: lua

   function InventoryState:resume()
      if self.decision:validateResponse() then
         self.manager:pop()
      end
   end

.. dropdown:: Complete ``inventoryactionstate.lua``

   `Source <https://github.com/PrismRL/Kicking-Kobolds/blob/part11/gamestates/inventoryactionstate.lua>`_

   .. code:: lua

      local keybindings = require "keybindingschema"
      local Name = prism.components.Name

      --- @class InventoryActionState : GameState
      --- @field decision ActionDecision
      --- @field previousState GameState
      --- @overload fun(display: Display, decision: ActionDecision, level: Level, item: Actor)
      local InventoryActionState = spectrum.GameState:extend "InventoryActionState"

      --- @param display Display
      --- @param decision ActionDecision
      --- @param level Level
      --- @param item Actor
      function InventoryActionState:__new(display, decision, level, item)
         self.display = display
         self.decision = decision
         self.level = level
         self.item = item

         self.actions = {}

         for _, Action in ipairs(self.decision.actor:getActions()) do
            local action = Action(self.decision.actor, self.item)
            if self.level:canPerform(action) then table.insert(self.actions, action) end
         end
      end

      function InventoryActionState:load(previous)
         --- @cast previous InventoryState
         self.previousState = previous.previousState
      end

      function InventoryActionState:draw()
         self.previousState:draw()
         self.display:clear()
         self.display:putString(1, 1, Name.get(self.item), nil, nil, 2, "right")

         for i, action in ipairs(self.actions) do
            local letter = string.char(96 + i)
            local name = string.gsub(action.className, "Action", "")
            self.display:putString(1, 1 + i, string.format("[%s] %s", letter, name), nil, nil, nil, "right")
         end

         self.display:draw()
      end

      function InventoryActionState:keypressed(key)
         for i, action in ipairs(self.actions) do
            if key == string.char(i + 96) then
               self.decision:setAction(action)
               self.manager:pop()
            end
         end

         local binding = keybindings:keypressed(key)
         if binding == "inventory" or binding == "return" then self.manager:pop() end
      end

      return InventoryActionState

In the next chapter
-------------------

We've made our food edible and expanded the ``InventoryState`` with dynamic action selection.
In the next chapter we'll go over drop tables and containers like chests, populating the 
dungeon with delicious meat and shiny trinkets!
