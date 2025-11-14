prism.registerTarget("InventoryTarget", function(...)
   return prism.Target(...):outsideLevel():related(prism.relations.InventoryRelation)
end)
