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

local SlowAimStack = {}
local spGetUnitPosition    = Spring.GetUnitPosition
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetTeamUnits       = Spring.GetTeamUnits
local spGetUnitStates      = Spring.GetUnitStates
local spGetSpectatingState = Spring.GetSpectatingState
local CMD_STOP             = CMD.STOP
local CMD_ATTACK           = CMD.ATTACK

local StarlightUnitDefID = UnitDefNames["mahlazer"].id
local BerthaUnitDefID = UnitDefNames["staticheavyarty"].id
local DRPUnitDefID = UnitDefNames["raveparty"].id

local immobiles = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isImmobile then
		immobiles[unitDefID] = true
	end
end

local function sqdist(p, x, y, z)
	return (p[1]-x)^2 + (p[2]-y)^2 + (p[3]-z)^2
end

local function getTargetToClosest(targetPos, precise)
	if not targetPos then
		return
	end

	--[[ Theoretically the distance should be calculated using conical/angular distance
	     to the weapon's line of aim, but using just the closest unit achieves similar
	     results and has a better implementation. ]]
	local tx, tz = targetPos[1], targetPos[3]
	local nearUnits = Spring.GetUnitsInRectangle(tx-SEARCH_DIST, tz-SEARCH_DIST, tx+SEARCH_DIST, tz+SEARCH_DIST)
	local shortestDist = math.max
	local bestSol
	for k, v in pairs(nearUnits) do
		if not (Spring.IsUnitAllied(v)) and (not precise or Spring.IsUnitInLos(v) or immobiles[spGetUnitDefID(v)]) then
			local x,y,z = spGetUnitPosition(v)
			local dist = sqdist(targetPos, x, y, z)
			if dist < shortestDist then
				shortestDist = dist
				bestSol = v
			end
		end
	end
	return bestSol
end

local function newSlowAimer(unitID, prcs)
	SlowAimStack[unitID] = {
		unitID = unitID,
		pos = {spGetUnitPosition(unitID)},
		targetPos = nil,
		currentTarget = nil,
		precise = prcs
	}
end

local function updateSlowAimer(unitID)
	local currSlowAimer = SlowAimStack[unitID]
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = spGetUnitPosition(unitIDorPos)
		if currSlowAimer.currentTarget ~= unitIDorPos or not targetZ then
			if not isUserTarget then
				local newTarget = getTargetToClosest(currSlowAimer.targetPos, currSlowAimer.precise)
				if newTarget then
					local targetX, targetY, targetZ = spGetUnitPosition(newTarget)
					currSlowAimer.targetPos = {targetX, targetY, targetZ}
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
			currSlowAimer.targetPos = {targetX, targetY, targetZ}
		end
		currSlowAimer.currentTarget = unitIDorPos
	end
end

local function isSlowAimer(unitDefID)
	return (unitDefID == StarlightUnitDefID) or (unitDefID == BerthaUnitDefID) or (unitDefID == DRPUnitDefID)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if isSlowAimer(unitDefID)
		and unitTeam == spGetMyTeamID() then
			newSlowAimer(unitID, unitDefID == StarlightUnitDefID)
		end
end

function widget:UnitDestroyed(unitID) 
	if SlowAimStack[unitID] then
		SlowAimStack[unitID]=nil
		spGiveOrderToUnit(unitID,CMD_STOP, {}, 0)
	end
end

function widget:GameFrame(n) 
	-- Every frame updates are acceptable for units this big and rare
	--if (n%UPDATE_FRAME==0) then
		for unitID in pairs(SlowAimStack) do 
			updateSlowAimer(unitID)
		end
	--end
end

--- COMMAND HANDLING

function widget:Initialize()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
	DisableForSpec()
	--Spring.Echo("Starlight targetting loaded")
	local units = spGetTeamUnits(spGetMyTeamID())
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		if isSlowAimer(unitDefID) and not SlowAimStack[unitID] then
			newSlowAimer(unitID, unitDefID == StarlightUnitDefID)
		end
	end
end

function widget:PlayerChanged(playerID)
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
		return
	end
end
