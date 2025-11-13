Inventory module
================

The inventory module includes components and actions to implement an inventory system, as well as an
extended :lua:class:`Target` for validating items.

Load it with the following:

.. code-block:: lua

   prism.loadModule("prism/extra/inventory")

.. toctree::
   :caption: Components
   :glob:
   :maxdepth: 1

   components/*

.. toctree::
   :caption: Actions
   :glob:
   :maxdepth: 1

   actions/*

.. toctree::
   :caption: Relations
   :glob:
   :maxdepth: 1

   relations/*

**Targets**

- .. lua:data:: prism.targets.InventoryTarget: Target

     A helper target equivalent to the following:

     .. code-block:: lua

        prism.Target(...)
           :outsideLevel()
           :related(prism.relations.InventoryRelation)
