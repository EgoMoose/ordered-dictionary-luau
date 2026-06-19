local OrderedDictionaryStatic = {}

local OrderedDictionaryClass = {}
OrderedDictionaryClass.__index = OrderedDictionaryClass
OrderedDictionaryClass.ClassName = "OrderedDictionary"

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

function OrderedDictionaryClass.getLength<K, V>(self: OrderedDictionary<K, V>)
	return self.length
end

function OrderedDictionaryClass.get<K, V>(self: OrderedDictionary<K, V>, key: K): V
	return self.dictionary[key]
end

function OrderedDictionaryClass.set<K, V>(self: OrderedDictionary<K, V>, key: K, value: V)
	local node = self.map[key]

	if node and not value then
		remove(self, key)
	elseif node and value then
		replace(self, key, value)
	elseif value then
		insert(self, self.root.prev, key, value)
	end
end

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

function OrderedDictionaryClass.iterate<K, V>(self: OrderedDictionary<K, V>, reversed: boolean?)
	local current = self.root
	local traversalKey = if reversed then "prev" else "next"
	return function()
		local key, value
		current = current[traversalKey]
		if current ~= self.root then
			key = current.key
			value = self.dictionary[key]
		end
		return key, value
	end
end

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

function OrderedDictionaryClass.keys<K, V>(self: OrderedDictionary<K, V>)
	local keys = {}
	for key, _value in self:iterate() do
		table.insert(keys, key)
	end
	return keys
end

function OrderedDictionaryClass.values<K, V>(self: OrderedDictionary<K, V>)
	local values = {}
	for _key, value in self:iterate() do
		table.insert(values, value)
	end
	return values
end

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
