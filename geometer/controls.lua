return spectrum.Input.Controls {
   controls = {
      undo = function()
         return not (
            (spectrum.Input.key.lctrl.down or spectrum.Input.key.rctrl.down)
            and spectrum.Input.key.z.pressed
         )
      end,
      redo = function()
         return not (
            (spectrum.Input.key.lctrl.down or spectrum.Input.key.rctrl.down)
            and spectrum.Input.key.y.pressed
         )
      end,
      copy = "c",
      paste = "v",
      fill = "f",
      pen = "n",
      delete = "e",
      rect = "r",
      ellipse = "o",
      line = "l",
      bucket = "b",
      select = "s",
   },
}
