local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

local HeatmapHandler = {}

function HeatmapHandler.CreateHeatmap(minSquareSize)

	local HEATSQUARE_MIN_SIZE = minSquareSize

	local HEAT_SIZE_X = ceil(MAP_WIDTH/HEATSQUARE_MIN_SIZE)
	local HEAT_SIZE_Z = ceil(MAP_HEIGHT/HEATSQUARE_MIN_SIZE)

	local HEAT_SQUARE_SIZE = max(MAP_WIDTH/HEAT_SIZE_X, MAP_HEIGHT/HEAT_SIZE_Z)
	
	local heatmap = {}
	
	-- Internal Functions
	local function WorldToArray(x,z)
		local i,j
		if x < 0 then
			i = 0
		elseif x >= MAP_WIDTH then
			i = HEAT_SIZE_X
		else
			i = floor(x/HEAT_SQUARE_SIZE)
		end
		if z < 0 then
			j = 0
		elseif z >= MAP_HEIGHT then
			j = HEAT_SIZE_Z
		else
			j = floor(z/HEAT_SQUARE_SIZE)
		end
		return i, j
	end

	local function ArrayToWorld(i,j) -- gets midpoint
		return (i+0.5)*HEAT_SQUARE_SIZE, (j+0.5)*HEAT_SQUARE_SIZE
	end

	local function AddHeatToArray(i, j, amount)
		if not heatmap[i] then
			heatmap[i] = {}
		end
		if not heatmap[i][j] then
			heatmap[i][j] = {
				value = amount,
			}
		else
			heatmap[i][j].value = heatmap[i][j].value + amount
			if heatmap[i][j].value < 0 then
				heatmap[i][j] = nil
			end
		end
	end

	local function RemoveHeatFromArray(i, j, amount)
		if heatmap[i] and heatmap[i][j] then
			heatmap[i][j].value = max(heatmap[i][j].value - amount, 0)
		end
	end
	
	-- Extermal Functions
	function AddHeatCircle(x, z, radius, amount)
		local aX, aZ = WorldToArray(x,z)
		local aRadius = ceil(radius/HEAT_SQUARE_SIZE)
		
		local radiusSq = radius^2
		
		local jStart = max(aZ - aRadius, 0)
		local iBound = min(aX + aRadius, HEAT_SIZE_X)
		local jBound = min(aZ + aRadius, HEAT_SIZE_Z)
		local i = max(aX - aRadius, 0)
		while i <= iBound do
			local squareX = (i+0.5)*HEAT_SQUARE_SIZE
			local xDisSq = (squareX - x)^2
			local j = jStart
			while j <= jBound do
				local wx, wz = ArrayToWorld(i,j)
				local squareZ = (j+0.5)*HEAT_SQUARE_SIZE
				local disSq = xDisSq + (squareZ - z)^2
				if disSq < radiusSq then
					AddHeatToArray(i, j, amount)
				end
				j = j + 1
			end
			i = i + 1
		end
		
	end

	function RemoveHeatCircle(x, z, radius, amount)
		AddHeatCircle(x, z, radius, -amount)
	end
	
	function GetValueByIndex(x, z)
		return (heatmap[x] and heatmap[x][z] and heatmap[x][z].value) or 0
	end
	
	local newHeatmap = {
		heatmap = heatmap,
		GetValueByIndex = GetValueByIndex,
		AddHeatCircle = AddHeatCircle,
		RemoveHeatCircle = RemoveHeatCircle,
	}
	
	return newHeatmap
end

return HeatmapHandler