Spectrum
========

The spectrum module extends the core engine with features like a display, camera, game states, and
more. You don't `have` to use anything here, but we try to make it applicable to as many games as
possible. Its classes can be accessed with the ``spectrum`` global, e.g. ``spectrum.Display``.

Registries
----------

- .. lua:data:: spectrum.gamestates: table<string, GameState>

     The game state registry.

.. toctree::
   :caption: Core
   :glob:
   :maxdepth: 1

   *

.. toctree::
   :caption: Components
   :maxdepth: 1
   :glob:

   components/*

.. toctree::
   :caption: Game states
   :maxdepth: 1
   :glob:

   gamestates/*

.. toctree::
   :caption: Messages
   :maxdepth: 1
   :glob:

   messages/*
