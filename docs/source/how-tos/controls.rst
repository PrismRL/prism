Input handling
==============

Input and controls are handled through the :lua:class:`spectrum.Input <Input>` class. Keyboard (key
presses and textual inputs), mouse, and controllers are supported.

Hooking in
----------

:lua:func:`Input.hook` must be called on load to begin tracking inputs.

.. caution::

   This must be done **before** :lua:func:`GameStateManager.hook`.

Querying inputs
---------------

Inputs can be queried directly on ``spectrum.Input`` itself.

.. code-block:: lua

   spectrum.Input.key.space.pressed -- space key pressed

   spectrum.Input.mouse[1].released -- mouse 1 released

   spectrum.Input.text[">"].pressed -- ">" entered on keyboard

   spectrum.Input.button.x.pressed  -- X controller button pressed

.. note::

   See `here <https://love2d.org/wiki/KeyConstant>`_ for a list of keys and
   `here <https://love2d.org/wiki/GamepadButton>`_ for a list of buttons.

Controls
--------

Controls can be defined with :lua:class:`spectrum.Input.Controls <Controls>`. Below is the control
scheme for the template.

.. code-block:: lua

   spectrum.Input.Controls {
      controls = {
         move_upleft    = { "q", "y" },
         move_up        = { "w", "k", "axis:lefty+" },
         move_upright   = { "e", "u" },
         move_left      = { "a", "h", "axis:leftx-" },
         move_right     = { "d", "l", "axis:leftx+" },
         move_downleft  = { "z", "b" },
         move_down      = { "s", "j", "axis:lefty-" },
         move_downright = { "c", "n" },
         wait           = "x",
      },
      pairs = {
         move = {
            "move_upleft", "move_up", "move_upright",
            "move_left", "move_right",
            "move_downleft", "move_down", "move_downright"
         },
      },
   }

Controls must be updated once per frame before use via :lua:func:`Controls.update`. They can then
be queried much like the global input.

.. code-block:: lua

   controls:update()

   controls.move_upleft.pressed

   controls.wait.pressed

   controls.move.pressed

   local vector = controls.move.vector

Querying other inputs
---------------------

Both ``spectrum.Input`` and instances of ``Controls`` can access the :lua:class:`InputGetter` via ``.get``. 
This can retrieve things like the mouse position, scroll wheel, control sticks, etc.

.. code-block:: lua

   local x, y = controls.get:mouse()
