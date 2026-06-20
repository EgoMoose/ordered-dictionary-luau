--[=[
	@class OrderedDictionary

	A generic dictionary that preserves the order in which keys are inserted.

	Entries are stored in a doubly linked list, so insertion, replacement, and
	removal are all O(1). Positional lookups (`keyAtIndex`/`indexAtKey`) are
	served from an index cache that is rebuilt lazily on the first lookup after
	a structural change, making repeated lookups O(1) until the next mutation.

	```lua
	local dict = OrderedDictionary.new()
	dict:set("first", 1)
	dict:set("second", 2)

	print(dict:indexAtKey("second")) --> 2
	print(dict:keyAtIndex(1)) --> "first", 1
	```
]=]
local OrderedDictionaryStatic = {}

local OrderedDictionaryClass = {}
OrderedDictionaryClass.__index = OrderedDictionaryClass

--[=[
	@within OrderedDictionary
	@prop ClassName "OrderedDictionary"
	@tag Field

	A constant identifier for the class.
]=]
OrderedDictionaryClass.ClassName = "OrderedDictionary"

--[=[
	@interface Pair
	@within OrderedDictionary
	.key K
	.value V

	A single key-value entry, as returned by [OrderedDictionary:pairs].
]=]
type Pair<K, V> = {
	key: K,
	value: V,
}

type LinkedNode<K> = {
	prev: LinkedNode<K>,
	next: LinkedNode<K>,
	key: K,
}

export type OrderedDictionary<K, V> = typeof(setmetatable(
	{} :: {
		root: LinkedNode<K>,
		map: { [K]: LinkedNode<K> },
		dictionary: { [K]: V },
		length: number,

		indicesDirty: boolean,
		indexByKey: { [K]: number },
		keyByIndex: { [number]: K },
	},
	OrderedDictionaryClass
))

--[=[
	Creates a new, empty OrderedDictionary.

	@within OrderedDictionary
	@function new
	@return OrderedDictionary<K, V>
]=]
function OrderedDictionaryStatic.new<K, V>()
	local self = setmetatable({}, OrderedDictionaryClass) :: OrderedDictionary<K, V>

	local root = {} :: LinkedNode<K>
	root.prev = root
	root.next = root

	self.root = root
	self.map = {}
	self.dictionary = {}
	self.length = 0

	self.indicesDirty = false
	self.indexByKey = {}
	self.keyByIndex = {}

	return self
end

-- Private

local function remove<K, V>(self: OrderedDictionary<K, V>, key: K)
	local node = assert(self.map[key], "No key-value pair can be found with the provided key.")

	local prevNode = node.prev
	local nextNode = node.next

	prevNode.next = nextNode
	nextNode.prev = prevNode

	self.map[node.key] = nil
	self.dictionary[node.key] = nil
	self.length = self.length - 1
	self.indicesDirty = true
end

local function insert<K, V>(self: OrderedDictionary<K, V>, prevNode: LinkedNode<K>, key: K, value: V)
	assert(not self.map[key], "Cannot insert a key that already exists.")

	local nextNode = prevNode.next

	local newNode = {
		prev = prevNode,
		next = nextNode,
		key = key,
	}

	prevNode.next = newNode
	nextNode.prev = newNode

	self.map[key] = newNode
	self.dictionary[key] = value

	self.length = self.length + 1
	self.indicesDirty = true
end

local function replace<K, V>(self: OrderedDictionary<K, V>, key: K, value: V)
	local node = assert(self.map[key], "No key-value pair can be found with the provided key.")
	local prevNode = node.prev
	remove(self, key)
	insert(self, prevNode, key, value)
end

local function nodeBeforePosition<K, V>(self: OrderedDictionary<K, V>, index: number): LinkedNode<K>
	local finalLength = self.length + 1

	local indexAbs = math.abs(index)
	assert(indexAbs > 0, "Index must not be zero.")
	assert(indexAbs <= finalLength, "Index must be within the OrderedDictionary length.")

	local position = if index < 0 then finalLength + index + 1 else index

	local prevNode = self.root
	for _ = 1, position - 1 do
		prevNode = prevNode.next
	end
	return prevNode
end

local function recomputeIndices<K, V>(self: OrderedDictionary<K, V>)
	table.clear(self.indexByKey)
	table.clear(self.keyByIndex)

	local current = self.root
	for i = 1, self.length do
		current = current.next
		self.keyByIndex[i] = current.key
		self.indexByKey[current.key] = i
	end

	self.indicesDirty = false
end

-- Public

--[=[
	Returns the number of key-value pairs in the dictionary.

	@within OrderedDictionary
	@method getLength
	@return number
]=]
function OrderedDictionaryClass.getLength<K, V>(self: OrderedDictionary<K, V>)
	return self.length
end

--[=[
	Returns the value associated with `key`, or `nil` if the key is not present.

	@within OrderedDictionary
	@method get
	@param key K
	@return V
]=]
function OrderedDictionaryClass.get<K, V>(self: OrderedDictionary<K, V>, key: K): V
	return self.dictionary[key]
end

--[=[
	Sets the value for `key`.

	- If the key is new, it is appended to the end of the order.
	- If the key already exists, its value is replaced in place, keeping its position.
	- If `value` is `nil`, the key is removed from the dictionary.

	When `index` is provided and the call results in an insert (new key) or a
	replace (existing key), the entry is placed at that 1-based position in the
	order instead of keeping/appending at the end. Positive indices count from
	the front; negative indices count from the back, with `-1` being the last
	position. For a new key the valid range is `1..getLength() + 1` (so
	`getLength() + 1` appends); for an existing key it is `1..getLength()`.
	`index` is ignored when `value` is `nil` (a removal). Positioning walks the
	order to find the target slot, making it O(n).

	@within OrderedDictionary
	@method set
	@param key K
	@param value V?
	@param index number?
]=]
function OrderedDictionaryClass.set<K, V>(self: OrderedDictionary<K, V>, key: K, value: V?, index: number?)
	local node = self.map[key]

	if node and not value then
		remove(self, key)
	elseif node and value then
		if index then
			remove(self, key)
			insert(self, nodeBeforePosition(self, index), key, value)
		else
			replace(self, key, value)
		end
	elseif value then
		insert(self, if index then nodeBeforePosition(self, index) else self.root.prev, key, value)
	end
end

--[=[
	Returns the key and value at the given 1-based position in the order.

	Positive indices count from the front (`1` is the first entry); negative
	indices count from the back (`-1` is the last entry). Throws if `index` is
	zero or its magnitude exceeds the length.

	@within OrderedDictionary
	@method keyAtIndex
	@param index number
	@return K
	@return V
]=]
function OrderedDictionaryClass.keyAtIndex<K, V>(self: OrderedDictionary<K, V>, index: number)
	local indexAbs = math.abs(index)
	assert(indexAbs > 0, "Index must not be zero.")
	assert(indexAbs <= self.length, "Index must be less than the OrderedDictionary length.")

	if self.indicesDirty then
		recomputeIndices(self)
	end

	if index < 0 then
		index = index + 1
	end

	local indexWrapped = ((index - 1) % self.length) + 1
	local key = self.keyByIndex[indexWrapped]
	return key, self.dictionary[key]
end

--[=[
	Returns the 1-based position of `key` in the order, or `nil` if the key is
	not present.

	@within OrderedDictionary
	@method indexAtKey
	@param key K
	@return number?
]=]
function OrderedDictionaryClass.indexAtKey<K, V>(self: OrderedDictionary<K, V>, key: K): number?
	local node = self.map[key]
	if not node then
		return nil
	end

	if self.indicesDirty then
		recomputeIndices(self)
	end

	return self.indexByKey[node.key]
end

--[=[
	Returns an iterator over the entries in insertion order, suitable for use in
	a generic `for` loop. Pass `true` to iterate from last to first instead.

	Each step yields the key, the value, and the entry's 1-based position in the
	order (the same value [OrderedDictionary:indexAtKey] would return for that
	key, regardless of direction).

	```lua
	for key, value, index in dict:iterate() do
		print(index, key, value)
	end
	```

	@within OrderedDictionary
	@method iterate
	@param reversed boolean?
	@return () -> (K?, V?, number?)
]=]
function OrderedDictionaryClass.iterate<K, V>(self: OrderedDictionary<K, V>, reversed: boolean?)
	local current = self.root
	local traversalKey = if reversed then "prev" else "next"
	local index = if reversed then self.length + 1 else 0
	local step = if reversed then -1 else 1
	return function()
		local key, value, position
		current = current[traversalKey]
		if current ~= self.root then
			index = index + step
			key = current.key
			value = self.dictionary[key]
			position = index
		end
		return key, value, position
	end
end

--[=[
	Swaps the positions of `keyA` and `keyB` in the order. Each key keeps its
	own value; only their positions are exchanged. Throws if either key is not
	present.

	@within OrderedDictionary
	@method swap
	@param keyA K
	@param keyB K
]=]
function OrderedDictionaryClass.swap<K, V>(self: OrderedDictionary<K, V>, keyA: K, keyB: K)
	local nodeA = assert(self.map[keyA], "keyA does not exist in the OrderedDictionary.")
	local nodeB = assert(self.map[keyB], "keyB does not exist in the OrderedDictionary.")

	nodeA.key, nodeB.key = keyB, keyA
	self.map[keyA], self.map[keyB] = nodeB, nodeA

	if not self.indicesDirty then
		local indexA, indexB = self.indexByKey[keyA], self.indexByKey[keyB]
		self.indexByKey[keyA], self.indexByKey[keyB] = indexB, indexA
		self.keyByIndex[indexA], self.keyByIndex[indexB] = keyB, keyA
	end
end

--[=[
	Removes every entry, resetting the dictionary to empty.

	@within OrderedDictionary
	@method clear
]=]
function OrderedDictionaryClass.clear<K, V>(self: OrderedDictionary<K, V>)
	self.root.next = self.root
	self.root.prev = self.root

	table.clear(self.map)
	table.clear(self.dictionary)
	self.length = 0

	table.clear(self.indexByKey)
	table.clear(self.keyByIndex)
	self.indicesDirty = true
end

--[=[
	Returns an array of the keys in insertion order.

	@within OrderedDictionary
	@method keys
	@return { K }
]=]
function OrderedDictionaryClass.keys<K, V>(self: OrderedDictionary<K, V>)
	local keys = {}
	for key, _value in self:iterate() do
		table.insert(keys, key)
	end
	return keys
end

--[=[
	Returns an array of the values in insertion order.

	@within OrderedDictionary
	@method values
	@return { V }
]=]
function OrderedDictionaryClass.values<K, V>(self: OrderedDictionary<K, V>)
	local values = {}
	for _key, value in self:iterate() do
		table.insert(values, value)
	end
	return values
end

--[=[
	Returns an array of [Pair] entries in insertion order.

	@within OrderedDictionary
	@method pairs
	@return { Pair<K, V> }
]=]
function OrderedDictionaryClass.pairs<K, V>(self: OrderedDictionary<K, V>)
	local values: { Pair<K, V> } = {}
	for key, value in self:iterate() do
		table.insert(values, {
			key = key,
			value = value,
		})
	end
	return values
end

--[=[
	Reorders the entries in place using `compare`, which receives two [Pair]
	values and should return `true` when the first should come before the
	second (the same contract as `table.sort`).

	```lua
	dict:sort(function(a, b)
		return a.value < b.value
	end)
	```

	@within OrderedDictionary
	@method sort
	@param compare (Pair<K, V>, Pair<K, V>) -> boolean
]=]
function OrderedDictionaryClass.sort<K, V>(self: OrderedDictionary<K, V>, compare: (Pair<K, V>, Pair<K, V>) -> boolean)
	local orderedPairs = self:pairs()
	table.sort(orderedPairs, compare)

	self:clear()
	for _, kvPair in orderedPairs do
		self:set(kvPair.key, kvPair.value)
	end
end

--

return OrderedDictionaryStatic
