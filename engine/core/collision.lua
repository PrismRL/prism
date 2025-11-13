--- Keeps track of different move types or "layers" in the game for use in collision detection.
--- @class Collision
local Collision = {}

--- @alias CollisionMask integer

--- Collision movetypes used for bitmasking. Each index represents a movetype/layer.
--- Each movetype represents a different collision category.
--- @type integer[]
Collision.MOVETYPES = {}
for i = 0, 15 do
   Collision.MOVETYPES[i] = bit.lshift(1, i)
end

--- Stores registered movetypes names mapped to their bitmask values.
--- @type table<string, integer>
Collision.registeredMovetypes = {}

--- Stores bitmask values mapped to their registered movetypes names.
--- @type table<integer, string>
Collision.movetypeNames = {}

--- Registers a user-defined name for a collision movetype.
--- Prevents duplicate registrations and invalid movetypes.
--- @param name string The name to associate with the movetype.
--- @param movetypeIndex integer The index key from `Collision.MOVETYPES`.
function Collision.registerMovetype(name, movetypeIndex)
   local bitmask = Collision.MOVETYPES[movetypeIndex]
   if bitmask == nil then error("Invalid movetype index: " .. tostring(movetypeIndex)) end
   if Collision.registeredMovetypes[name] then
      error("movetype name already registered: " .. name)
   end
   if Collision.movetypeNames[bitmask] then
      error("movetype already assigned to another name: " .. Collision.movetypeNames[bitmask])
   end

   Collision.registeredMovetypes[name] = bitmask
   Collision.movetypeNames[bitmask] = name
end

--- Retrieves the bitmask value associated with a registered movetype name.
--- @param name string The registered movetype name.
--- @return integer|nil value The bitmask value, or nil if not found.
function Collision.getMovetypeByName(name)
   return Collision.registeredMovetypes[name]
end

--- Retrieves the registered movetype name associated with a bitmask value.
--- @param bitmask integer The bitmask value.
--- @return string|nil name The movetype name, or nil if not found.
function Collision.getMovetypeName(bitmask)
   return Collision.movetypeNames[bitmask]
end

--- Assigns the next available unregistered movetype to a given name.
--- @param name string The name to associate with the next available movetype.
--- @return integer bitmask The bitmask value assigned.
function Collision.assignNextAvailableMovetype(name)
   if Collision.registeredMovetypes[name] then
      error("movetype name already registered: " .. name)
   end

   for index, bitmask in ipairs(Collision.MOVETYPES) do
      if not Collision.movetypeNames[bitmask] then
         Collision.registerMovetype(name, index)
         return bitmask
      end
   end

   error("No available collision movetypes remaining.")
end

--- Converts a list of collision movetypes names into a combined bitmask.
--- @param movetypesNames string[] A list of movetypes names to combine.
--- @return Bitmask bitmask The combined bitmask.
function Collision.createBitmaskFromMovetypes(movetypesNames)
   local bitmask = 0

   for _, name in ipairs(movetypesNames) do
      local movetypesBitmask = Collision.registeredMovetypes[name]
      if not movetypesBitmask then error("movetype name not found: " .. name) end
      bitmask = bit.bor(bitmask, movetypesBitmask)
   end

   return bitmask
end

--- Checks if two bitmasks have any overlapping collision movetypes.
--- @param bitmaskA integer The first bitmask.
--- @param bitmaskB integer The second bitmask.
--- @return boolean True if there is an overlap, false otherwise.
function Collision.checkBitmaskOverlap(bitmaskA, bitmaskB)
   return bit.band(bitmaskA, bitmaskB) ~= 0
end

return Collision
