require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect
local Color4 = prism.Color4

describe("Color4", function()
   it("adds scaled colors with a fresh result or either input as output", function()
      for _, destination in ipairs { "new", "a", "b", "separate" } do
         local a, b = Color4(1, 2, 3, 4), Color4(4, 6, 8, 10)
         local out
         if destination == "a" then out = a end
         if destination == "b" then out = b end
         if destination == "separate" then out = Color4() end
         local result = a:addScaled(b, 0.5, out)
         expect.equal(result, Color4(3, 5, 7, 9))
         if out then assert(rawequal(result, out)) end
         if not rawequal(result, a) then expect.equal(a, Color4(1, 2, 3, 4)) end
         if not rawequal(result, b) then expect.equal(b, Color4(4, 6, 8, 10)) end
      end
   end)

   it("lerps with either input as output", function()
      for _, destination in ipairs { "a", "b" } do
         local a, b = Color4(1, 2, 3, 4), Color4(4, 6, 8, 10)
         local out = destination == "a" and a or b
         local result = a:lerp(b, 0.5, out)
         assert(rawequal(result, out))
         expect.equal(result, Color4(2.5, 4, 5.5, 7))
      end
   end)
end)
