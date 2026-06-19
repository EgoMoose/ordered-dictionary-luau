<!-- Links -->

[links/wally]: https://wally.run/package/egomoose/ordered-dictionary
[links/github]: https://github.com/EgoMoose/ordered-dictionary-luau/releases

<!-- Badges -->

[badges/wally]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/wally.svg
[badges/github]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/github.svg

# ordered-dictionary

A generic luau dictionary that remembers the order in which keys were first inserted.

A plain Luau table gives you no guarantees about iteration order. `OrderedDictionary` wraps a doubly linked list and a hash map so that you get the best of both: O(1) insertion, replacement, and removal, while iteration always walks the entries in the order they were added.

[![Get it on Wally][badges/wally]][links/wally] [![Get it on Github][badges/github]][links/github]

## Features

- **Stable ordering** — entries iterate in the order keys were first inserted.
- **O(1) mutation** — `set`, replace, and remove are all constant time.
- **Cached positional lookups** — `keyAtIndex` / `indexAtKey` are served from an index cache that is rebuilt lazily after a structural change, so repeated lookups stay O(1).
- **Positive and negative indexing** — `1` is the first entry, `-1` is the last.
- **Fully generic and typed** — `OrderedDictionary<K, V>` is exported for use in your own type annotations.

## Usage

```lua
local OrderedDictionary = require(path.to.OrderedDictionary)

local dict = OrderedDictionary.new()
dict:set("first", 1)
dict:set("second", 2)
dict:set("third", 3)

print(dict:indexAtKey("second")) --> 2
print(dict:keyAtIndex(1))        --> "first", 1
print(dict:keyAtIndex(-1))       --> "third", 3

for key, value, index in dict:iterate() do
	print(index, key, value)
	--> 1 first 1
	--> 2 second 2
	--> 3 third 3
end
```
