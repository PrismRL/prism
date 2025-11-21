require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

describe("prism", function()
   describe("components", function()
      it("add component", function()
         local actor = prism.Actor()
         actor:give(prism.components.Collider())
         expect.truthy(actor:has(prism.components.Collider))
      end)

      it("remove component", function()
         local actor = prism.Actor()
         actor:give(prism.components.Collider())
         actor:remove(prism.components.Collider)
         expect.falsy(actor:has(prism.components.Collider))
      end)
   end)
end)
