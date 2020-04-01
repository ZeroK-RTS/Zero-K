--
-- Adapted from:
-- https://gist.githubusercontent.com/frnsys/6014eed30c69c6722177/raw/ec32813a900348cbb3ab60205921d70c60286ce3/optics.py
--
local PQ = VFS.Include("LuaUI/Widgets/libs/PriorityQueue.lua")

local function DistSq(p1, p2)
	return (p1.x - p2.x)^2 + (p1.z - p2.z)^2
end

local function TableEcho(data, name, indent, tableChecked)
	name = name or "TableEcho"
	indent = indent or ""
	if (not tableChecked) and type(data) ~= "table" then
		Spring.Echo(indent .. name, data)
		return
	end
	Spring.Echo(indent .. name .. " = {")
	local newIndent = indent .. "    "
	for name, v in pairs(data) do
		local nameStr = tostring(name)
		local ty = type(v)
		if ty == "table" then
			TableEcho(v, nameStr, newIndent, true)
		elseif ty == "boolean" then
			Spring.Echo(newIndent .. nameStr .. " = " .. (v and "true" or "false"))
		elseif ty == "string" or ty == "number" then
			Spring.Echo(newIndent .. nameStr .. " = " .. v)
		else
			Spring.Echo(newIndent .. nameStr .. " = ", v)
		end
	end
	Spring.Echo(indent .. "},")
end

local Optics = {}
function Optics.new(incPoints, incNeighborMatrix, incMinPoints, incBenchmark)
	if not incBenchmark then
		incBenchmark = {}
		incBenchmark.Enter = function (name) end
		incBenchmark.Leave = function (name) end
	end
	local object = setmetatable({}, {
		__index = {
			points = incPoints or {},
			neighborMatrix  = incNeighborMatrix or {},
			minPoints = incMinPoints,
			benchmark = incBenchmark,

			pointByfID = {},

			unprocessed = {},
			ordered = {},

			-- get ready for a clustering run
			_Setup = function(self)
				self.benchmark:Enter("Optics:_Setup")
				local points, unprocessed = self.points, self.unprocessed
				--Spring.Echo("epsSq", self.epsSq, "minPoints", self.minPoints)

				for pIdx, point in pairs(points) do
					point.rd = nil
					point.cd = nil
					point.processed = nil
					unprocessed[point] = true
					self.pointByfID[point.fID] = point
				end
				--TableEcho(points, "_Setup points")
				self.benchmark:Leave("Optics:_Setup")
			end,

			-- distance from a point to its nth neighbor (n = minPoints - 1)
			_CoreDistance = function(self, point, neighbors)
				self.benchmark:Enter("Optics:_CoreDistance")
				if point.cd then
					self.benchmark:Leave("Optics:_CoreDistance")
					return point.cd
				end

				if #neighbors >= self.minPoints - 1 then --(minPoints - 1) because point is also part of minPoints
					local distTable = {}
					for i = 1, #neighbors do
						local neighbor = neighbors[i]
						distTable[#distTable + 1] = DistSq(point, neighbor)
					end
					table.sort(distTable)
					--TableEcho({point=point, neighbors=neighbors, distTable=distTable}, "_CoreDistance (#neighbors >= self.minPoints - 1)")

					point.cd = distTable[self.minPoints - 1] --return (minPoints - 1) farthest distance as CoreDistance
					self.benchmark:Leave("Optics:_CoreDistance")
					return point.cd
				end
				self.benchmark:Leave("Optics:_CoreDistance")
				return nil
			end,

			-- neighbors for a point within eps
			_Neighbors = function(self, pIdx)
				self.benchmark:Enter("Optics:_Neighbors")
				local neighbors = {}

				for pIdx2, _ in pairs(self.neighborMatrix[pIdx]) do
					neighbors[#neighbors + 1] = self.pointByfID[pIdx2]
				end
				--Spring.Echo("#neighbors", #neighbors)

				self.benchmark:Leave("Optics:_Neighbors")
				return neighbors
			end,

			-- mark a point as processed
			_Processed = function(self, point)
				--Spring.Echo("_Processed")
				point.processed = true
				self.unprocessed[point] = nil

				local ordered = self.ordered
				ordered[#ordered + 1] = point
			end,

			-- update seeds if a smaller reachability distance is found
			_Update = function(self, neighbors, point, seedsPQ)
				self.benchmark:Enter("Optics:_Update")
				for ni = 1, #neighbors do
					local n = neighbors[ni]
					if not n.processed then
						--Spring.Echo("newRD")
						local newRd = math.max(point.cd, DistSq(point, n))
						if n.rd == nil then
							n.rd = newRd
							--this is a bug!!!!
							seedsPQ:push({newRd, n})
						elseif newRd < n.rd then
							--this is a bug!!!!
							n.rd = newRd
						end
					end
				end
				self.benchmark:Leave("Optics:_Update")
				--return seedsPQ
			end,

			-- run the OPTICS algorithm
			Run = function(self)
				self:_Setup()

				local unprocessed = self.unprocessed
				--TableEcho(unprocessed, "unprocessed")
				self.benchmark:Enter("Optics:Run Main Body")
				while next(unprocessed) do
					self.benchmark:Enter("Optics:Run (while next(unprocessed) do)")
					--TableEcho({item=next(unprocessed)}, "next(unprocessed)")
					local point = next(unprocessed)

					-- mark p as processed
					self:_Processed(point)

					-- find p's neighbors
					local neighbors = self:_Neighbors(point.fID)
					--TableEcho({point=point, neighbors=neighbors}, "self:_Neighbors(point)")
					--TableEcho({point=point, neighborsNum=#neighbors}, "self:_Neighbors(point)")

					-- if p has a core_distance, i.e has min_cluster_size - 1 neighbors
					if self:_CoreDistance(point, neighbors) then
						self.benchmark:Enter("Optics:Run (self:_CoreDistance(point, neighbors))")
						--Spring.Echo("if self:_CoreDistance(point, neighbors) then")
						local seedsPQ = PQ.new( function(a,b) return a[1] < b[1] end )
						--seedsPQ = self:_Update(neighbors, point, seedsPQ)
						self:_Update(neighbors, point, seedsPQ)
						while seedsPQ:peek() do
							self.benchmark:Enter("Optics:Run (while seedsPQ:peek() do)")
							-- seeds.sort(key=lambda n: n.rd)
							local n = seedsPQ:pop()[2] --because we don't need priority
							--TableEcho({n=n}, "seedsPQ:pop()")

							-- mark n as processed
							self:_Processed(n)

							-- find n's neighbors
							local nNeighbors = self:_Neighbors(n.fID)
							--TableEcho({n=n, nNeighbors=nNeighbors}, "seedsPQ:peek()")

							-- if p has a core_distance...
							if self:_CoreDistance(n, nNeighbors) then
								--seedsPQ = self:_Update(nNeighbors, n, seedsPQ)
								self:_Update(nNeighbors, n, seedsPQ)
							end
							self.benchmark:Leave("Optics:Run (while seedsPQ:peek() do)")
						end
						self.benchmark:Leave("Optics:Run (self:_CoreDistance(point, neighbors))")
					end
					self.benchmark:Leave("Optics:Run (while next(unprocessed) do)")
				end
				self.benchmark:Leave("Optics:Run Main Body")

				-- when all points have been processed
				-- return the ordered list
				--Spring.Echo("#ordered", #self.ordered)
				--TableEcho({ordered = self.ordered}, "ordered")
				return self.ordered
			end,

			-- ???
			Clusterize = function(self, clusterThreshold)
				local clusters = {}
				local separators = {}

				local clusterThresholdSq = clusterThreshold^2

				local ordered = self.ordered

				for i = 1, #ordered do
					local thisP = ordered[i]
					local thisRD = thisP.rd or math.huge

					-- use an upper limit to separate the clusters

					if thisRD > clusterThresholdSq then
						separators[#separators + 1] = i
					end
				end
				separators[#separators + 1] = #ordered + 1
				--TableEcho(separators,"separators")

				for j = 1, #separators - 1 do
					local sepStart = separators[j]
					local sepEnd = separators[j + 1]
					print(sepEnd, sepStart, sepEnd - sepStart, self.minPoints)
					if sepEnd - sepStart >= self.minPoints then
						--Spring.Echo("sepEnd - sepStart >= self.minPoints")
						--self.ordered[start:end]
						local clPoints = {}
						for si = sepStart, sepEnd - 1 do
							clPoints[#clPoints + 1] = ordered[si].fID
						end
					--	TableEcho({clPoints=clPoints}, "clPoints")

						clusters[#clusters + 1] = {}
						clusters[#clusters].members = clPoints
						--Spring.Echo("#clPoints", #clPoints)
					end
				end
				--TableEcho({ordered=ordered}, "clusters")
				return clusters
			end,
		}
	})
	return object
end

return Optics