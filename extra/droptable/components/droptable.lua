--- @alias DropTableOptions DropTableCategory[]|DropTableCategory

--- @class DropTableCategory
--- @field chance? number A number from 0-1 to determine the chance for the category to drop. Defaults to 1 (100%).
--- @field entries? DropTableWeightedOption[] Weighted items to choose from when the category does drop.
--- @field quantity? integer The amount to drop. Defaults to 1.
--- @field entry? DropTableEntry The actual actor to drop. This or entries must not be nil.

--- @class DropTableWeightedOption
--- @field weight integer The weight of the item, e.g. if there are weights of 50 and 30, the former will drop 50/80 times.
--- @field entry DropTableEntry The actual actor to drop.
--- @field quantity? integer The amount to drop. Defaults to 1.

--- @alias DropTableEntry ActorName|Actor

--- A drop table which tracks what items the actor should drop upon death.
--- @class DropTable : Component
--- @field categories DropTableCategory[]
--- @field weights table<DropTableCategory, table<integer, integer>> Weights per category per entry.
--- @overload fun(table: DropTableOptions): DropTable
local DropTable = prism.Component:extend "DropTable"

--- @param options DropTableOptions
function DropTable:__new(options)
   -- Wrap single categories in a table to simplify logic.
   if options.chance or options.entries or options.entry then
      --- @cast options DropTableCategory
      self.categories = { options }
   else
      --- @cast options DropTableCategory[]
      self.categories = options
   end

   assert(#self.categories > 0, "Initialized a drop table with zero elements!")

   -- Calculate the weights for categories with multiple entries.
   self.weights = {}
   for i, category in ipairs(self.categories) do
      if category.entries then
         --- @type table<integer, integer>
         local cumulativeWeights = {}
         local cumulativeWeight = 0
         for j, weightedOption in ipairs(category.entries) do
            cumulativeWeight = cumulativeWeight + weightedOption.weight
            cumulativeWeights[j] = cumulativeWeight
         end

         self.weights[category] = cumulativeWeights
      elseif not category.entry then
         error("Category " .. i .. " has neither entries nor entry field!")
      end
   end
end

--- @private
--- @param quantity integer
--- @param item DropTableEntry
--- @return Actor[] drops
function DropTable:quantifyItem(quantity, item)
   if type(item) ~= "string" then
      if quantity > 1 then
         prism.logger.warn("DropTable entry had specific actor and quantity >1 dropping 1 instead!")
      end

      return { item:clone() }
   end

   local dummy = prism.actors[item]()
   if prism.components.Item and dummy:has(prism.components.Item) then
      dummy:expect(prism.components.Item).stackCount = quantity
      return { dummy }
   end

   local drops = {}
   for _ = 1, quantity do
      table.insert(drops, prism.actors[item]())
   end

   return drops
end

--- Takes an RNG and returns a table of actors from the drop table.
---@param rng RNG
---@return Actor[]
function DropTable:getDrops(rng)
   --- @type Actor[]
   local drops = {}

   for _, category in ipairs(self.categories) do
      local chance = category.chance or 1.0
      local quantity = category.quantity or 1

      if rng:random() <= chance then
         local entry = category.entry

         if category.entries then
            local cumulativeWeights = self.weights[category]
            local roll = rng:random(0, cumulativeWeights[#cumulativeWeights] - 1)

            -- Binary search over cumulativeWeights
            local low, high = 1, #cumulativeWeights
            while low < high do
               local mid = math.floor((low + high) / 2)
               if roll < cumulativeWeights[mid] then
                  high = mid
               else
                  low = mid + 1
               end
            end

            quantity = category.entries[low].quantity or quantity
            entry = category.entries[low].entry
         end

         for _, actor in ipairs(self:quantifyItem(quantity, entry)) do
            table.insert(drops, actor)
         end
      end
   end

   return drops
end

return DropTable
