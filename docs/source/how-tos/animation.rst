Animation
=========

:lua:class:`Display` supports playing :lua:class:`Animations <Animation>`.

Define an animation
-------------------

Animations can either be frame-based, or use a custom function. Here's a frame-based
animation:

.. grid:: 1 1 2 2
    :gutter: 0

    .. grid-item::
       :child-align: center
       :columns: 12 12 10 10

       .. code-block:: lua

          local on = { index = "!", color = prism.Color4.YELLOW }
          local off = { index = " ", color = prism.Color4.BLACK }
          spectrum.Animation({ on, off, on }, 0.2, "pauseAtEnd")

    .. grid-item::
       :child-align: center
       :columns: 12 12 2 2

       .. video:: ../_static/animation1.mp4
          :autoplay:
          :nocontrols:
          :loop:
          :muted:
          :align: right

``0.2`` is the amount of seconds to play each frame for. It could also be a table of
times, ``{ 0.2, 0.2, 0.2, 0.2 }``, or by ranges, ``{ ["1-2"] = 0.5, ["3-4"] = 0.25 }``.
The final parameter tells the animation what to do when it loops. This can either be a
function (which accepts the animation instance and the number of loops), or the string
name of a function on :lua:class:`Animation`.

Animations can be registered to the ``spectrum.animations`` registry:

.. code-block:: lua

    local on = { index = "!", color = prism.Color4.YELLOW }
    local off = { index = " ", color = prism.Color4.BLACK }
    spectrum.registerAnimation("Exclamation", function()
       return spectrum.Animation({ on, off, on }, 0.2, "pauseAtEnd")
    end)

Individual frames can also be functions that accept a :lua:class:`Display`, ``x``, and
``y``:

.. grid:: 1 1 2 2
    :gutter: 0

    .. grid-item::
       :child-align: center
       :columns: 12 12 9 9

       .. code-block:: lua

          local on = { index = "!", color = prism.Color4.YELLOW }
          local off = { index = " ", color = prism.Color4.BLACK }
          local function putAround(display, x, y)
             display:putSprite(x + 1, y, "!", on)
             display:putSprite(x - 1, y, "!", on)
             display:putSprite(x, y + 1, "!", on)
             display:putSprite(x, y - 1, "!", on)
          end
          spectrum.registerAnimation("Exclamation", function()
             return spectrum.Animation(
                { putAround, off, putAround },
                0.2,
                "pauseAtEnd"
             )
          end)

    .. grid-item::
       :child-align: center
       :columns: 12 12 3 3

       .. video:: ../_static/animation2.mp4
          :autoplay:
          :nocontrols:
          :loop:
          :muted:
          :align: right

For more complex animations, a function that accepts the elapsed time and the display
can be used. Other parameters passed to the constructor are ignored.

.. code-block:: lua

    spectrum.registerAnimation("Projectile", function(owner, targetPosition)
       --- @cast owner Actor
       --- @cast targetPosition Vector2
       local x, y = owner:expectPosition():decompose()
       local line = prism.Bresenham(x, y, targetPosition.x, targetPosition.y)

       return spectrum.Animation(function(t, display)
          local index = math.floor(t / 0.05) + 1
          display:put(line[index][1], line[index][2], "*", prism.Color4.ORANGE)

          if index == #line then return true end

          return false
       end)
    end)

.. video:: ../_static/animation3.mp4
    :autoplay:
    :nocontrols:
    :loop:
    :muted:
    :align: right

.. tip::

    Make sure to return ``true`` when the animation is over.

Play an animation
-----------------

To play an animation, :lua:func:`Level.yield` an :lua:class:`AnimationMessage`. There
are a few options here. You can play an animation at an actor's position:

.. grid:: 1 1 2 2
    :gutter: 0

    .. grid-item::
       :child-align: center
       :columns: 12 12 10 10

       .. code-block:: lua

          level:yield(prism.messages.Animation {
             animation = spectrum.animations.Exclamation(),
             actor = kobold
          })

    .. grid-item::
       :child-align: center
       :columns: 12 12 2 2

       .. video:: ../_static/animation4.mp4
          :autoplay:
          :nocontrols:
          :loop:
          :muted:
          :align: right

Or at a position:

.. code-block:: lua

    level:yield(prism.messages.Animation {
       animation = spectrum.animations.Exclamation(),
       x = position.x,
       y = position.y
    })

If an ``actor`` is passed, the ``x`` and ``y`` are relative to the actor's position:

.. grid:: 1 1 2 2
    :gutter: 0

    .. grid-item::
       :child-align: center
       :columns: 12 12 10 10

       .. code-block:: lua

          level:yield(prism.messages.Animation {
             animation = spectrum.animations.Exclamation(),
             actor = target,
             y = -1
          })

    .. grid-item::
       :child-align: center
       :columns: 12 12 2 2

       .. video:: ../_static/animation6.mp4
          :autoplay:
          :nocontrols:
          :loop:
          :muted:
          :align: right

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

Drawing animations
------------------

:lua:class:`Display` won't draw animations by default. Call
:lua:func:`Display.putAnimations` when you want them to be drawn.
