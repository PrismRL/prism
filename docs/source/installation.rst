Installation
============

Prism is based on version 12.0 of `LÖVE <https://love2d.org>`_, which
is in a stable but pre-release state.

Latest downloads:

- `Windows <https://nightly.link/love2d/love/workflows/main/main/love-windows-x64.zip>`_
- `Linux AppImage <https://nightly.link/love2d/love/workflows/main/main/love-linux-X64.AppImage.zip>`_
- `macOS <https://nightly.link/love2d/love/workflows/main/main/love-macos.zip>`_
- `Others <https://nightly.link/love2d/love/workflows/main/main>`_

.. note::

   Prism makes heavy use of Lua type annotations to improve autocomplete and catch typing errors,
   so we recommend installing the `Lua language server <https://luals.github.io/>`_ for your editor.

.. note::

   We've published a VS Code `extension <https://marketplace.visualstudio.com/items?itemName=prismrl.prismrl>`_
   for Prism that includes a few snippets for creating common objects.

Project template
----------------

It is highly recommended to use our project template to kick off games made with prism.
`Click here <https://github.com/new?template_name=prism-template&template_owner=PrismRL>`_ 
to start a new GitHub repository, or you can download it directly. Use the following 
command to clone it locally, replacing the URL if you created a new repository:

.. code:: sh

   git clone --recursive --depth 1 https://github.com/PrismRL/prism-template.git

The following command will initialize the submodule if ``--recursive`` was left out:

.. code:: sh

    git submodule update --init --recursive

You can start the game by running ``love .`` in the terminal from the root directory,
or dragging the root folder onto the LÖVE executable.

Upon launching, you should see an ``@`` symbol on the screen. You can
move this character using the following default keys:

* ``WASD`` for movement
* ``QEZC`` for diagonal movement

Without the template
--------------------

Simply clone prism itself into your project:

.. code-block:: sh

   git clone https://github.com/PrismRL/prism.git

Then ``require`` prism:

.. code-block:: lua

   -- prism uses globals, sorry!
   require "path.to.prism"
