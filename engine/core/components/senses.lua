--- Senses is used by the sense system as the storage for all of the sensory information
--- from the other sense components/systems. It is required for sight. See the SensesSystem for more.
--- @class Senses : Component
--- @field cells SparseGrid A sparse grid of cells representing the portion of the map the actor's senses reveal.
--- @field explored SparseGrid A sparse grid of cells the actor's senses have previously revealed.
--- @field remembered SparseGrid
--- @field exploredStorage table<Level, SparseGrid>
--- @field rememberedStorage table<Level, SparseGrid>
--- @field unknown SparseMap<Vector2> Unkown actors are things the player is aware of the location of, but not the components.
--- @overload fun(): Senses
local Senses = prism.Component:extend "Senses"

function Senses:__new(actor)
   self.exploredStorage = {}
   self.rememberedStorage = {}
   self.cells = prism.SparseGrid()
   self.unknown = prism.SparseMap()
end

--- Queries the level, but only for actors sensed by the component's owner.
--- @param level Level The level.
--- @param ... Component A list of components to pass to the query.
function Senses:query(level, ...)
   return level:query(...):relationship(self.owner, prism.relationships.Senses)
end

return Senses
