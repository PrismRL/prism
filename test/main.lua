require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

describe("prism", function()
   require "test.tests.vector2"
   require "test.tests.sparsearray"
   require "test.tests.sparsemap"
   require "test.tests.grid"
   require "test.tests.priorityqueue"
   require "test.tests.queue"
   require "test.tests.sparsemap"
   require "test.tests.bitmaskbuffer"
   require "test.tests.booleanbuffer"
   require "test.tests.cascadingbitmaskbuffer"
   require "test.tests.query"
   require "test.tests.serialization"

   describe("Component", function()
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

      it("give replaces a component of the same type", function()
         local actor = prism.Actor()
         local first, second = prism.components.Collider(), prism.components.Collider()
         actor:give(first)
         actor:give(second)
         expect.equal(#actor.components, 1)
         expect.truthy(actor:get(prism.components.Collider) == second)
         expect.falsy(first.owner)
      end)
   end)
end)
