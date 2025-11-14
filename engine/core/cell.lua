--- A single tile on the map.
--- Like actors, they hold components that can be used to modify their behaviour.
--- Cells are required to have a :lua:class:`Collider`. :lua:class:`Opaque` can be
--- used to block sight in the default field of view implementation.
--- @class Cell : Entity
--- @overload fun(): Cell
local Cell = prism.Entity:extend("Cell")

--- @alias CellFactory fun(...): Cell

--- Constructor for the Cell class.
function Cell:__new()
   self.super.__new(self)
end

--- Initializes a cell from a list of components.
--- @param components Component[] A list of components to give to the new cell.
--- @return Cell cell The new actor.
function Cell.fromComponents(components)
   local cell = Cell()
   for _, component in ipairs(components) do
      cell:give(component)
   end
   return cell
end

--- @return Bitmask mask The collision mask of the cell.
function Cell:getCollisionMask()
   return self:expect(prism.components.Collider):getMask()
end

return Cell
