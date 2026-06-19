local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local OrderedDictionary = require(ReplicatedStorage.Packages.OrderedDictionary)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

-- Builds an OrderedDictionary with the given keys inserted in order, each
-- mapped to a deterministic value so we can assert key/value association.
local function build(...)
	local dict = OrderedDictionary.new()
	for _, key in { ... } do
		dict:set(key, key .. "-value")
	end
	return dict
end

describe("new / getLength", function()
	it("starts empty", function()
		local dict = OrderedDictionary.new()
		expect(dict:getLength()).toBe(0)
	end)

	it("is usable immediately after construction (inserts-only path)", function()
		local dict = OrderedDictionary.new()
		dict:set("a", 1)

		-- Exercises the index cache on a dict that has only ever been inserted
		-- into, with no prior remove/read to lazily allocate the cache tables.
		expect(dict:indexAtKey("a")).toBe(1)
		expect((dict:keyAtIndex(1))).toBe("a")
	end)
end)

describe("get / set", function()
	it("stores and retrieves values", function()
		local dict = build("a", "b")
		expect(dict:get("a")).toBe("a-value")
		expect(dict:get("b")).toBe("b-value")
	end)

	it("returns nil for a missing key", function()
		local dict = build("a")
		expect(dict:get("missing")).toBeNil()
	end)

	it("appends new keys to the end", function()
		local dict = build("a", "b", "c")
		expect(dict:keys()).toEqual({ "a", "b", "c" })
		expect(dict:getLength()).toBe(3)
	end)

	it("replaces a value in place without changing order", function()
		local dict = build("a", "b", "c")
		dict:set("b", "new-b")

		expect(dict:get("b")).toBe("new-b")
		expect(dict:keys()).toEqual({ "a", "b", "c" })
		expect(dict:indexAtKey("b")).toBe(2)
	end)

	it("removes a key when set to nil", function()
		local dict = build("a", "b", "c")
		dict:set("b", nil)

		expect(dict:get("b")).toBeNil()
		expect(dict:getLength()).toBe(2)
		expect(dict:keys()).toEqual({ "a", "c" })
	end)

	it("does nothing when removing a key that does not exist", function()
		local dict = build("a")
		dict:set("missing", nil)
		expect(dict:getLength()).toBe(1)
	end)
end)

describe("keyAtIndex", function()
	it("returns the key and value at a positive index", function()
		local dict = build("a", "b", "c")

		local key, value = dict:keyAtIndex(2)
		expect(key).toBe("b")
		expect(value).toBe("b-value")
	end)

	it("indexes from the end for negative indices", function()
		local dict = build("a", "b", "c")

		expect((dict:keyAtIndex(-1))).toBe("c")
		expect((dict:keyAtIndex(-2))).toBe("b")
		expect((dict:keyAtIndex(-3))).toBe("a")
	end)

	it("throws on a zero index", function()
		local dict = build("a")
		expect(function()
			dict:keyAtIndex(0)
		end).toThrow()
	end)

	it("throws when the index is out of range", function()
		local dict = build("a", "b")
		expect(function()
			dict:keyAtIndex(3)
		end).toThrow()
		expect(function()
			dict:keyAtIndex(-3)
		end).toThrow()
	end)
end)

describe("indexAtKey", function()
	it("returns the 1-based index of a key", function()
		local dict = build("a", "b", "c")
		expect(dict:indexAtKey("a")).toBe(1)
		expect(dict:indexAtKey("b")).toBe(2)
		expect(dict:indexAtKey("c")).toBe(3)
	end)

	it("returns nil for a missing key", function()
		local dict = build("a", "b")
		expect(dict:indexAtKey("missing")).toBeNil()
	end)

	it("is the inverse of keyAtIndex", function()
		local dict = build("a", "b", "c")
		for index = 1, dict:getLength() do
			local key = dict:keyAtIndex(index)
			expect(dict:indexAtKey(key)).toBe(index)
		end
	end)

	it("reflects indices after a removal", function()
		local dict = build("a", "b", "c")
		dict:set("a", nil)

		expect(dict:indexAtKey("b")).toBe(1)
		expect(dict:indexAtKey("c")).toBe(2)
	end)
end)

describe("iterate", function()
	it("iterates in insertion order, yielding key, value, and index", function()
		local dict = build("a", "b", "c")

		local seen = {}
		for key, value, index in dict:iterate() do
			table.insert(seen, { key, value, index })
		end

		expect(seen).toEqual({
			{ "a", "a-value", 1 },
			{ "b", "b-value", 2 },
			{ "c", "c-value", 3 },
		} :: { { any } })
	end)

	it("iterates in reverse when requested, with positions counting down", function()
		local dict = build("a", "b", "c")

		local seen = {}
		for key, value, index in dict:iterate(true) do
			table.insert(seen, { key, value, index })
		end

		expect(seen).toEqual({
			{ "c", "c-value", 3 },
			{ "b", "b-value", 2 },
			{ "a", "a-value", 1 },
		} :: { { any } })
	end)

	it("yields an index that agrees with indexAtKey", function()
		local dict = build("a", "b", "c", "d")
		for key, _value, index in dict:iterate() do
			expect(index).toBe(dict:indexAtKey(key))
		end
	end)

	it("does nothing for an empty dictionary", function()
		local dict = OrderedDictionary.new()

		local count = 0
		for _key in dict:iterate() do
			count += 1
		end

		expect(count).toBe(0)
	end)
end)

describe("swap", function()
	it("exchanges the positions of two keys while keeping their values", function()
		local dict = build("a", "b", "c")
		dict:swap("a", "c")

		expect(dict:keys()).toEqual({ "c", "b", "a" })
		expect(dict:get("a")).toBe("a-value")
		expect(dict:get("c")).toBe("c-value")
	end)

	it("updates the index cache incrementally when the cache is clean", function()
		local dict = build("a", "b", "c")
		-- Prime the cache so it is clean before the swap (exercises the
		-- incremental update branch rather than a full recompute).
		expect(dict:indexAtKey("a")).toBe(1)

		dict:swap("a", "c")

		expect(dict:indexAtKey("a")).toBe(3)
		expect(dict:indexAtKey("c")).toBe(1)
		expect((dict:keyAtIndex(1))).toBe("c")
		expect((dict:keyAtIndex(3))).toBe("a")
	end)

	it("is correct when the cache is dirty (full recompute path)", function()
		-- No read between insertion and swap, so indicesDirty is still true
		-- and swap must fall back to a recompute on the next read.
		local dict = build("a", "b", "c")
		dict:swap("a", "b")

		expect(dict:indexAtKey("a")).toBe(2)
		expect(dict:indexAtKey("b")).toBe(1)
	end)

	it("throws when either key is missing", function()
		local dict = build("a")
		expect(function()
			dict:swap("a", "missing")
		end).toThrow()
		expect(function()
			dict:swap("missing", "a")
		end).toThrow()
	end)
end)

describe("clear", function()
	it("empties the dictionary", function()
		local dict = build("a", "b", "c")
		dict:clear()

		expect(dict:getLength()).toBe(0)
		expect(dict:get("a")).toBeNil()
		expect(dict:keys()).toEqual({})
	end)

	it("can be reused after clearing", function()
		local dict = build("a", "b")
		dict:clear()
		dict:set("x", "x-value")

		expect(dict:getLength()).toBe(1)
		expect(dict:indexAtKey("x")).toBe(1)
		expect((dict:keyAtIndex(1))).toBe("x")
	end)
end)

describe("keys / values / pairs", function()
	it("returns keys in order", function()
		local dict = build("a", "b", "c")
		expect(dict:keys()).toEqual({ "a", "b", "c" })
	end)

	it("returns values in order", function()
		local dict = build("a", "b", "c")
		expect(dict:values()).toEqual({ "a-value", "b-value", "c-value" })
	end)

	it("returns key/value pairs in order", function()
		local dict = build("a", "b")
		expect(dict:pairs()).toEqual({
			{ key = "a", value = "a-value" },
			{ key = "b", value = "b-value" },
		})
	end)
end)

describe("sort", function()
	it("reorders entries by the comparator", function()
		local dict = build("c", "a", "b")
		dict:sort(function(left: { key: string, value: string }, right: { key: string, value: string })
			return left.key < right.key
		end)

		expect(dict:keys()).toEqual({ "a", "b", "c" })
		expect(dict:indexAtKey("a")).toBe(1)
		expect(dict:indexAtKey("c")).toBe(3)
	end)

	it("keeps each key associated with its own value", function()
		local dict = build("c", "a", "b")
		dict:sort(function(left: { key: string, value: string }, right: { key: string, value: string })
			return left.key < right.key
		end)

		expect(dict:get("a")).toBe("a-value")
		expect(dict:get("b")).toBe("b-value")
		expect(dict:get("c")).toBe("c-value")
	end)
end)
