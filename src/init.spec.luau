--!strict

local function generateAlphabet(length: number)
	local alphabet = {}
	for i = 1, math.min(length, 26) do
		table.insert(alphabet, string.char(97 + i - 1))
	end
	return alphabet
end

local ALPHABET = table.freeze(generateAlphabet(26))

return function()
	local OrderedDictionary = require(script.Parent)

	describe(".new()", function()
		it("should :iterate()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			expect(orderedDict:getLength()).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict:iterate() do
				count = count + 1
				expect(i).to.equal(count)
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should provide :keys()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local keys = orderedDict:keys()

			expect(#keys).to.equal(#ALPHABET)

			for i, key in keys do
				expect(key).to.equal(ALPHABET[i])
			end
		end)

		it("should provide :values()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local values = orderedDict:values()

			expect(#values).to.equal(#ALPHABET)

			for i, value in values do
				expect(value).to.equal(i)
			end
		end)

		it("should provide :pairs()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local pairs = orderedDict:pairs()

			expect(#pairs).to.equal(#ALPHABET)

			for i, pair in pairs do
				expect(pair.key).to.equal(ALPHABET[i])
				expect(pair.value).to.equal(i)
			end
		end)

		it("should :getLength()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			expect(orderedDict:getLength()).to.equal(#ALPHABET)
		end)

		it("should :get()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local middle = math.ceil(#ALPHABET / 2)
			local letter = ALPHABET[middle]
			expect(orderedDict:get(letter)).to.equal(middle)
		end)

		it("should :set()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			expect(orderedDict:getLength()).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict:iterate() do
				count = count + 1
				expect(i).to.equal(count)
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should :popFront()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local k, v = orderedDict:popFront()
			expect(orderedDict:getLength()).to.equal(#ALPHABET - 1)
			expect(k).to.equal(ALPHABET[1])
			expect(v).to.equal(1)

			local count = 1
			for letter, i in orderedDict:iterate() do
				count = count + 1
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should :popBack()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local k, v = orderedDict:popBack()
			expect(orderedDict:getLength()).to.equal(#ALPHABET - 1)
			expect(k).to.equal(ALPHABET[#ALPHABET])
			expect(v).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict:iterate() do
				count = count + 1
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should :moveToFront()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			orderedDict:moveToFront("d")
			expect(orderedDict.root.next.key).to.equal("d")
		end)

		it("should :moveToBack()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			orderedDict:moveToBack("d")
			expect(orderedDict.root.prev.key).to.equal("d")
		end)

		it("should :clone()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			local copy = orderedDict:clone()

			expect(orderedDict:getLength()).to.equal(copy:getLength())

			for letter, _i in orderedDict:iterate() do
				expect(orderedDict:get(letter)).to.equal(copy:get(letter))
			end
		end)

		it("should :clear()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			orderedDict:clear()
			expect(orderedDict:getLength()).to.equal(0)
		end)

		it("should :sort()", function()
			local orderedDict = OrderedDictionary.new()

			for i, letter in ALPHABET do
				orderedDict:set(letter, i)
			end

			orderedDict:sort(function(a, b)
				return string.byte(a.key) > string.byte(b.key)
			end)

			expect(orderedDict:getLength()).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict:iterate() do
				expect(letter).to.equal(ALPHABET[#ALPHABET - count])
				count = count + 1
			end
		end)
	end)

	describe(".meta()", function()
		it("should iterate", function()
			local orderedDict = OrderedDictionary.meta()

			for i, letter in ALPHABET do
				orderedDict[letter] = i
			end

			expect(#orderedDict).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict do
				count = count + 1
				expect(i).to.equal(count)
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should :getLength()", function()
			local orderedDict = OrderedDictionary.meta()

			for i, letter in ALPHABET do
				orderedDict[letter] = i
			end

			expect(#orderedDict).to.equal(#ALPHABET)
		end)

		it("should :get()", function()
			local orderedDict = OrderedDictionary.meta()

			for i, letter in ALPHABET do
				orderedDict[letter] = i
			end

			local middle = math.ceil(#ALPHABET / 2)
			local letter = ALPHABET[middle]
			expect(orderedDict[letter]).to.equal(middle)
		end)

		it("should :set()", function()
			local orderedDict = OrderedDictionary.meta()

			for i, letter in ALPHABET do
				orderedDict[letter] = i
			end

			expect(#orderedDict).to.equal(#ALPHABET)

			local count = 0
			for letter, i in orderedDict do
				count = count + 1
				expect(i).to.equal(count)
				expect(letter).to.equal(ALPHABET[count])
			end
		end)

		it("should return a non-meta object when called", function()
			local orderedDict = OrderedDictionary.meta()

			for i, letter in ALPHABET do
				orderedDict[letter] = i
			end

			local nonMeta = orderedDict()

			expect(nonMeta:getLength()).to.equal(#ALPHABET)

			local count = 0
			for letter, i in nonMeta:iterate() do
				count = count + 1
				expect(i).to.equal(count)
				expect(letter).to.equal(ALPHABET[count])
			end
		end)
	end)
end
