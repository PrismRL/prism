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

    <canvas id="loadingCanvas" oncontextmenu="event.preventDefault()" width="800" height="600"></canvas>
    <canvas id="canvas" oncontextmenu="event.preventDefault()"></canvas>

   <script type='text/javascript'>
     function goFullScreen(){
           var canvas = document.getElementById("canvas");
           if(canvas.requestFullScreen)
               canvas.requestFullScreen();
           else if(canvas.webkitRequestFullScreen)
               canvas.webkitRequestFullScreen();
           else if(canvas.mozRequestFullScreen)
               canvas.mozRequestFullScreen();
     }
     function FullScreenHook(){
       var canvas = document.getElementById("canvas");
       canvas.width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
       canvas.height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
     }
     var loadingContext = document.getElementById('loadingCanvas').getContext('2d');
     function drawLoadingText(text) {
       var canvas = loadingContext.canvas;

       loadingContext.fillStyle = "rgb(142, 195, 227)";
       loadingContext.fillRect(0, 0, canvas.scrollWidth, canvas.scrollHeight);

       loadingContext.font = '2em arial';
       loadingContext.textAlign = 'center'
       loadingContext.fillStyle = "rgb( 11, 86, 117 )";
       loadingContext.fillText(text, canvas.scrollWidth / 2, canvas.scrollHeight / 2);

       loadingContext.fillText("Powered By Emscripten.", canvas.scrollWidth / 2, canvas.scrollHeight / 4);
       loadingContext.fillText("Powered By LÖVE.", canvas.scrollWidth / 2, canvas.scrollHeight / 4 * 3);
     }

     window.onload = function () { window.focus(); };
     window.onclick = function () { window.focus(); };

     window.addEventListener("keydown", function(e) {
       // space and arrow keys
       if([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
         e.preventDefault();
       }
     }, false);

     var Module = {
       arguments: ["./game.love"],
       INITIAL_MEMORY: 20000000,
       printErr: console.error.bind(console),
       canvas: (function() {
         var canvas = document.getElementById('canvas');

         // As a default initial behavior, pop up an alert when webgl context is lost. To make your
         // application robust, you may want to override this behavior before shipping!
         // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
         canvas.addEventListener("webglcontextlost", function(e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);

         return canvas;
       })(),
       setStatus: function(text) {
         if (text) {
           drawLoadingText(text);
         } else if (Module.remainingDependencies === 0) {
           document.getElementById('loadingCanvas').style.display = 'none';
           document.getElementById('canvas').style.visibility = 'visible';
         }
       },
       totalDependencies: 0,
       remainingDependencies: 0,
       monitorRunDependencies: function(left) {
         this.remainingDependencies = left;
         this.totalDependencies = Math.max(this.totalDependencies, left);
         Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
       }
     };
     Module.setStatus('Downloading...');
     window.onerror = function(event) {
       // TODO: do not warn on ok events like simulating an infinite loop or exitStatus
       Module.setStatus('Exception thrown, see JavaScript console');
       Module.setStatus = function(text) {
         if (text) Module.printErr('[post-exception status] ' + text);
       };
     };

     var applicationLoad = function(e) {
       Love(Module);
     }
   </script>
   <script type="text/javascript" src="_static/demo/game.js"></script>
   <script async type="text/javascript" src="_static/demo/love.js" onload="applicationLoad(this)"></script>

.. toctree::
   :hidden:

   installation
   architecture-primer
   conventions
   gallery
   roadmap

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
