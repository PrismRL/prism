--- A conditional node in the behavior tree.
--- @class BehaviorTree.Conditional : BehaviorTree.Node
--- @overload fun(conditionFunc: fun(self: BehaviorTree.Conditional, level: Level, actor: Actor)): BehaviorTree.Conditional
local BTConditional = prism.BehaviorTree.Node:extend("BehaviorTree.Conditional")

--- Creates a new BehaviorTree.Conditional.
--- @param conditionFunc fun(self: BehaviorTree.Conditional, level: Level, actor: Actor): boolean
function BTConditional:__new(conditionFunc)
   self.conditionFunc = conditionFunc
end

--- Runs the conditional node.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function BTConditional:run(level, actor, controller)
   return self:conditionFunc(level, actor)
end

return BTConditional
