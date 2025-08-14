Conventions
===========

These are some tips and standards to follow when writing a game with Prism.

Naming
------

Prism follows PascalCase for classes and camelCase for most other things.

Actors, components, and cells should just be nouns, e.g.:

- ``KoboldArcher`` or ``HealthPotion``
- ``Health`` or ``Collider``
- ``Wall`` or ``Lava``

Actions should be verbs:

- ``Attack`` or ``Move``

Everything else should have its type associated:

- ``DeathSystem``
- ``SpellTarget``

Modifying level state
---------------------

:lua:func:`Action.perform` should be the primary way to modify level state, i.e. actors and cells.
This makes it easier to keep track of how the state is changing.
