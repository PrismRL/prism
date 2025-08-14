Queries
=======

Most roguelikes involve systems where you need to efficiently find actors or entities with certain
components—such as all enemies, or everyone at a specific location. Prism provides a built-in query
system to make this easy and efficient.

Basic usage
-----------

To start a query, call :lua:func:`IQueryable.query` with the component types you want to require.
This interface is implemented by :lua:class:`Level`, :lua:class:`MapBuilder`, and
:lua:class:`ActorStorage`.

.. code-block:: lua

   local query = level:query(prism.components.Controller, prism.components.Collider)

This creates a :lua:class:`Query` object. You can add more required components later with
:lua:func:`Query.with`.

.. code-block:: lua

   query:with(prism.components.Senses)

You can also restrict the query to a single tile with :lua:func:`Query.at`.

.. code-block:: lua

   query:at(10, 5)

Iterating over results
----------------------

Use :lua:func:`Query.iter` to get an iterator over matching actors and their components:

.. code-block:: lua

   for actor, controller, collider, senses in query:iter() do
       -- do stuff
   end

Alternatively, use :lua:func:`Query.each` to apply a function to each match:

.. code-block:: lua

   query:each(function(actor, controller, collider, senses)
       -- do stuff
   end)

Gathering results
-----------------

To gather results into a list, use :lua:func:`Query.gather`:

.. code-block:: lua

   local results = query:gather()

   for _, actor in ipairs(results) do
       -- Do something with them
   end

Getting a single result
-----------------------

Use :lua:func:`Query:first()` to get the first match:

.. code-block:: lua

   local actor, playerController = level:query(prism.components.PlayerController):first()

Good for singleton components like if your game has only one actor with a PlayerController. First
calls iter behind the scenes and discards the iterator after the first result.

Putting it together
-------------------

Here's an example of it all put together:

.. code-block:: lua

   local query = level:query(prism.components.Controller, prism.components.Senses)
       :with(prism.components.Senses)
       :at(x, y)

   for actor, controller, collider, senses in query:iter() do
       -- do stuff
   end

.. note::

   Query performance is optimized internally based on your filters. Position-based queries and
   single-component queries are particularly fast.
