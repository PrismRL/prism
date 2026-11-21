local Activity = prism.Component:extend "Activity"
Activity.cancellable = false -- Can a controller choose to stop this activity each turn?

function Activity:__new(action, cancellable)
   self.action = action
   self.cancellable = cancellable
end

function Activity:next()
   return self.action
end

return Activity