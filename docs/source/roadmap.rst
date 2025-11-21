Roadmap
=======

Plans for future versions of prism. Open an issue on GitHub or talk to us on Discord to give input
on priorities!

.. timeline::

   .. timeline-card:: 1.1

      Compatibility with Lua 5.1, for other platforms (including web).

   .. timeline-card:: 1.2

      Expanding the ``extra`` module library with lighting, sound, smell, and auto tiling modules.

   .. timeline-card:: 1.x

      - Reimplement Geometer with a :doc:`reference/spectrum/index`-based UI module, in
        preparation for features like a component editor.
      - Exposing/supporting said UI module for public use as a built-in UI to use in games.
      - Hot reloading of game objects?

   .. timeline-card:: 2.0

      - Unify querying on both cells and actors.
      - Unify the :lua:class:`Controller` and :lua:class:`Decision` API.
      - Split :lua:class:`Vector2` into ``Vector2i`` and ``Vector2f`` for better validation.
