Sprites
=======

spectrum provides a :lua:class:`SpriteAtlas` class for managing and drawing sprites from a single image
file. These are used with :lua:class:`Display` and :lua:class:`Drawable`.

Loading an Atlas
----------------

The simplest way to create an atlas is from a grid of evenly sized cells:

.. code-block:: lua

   -- Load a 16×16 grid-based sprite sheet
   local atlas = spectrum.SpriteAtlas.fromGrid("tiles_16x16.png", 16, 16)

If your grid represents ASCII-like glyphs (from codepoint 0 upward), use the helper:

.. code-block:: lua

   local asciiAtlas = spectrum.SpriteAtlas.fromASCIIGrid("display/tiles_16x16.png", 16, 16)

This maps each quad to a UTF-8 character, allowing you to directly index by characters in
:lua:class:`Display`.

Integration with Display
------------------------

:lua:func:`SpriteAtlas.fromASCIIGrid` is designed for codepages:

.. code-block:: lua

   love.graphics.setDefaultFilter("nearest", "nearest")

   local atlas = spectrum.SpriteAtlas.fromASCIIGrid("display/tiles_16x16.png", 16, 16)
   local display = spectrum.Display(81, 41, atlas, prism.Vector2(16, 16))

Each display cell corresponds directly to a UTF-8 character mapped in the atlas.

Naming Sprites
--------------

:lua:func:`SpriteAtlas.fromGrid` allows custom sprite names:

.. code-block:: lua

   local names = { "floor", "wall", "water", "tree" }
   local atlas = spectrum.SpriteAtlas.fromGrid("terrain.png", 16, 16, names)

You can then look up quads by those names:

.. code-block:: lua

   local quad = atlas:getQuadByName("tree")

Using SpriteAtlas with Drawable
-------------------------------

To draw something from a spritesheet, a :lua:class:`Drawable` must reference a sprite
defined in the :lua:class:`SpriteAtlas`. This is done by setting sprite.index on the
:lua:class:`Drawable` (or on the :lua:class:`Sprite` passed into it). The ``index`` can be:

* a **number**, selecting a quad by its grid position, or
* a **string**, selecting a quad by the name assigned when creating the atlas
  (e.g. via :lua:func:`SpriteAtlas.fromGrid` with custom names or :lua:func:`SpriteAtlas.fromAtlased`).

When :lua:class:`Display` draws a :lua:class:`Drawable`, it resolves this value automatically:

* numeric ``index`` → ``spriteAtlas:getQuadByIndex(index)``
* string ``index`` → ``spriteAtlas:getQuadByName(name)``

To use a named sprite, provide the matching name:

.. code-block:: lua

    prism.components.Drawable{index = "player", color = prism.Color4.WHITE} -- named
    prism.components.Drawable{index = "@", color = prism.Color4.WHITE} -- ASCII

Or use a numeric index directly:

.. code-block:: lua

   prism.components.Drawable{index = 42, color = prism.Color4.WHITE}