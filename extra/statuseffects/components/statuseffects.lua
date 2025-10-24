--- @alias StatusEffectsHandle integer

--- @class StatusEffects : Component
--- @field instances SparseArray
--- @field modifierMap table<StatusEffectsModifier, StatusEffectsModifier[]>
--- @overload fun(): StatusEffects
local StatusEffects = prism.Component:extend "StatusEffects"

function StatusEffects:__new()
   self.instances = prism.SparseArray()
   self.modifierMap = {}
end

--- @param instance StatusEffectsInstance
--- @return StatusEffectsHandle handle
function StatusEffects:add(instance)
   -- remove existing instances of the same subclass if set to singleton
   if instance.singleton then
      local toRemove = {}
      for handle, existing in self:pairs() do
         if getmetatable(instance) == self.Instance then
            prism.logger.warn("Status effect set to singleton, but not subclassed! This will remove all anonymous instances!")
         end

         if getmetatable(instance).is(existing) then
            table.insert(toRemove, handle)
         end
      end

      for _, handle in ipairs(toRemove) do
         self:remove(handle)
      end
   end

   local handle = self.instances:add(instance)

   for _, modifier in ipairs(instance.modifiers) do
      local meta = getmetatable(modifier)

      if not self.modifierMap[meta] then
         self.modifierMap[meta] = {}
      end

      table.insert(self.modifierMap[meta], modifier)
   end

   return handle
end

--- @param handle StatusEffectsHandle
function StatusEffects:remove(handle)
   local instance = self.instances:get(handle)
   --- @cast instance StatusEffectsInstance

   -- Remove modifiers from global map/set
   for _, modifier in ipairs(instance.modifiers) do
      local meta = getmetatable(modifier)
      local list = self.modifierMap[meta]

      if list then
         for i = #list, 1, -1 do
            if list[i] == modifier then
               table.remove(list, i)
               break
            end
         end
         if #list == 0 then
            self.modifierMap[meta] = nil
         end
      end
   end

   self.instances:remove(handle)
end

--- @generic T
--- @param prototype T
--- @return T[]
function StatusEffects:getModifiers(prototype)
   return self.modifierMap[prototype] or {}
end

--- @param handle StatusEffectsHandle
--- @return StatusEffectsInstance instance
function StatusEffects:getInstance(handle)
   return self.instances:get(handle)
end

local ignore = { owner = true }
function StatusEffects:clone()
   return self:deepcopy(ignore)
end

local dummy = {}

--- @generic T
--- @param actor Entity
--- @param prototype T
--- @return T[]
function StatusEffects.getActorModifiers(actor, prototype)
   local status = actor:get(prism.components.StatusEffects)
   if not status then return dummy end

   local modifiers = status:getModifiers(prototype)
   return modifiers
end

--- @return fun():(StatusEffectsHandle, StatusEffectsInstance)
function StatusEffects:pairs()
   return self.instances:pairs()
end

--- @class StatusEffectsInstanceOptions
--- @field modifiers StatusEffectsModifier[]

--- @class StatusEffectsInstance : Object
--- @field modifiers StatusEffectsModifier[]
--- @field singleton boolean
--- @field modifierMap table<StatusEffectsModifier, StatusEffectsModifier[]>
local StatusEffectsInstance = prism.Object:extend "StatusEffectsInstance"
StatusEffectsInstance.singleton = false

function StatusEffectsInstance:__new(options)
   self.modifiers = options.modifiers
   self.modifierMap = {}

   for _, modifier in ipairs(self.modifiers) do
      local meta = getmetatable(modifier)
      if not self.modifierMap[meta] then
         self.modifierMap[meta] = {}
      end

      table.insert(self.modifierMap[meta], modifier)
   end
end

--- @generic T
--- @param prototype T
--- @return T[]
function StatusEffectsInstance:getModifiers(prototype)
   return self.modifierMap[prototype] or {}
end


--- @class StatusEffectsModifier : Object
local StatusEffectsModifier = prism.Object:extend "StatusEffectsModifier"

StatusEffects.Modifier = StatusEffectsModifier
StatusEffects.Instance = StatusEffectsInstance

return StatusEffects