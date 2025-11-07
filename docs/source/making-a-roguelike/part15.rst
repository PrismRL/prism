Gearing up
==========

In this chapter we'll start gearing up our hero using the equipment module!

Setting up
----------

To begin, load the equipment module.

.. code-block:: lua

   prism.loadModule("prism/extra/equipment")

Then we'll give our player an :lua:class:`Equipper` component in ``player.lua``.

.. code-block:: lua

   prism.components.Equipper {
      "head",
      "armor",
      "boots",
      { name = "ringl", category = "ring", label = "ring" },
      { name = "ringr", category = "ring", label = "ring" },
      "amulet"
   }

Forging the ring
----------------

We'll start off with a ring of vitality that uses our ``HealthModifier`` from part 13. The
:lua:class:`Equipment` component accepts a list of required categories and a condition to apply
while equipped.

.. code-block:: lua

   prism.registerActor("RingofVitality", function()
      return prism.Actor.fromComponents {
         prism.components.Name("Ring of Vitality"),
         prism.components.Drawable {
            index = "o",
            color = prism.Color4.YELLOW,
         },
         prism.components.Item(),
         prism.components.Equipment(
            "ring",
            prism.condition.Condition(prism.modifiers.HealthModifier(5))
         ),
         prism.components.Position(),
      }
   end)

.. note::

   Equipment accepts a list of categories to support cases like two-handed weapons, e.g. ``{ "hand",
   "hand" }``.

We can get them to start dropping from chests by adding another entry in ``loot/chest.lua``. We'll
give it the same weight as wands.

.. code-block:: lua

   {
      entry = "RingofVitality",
      weight = 50
   }

Find (or cheat one in with Geometer, we won't judge) a ring and pop open the inventory screen. If
you select the ring you should already see an option to equip it! You should see our health go up by
5 when we slip it on. The built in :lua:class:`Equip` action gets picked up automatically by our
``InventoryActionState``, and modifier was handled previously.

The armory
----------

To view and unequip our items we'll implement a new game state,
``modules/game/gamestates/equipmentstate.lua``. Let's start off with our controls and defining our
familiar state fields, along with the ``Equipper`` component.

.. code-block:: lua

   local controls = require "controls"

   --- @class EquipmentState : GameState
   --- @field previousState GameState
   --- @overload fun(display: Display, decision: ActionDecision, level: Level, equipper: Equipper): self
   local EquipmentState = spectrum.GameState:extend "EquipmentState"

In our constructor we'll set our fields and then build up a data structure to display the slots. For
each slot, we'll grab the label and the actor (which may be ``nil``).

.. code-block:: lua

   --- @param display Display
   --- @param decision ActionDecision
   --- @param level Level
   --- @param equipper Equipper
   function EquipmentState:__new(display, decision, level, equipper)
      self.display = display
      self.decision = decision
      self.level = level
      self.equipper = equipper

      self.entries = {}
      self.letters = {}

      for i, slot in ipairs(equipper.slots or {}) do
         self.entries[i] = {
            slot = slot.label,
            actor = equipper:get(slot.name)
         }
         self.letters[i] = string.char(96 + i) -- a, b, c, ...
      end
   end

Don't forget to set our ``previousState`` when we load into this one!

.. code-block:: lua

   function EquipmentState:load(previous)
      self.previousState = previous
   end

Next we have to draw our slots. Like usual, we start by drawing the previous state and clearing the
display. Then for each of our entries we build up a line to display, e.g. ``[a] head - (empty)``.

.. code-block:: lua

   function EquipmentState:draw()
      self.previousState:draw()
      self.display:clear()
      self.display:print(self.display.width - 28, 1, "Equipment", nil, nil, 2)

      for i, entry in ipairs(self.entries) do
         local letter = self.letters[i]
         local slot = entry.slot
         local name = entry.actor and prism.components.Name.get(entry.actor) or "(empty)"
         local line = ("[%s] %s - %s"):format(letter, slot, name)
         self.display:print(self.display.width - 28, 1 + i, line, nil, nil, 2)
         if entry.actor then
            self.display:putActor(self.display.width - 28 + #line, 1 + i, drawable)
         end
      end

      self.display:draw()
   end

Finally, we'll call the built in ``Unequip`` action and pop the state when we press the
corresponding key. We'll allow backing out of the state like our other ones.

.. code-block:: lua

   function EquipmentState:update(dt)
      controls:update()

      for i, letter in ipairs(self.letters) do
         if spectrum.Input.key[letter].pressed then
            self.decision:setAction(
               prism.actions.Unequip(self.decision.actor, self.entries[i].actor),
               self.level
            )
            self.manager:pop()
         end
      end

      -- No equipment interaction yet—just allow closing
      if controls.equipment.pressed or controls.back.pressed then
         self.manager:pop()
         return
      end
   end

   return EquipmentState

Hook it together
----------------

All we have left to do is hook our state up in ``gamelevelstate.lua``.

.. code-block:: lua

   if controls.equipment.pressed then
      local equipper = owner:get(prism.components.Equipper)
      if equipper then
         local equipState =
            spectrum.gamestates.EquipmentState(self.display, decision, self.level, equipper)
         self.manager:push(equipState)
      end
   end

And add an entry to ``controls.lua``.

.. code-block:: lua

   equipment = "o",

Pop the ring on again and open the equipment state. The ring should show up in the screen, and
pressing the corresponding key should remove it, lowering our max health by 5.

Next time
---------

We'll go over serialization in the next chapter, allowing us to save our game and resume it later!
