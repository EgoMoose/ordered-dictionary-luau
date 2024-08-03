# ordered-dictionary-luau

A dictionary that remembers the order in which keys were first inserted.

Get it here:

* [Wally](https://wally.run/package/egomoose/ordered-dictionary)
* [Releases](https://github.com/EgoMoose/ordered-dictionary-luau/releases)

## Examples

There are two constructors that this module provides for creating ordered dictionaries.

The first is a standard luau OOP object that provides a number of useful methods for manipulating the contents of the ordered dictionary.

```lua
local booksBorrowed = OrderedDictionary.new()

booksBorrowed:set("Tom", 2)
booksBorrowed:set("Sarah", 4)
booksBorrowed:set("John", 1)
booksBorrowed:set("Emily", 6)
booksBorrowed:set("Marcus", 0)

for person, books in booksBorrowed:iterate() do
	print(person, books)
end

local name, books = booksBorrowed:popFront() -- "Tom", 2
```

The second is wrapped within metatables allowing access much like a built-in dictionary. The trade off however is that less methods are accessible.

```lua
local booksBorrowed = OrderedDictionary.meta()

booksBorrowed["Tom"] = 2
booksBorrowed["Sarah"] = 4
booksBorrowed["John"] = 1
booksBorrowed["Emily"] = 6
booksBorrowed["Marcus"] = 0

for person, books in booksBorrowed do
	print(person, books)
end

-- can get the object by calling like a function
local booksBorrowedObject = booksBorrowed()
local name, books = booksBorrowedObject:popBack() -- "Marcus", 0
```
