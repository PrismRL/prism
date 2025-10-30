local Inky = geometer.require "inky"
---@type ButtonInit
local Button = geometer.require "elements.button"

---@class FilePanelProps : Inky.Props
---@field scale Vector2
---@field name string
---@field overlay love.Texture
---@field open boolean
---@field editor Editor

---@class FilePanel : Inky.Element
---@field props FilePanelProps

---@param self FilePanel
---@param scene Inky.Scene
local function File(self, scene)
   self.props.name = self.props.name or ""
   self.props.open = self.props.open or false

   ---@param pointer Inky.Pointer
   local function close(pointer)
      self.props.open = false
      pointer:captureElement(self, false)
      scene:raise("closeFilePanel")
   end

   local function savedialog(result)
      if not result[1] then return end

      result = result[1]
      -- Open the file in write mode and write some content
      local file, err = io.open(result, "w")
      if file then
         local normalized = self.props.editor.attachable
         if normalized.clone then
            --- @cast normalized LevelBuilder
            normalized = normalized:clone()
            normalized:normalize()
         end

         local json = prism.json.encode(prism.Object.serialize(normalized))
         local compressed = love.data.compress("string", "lz4", json)

         ---@diagnostic disable-next-line
         file:write(compressed)
         file:close()
      else
         print("Failed to save file: " .. err)
      end
   end

   self:onPointer("press", function(_, pointer)
      if not pointer:doesOverlapElement(self) then close(pointer) end
   end)

   local image = love.graphics.newImage(geometer.assetPath .. "/assets/filebutton.png")
   local quad = love.graphics.newQuad(0, 0, image:getWidth(), image:getHeight(), image)
   local newButton = Button(scene)
   newButton.props.tileset = image
   newButton.props.hoveredQuad = quad
   newButton.props.onPress = function(pointer)
      self.props.editor:setAttachable(prism.LevelBuilder(prism.defaultCell))
      close(pointer)
   end

   local openButton = Button(scene)
   openButton.props.tileset = image
   openButton.props.hoveredQuad = quad
   openButton.props.onPress = function(pointer)
      ---@diagnostic disable-next-line
      love.window.showFileDialog("openfile", function(result)
         if not result[1] then return end

         result = result[1]                      -- Assuming success contains a list of selected files
         -- Open the file in read mode and read its content
         local file, err = io.open(result, "rb") -- Open in binary mode to handle compressed data
         if file then
            local compressed = file:read("*a")   -- Read the entire file content
            file:close()

            -- Decompress the content
            local ok, json = pcall(function()
               return love.data.decompress("string", "lz4", compressed)
            end)

            if ok and json then
               -- Deserialize the JSON content and apply it to the editor
               local data = prism.json.decode(json)

               local builder = prism.Object.deserialize(data)
               if builder:instanceOf(prism.LevelBuilder) then
                  builder.initialValue = prism.defaultCell
               end

               self.props.editor:setAttachable(builder)
               self.props.editor.filepath = result

               print("File loaded successfully from: " .. result)
            else
               print("Failed to decompress or parse file.")
            end
         else
            print("Failed to open file: " .. err)
         end
      end, {
         title = "Open Prefab",
      })

      close(pointer)
   end

   local saveButton = Button(scene)
   saveButton.props.tileset = image
   saveButton.props.hoveredQuad = quad
   saveButton.props.onPress = function(pointer)
      if not self.props.editor.filepath then
         if not self.props.editor.filepath then
            --- @diagnostic disable-next-line
            love.window.showFileDialog("savefile", savedialog, {
               title = "Save Prefab",
               directory = love.filesystem.getSourceBaseDirectory(),
            })
         else
            -- Open the file in write mode and write some content
            local file, err = io.open(self.props.editor.filepath, "w")
            if file then
               local json = prism.json.encode(prism.Object.serialize(self.props.editor.attachable))
               local compressed = love.data.compress("string", "lz4", json)

               ---@diagnostic disable-next-line
               file:write(compressed)
               file:close()
            else
               print("Failed to save file: " .. err)
            end
         end
      end
      close(pointer)
   end

   local saveAsButton = Button(scene)
   saveAsButton.props.tileset = image
   saveAsButton.props.hoveredQuad = quad
   saveAsButton.props.onPress = function(pointer)
      print(love.filesystem.getSourceBaseDirectory())
      ---@diagnostic disable-next-line
      love.window.showFileDialog("savefile", savedialog, {
         title = "Save Prefab",
         directory = love.filesystem.getSourceBaseDirectory(),
      })

      close(pointer)
   end

   local quitButton = Button(scene)
   quitButton.props.tileset = image
   quitButton.props.hoveredQuad = quad
   quitButton.props.onPress = function()
      love.event.quit()
   end

   local background = love.graphics.newImage(geometer.assetPath .. "/assets/file.png")
   local font = love.graphics.newFont(
      geometer.assetPath .. "/assets/FROGBLOCK-Polyducks.ttf",
      8 * (math.floor(self.props.scale.x) - 1)
   )
   local size = 8 * self.props.scale.x
   local pad = size / 4

   return function(_, x, y, w, h)
      local tileX, tileY = x / 8, y / 8
      love.graphics.draw(background, x, y)
      newButton:render(x + 8, y + 8, 80, 8)
      openButton:render(x + 8, y + 8 * 2, 80, 8)
      saveButton:render(x + 8, y + 8 * 3, 80, 8)
      saveAsButton:render(x + 8, y + 8 * 4, 80, 8)
      quitButton:render(x + 8, y + 8 * 6, 80, 8)

      local textX = (tileX + 1) * size

      love.graphics.push("all")
      love.graphics.setFont(font)
      love.graphics.setCanvas(self.props.overlay)
      love.graphics.scale(1, 1)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print("NEW", textX, (tileY + 1) * size + pad)
      love.graphics.print("OPEN", textX, (tileY + 2) * size + pad)
      love.graphics.print("SAVE", textX, (tileY + 3) * size + pad)
      love.graphics.print("SAVE AS", textX, (tileY + 4) * size + pad)
      love.graphics.print(self.props.name, textX, (tileY + 5) * size + pad)
      love.graphics.print("QUIT", textX, (tileY + 6) * size + pad)
      love.graphics.pop()
   end
end

---@alias FilePanelInit fun(scene: Inky.Scene): FilePanel
---@type FilePanelInit
local FileElement = Inky.defineElement(File)
return FileElement
