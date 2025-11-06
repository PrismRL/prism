local path = ...
-- Strip the last component of the path
local basePath = path:match("^(.*)%.") or ""

prism.inventory = {}
--- @module "extra.inventory.inventorytarget"
prism.inventory.InventoryTarget = require(basePath .. ".inventorytarget")

