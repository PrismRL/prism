Extra
=====

These are optional modules for common features. Use them in your games and modify them when
necessary by copying the module into your game's modules. To prevent the Lua language server from
complaining about double declarations, you can specify modules directly in the ``.luarc.json``, e.g.

.. code-block:: json

   "Lua.workspace.library": [
       "prism/engine",
       "prism/lib",
       "prism/spectrum",
       "prism/geometer",
       "prism/extra/condition",
   ],

If you wanted to modify the ``condition`` module, delete its entry.

.. toctree::
   :maxdepth: 2
   :glob:

   */index
