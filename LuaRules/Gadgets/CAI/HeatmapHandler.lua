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

local HeatmapHandler = {}

function HeatmapHandler.CreateHeatmap(minSquareSize, teamID)

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
	
	-- Heatmap Modifcation
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
	function AddHeatPoint(x, z, amount)
		local aX, aZ = WorldToArray(x,z)
		AddHeatToArray(aX, aZ, amount)
	end
	
	function RemoveHeatPoint(x, z, amount)
		AddHeatPoint(x, z, -amount)
	end
	
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
	
	-- External unit functions
	function AddUnitHeat(unitID,  x, z, radius, amount)
		AddUnit(unitID, x, z, radius, amount)
	end
	
	function ModifyUnitPosition(unitID,  x, z)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			local data = unitList[index]
			ModifyUnit(unitID, x, z, data.radius, data.amount)
		end
	end
	
	function RemoveUnitHeat(unitID)
		RemoveUnit(unitID)
	end
	
	function UpdateUnitPositions(removeUnseen)
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
	
	function GetValueByIndex(x, z)
		return (heatmap[x] and heatmap[x][z] and heatmap[x][z].value) or 0
	end
	
	local newHeatmap = {
		heatmap = heatmap,
		AddHeatPoint = AddHeatPoint,
		RemoveHeatPoint = RemoveHeatPoint,
		AddHeatCircle = AddHeatCircle,
		RemoveHeatCircle = RemoveHeatCircle,
		AddUnitHeat = AddUnitHeat,
		ModifyUnitPosition = ModifyUnitPosition,
		RemoveUnitHeat = RemoveUnitHeat,
		UpdateUnitPositions = UpdateUnitPositions,
		GetValueByIndex = GetValueByIndex,
	}
	
	return newHeatmap
end

return HeatmapHandler