--- Binary Heap
-- Taken from https://raw.githubusercontent.com/geoffleyland/lua-heaps/master/lua/binary_heap.lua


-- heap construction ---------------------------------------------------------
local BinHeap = {}


function BinHeap.new(cmp)

	local bh = setmetatable({}, {
		__index = {
			length = 0,
			cmp = cmp or function(a,b) return a < b end,

		peek = function(self)
			if self.length > 0 then
				return self[1].key, self[1].value
			end
			return nil
		end,

		empty = function(self)
			return self.length == 0
		end,

		push = function(self, k, v)
			local cmp = self.cmp

			-- float the new key up from the bottom of the heap
			self.length = self.length + 1
			local new_record = self[self.length]  -- keep the old table to save garbage
			local child_index = self.length
			while child_index > 1 do
				local parent_index = math.floor(child_index / 2)
				local parent_rec = self[parent_index]
				if cmp(k, parent_rec.key) then
					self[child_index] = parent_rec
				else
					break
				end
				child_index = parent_index
			end
			if new_record then
				new_record.key = k
				new_record.value = v
			else
				new_record = {key = k, value = v}
			end
				self[child_index] = new_record
		end,

		pop = function(self)
			if self:empty() then
				return nil
			end

			local cmp = self.cmp

			-- pop the top of the heap
			local result = self[1]

			-- push the last element in the heap down from the top
			local last = self[self.length]
			local last_key = (last and last.key) or nil
			-- keep the old record around to save on garbage
			self[self.length] = self[1]
			self.length = self.length - 1

			local parent_index = 1
			while parent_index * 2 <= self.length do
				local child_index = parent_index * 2
				if child_index+1 <= self.length and
					cmp(self[child_index+1].key, self[child_index].key) then
					child_index = child_index + 1
				end
				local child_rec = self[child_index]
				local child_key = child_rec.key
				if cmp(last_key, child_key) then
					break
				else
					self[parent_index] = child_rec
					parent_index = child_index
				end
			end
			self[parent_index] = last
			return result.key, result.value
		end,

		}
	})


	return bh
end

return BinHeap