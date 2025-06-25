local path = ...
-- Strip the last component of the path
local basePath = path:match("^(.*)%.") or ""

--- @module "Inventory.inventorytarget"
prism.InventoryTarget = require(basePath .. ".inventorytarget")