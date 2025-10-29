--- @meta

--- Animations registry.
spectrum.animations = {}

--- Registers an animation in the animations registry.
--- @param name string
--- @param factory AnimationFactory
function spectrum.registerAnimation(name, factory) end

---
---@class GameState
local GameState = nil

---Called when the active audio device is disconnected (e.g. physically unplugging headphones).
---All audio are stopped and loses their playback position when this callback is called.
---
---[Open in Browser](https://love2d.org/wiki/love.audiodisconnected)
---
---@param sources (love.audio.Source)[] List of sources that was playing.
---@return boolean reconnected Is audio re-connection attempt has been done?
GameState.audiodisconnected = function(self, sources) end

---Callback function triggered when a directory is dragged and dropped onto the window.
---
---Paths passed into this callback are able to be used with love.filesystem.mount, which is the only way to get read access via love.filesystem to the dropped directory. love.filesystem.mount does not generally accept other full platform-dependent directory paths that haven't been dragged and dropped onto the window.
---
---[Open in Browser](https://love2d.org/wiki/love.directorydropped)
---
---@param path string The full platform-dependent path to the directory. It can be used as an argument to love.filesystem.mount, in order to gain read access to the directory with love.filesystem.
---@param x number
---@param y number
GameState.directorydropped = function(self, path, x, y) end

---Called when the device display orientation changed, for example, user rotated their phone 180 degrees.
---
---[Open in Browser](https://love2d.org/wiki/love.displayrotated)
---
---@param index number The index of the display that changed orientation.
---@param orientation love.window.DisplayOrientation The new orientation.
GameState.displayrotated = function(self, index, orientation) end

---Callback function used to draw on the screen every frame.
---
---[Open in Browser](https://love2d.org/wiki/love.draw)
---
GameState.draw = function(self) end

---
---[Open in Browser](https://love2d.org/wiki/love.dropbegan)
---
GameState.dropbegan = function(self) end

---
---[Open in Browser](https://love2d.org/wiki/love.dropcompleted)
---
---@param x number
---@param y number
GameState.dropcompleted = function(self, x, y) end

---
---[Open in Browser](https://love2d.org/wiki/love.dropmoved)
---
---@param x number
---@param y number
GameState.dropmoved = function(self, x, y) end

---The error handler, used to display error messages.
---
---[Open in Browser](https://love2d.org/wiki/love.errorhandler)
---
---@param msg string The error message.
---@return fun():(any) mainLoop Function which handles one frame, including events and rendering, when called. If this is nil then LÖVE exits immediately.
GameState.errorhandler = function(self, msg) end

---
---[Open in Browser](https://love2d.org/wiki/love.exposesd)
---
GameState.exposesd = function(self) end

---Callback function triggered when a file is dragged and dropped onto the window.
---
---[Open in Browser](https://love2d.org/wiki/love.filedropped)
---
---@param file love.filesystem.File The unopened File object representing the file that was dropped.
---@param x number
---@param y number
GameState.filedropped = function(self, file, x, y) end

---Callback function triggered when window receives or loses focus.
---
---[Open in Browser](https://love2d.org/wiki/love.focus)
---
---@param focus boolean True if the window gains focus, false if it loses focus.
GameState.focus = function(self, self, focus) end

---Called when a Joystick's virtual gamepad axis is moved.
---
---[Open in Browser](https://love2d.org/wiki/love.gamepadaxis)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param axis love.joystick.GamepadAxis The virtual gamepad axis.
---@param value number The new axis value.
GameState.gamepadaxis = function(self, joystick, axis, value) end

---Called when a Joystick's virtual gamepad button is pressed.
---
---[Open in Browser](https://love2d.org/wiki/love.gamepadpressed)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param button love.joystick.GamepadButton The virtual gamepad button.
GameState.gamepadpressed = function(self, joystick, button) end

---Called when a Joystick's virtual gamepad button is released.
---
---[Open in Browser](https://love2d.org/wiki/love.gamepadreleased)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param button love.joystick.GamepadButton The virtual gamepad button.
GameState.gamepadreleased = function(self, joystick, button) end

---Called when a Joystick is connected.
---
---This callback is also triggered after love.load for every Joystick which was already connected when the game started up.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickadded)
---
---@param joystick love.joystick.Joystick The newly connected Joystick object.
GameState.joystickadded = function(self, joystick) end

---Called when a joystick axis moves.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickaxis)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param axis number The axis number.
---@param value number The new axis value.
GameState.joystickaxis = function(self, joystick, axis, value) end

---Called when a joystick hat direction changes.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickhat)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param hat number The hat number.
---@param direction love.joystick.JoystickHat The new hat direction.
GameState.joystickhat = function(self, joystick, hat, direction) end

---Called when a joystick button is pressed.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickpressed)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param button number The button number.
GameState.joystickpressed = function(self, joystick, button) end

---Called when a joystick button is released.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickreleased)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param button number The button number.
GameState.joystickreleased = function(self, joystick, button) end

---Called when a Joystick is disconnected.
---
---[Open in Browser](https://love2d.org/wiki/love.joystickremoved)
---
---@param joystick love.joystick.Joystick The now-disconnected Joystick object.
GameState.joystickremoved = function(self, joystick) end

---Called when a Joystick's sensor is updated with new values.
---Only Joystick sensors enabled with Joystick:setSensorEnabled will trigger this event.
---
---[Open in Browser](https://love2d.org/wiki/love.joysticksensorupdated)
---
---@param joystick love.joystick.Joystick The joystick object.
---@param sensorType love.sensor.SensorType The type of sensor.
---@param x number The new sensor 1st value.
---@param y number The new sensor 2nd value.
---@param z number The new sensor 3rd value.
GameState.joysticksensorupdated = function(self, joystick, sensorType, x, y, z) end

---Callback function triggered when a key is pressed.
---
---Scancodes are keyboard layout-independent, so the scancode 'w' will be generated if the key in the same place as the 'w' key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.
---
---Key repeat needs to be enabled with love.keyboard.setKeyRepeat for repeat keypress events to be received. This does not affect love.textinput.
---
---[Open in Browser](https://love2d.org/wiki/love.keypressed)
---
---@param key love.keyboard.KeyConstant Character of the pressed key.
---@param scancode love.keyboard.Scancode The scancode representing the pressed key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
GameState.keypressed = function(self, key, scancode, isrepeat) end

---Callback function triggered when a keyboard key is released.
---
---Scancodes are keyboard layout-independent, so the scancode 'w' will be used if the key in the same place as the 'w' key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.
---
---[Open in Browser](https://love2d.org/wiki/love.keyreleased)
---
---@param key love.keyboard.KeyConstant Character of the released key.
---@param scancode love.keyboard.Scancode The scancode representing the released key.
GameState.keyreleased = function(self, key, scancode) end

---Callback function triggered when the user's system locale preferences have changed.
---
---[Open in Browser](https://love2d.org/wiki/love.localechanged)
---
GameState.localechanged = function(self) end

---Callback function triggered when the system is running out of memory on mobile devices.
---
---Mobile operating systems may forcefully kill the game if it uses too much memory, so any non-critical resource should be removed if possible (by setting all variables referencing the resources to '''nil'''), when this event is triggered. Sounds and images in particular tend to use the most memory.
---
---[Open in Browser](https://love2d.org/wiki/love.lowmemory)
---
GameState.lowmemory = function(self) end

---Callback function triggered when window receives or loses mouse focus.
---
---[Open in Browser](https://love2d.org/wiki/love.mousefocus)
---
---@param focus boolean Whether the window has mouse focus or not.
GameState.mousefocus = function(self, focus) end

---Callback function triggered when the mouse is moved.
---
---If Relative Mode is enabled for the mouse, the '''dx''' and '''dy''' arguments of this callback will update but '''x''' and '''y''' are not guaranteed to.
---
---[Open in Browser](https://love2d.org/wiki/love.mousemoved)
---
---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
GameState.mousemoved = function(self, x, y, dx, dy, istouch) end

---Callback function triggered when a mouse button is pressed.
---
---Use love.wheelmoved to detect mouse wheel motion. It will not register as a button press in version 0.10.0 and newer.
---
---[Open in Browser](https://love2d.org/wiki/love.mousepressed)
---
---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks
GameState.mousepressed = function(self, x, y, button, istouch, presses) end

---Callback function triggered when a mouse button is released.
---
---[Open in Browser](https://love2d.org/wiki/love.mousereleased)
---
---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was released. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button release originated from a touchscreen touch-release.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks
GameState.mousereleased = function(self, x, y, button, istouch, presses) end

---
---[Open in Browser](https://love2d.org/wiki/love.occluded)
---
GameState.occluded = function(self) end

---Callback function triggered when the game is closed.
---
---[Open in Browser](https://love2d.org/wiki/love.quit)
---
---@return boolean r Abort quitting. If true, do not close the game.
GameState.quit = function(self) end

---Called when the window is resized, for example if the user resizes the window, or if love.window.setMode is called with an unsupported width or height in fullscreen and the window chooses the closest appropriate size.
---
---Calls to love.window.setMode will '''only''' trigger this event if the width or height of the window after the call doesn't match the requested width and height. This can happen if a fullscreen mode is requested which doesn't match any supported mode, or if the fullscreen type is 'desktop' and the requested width or height don't match the desktop resolution.
---
---Since 11.0, this function returns width and height in DPI-scaled units rather than pixels.
---
---[Open in Browser](https://love2d.org/wiki/love.resize)
---
---@param w number The new width.
---@param h number The new height.
GameState.resize = function(self, w, h) end

---The main function, containing the main loop. A sensible default is used when left out.
---
---[Open in Browser](https://love2d.org/wiki/love.run)
---
---@return fun():(any) mainLoop Function which handlers one frame, including events and rendering when called.
GameState.run = function(self) end

---Called when the in-device sensor is updated with new values.
---Only sensors enabled with love.sensor.setEnabled will trigger this event.
---
---[Open in Browser](https://love2d.org/wiki/love.sensorupdated)
---
---@param sensorType love.sensor.SensorType The type of sensor.
---@param x number The new sensor 1st value.
---@param y number The new sensor 2nd value.
---@param z number The new sensor 3rd value.
GameState.sensorupdated = function(self, sensorType, x, y, z) end

---Called when the in-device sensor is updated with new values.
---Only sensors enabled with love.sensor.setEnabled will trigger this event.
---
---[Open in Browser](https://love2d.org/wiki/love.sensorupdated)
---
---@param sensorType love.sensor.SensorType The type of sensor.
---@param x number The new sensor 1st value.
---@param y number The new sensor 2nd value.
---@param z number The new sensor 3rd value.
GameState.sensorupdated = function(self, sensorType, x, y, z) end

---Called when the candidate text for an IME (Input Method Editor) has changed.
---
---The candidate text is not the final text that the user will eventually choose. Use love.textinput for that.
---
---[Open in Browser](https://love2d.org/wiki/love.textedited)
---
---@param text string The UTF-8 encoded unicode candidate text.
---@param start number The start cursor of the selected candidate text.
---@param length number The length of the selected candidate text. May be 0.
GameState.textedited = function(self, text, start, length) end

---Called when text has been entered by the user. For example if shift-2 is pressed on an American keyboard layout, the text '@' will be generated.
---
---Although Lua strings can store UTF-8 encoded unicode text just fine, many functions in Lua's string library will not treat the text as you might expect. For example, #text (and string.len(text)) will give the number of ''bytes'' in the string, rather than the number of unicode characters. The Lua wiki and a presentation by one of Lua's creators give more in-depth explanations, with some tips.
---
---The utf8 library can be used to operate on UTF-8 encoded unicode text (such as the text argument given in this function.)
---
---On Android and iOS, textinput is disabled by default; call love.keyboard.setTextInput to enable it.
---
---[Open in Browser](https://love2d.org/wiki/love.textinput)
---
---@param text string The UTF-8 encoded unicode text.
GameState.textinput = function(self, text) end

---Callback function triggered when a Thread encounters an error.
---
---[Open in Browser](https://love2d.org/wiki/love.threaderror)
---
---@param thread love.thread.Thread The thread which produced the error.
---@param errorstr string The error message.
GameState.threaderror = function(self, thread, errorstr) end

---Callback function triggered when a touch press moves inside the touch screen.
---
---The identifier is only guaranteed to be unique for the specific touch press until love.touchreleased is called with that identifier, at which point it may be reused for new touch presses.
---
---The unofficial Android and iOS ports of LÖVE 0.9.2 reported touch positions as normalized values in the range of 1, whereas this API reports positions in pixels.
---
---[Open in Browser](https://love2d.org/wiki/love.touchmoved)
---
---@param id lightuserdata The identifier for the touch press.
---@param x number The x-axis position of the touch inside the window, in pixels.
---@param y number The y-axis position of the touch inside the window, in pixels.
---@param dx number The x-axis movement of the touch inside the window, in pixels.
---@param dy number The y-axis movement of the touch inside the window, in pixels.
---@param pressure number The amount of pressure being applied. Most touch screens aren't pressure sensitive, in which case the pressure will be 1.
GameState.touchmoved = function(self, id, x, y, dx, dy, pressure) end

---Callback function triggered when the touch screen is touched.
---
---The identifier is only guaranteed to be unique for the specific touch press until love.touchreleased is called with that identifier, at which point it may be reused for new touch presses.
---
---The unofficial Android and iOS ports of LÖVE 0.9.2 reported touch positions as normalized values in the range of 1, whereas this API reports positions in pixels.
---
---[Open in Browser](https://love2d.org/wiki/love.touchpressed)
---
---@param id lightuserdata The identifier for the touch press.
---@param x number The x-axis position of the touch press inside the window, in pixels.
---@param y number The y-axis position of the touch press inside the window, in pixels.
---@param dx number The x-axis movement of the touch press inside the window, in pixels. This should always be zero.
---@param dy number The y-axis movement of the touch press inside the window, in pixels. This should always be zero.
---@param pressure number The amount of pressure being applied. Most touch screens aren't pressure sensitive, in which case the pressure will be 1.
GameState.touchpressed = function(self, id, x, y, dx, dy, pressure) end

---Callback function triggered when the touch screen stops being touched.
---
---The identifier is only guaranteed to be unique for the specific touch press until love.touchreleased is called with that identifier, at which point it may be reused for new touch presses.
---
---The unofficial Android and iOS ports of LÖVE 0.9.2 reported touch positions as normalized values in the range of 1, whereas this API reports positions in pixels.
---
---[Open in Browser](https://love2d.org/wiki/love.touchreleased)
---
---@param id lightuserdata The identifier for the touch press.
---@param x number The x-axis position of the touch inside the window, in pixels.
---@param y number The y-axis position of the touch inside the window, in pixels.
---@param dx number The x-axis movement of the touch inside the window, in pixels.
---@param dy number The y-axis movement of the touch inside the window, in pixels.
---@param pressure number The amount of pressure being applied. Most touch screens aren't pressure sensitive, in which case the pressure will be 1.
GameState.touchreleased = function(self, id, x, y, dx, dy, pressure) end

---Callback function used to update the state of the game every frame.
---
---[Open in Browser](https://love2d.org/wiki/love.update)
---
---@param dt number Time since the last update in seconds.
GameState.update = function(self, dt) end

---Callback function triggered when window is minimized/hidden or unminimized by the user.
---
---[Open in Browser](https://love2d.org/wiki/love.visible)
---
---@param visible boolean True if the window is visible, false if it isn't.
GameState.visible = function(self, visible) end

---Callback function triggered when the mouse wheel is moved.
---
---[Open in Browser](https://love2d.org/wiki/love.wheelmoved)
---
---@param x number Amount of horizontal mouse wheel movement. Positive values indicate movement to the right.
---@param y number Amount of vertical mouse wheel movement. Positive values indicate upward movement.
---@param dir string "flipped" or "standard"
GameState.wheelmoved = function(self, x, y, dir) end
