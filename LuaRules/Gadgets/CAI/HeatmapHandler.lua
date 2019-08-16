--[[ Handles Heatmaps
 * Use this file to create a heatmap object with a square size.
 * Can add circles of heat or points.
 * Is able to track units by unitID and update the heatmap based
 on their position.
--]]

local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local abs = math.abs

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight

local HeatmapHandler = {}

function HeatmapHandler.CreateHeatmap(minSquareSize, teamID, allowNegativeValues, defaultValue)

	defaultValue = defaultValue or 0
	
	local HEATSQUARE_MIN_SIZE = minSquareSize
	
	local MODIFY_UNIT_THRESHOLD = 128

	local HEAT_SIZE_X = ceil(MAP_WIDTH/HEATSQUARE_MIN_SIZE)
	local HEAT_SIZE_Z = ceil(MAP_HEIGHT/HEATSQUARE_MIN_SIZE)

	local HEAT_SQUARE_SIZE = max(MAP_WIDTH/HEAT_SIZE_X, MAP_HEIGHT/HEAT_SIZE_Z)
	
	local heatmap = {}
	
	local unitMap = {}
	local unitList = {}
	local unitCount = 0
	local unitAmountSum = 0
	
	local heatmapWorldPosition = {}
	for i = 1, HEAT_SIZE_X do
		heatmapWorldPosition[i] = {}
		for j = 1, HEAT_SIZE_Z do
			heatmapWorldPosition[i][j] = {
				x = HEAT_SQUARE_SIZE*(i-0.5), z = HEAT_SQUARE_SIZE*(j-0.5)
			}
			heatmapWorldPosition[i][j].y = spGetGroundHeight(heatmapWorldPosition[i][j].x,heatmapWorldPosition[i][j].z)
		end
	end
	
	-- Internal local functions
	local function WorldToArray(x,z)
		local i,j
		if x < 0 then
			i = 1
		elseif x >= MAP_WIDTH then
			i = HEAT_SIZE_X
		else
			i = ceil(x/HEAT_SQUARE_SIZE)
		end
		if z < 0 then
			j = 1
		elseif z >= MAP_HEIGHT then
			j = HEAT_SIZE_Z
		else
			j = ceil(z/HEAT_SQUARE_SIZE)
		end
		return i, j
	end
	
	-- Heatmap Modification
	local function AddHeatToArray(i, j, amount)
		if not heatmap[i] then
			heatmap[i] = {}
		end
		if not heatmap[i][j] then
			heatmap[i][j] = {
				value = defaultValue + amount,
			}
		else
			heatmap[i][j].value = heatmap[i][j].value + amount
			if not allowNegativeValues and heatmap[i][j].value < 0 then
				heatmap[i][j].value = 0
			end
		end
	end
	
	local function SetHeatPointInArray(i, j, amount)
		if not heatmap[i] then
			heatmap[i] = {}
		end
		if not heatmap[i][j] then
			heatmap[i][j] = {
				value = amount,
			}
		else
			heatmap[i][j].value = amount
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

	-- External local functions
	local function ArrayToWorld(i,j) -- gets midpoint
		if heatmapWorldPosition[i] and heatmapWorldPosition[i][j] then
			return heatmapWorldPosition[i][j].x,  heatmapWorldPosition[i][j].y, heatmapWorldPosition[i][j].z
		end
		return (i-0.5)*HEAT_SQUARE_SIZE, (j-0.5)*HEAT_SQUARE_SIZE
	end
	
	local function AddHeatPoint(x, z, amount)
		local aX, aZ = WorldToArray(x,z)
		AddHeatToArray(aX, aZ, amount)
	end
	
	local function SetHeatPoint(x, z, amount)
		local aX, aZ = WorldToArray(x,z)
		SetHeatPointInArray(aX, aZ, amount)
	end
	
	local function SetHeatPointByIndex(aX, aZ, amount)
		SetHeatPointInArray(aX, aZ, amount)
	end
	
	local function RemoveHeatPoint(x, z, amount)
		AddHeatPoint(x, z, -amount)
	end
	
	local function AddHeatCircle(x, z, radius, amount)
		local aX, aZ = WorldToArray(x,z)
		local aRadius = ceil(radius/HEAT_SQUARE_SIZE)
		
		local radiusSq = radius^2
		
		local jStart = max(aZ - aRadius, 0)
		local iBound = min(aX + aRadius, HEAT_SIZE_X)
		local jBound = min(aZ + aRadius, HEAT_SIZE_Z)
		local i = max(aX - aRadius, 0)
		while i <= iBound do
			local squareX = (i-0.5)*HEAT_SQUARE_SIZE
			local xDisSq = (squareX - x)^2
			local j = jStart
			while j <= jBound do
				local wx, wz = ArrayToWorld(i,j)
				local squareZ = (j-0.5)*HEAT_SQUARE_SIZE
				local disSq = xDisSq + (squareZ - z)^2
				if disSq < radiusSq then
					AddHeatToArray(i, j, amount)
				end
				j = j + 1
			end
			i = i + 1
		end
		
	end

	local function RemoveHeatCircle(x, z, radius, amount)
		AddHeatCircle(x, z, radius, -amount)
	end
	
	-- Unit tracking
	local function ModifyUnit(unitID, x, z, radius, amount)
		if unitMap[unitID] then
			-- Do not modify if the change is small enough
			local index = unitMap[unitID]
			local data = unitList[index]
			
			if amount == data.amount and radius == data.radius and abs(data.x - x) < MODIFY_UNIT_THRESHOLD and abs(data.z - z) < MODIFY_UNIT_THRESHOLD then
				return
			end
			
			-- Remove old unit data from heatmap
			if data.radius then
				RemoveHeatCircle(data.x, data.z, data.radius, data.amount)
			else
				RemoveHeatPoint(data.x, data.z, data.amount)
			end
			unitAmountSum = unitAmountSum - data.amount
			
			-- Add unit to heatmap
			if radius then
				AddHeatCircle(x, z, radius, amount)
			else
				AddHeatPoint(x, z, amount)
			end
			unitAmountSum = unitAmountSum + amount
			
			-- Update entry
			unitList[index].x = x
			unitList[index].z = z
			unitList[index].radius = radius
			unitList[index].amount = amount
		end
	end
	
	local function AddUnit(unitID, x, z, radius, amount)
		if unitMap[unitID] then
			ModifyUnit(unitID, x, z, radius, amount)
			return
		end
		-- Add unit heat to heatmap
		if radius then
			AddHeatCircle(x, z, radius, amount)
		else
			AddHeatPoint(x, z, amount)
		end
		unitAmountSum = unitAmountSum + amount
		
		-- Add unit to list
		unitCount = unitCount + 1
		unitList[unitCount] = {
			unitID = unitID,
			x = x,
			z = z,
			radius = radius,
			amount = amount,
		}
		unitMap[unitID] = unitCount
	end
	
	local function RemoveUnit(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			local data = unitList[index]
			
			-- Remove unit from heatmap
			if data.radius then
				RemoveHeatCircle(data.x, data.z, data.radius, data.amount)
			else
				RemoveHeatPoint(data.x, data.z, data.amount)
			end
			unitAmountSum = unitAmountSum - data.amount
			
			-- Copy the end of the list to this index
			unitList[index] = unitList[unitCount]
			unitMap[unitList[index].unitID] = index
			
			-- Remove the end of the list
			unitList[unitCount] = nil
			unitCount = unitCount - 1
			unitMap[unitID] = nil
		end
	end
	
	-- External unit local functions
	local function AddUnitHeat(unitID,  x, z, radius, amount)
		AddUnit(unitID, x, z, radius, amount)
	end
	
	local function ModifyUnitPosition(unitID,  x, z)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			local data = unitList[index]
			ModifyUnit(unitID, x, z, data.radius, data.amount)
		end
	end
	
	local function RemoveUnitHeat(unitID)
		RemoveUnit(unitID)
	end
	
	local function UpdateUnitPositions(removeUnseen)
		CallAsTeam(teamID,
			function ()
				local i = 1
				while i <= unitCount do
					local data = unitList[i]
					local unitID = data.unitID
					local x, _, z = spGetUnitPosition(unitID)
					if x and z then
						ModifyUnit(unitID, x, z, data.radius, data.amount)
						i = i + 1
					elseif removeUnseen then
						RemoveUnit(unitID)
					else
						i = i + 1
					end
				end
			end
		)
	end
	
	-- Get particular vaules
	local function GetValueByIndex(x, z)
		return (heatmap[x] and heatmap[x][z] and heatmap[x][z].value) or defaultValue
	end
	
	local function Iterator()
		local i = 1
		local j = 0
		return function ()
			j = j + 1
			if j > HEAT_SIZE_Z then
				i = i + 1
				j = 1
				if i > HEAT_SIZE_X then
					return nil
				end
			end
			return i, j
		end
	end
	
	-- Return the accessible local functions
	local newHeatmap = {
		heatmap = heatmap, -- Heatmap is accessible for drawing
		HEAT_SIZE_X = HEAT_SIZE_X,
		HEAT_SIZE_Z = HEAT_SIZE_Z,
		ArrayToWorld = ArrayToWorld,
		AddHeatPoint = AddHeatPoint,
		SetHeatPoint = SetHeatPoint,
		SetHeatPointByIndex = SetHeatPointByIndex,
		RemoveHeatPoint = RemoveHeatPoint,
		AddHeatCircle = AddHeatCircle,
		RemoveHeatCircle = RemoveHeatCircle,
		AddUnitHeat = AddUnitHeat,
		ModifyUnitPosition = ModifyUnitPosition,
		RemoveUnitHeat = RemoveUnitHeat,
		UpdateUnitPositions = UpdateUnitPositions,
		GetValueByIndex = GetValueByIndex,
		DoForEachPoint = DoForEachPoint,
		Iterator = Iterator,
	}
	
	return newHeatmap
end

return HeatmapHandler
