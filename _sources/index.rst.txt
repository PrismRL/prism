..
   Prism documentation master file, created by
   sphinx-quickstart on Sun Apr  6 16:41:35 2025.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Prism
=====

A comprehensive traditional roguelike engine, built on top of `LÖVE <https://love2d.org/>`_.

Features
--------

- **Geometer**: a built-in live editor for testing, prefab creation, and level generation
  debugging/visualization.
- **Collision**: An easy way to define how movement through the level works.
- **Multi-tile actors**: No longer does a dragon need to inhabit just one tile!
- **Animations**: Liven up the world with a flexible animation system.
- **Input handling**: Easily handle input of all kinds, including textual inputs (like ``>``) or
  combinations.
- **Built-in modules**: A suite of "extra" modules for common features like equipment, inventory,
  status effects, lighting, etc. that you can drop in or use as a base for custom implementations

Getting started
---------------

Check out :doc:`the tutorial <making-a-roguelike/part1>` for a guided walk-through of creating a
game, or just :doc:`install prism <installation>` and start hacking away.

"Traditional" roguelike?
------------------------

Prism is geared towards classic roguelike games like `NetHack <https://www.nethack.org/>`_ or
`Brogue <https://sites.google.com/site/broguegame/>`_, turn-based games set in randomly generated
grid levels. Other turn-based tactics games might also be a good fit.

Community
---------

Our discord can be found `here <https://discord.gg/9YpsH4hYVF>`_.

Demo
----

Below is the template project. Try pressing ``~`` to enable Geometer, the live editor!

.. raw:: html

   <button style="margin-bottom: var(--global-space)" onclick="document.getElementById('demo-app').contentWindow.applicationLoad();" class="btn btn-default">
      Launch
   </button>
   <iframe
      style="display: block;"
      frameborder="0"
      width="700"
      height="516"
      scrolling="no"
      src="_static/demo/index.html"
      title="The prism demo project"
      id="demo-app"
   >
   </iframe>

.. toctree::
   :hidden:

   installation
   architecture-primer
   conventions
   gallery
   releases

.. toctree::
   :caption: How-tos
   :glob:
   :hidden:

   how-tos/object-registration
   how-tos/query
   how-tos/*

.. toctree::
   :caption: Making a roguelike
   :hidden:

   making-a-roguelike/part1
   making-a-roguelike/part2
   making-a-roguelike/part3
   making-a-roguelike/part4
   making-a-roguelike/part5
   making-a-roguelike/part6
   making-a-roguelike/part7
   making-a-roguelike/part8
   making-a-roguelike/part9
   making-a-roguelike/part10
   making-a-roguelike/part11
   making-a-roguelike/part12
   making-a-roguelike/part13
   making-a-roguelike/part14
   making-a-roguelike/part15
   making-a-roguelike/part16

.. toctree::
   :caption: Explainers
   :hidden:
   :glob:

   explainers/*

.. toctree::
   :caption: Reference
   :hidden:

   reference/prism/index
   reference/spectrum/index
   reference/extra/index
   reference/geometer/index
