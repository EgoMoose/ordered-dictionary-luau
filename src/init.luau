--!strict

local OrderedDictionaryConstructors = {}

local OrderedDictionaryClass = {}
OrderedDictionaryClass.__index = OrderedDictionaryClass
OrderedDictionaryClass.ClassName = "OrderedDictionary"

-- Types

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
	},
	OrderedDictionaryClass
))

-- Constructors

function OrderedDictionaryConstructors.new<K, V>(): OrderedDictionary<K, V>
	local self = setmetatable({}, OrderedDictionaryClass) :: OrderedDictionary<K, V>

	self.root = {} :: LinkedNode<K>
	self.root.next = self.root
	self.root.prev = self.root

	self.map = {}
	self.dictionary = {}
	self.length = 0

	return self
end

function OrderedDictionaryConstructors.meta<K, V>()
	local orderedDict = OrderedDictionaryConstructors.new() :: OrderedDictionary<K, V>

	local meta = {
		__index = function(_self: any, key: K)
			return orderedDict:get(key)
		end,
		__newindex = function(_self: any, key: K, value: V)
			orderedDict:set(key, value)
		end,
		__len = function(_self: any)
			return orderedDict:getLength()
		end,
		__iter = function(_self: any)
			return orderedDict:iterate()
		end,
		__call = function(_self: any)
			return orderedDict
		end,
		__metatable = false,
	}

	local result = setmetatable({} :: { [K]: V }, meta)
	return result
end

-- Private Methods

local function remove<K, V>(self: OrderedDictionary<K, V>, key: K)
	local node = self.map[key]
	assert(node, `No key-value pair can be found with the following key: {tostring(key)}`)

	local prevNode = node.prev
	local nextNode = node.next

	prevNode.next = nextNode
	nextNode.prev = prevNode

	self.map[node.key] = nil
	self.length = self.length - 1
end

local function insert<K, V>(self: OrderedDictionary<K, V>, prevNode: LinkedNode<K>, key: K, value: V)
	assert(not self.map[key], `Cannot insert a key that already exists for: {tostring(key)}`)

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
end

local function replace<K, V>(self: OrderedDictionary<K, V>, key: K, value: V)
	local node = self.map[key]
	assert(node, `No key-value pair can be found with the following key: {tostring(key)}`)

	local prevNode = node.prev
	remove(self, key)
	insert(self, prevNode, key, value)
end

local function pop<K, V>(self: OrderedDictionary<K, V>, key: K)
	local node = self.map[key]
	assert(node, `No key-value pair can be found with the following key: {tostring(key)}`)

	local value = self:get(key)
	remove(self, key)

	return key, value :: V
end

local function moveTo<K, V>(self: OrderedDictionary<K, V>, prevNode: LinkedNode<K>, key: K)
	local _, value = pop(self, key)
	insert(self, prevNode, key, value)
end

-- Public Methods

function OrderedDictionaryClass.iterate<K, V>(self: OrderedDictionary<K, V>)
	local current = self.root
	return function()
		current = current.next
		if current ~= self.root then
			local key = current.key
			local value = self.dictionary[key]
			return key, value
		end
		return nil :: any, nil :: any
	end
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
	local values = {}
	for key, value in self:iterate() do
		table.insert(values, {
			key = key,
			value = value,
		})
	end
	return values
end

function OrderedDictionaryClass.getLength<K, V>(self: OrderedDictionary<K, V>): number
	return self.length
end

function OrderedDictionaryClass.get<K, V>(self: OrderedDictionary<K, V>, key: K): V?
	return self.dictionary[key]
end

function OrderedDictionaryClass.set<K, V>(self: OrderedDictionary<K, V>, key: K, value: V?)
	local node = self.map[key]

	if node and not value then
		remove(self, key)
	elseif node and value then
		replace(self, key, value)
	elseif value then
		insert(self, self.root.prev, key, value)
	end
end

function OrderedDictionaryClass.popFront<K, V>(self: OrderedDictionary<K, V>)
	assert(self:getLength() > 0, "OrderedDictionary has no key-value pairs to pop.")
	return pop(self, self.root.next.key)
end

function OrderedDictionaryClass.popBack<K, V>(self: OrderedDictionary<K, V>)
	assert(self:getLength() > 0, "OrderedDictionary has no key-value pairs to pop.")
	return pop(self, self.root.prev.key)
end

function OrderedDictionaryClass.moveToFront<K, V>(self: OrderedDictionary<K, V>, key: K)
	return moveTo(self, self.root, key)
end

function OrderedDictionaryClass.moveToBack<K, V>(self: OrderedDictionary<K, V>, key: K)
	return moveTo(self, self.root.prev, key)
end

function OrderedDictionaryClass.clear<K, V>(self: OrderedDictionary<K, V>)
	self.root.next = self.root
	self.root.prev = self.root

	self.map = {}
	self.dictionary = {}
	self.length = 0
end

--

return OrderedDictionaryConstructors
