
### __call


```lua
function
```

### __index


```lua
Object
```

 A simple class system for Lua. This is the base class for all other classes in PRISM.

### __new


```lua
(method) SparseGrid:__new()
  -> SparseGrid
```

 The constructor for the 'SparseGrid' class.
 Initializes the sparse grid with an empty data table.

### _serializationBlacklist


```lua
table
```

### adopt


```lua
(method) Object:adopt(o: any)
  -> unknown
```

### className


```lua
string
```

A unique name for this class. By convention this should match the annotation name you use.

### clear


```lua
(method) SparseGrid:clear()
```

 Clears all values in the sparse grid.

### data


```lua
table
```

### deserialize


```lua
function Object.deserialize(data: any)
  -> unknown
```

### each


```lua
(method) SparseGrid:each()
  -> iter: fun(x: integer, y: integer, V: any)
```

 Iterator function for the SparseGrid.
 Iterates over all entries in the sparse grid, returning the coordinates and value for each entry.

@*return* `iter` — An iterator function that returns the x-coordinate, y-coordinate, and value for each entry.

### extend


```lua
(method) Object:extend(className: string, ignoreclassName?: boolean)
  -> prototype: <T>
```

 Creates a new class and sets its metatable to the extended class.

@*param* `className` — name for the class

@*param* `ignoreclassName` — if true, skips the uniqueness check in prism's registry

@*return* `prototype` — The new class prototype extended from this one.

### get


```lua
(method) SparseGrid:get(x: integer, y: integer)
  -> value: any
```

 Gets the value at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*return* `value` — The value at the specified coordinates, or nil if not set.

### instanceOf


```lua
(method) Object:instanceOf(o: table)
  -> extends: boolean
```

 Checks if o is the first class in the inheritance chain of self.

@*param* `o` — The class to check.

@*return* `extends` — True if o is the first class in the inheritance chain of self, false otherwise.

### is


```lua
(method) Object:is(o: table)
  -> is: boolean
```

 Checks if o is in the inheritance chain of self.

@*param* `o` — The class to check.

@*return* `is` — True if o is in the inheritance chain of self, false otherwise.

### mixin


```lua
(method) Object:mixin(mixin: table)
  -> Object
```

 Mixes in methods and properties from another table, excluding blacklisted metamethods.
 THis does not deep copy or merge tables, currently. It's a shallow mixin.

@*param* `mixin` — The table containing methods and properties to mix in.

### prettyprint


```lua
function Object.prettyprint(obj: table, indent: string, visited: table)
  -> string
```

 Pretty-prints an object for debugging or visualization.

@*param* `obj` — The object to pretty-print.

@*param* `indent` — The current indentation level (used for recursion).

@*param* `visited` — A table of visited objects to prevent circular references.

### serializationBlacklist


```lua
table<string, boolean>
```

### serialize


```lua
function Object.serialize(object: any)
  -> table
```

### set


```lua
(method) SparseGrid:set(x: integer, y: integer, value: any)
```

 Sets the value at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*param* `value` — The value to set.

### stripName


```lua
boolean
```


---

