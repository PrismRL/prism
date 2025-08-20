-- RNG Class.
-- A modification of a Lua port of Johannes Baagøe's Alea in ROTLove. I forked this
-- from ROTLove mostly because I only needed a few things from it, and for consistency
-- in class library and documentation.
-- From http://baagoe.com/en/RandomMusings/javascript/
-- Johannes Baagøe <baagoe@baagoe.com>, 2010
-- Mirrored at: https://github.com/nquinlan/better-random-numbers-for-javascript-mirror

--- A random number generator using the Mersenne Twister algorithm.
--- @class RNG : Object
--- @overload fun(seed: any): RNG -- Seed must implement tostring!
local RNG = prism.Object:extend("RNG")

local function createMash()
   local n = 0xefc8249d
   --- @param data string
   local function mash(data)
      data = tostring(data)

      for i = 1, #data do
         n = n + data:byte(i)
         local hash = 0.02519603282416938 * n
         n = math.floor(hash)
         hash = hash - n
         hash = hash * n
         n = math.floor(hash)
         hash = hash - n
         n = n + hash * 0x100000000 -- 2^32
      end
      return math.floor(n) * 2.3283064365386963e-10 -- 2^-32
   end

   return mash
end

--- Initializes a new RNG instance.
--- @param seed any The seed for the RNG.
function RNG:__new(seed)
   assert(seed, "A seed must be provided to instantiate an RNG!")
   assert(tostring(seed), "Seed must be a string or implement __tostring!")

   self.state0 = 0
   self.state1 = 0
   self.state2 = 0
   self.carrier = 1
   self:setSeed(seed)
end

--- Gets the current seed.
--- @return any seed The current seed.
function RNG:getSeed()
   return self.seed
end

--- Sets the seed for the RNG.
--- @param seed string The seed to set (optional).
function RNG:setSeed(seed)
   self.carrier = 1
   self.seed = seed

   local mash = createMash()
   self.state0 = mash(" ")
   self.state1 = mash(" ")
   self.state2 = mash(" ")

   self.state0 = self.state0 - mash(self.seed)
   if self.state0 < 0 then self.state0 = self.state0 + 1 end
   self.state1 = self.state1 - mash(self.seed)
   if self.state1 < 0 then self.state1 = self.state1 + 1 end
   self.state2 = self.state2 - mash(self.seed)
   if self.state2 < 0 then self.state2 = self.state2 + 1 end
end

--- Gets a uniform random number between 0 and 1.
--- @return number uniform A uniform random number.
function RNG:getUniform()
   local t = 2091639 * self.state0 + self.carrier * 2.3283064365386963e-10 -- 2^-32
   self.state0 = self.state1
   self.state1 = self.state2
   self.carrier = math.floor(t)
   self.state2 = t - self.carrier
   return self.state2
end

--- Gets a uniform random integer between lowerBound and upperBound.
--- @param lowerBound number The lower bound.
--- @param upperBound number The upper bound.
--- @return number uniformInteger A uniform random integer.
function RNG:getUniformInt(lowerBound, upperBound)
   local max = math.max(lowerBound, upperBound)
   local min = math.min(lowerBound, upperBound)
   return math.floor(self:getUniform() * (max - min + 1)) + min
end

--- Gets a normally distributed random number with the given mean and standard deviation.
--- @param mean number The mean (optional, default is 0).
--- @param stddev number The standard deviation (optional, default is 1).
--- @return number normal A normally distributed random number.
function RNG:getNormal(mean, stddev)
   local u, v, r
   repeat
      u = 2 * self:getUniform() - 1
      v = 2 * self:getUniform() - 1
      r = u * u + v * v
   until r > 1 or r == 0

   local gauss = u * math.sqrt(-2 * math.log(r) / r)
   return (mean or 0) + gauss * (stddev or 1)
end

--- Gets a random percentage between 1 and 100.
--- @return number percentage A random percentage.
function RNG:getPercentage()
   return 1 + math.floor(self:getUniform() * 100)
end

--- Gets a random value from a weighted table.
--- @generic K, V
--- @param tbl table<K, V> The weighted table.
--- @return V value The selected value.
function RNG:getWeightedValue(tbl)
   local totalWeight = 0
   for _, weight in pairs(tbl) do
      totalWeight = totalWeight + weight
   end
   local rand = self:getUniform() * totalWeight
   local cumulativeWeight = 0
   for value, weight in pairs(tbl) do
      cumulativeWeight = cumulativeWeight + weight
      if rand < cumulativeWeight then return value end
   end
   return nil
end

--- Gets the current state of the RNG.
--- @return table The current state.
function RNG:getState()
   return { self.state0, self.state1, self.state2, self.carrier, self.seed }
end

--- Sets the state of the RNG.
--- @param stateTable table The state to set.
function RNG:setState(stateTable)
   self.state0, self.state1, self.state2, self.carrier, self.seed =
      stateTable[1], stateTable[2], stateTable[3], stateTable[4], stateTable[5]
end

--- Clones the RNG.
--- @return RNG The cloned RNG.
function RNG:clone()
   local clone = RNG()
   clone:setState(self:getState())
   return clone
end

--- Gets a random number.
--- If nothing is passed, returns a real number between 0 and 1.
--- If only max is passed, returns an integer between 1 and max.
--- If max and min is passed, returns an integer between min and max.
--- @overload fun(min: integer, max: integer): integer
--- @overload fun(max: integer): integer
--- @overload fun(): number
function RNG:random(min, max)
   if not min then
      return self:getUniform()
   elseif not max then
      return self:getUniformInt(1, min)
   else
      return self:getUniformInt(min, max)
   end
end

RNG.randomseed = RNG.setSeed

return RNG
