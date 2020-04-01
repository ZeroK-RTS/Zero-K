--
-- Slight adaptation from:
-- https://gist.github.com/leegao/1074642
--
local insert = table.insert
local remove = table.remove

local PriorityQueueBroken = {}

function PriorityQueueBroken.new(cmp, initial)
    local pq = setmetatable({}, {
        __index = {
			cmp = cmp or function(a,b) return a < b end,
            push = function(self, v)
                insert(self, v)
                local next = #self
                local prev = (next-next%2)/2
                while next > 1 and cmp(self[next], self[prev]) do
                    self[next], self[prev] = self[prev], self[next]
                    next = prev
                    prev = (next-next%2)/2
                end
            end,
            pop = function(self)
                if #self < 2 then
                    return remove(self)
                end
                local root = 1
                local r = self[root]
                self[root] = remove(self)
                local size = #self
                if size > 1 then
                    local child = 2*root
                    while child <= size do
                        if cmp(self[child], self[root]) then
                            self[root], self[child] = self[child], self[root]
                            root = child
                        elseif child+1 <= size and cmp(self[child+1], self[root]) then
                            self[root], self[child+1] = self[child+1], self[root]
                            root = child+1
                        else
                            break
                        end
                        child = 2*root
                    end
                end
                return r
            end,
            peek = function(self)
                return self[1]
            end,
        }
    })

    for _,el in ipairs(initial or {}) do
        pq:push(el)
    end

    return pq
end

return PriorityQueueBroken