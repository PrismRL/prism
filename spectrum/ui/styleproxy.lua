--- Read-only proxy over a fully-resolved ui.style table.
---@class StyleProxy : Style
---@field ui UI
---@field path string[]
---@field cache table<string, StyleProxy>  -- child proxies for subtables (prebuilt)
local StyleProxy = {}

-- Class members first; then child proxies; then scalars from ui.style
StyleProxy.__index = function(self, key)
   local cls = rawget(StyleProxy, key)
   if cls ~= nil then return cls end

   local child = self.cache[key]
   if child ~= nil then return child end

   local stack = self.ui.styleStack
   if stack then
      for i = #stack, 1, -1 do
         local style = stack[i]
         local t = StyleProxy._getAt(style, self.path)
         if type(t) == "table" and t[key] ~= nil then
            return t[key]
         end
      end
   end

   local base = StyleProxy._getAt(self.ui.baseStyle, self.path)
   if type(base) == "table" then
      return base[key]
   end

   return nil
end

-- Read-only
StyleProxy.__newindex = function(_, k, _v)
   error(("StyleProxy is read-only (attempt to set '%s')"):format(tostring(k)), 2)
end

---@private
---@param tbl table|nil
---@param path string[]
---@return any
function StyleProxy._getAt(tbl, path)
   local t = tbl
   for i = 1, #path do
      if type(t) ~= "table" then return nil end
      t = t[path[i]]
   end
   return t
end

---@private
---@param t any
---@return boolean
local function _isPlainTable(t)
   return type(t) == "table" and getmetatable(t) == nil
end

--- Constructor: prebuilds the entire subtree of proxies under ui.style at this path.
---@param ui UI
---@param path? string[]
---@return StyleProxy
function StyleProxy.new(ui, path)
   local self = {
      ui    = ui,
      path  = path or {},
      cache = {},
   }
   setmetatable(self, StyleProxy)

   local t = StyleProxy._getAt(ui.baseStyle, self.path)
   -- Only iterate if the current node is a plain table (no metatable)
   if _isPlainTable(t) then
      for k, v in pairs(t) do
         -- Only create child proxies for plain subtables (no metatable)
         if _isPlainTable(v) then
            local childPath = { unpack(self.path) }
            childPath[#childPath + 1] = k
            self.cache[k] = StyleProxy.new(ui, childPath)
         end
      end
   end

   return self
end

function StyleProxy:__tostring()
   return ("StyleProxy{ path = %s }"):format(table.concat(self.path, "."))
end

return StyleProxy
