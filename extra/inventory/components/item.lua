--- Indicates that an actor can be held in an :lua:class:`Inventory`.
--- @class Item : Component
--- @field owner Actor
--- @field private weight number
--- @field private volume number
--- @field stackable string Other items with this identifier will stack with it.
--- @overload fun(options: ItemOptions?): Item
local Item = prism.Component:extend("Item")
Item.weight = 0
Item.volume = 0
Item.stackable = nil
Item.stackCount = 1
Item.stacklimit = math.huge

--- @alias ItemOptions { weight?: number, volume?: number, stackable?: string, stackLimit: number|nil, stackCount?: number }

--- Constructor for the Item component, see ItemOptions for available options.
--- @param options ItemOptions
function Item:__new(options)
   if not options then return end

   self.weight = options.weight or 0
   self.volume = options.volume or 0
   self.stackable = options.stackable
   self.stackLimit = options.stackable and options.stackLimit or math.huge
   self.stackCount = options.stackCount or 1
end

--- Stacks an actor into this item. Updates the stackCount of both this item and
--- the input item.
--- @param actor Actor
function Item:stack(actor)
   local item = actor:expect(prism.components.Item)

   assert(self.stackable == item.stackable)
   local numToStack = math.min(item.stackCount, self.stackLimit - self.stackCount)
   item.stackCount = item.stackCount - numToStack
   self.stackCount = self.stackCount + numToStack
end

--- Splits the stack, constructing a new actor with the correct count
--- and returning it. Returns its owner if count is 1 and the item
--- is not stackable.
--- @param count integer
--- @return Actor split
function Item:split(count)
   if count == 1 and not self.stackable then return self.owner end

   assert(self.stackable, "Can't split a non-stackable item")
   assert(
      count >= 1 and count < self.stackCount,
      "Split count must be less than current stackCount"
   )

   self.stackCount = self.stackCount - count

   local newActor = self.owner:clone()
   local newItem = newActor:expect(prism.components.Item)
   newItem.stackCount = count

   return newActor
end

--- Gets the total weight of this item taking into account its stackCount.
--- @return number weight
function Item:getWeight()
   return self.weight * self.stackCount
end

--- Gets the total volume of this item taking into account its stackCount.
--- @return number volume
function Item:getVolume()
   return self.volume * self.stackCount
end

return Item
