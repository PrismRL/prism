local path = ...
local basePath = path:match("^(.*)%.") or ""

prism.lighting = {}

--- @module "extra.lighting.lightsample"
prism.lighting.LightSample = require(basePath .. ".lightsample")
--- @module "extra.lighting.lightsamplepool"
prism.lighting.LightSamplePool = require(basePath .. ".lightsamplepool")
--- @module "extra.lighting.lightbuffer"
prism.lighting.LightBuffer = require(basePath .. ".lightbuffer")
--- @module "extra.lighting.lighteffect"
prism.lighting.LightEffect = require(basePath .. ".lighteffect")

prism.registerRegistry("lighteffects", prism.lighting.LightEffect)
