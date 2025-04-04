
### __call


```lua
function
```

### __count


```lua
integer
```

### __index


```lua
Object
```

 A simple class system for Lua. This is the base class for all other classes in PRISM.

### __new


```lua
(method) SparseMap:__new()
```

 The constructor for the 'SparseMap' class.
 Initializes the map and counters.

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

### contains


```lua
(method) SparseMap:contains(value: any)
  -> containsValue: boolean
```

 Checks where the specified value exists within the map.

### count


```lua
(method) SparseMap:count()
  -> The: number
```

 Returns the total number of entries in the sparse map.

@*return* `The` — total number of entries.

### countCell


```lua
(method) SparseMap:countCell(x: integer, y: integer)
  -> The: number
```

 Returns the number of values stored at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*return* `The` — number of values stored at the specified coordinates.

### deserialize


```lua
function Object.deserialize(data: any)
  -> unknown
```

### each


```lua
(method) SparseMap:each()
  -> An: function
```

 Returns an iterator over all entries in the sparse map.

@*return* `An` — iterator that returns the value, coordinates, and hash for each entry.

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
(method) SparseMap:get(x: integer, y: integer)
  -> elements: table
```

 Gets the values stored at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*return* `elements` — A set[actor]=bool of values stored at the specified coordinates, or an empty table if none.

### getByHash


```lua
(method) SparseMap:getByHash(hash: number)
  -> A: table
```

 Gets the values stored at the specified hash.

@*param* `hash` — The hash value of the coordinates.

@*return* `A` — table of values stored at the specified hash, or an empty table if none.

### has


```lua
(method) SparseMap:has(x: integer, y: integer, value: any)
  -> True: boolean
```

 Checks whether the specified value is stored at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*param* `value` — The value to check.

@*return* `True` — if the value is stored at the specified coordinates, false otherwise.

### insert


```lua
(method) SparseMap:insert(x: integer, y: integer, val: any)
```

 Inserts a value at the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*param* `val` — The value to insert.

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

### list


```lua
table
```

### map


```lua
table
```

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

### remove


```lua
(method) SparseMap:remove(x: integer, y: integer, val: any)
  -> True: boolean
```

 Removes a value from the specified coordinates.

@*param* `x` — The x-coordinate.

@*param* `y` — The y-coordinate.

@*param* `val` — The value to remove.

@*return* `True` — if the value was successfully removed, false otherwise.

### serializationBlacklist


```lua
table<string, boolean>
```

### serialize


```lua
function Object.serialize(object: any)
  -> table
```

### stripName


```lua
boolean
```


---

