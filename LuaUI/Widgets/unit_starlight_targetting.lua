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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SEARCH_DIST = 2000

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local slowAimers = IterableMap.New()

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

local immobileDefs = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isImmobile or unitDef.customParams.like_structure then
		immobileDefs[unitDefID] = true
	end
end

local function DistanceSq(x1, y1, z1, x2, y2, z2)
	return (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetTargetToClosest(slowAimer)
	local tX, tY, tZ = slowAimer.tX, slowAimer.tY, slowAimer.tZ
	local precise = slowAimer.precise
	
	-- Theoretically the distance should be calculated using conical/angular distance
	-- to the weapon's line of aim, but using just the closest unit achieves similar
	-- results and has a better implementation.
	local nearUnits = Spring.GetUnitsInRectangle(tX - SEARCH_DIST, tZ - SEARCH_DIST, tX + SEARCH_DIST, tZ + SEARCH_DIST)
	local bestSol, shortestDistSq = false, false
	for i = 1, #nearUnits do
		local targetID = nearUnits[i]
		if not (Spring.IsUnitAllied(targetID)) and (not precise or Spring.IsUnitInLos(targetID) or immobileDefs[spGetUnitDefID(targetID)]) then
			local x, y, z = spGetUnitPosition(targetID)
			local distSq = DistanceSq(tX, tY, tZ, x, y, z)
			if (not shortestDistSq) or distSq < shortestDistSq then
				shortestDistSq = distSq
				bestSol = targetID
			end
		end
	end
	return bestSol
end

local function UpdateSlowAimer(unitID, slowAimData)
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = spGetUnitPosition(unitIDorPos)
		if slowAimData.tX and (slowAimData.currentTarget ~= unitIDorPos or not targetZ) then
			if not isUserTarget then
				local newTarget = GetTargetToClosest(slowAimData)
				if newTarget then
					local targetX, targetY, targetZ = spGetUnitPosition(newTarget)
					slowAimData.tX, slowAimData.tY, slowAimData.tZ = targetX, targetY, targetZ
					slowAimData.currentTarget = newTarget
					--Spring.Echo("trying set target")
					--Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
					spGiveOrderToUnit(unitID, CMD_ATTACK, newTarget, 0)
					--Spring.Echo("Set")
					return
				end
			end
		end
		if targetZ then
			slowAimData.tX, slowAimData.tY, slowAimData.tZ = targetX, targetY, targetZ
		end
		slowAimData.currentTarget = unitIDorPos
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if slowAimerDefs[unitDefID] and unitTeam == myTeamID then
		IterableMap.Add(slowAimers, unitID, 
			{
				precise = slowAimerPrecise[unitDefID]
			}
		)
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	if slowAimerDefs[unitDefID] then
		IterableMap.Remove(slowAimers, unitID)
	end
end

function widget:GameFrame(n)
	IterableMap.Apply(slowAimers, UpdateSlowAimer)
end

local function InitialiseUnits()
	local units = spGetTeamUnits(myTeamID)
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		widget:UnitFinished(unitID, unitDefID, myTeamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:PlayerChanged(playerID)
	if playerID ~= myPlayerID then
		return
	end
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
	if myTeamID ~= Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		slowAimers = IterableMap.New()
		InitialiseUnits()
	end
end

function widget:Initialize()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
	--Spring.Echo("Starlight targetting loaded")
	InitialiseUnits()
end
