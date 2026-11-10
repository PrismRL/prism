Serialization
=============

prism can turn any :lua:class:`Object` into a plain table and back again, which is how levels get
saved in Geometer and how the tutorial saves the game. This page covers the parts you'll run into
when your own classes end up in a save.

Saving and loading
------------------

:lua:func:`Serializer.serialize` returns a table made only of strings, numbers, booleans and other
tables, so it can be handed to any encoder. prism ships with JSON and messagepack.

.. code-block:: lua

   local data = prism.Serializer.serialize(Game)
   local packed = prism.messagepack.pack(data)
   love.filesystem.write("save.lz4", love.data.compress("string", "lz4", packed))

``Game:serialize()`` is shorthand for the first line. The existing ``prism.Object.serialize``
and ``prism.Object.deserialize`` functions also delegate to ``prism.Serializer``.
Loading is the same thing in reverse.

.. code-block:: lua

   local packed = love.data.decompress("string", "lz4", love.filesystem.read("save.lz4"))
   Game = prism.Serializer.deserialize(prism.messagepack.unpack(packed))

Everything reachable from the object you pass in is saved. Objects that are referenced from more
than one place are saved once and stay shared after loading, and cycles are fine.

What can't be saved
-------------------

Functions are skipped. Userdata, such as a LÖVE image or an FFI buffer, raises an error that names
the field it was found in:

.. code-block:: text

   Cannot serialize userdata at Level.map.tileset

Classes have to be registered, which happens automatically when you call ``extend`` with a unique
name. Constructors aren't called when loading, so anything ``__new`` sets up beyond plain fields
has to be saved or rebuilt.

Leaving fields out
------------------

List fields that shouldn't be saved in ``_serializationBlacklist``. Caches and anything holding
userdata belong here.

.. code-block:: lua

   local IdleAnimation = prism.Component:extend "IdleAnimation"
   IdleAnimation._serializationBlacklist = { animation = true }

A class also skips everything its parents skip, so you only need to list your own fields.

Rebuilding after a load
-----------------------

Three optional methods are called on loaded objects, in this order:

- ``__deserialize()`` runs once every object has its saved fields back. Use it to rebuild
  anything that only depends on the object itself.
- ``__wire()`` runs after every ``__deserialize``, for state that depends on other objects.
- ``__finalize()`` runs last. :lua:class:`Level` uses it to rebuild its caches.

.. code-block:: lua

   function IdleAnimation:__deserialize()
      self.animation = spectrum.animations[self.animationName]()
   end

Don't rely on the order objects are visited in within one step.

Actors and cells from factories
-------------------------------

An actor or cell made by a registered factory is saved as the name of its factory plus whatever
has changed since, which keeps maps small. When the save is loaded the factory is called again and
the changes are applied on top. This has a few consequences:

- Factories are called with no arguments, so every parameter must be optional.
- A factory should build the same thing every time. Roll random values after creating the actor,
  not inside the factory.
- If you change a factory, actors in old saves pick up the change for anything they hadn't
  modified. Removing or renaming a factory breaks saves that use it.
- The order of an entity's components isn't kept.

Entities built by hand are saved in full.

Keeping old saves working
-------------------------

If you rename a class, register the old name before loading:

.. code-block:: lua

   prism.Serializer.registerClassAlias("OldName", prism.components.NewName)

Saves record the version of the format they were written in, and loading one from a version prism
doesn't know raises an error.
