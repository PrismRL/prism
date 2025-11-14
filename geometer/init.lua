if not spectrum then error("Geometer depends on spectrum!") end

geometer = {}

--- @type string
geometer.path = ...

--- @type string
geometer.assetPath = geometer.path:gsub("%.", "/")

function geometer.require(p)
   return require(table.concat({ geometer.path, p }, "."))
end

--- @module "geometer.modification"
geometer.Modification = geometer.require "modification"

--- @module "geometer.tool"
geometer.Tool = geometer.require "tool"

--- @module "geometer.editor"
geometer.Editor = geometer.require "editor"
