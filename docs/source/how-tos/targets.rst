Targets
=======

The ``Target`` class defines **an object an action can act on**. It uses a builder pattern to
combine filters and checks. Targets validate parameters to actions at runtime allowing you to easily
and safely discriminate an any type to something more specific. They are designed such that you can
pass in any arbitrary Lua type into the Action's parameters without runtime errors.

This how-to is going to use a simple Health component as an example, this does not ship with the
engine but can be found in the tutorial.

Creating a basic target
-----------------------

To create a Target that requires certain components:

.. code-block:: lua

   local myTarget = prism.Target(prism.components.Health, prism.components.Opaque)

You can add additional required components with the ``:with(...)`` function:

.. code-block:: lua

   myTarget:with(prism.components.Collider, prism.components.Senses)

This ensures the target object **must** have the specified component(s).

Adding custom filters
---------------------

You can add custom logic with ``:filter()``. For example, to target only actors with less than half
health:

.. code-block:: lua

   myTarget:filter(function(level, owner, target)
      local health = target:get(prism.components.Health)
      return health and health.hp < (health.maxHP / 2)
   end)

Limiting targets to a range
---------------------------

Restrict targets to those within a certain distance (in tiles):

.. code-block:: lua

   myTarget:range(5)

This ensures the target is at most 5 tiles away from the actor performing the action.

Sensed targets
--------------

Require the target to be visible or otherwise sensed by the actor:

.. code-block:: lua

   myTarget:sensed()

This uses the actor’s ``Senses`` component.

Line of sight
-------------

Require an unobstructed path from the actor to the target:

.. code-block:: lua

   myTarget:los(collisionMask)

This checks tiles along a Bresenham line and fails if any cell blocks movement. For more info on
collision masks see the Collision how-to!

Checking target types
---------------------

Require the target to be an instance of a specific object class:

.. code-block:: lua

   myTarget:isPrototype(prism.Actor)

Or check the target’s Lua type:

.. code-block:: lua

   myTarget:isType("number")

Targeting outside the level
---------------------------

If your target is not part of the level (e.g. an inventory item):

.. code-block:: lua

   myTarget:outsideLevel()

By default, targets are required to exist in the level.

Making targets optional
-----------------------

.. code-block:: lua

   myTarget:optional()

This target will now validate even if it's nil.

An example complex target
-------------------------

Suppose we want a target that:

- Must be an Actor
- Must have the ``Health`` component
- Must be sensed
- Must be within 3 tiles
- Must be wounded (health < max)

.. code-block:: lua

   local woundedEnemyTarget = prism.Target:new(prism.components.Health)
      :isPrototype(prism.Actor)
      :sensed()
      :range(3)
      :filter(function(level, owner, target)
         local health = target:expect(prism.components.Health)
         return health and health.current < health.max
      end)

We can chain our builder functions together like so to accomplish this. This can then be specified
in an Action's ``targets`` table to discriminate targets.
