PriorityQueue2 = {}

function PriorityQueue2.new(cmp)
	local pq = setmetatable({}, {
		__index = {
			push = function(self, p, v)
				local q = self[p]
				if not q then
					q = {first = 1, last = 0}
					self[p] = q
				end
				q.last = q.last + 1
				q[q.last] = v
			end,

			pop = function(self)
				for p, q in pairs(self) do
					if q.first <= q.last then
						local v = q[q.first]
						q[q.first] = nil
						q.first = q.first + 1
						return p, v
					else
						self[p] = nil
					end
				end
			end,
		}
	})


	return pq
end

return PriorityQueue2