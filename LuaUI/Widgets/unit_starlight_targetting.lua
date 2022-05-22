function widget:GetInfo()
	return {
		name    = "Starlight Targetting",
		desc    = "Slow-aiming superweapons prefer closer targets",
		author  = "dyth68",
		date    = "2022",
		license = "PD",
		layer   = 0,
		handler = true, -- for adding customCommand into UI
		enabled = true
	}
end


local UPDATE_FRAME = 2
local SEARCH_DIST = 2000

local slowAimStack = {}
local spGetUnitPosition    = Spring.GetUnitPosition
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetTeamUnits       = Spring.GetTeamUnits
local spGetUnitStates      = Spring.GetUnitStates
local spGetSpectatingState = Spring.GetSpectatingState
local CMD_STOP             = CMD.STOP
local CMD_ATTACK           = CMD.ATTACK

local myPlayerID = Spring.GetMyPlayerID()
local myTeamID   = Spring.GetMyTeamID()

local slowAimerDefs = {
	[UnitDefNames["mahlazer"].id] = true,
	[UnitDefNames["staticheavyarty"].id] = true,
	[UnitDefNames["raveparty"].id] = true,
}

local slowAimerPrecise = {
	[UnitDefNames["mahlazer"].id] = true
}

local immobiles = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isImmobile then
		immobiles[unitDefID] = true
	end
end

local function DistanceSq(p, x, y, z)
	return (p[1]-x)^2 + (p[2]-y)^2 + (p[3]-z)^2
end

local function GetTargetToClosest(slowAimer)
	if not targetPos then
		return false
	end

	local tX, tZ = slowAimer.tX, slowAimer.tZ
	local precise = slowAimer.precise
	
	-- Theoretically the distance should be calculated using conical/angular distance
	-- to the weapon's line of aim, but using just the closest unit achieves similar
	-- results and has a better implementation.
	local nearUnits = Spring.GetUnitsInRectangle(tx-SEARCH_DIST, tz-SEARCH_DIST, tx+SEARCH_DIST, tz+SEARCH_DIST)
	local bestSol, shortestDistSq = false, false
	for i = 1, #nearUnits do
		local targetID = nearUnits[i]
		if not (Spring.IsUnitAllied(nearUnits)) and (not precise or Spring.IsUnitInLos(nearUnits) or immobiles[spGetUnitDefID(nearUnits)]) then
			local x, y, z = spGetUnitPosition(nearUnits)
			local distSq = DistanceSq(targetPos, x, y, z)
			if (not shortestDistSq) or distSq < shortestDistSq then
				shortestDistSq = distSq
				bestSol = nearUnits
			end
		end
	end
	return bestSol
end

local function NewSlowAimer(unitID, precise)
	slowAimStack[unitID] = {
		unitID = unitID,
		currentTarget = nil,
		precise = precise
	}
end

local function UpdateSlowAimer(unitID)
	local currSlowAimer = slowAimStack[unitID]
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = spGetUnitPosition(unitIDorPos)
		if currSlowAimer.currentTarget ~= unitIDorPos or not targetZ then
			if not isUserTarget then
				local newTarget = GetTargetToClosest(currSlowAimer)
				if newTarget then
					local targetX, targetY, targetZ = spGetUnitPosition(newTarget)
					currSlowAimer.tX, currSlowAimer.tY, currSlowAimer.tZ = targetX, targetY, targetZ
					currSlowAimer.currentTarget = newTarget
					--Spring.Echo("trying set target")
					--Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
					spGiveOrderToUnit(unitID, CMD_ATTACK, newTarget, 0)
					--Spring.Echo("Set")
					return
				end
			end
		end
		if targetZ then
			currSlowAimer.tX, currSlowAimer.tY, currSlowAimer.tZ = targetX, targetY, targetZ
		end
		currSlowAimer.currentTarget = unitIDorPos
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if slowAimerDefs[unitDefID] and unitTeam == myTeamID then
		NewSlowAimer(unitID, slowAimerPrecise[unitDefID])
	end
end

function widget:UnitDestroyed(unitID) 
	if slowAimStack[unitID] then
		slowAimStack[unitID]=nil
		spGiveOrderToUnit(unitID,CMD_STOP, {}, 0)
	end
end

function widget:GameFrame(n) 
	-- Every frame updates are acceptable for units this big and rare
	--if (n%UPDATE_FRAME==0) then
		for unitID in pairs(slowAimStack) do 
			UpdateSlowAimer(unitID)
		end
	--end
end

--- COMMAND HANDLING

function widget:Initialize()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
	--Spring.Echo("Starlight targetting loaded")
	local units = spGetTeamUnits(Spring.GetMyTeamID())
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		if slowAimerDefs[unitDefID] and not slowAimStack[unitID] then
			NewSlowAimer(unitID, slowAimerPrecise[unitDefID])
		end
	end
end

function widget:PlayerChanged(playerID)
	if playerID ~= myPlayerID then
		return
	end
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
	myTeamID = Spring.GetMyTeamID()
end
