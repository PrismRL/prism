Conditions module
=================

The conditions module adds a single component, :lua:class:`ConditionHolder`, a generic holder for
modifications or status effects on an :lua:class:`Entity`, as well as the :lua:class:`Condition` and
:lua:class:`ConditionModifier` types, which can be accessed via ``prism.condition.Condition``.

Load it with the following:

.. code-block:: lua

   prism.loadModule("prism/extra/condition")

**Registries**

- .. lua:data:: prism.conditions: table<string, Condition>

     The condition registry.
- .. lua:data:: prism.modifiers: table<string, ConditionModifier>

     The condition modifier registry.

.. toctree::
   :caption: Core
   :glob:
   :maxdepth: 1

   *

.. toctree::
   :caption: Components
   :glob:
   :maxdepth: 1

   components/*
