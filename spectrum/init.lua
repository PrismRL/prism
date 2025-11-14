if not prism then error("Spectrum depends on prism!") end

spectrum = {}
--- @type string
spectrum.path = ...

function spectrum.require(p)
   return require(table.concat({ spectrum.path, p }, "."))
end

--- @module "spectrum.camera"
spectrum.Camera = spectrum.require "camera"

--- @module "spectrum.spriteatlas"
spectrum.SpriteAtlas = spectrum.require "spriteatlas"

--- @module "spectrum.display"
spectrum.Display = spectrum.require "display"

--- @module "spectrum.input"
spectrum.Input = spectrum.require "input"

--- @module "spectrum.animation"
spectrum.Animation = spectrum.require "animation"

--- @module "spectrum.gamestate"
spectrum.GameState = spectrum.require "gamestate"

--- @module "spectrum.statemanager"
spectrum.StateManager = spectrum.require "statemanager"

prism.registerRegistry("animations", spectrum.Animation, true, "spectrum")
prism.registerRegistry("gamestates", spectrum.GameState, false, "spectrum")
