local Benchmark = {}

function Benchmark.new()
    local object = setmetatable({}, {
        __index = {
			timer = {},
			cumTime = {},
			num = {},

			Enter = function (self, name)
				--Spring.Echo("Entered", name)
				self.timer[name] = Spring.GetTimer()
			end,

			Leave = function (self, name)
				--Spring.Echo("Left", name)
				self.cumTime[name] = (self.cumTime[name] or 0) + Spring.DiffTimers(Spring.GetTimer(), self.timer[name] , true)
				self.num[name] = (self.num[name] or 0) + 1
			end,

			GetTotalTime = function (self, name)
				return self.cumTime[name] or nil
			end,

			GetAverageTime = function (self, name)
				if self.num[name] and self.num[name] > 0 then
					return self.cumTime[name] / self.num[name]
				end
				return nil
			end,

			PrintAllStat = function (self)
				Spring.Echo("##################################### Total Time (ms) #####################################")
				for name, _ in pairs(self.cumTime) do
					Spring.Echo(name.." <====> "..self:GetTotalTime(name))
				end
				Spring.Echo("##################################### Average Time (ms) #####################################")
				for name, _ in pairs(self.cumTime) do
					Spring.Echo(name.." <====> "..self:GetAverageTime(name))
				end
			end,
        }
    })

	return object
end

return Benchmark