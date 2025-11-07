local path = ...
local basePath = path:match("^(.*)%.") or ""

prism.condition = {}
--- @module "extra.condition.condition"
prism.condition.Condition = require(basePath .. ".condition")
--- @class ConditionModifier : Object
prism.condition.ConditionModifier = prism.Object:extend "ConditionModifier"

prism.registerRegistry("conditions", prism.condition.Condition)
prism.registerRegistry("modifiers", prism.condition.ConditionModifier)
