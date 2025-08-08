Animation
=========

:lua:class:`Display` supports playing animations.

Define an animation
-------------------

Animations can either be frame based, or use a custom function. Here's an example:

.. code-block:: lua

    local on = { index = "!", color = prism.Color4.WHITE }
    local off = { index = " ", color = prism.Color4.BLACK }
    spectrum.Animation({ on, off, on, off }, 0.2, "pauseAtEnd")

Animations can be registered to the ``spectrum.animations`` registry:

.. code-block:: lua

    local on = { index = "!", color = prism.Color4.WHITE }
    local off = { index = " ", color = prism.Color4.BLACK }
    spectrum.registerAnimation("Exclamation", function()
       return spectrum.Animation({ on, off, on, off }, 0.2, "pauseAtEnd")
    end)

Individual frames can also be functions that accept a :lua:class:`Display`, ``x``, and
``y``:

.. code-block:: lua

    local off = { index = " ", color = prism.Color4.BLACK }
    local function putAround(display, x, y)
       display:put(x + 1, y, "!", prism.Color4.WHITE, prism.Color4.BLACK)
       display:put(x - 1, y, "!", prism.Color4.WHITE, prism.Color4.BLACK)
       display:put(x, y + 1, "!", prism.Color4.WHITE, prism.Color4.BLACK)
       display:put(x, y - 1, "!", prism.Color4.WHITE, prism.Color4.BLACK)
    end
    spectrum.registerAnimation("Exclamation", function()
       return spectrum.Animation({ putAround, off, putAround, off }, 0.2, "pauseAtEnd")
    end)

For more complex animations, a function that accepts the elapsed time and the display
can be used:

.. code-block:: lua

    spectrum.registerAnimation("Projectile", function(owner, targetPosition)
       local x, y = owner:expectPosition():decompose()
       local line = prism.Bresenham(x, y, targetPosition.x, targetPosition.y)

       return spectrum.Animation(function(t, display)
          local index = math.floor(t / 0.5) + 1
          display:put(line[index][1], line[index][2], "*", prism.Color4.WHITE, prism.Color4.BLACK, 2)

          if index == #line then return true end

          return false
       end)
    end)

.. tip::

    Make sure to return ``true`` when the animation is over.

Play an animation
-----------------

To play an animation, :lua:func:`Level.yield` an :lua:class:`AnimationMessage`. There
are a few options here. You can play an animation at an actor's position:

.. code-block:: lua

    level:yield(prism.messages.Animation {
       animation = spectrum.animations.Exclamation(),
       actor = self.owner
    })

Or at a position:

.. code-block:: lua

    level:yield(prism.messages.Animation {
       animation = spectrum.animations.Exclamation(),
       x = position.x,
       y = position.y
    })

If an ``actor`` is passed, the ``x`` and ``y`` are relative to the actor's position:

.. code-block:: lua

    level:yield(prism.messages.Animation {
       animation = spectrum.animations.Exclamation(),
       actor = target,
       y = -1
    })

Animations can force the :lua:class:`LevelState` to wait for them to finish playing:

.. code-block:: lua

    level:yield(prism.messages.Animation {
       animation = spectrum.animations.Exclamation(),
       actor = target,
       y = -1,
       blocking = true
    })

Or they can be skippable by passing ``skippable = true``, though you will have to decide
when you want animations to be skipped by calling :lua:func:`Display.skipAnimations`,
e.g. on a key press or mouse click.
