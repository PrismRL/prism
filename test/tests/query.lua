local lester = require("test.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
prism.register(prism.Component:extend("ComponentA"))
prism.register(prism.Component:extend("ComponentB"))
prism.register(prism.Component:extend("ComponentC"))

describe("query", function()
   it("without excludes actors containing excluded components", function()
      local actorStorage = prism.ActorStorage()
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentB(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentB(),
      }))
      local q = actorStorage:query():without(prism.components.ComponentB)
      expect.equal(#q:gather(), 1)
   end)
   it("without excludes actors containing excluded components regardless of with", function()
      local actorStorage = prism.ActorStorage()
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentB(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
      }))
      local q =
         actorStorage:query():without(prism.components.ComponentB):with(prism.components.ComponentC)
      expect.equal(#q:gather(), 1)
   end)
   it("without supports multiple params", function()
      local actorStorage = prism.ActorStorage()
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentB(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
      }))
      local q =
         actorStorage:query():without(prism.components.ComponentB, prism.components.ComponentC)
      expect.equal(#q:gather(), 1)
   end)
   it("multiple without calls chain properly", function()
      local actorStorage = prism.ActorStorage()
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentB(),
         prism.components.ComponentC(),
      }))
      actorStorage:addActor(prism.Actor.fromComponents({
         prism.components.ComponentA(),
      }))
      local q = actorStorage
         :query()
         :without(prism.components.ComponentB)
         :without(prism.components.ComponentC)
      expect.equal(#q:gather(), 1)
   end)
end)
