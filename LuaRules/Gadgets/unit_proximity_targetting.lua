
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name    = "Proximity Targetting",
		desc    = "Slow-aiming superweapons prefer targets closest to their most recent target.",
		author  = "dyth68, GoogleFrog",
		date    = "2022",
		license = "PD",
		layer   = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SEARCH_DIST = 2000

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local slowAimers = IterableMap.New()

local spGetUnitPosition       = Spring.GetUnitPosition
local spGiveOrderToUnit       = Spring.GiveOrderToUnit
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetUnitStates         = Spring.GetUnitStates
local spGetUnitAllyTeam       = Spring.GetUnitAllyTeam
local spGetUnitTeam           = Spring.GetUnitTeam
local spGetUnitLosState       = Spring.GetUnitLosState
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local CMD_STOP                = CMD.STOP
local CMD_ATTACK              = CMD.ATTACK

local slowAimerDefs = {}
local slowAimerPreciseDefs = {}
local immobileDefs = {}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.isImmobile or ud.customParams.like_structure then
		immobileDefs[unitDefID] = true
	end
	if ud.customParams.want_proximity_targetting then
		slowAimerDefs[unitDefID] = true
	end
	if ud.customParams.want_precise_proximity_targetting then
		slowAimerDefs[unitDefID] = true
		slowAimerPreciseDefs[unitDefID] = true
	end
end

local function DistanceSq(x1, y1, z1, x2, y2, z2)
	return (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetTargetToClosest(unitID, slowAimer)
	local tX, tY, tZ = slowAimer.tX, slowAimer.tY, slowAimer.tZ
	local precise = slowAimer.precise
	local aimerAllyTeam = spGetUnitAllyTeam(unitID)
	local aimerTeam = spGetUnitTeam(unitID)
	
	-- Theoretically the distance should be calculated using conical/angular distance
	-- to the weapon's line of aim, but using just the closest unit achieves similar
	-- results and has a better implementation.
	local nearUnits = Spring.GetUnitsInRectangle(tX - SEARCH_DIST, tZ - SEARCH_DIST, tX + SEARCH_DIST, tZ + SEARCH_DIST)
	local bestSol, nextBestSol, shortestDistSq, nextShortestDistSq = false, false, false, false
	for i = 1, #nearUnits do
		local targetID = nearUnits[i]
		if (spGetUnitAllyTeam(targetID) ~= aimerAllyTeam) then
			local losState = spGetUnitLosState(targetID, aimerAllyTeam, true)
			if (losState % 2 == 1) or ((not precise) and losState % 4 == 2) or (immobileDefs[spGetUnitDefID(targetID)] and losState >= 8) then
				if (not GG.baitPrevention_ChaffShootingBlock) or not GG.baitPrevention_ChaffShootingBlock(unitID, targetID) then
					local x, y, z = CallAsTeam(aimerTeam, spGetUnitPosition, targetID)
					local distSq = DistanceSq(tX, tY, tZ, x, y, z)
					if (not shortestDistSq) or distSq < shortestDistSq then
						nextBestSol = bestSol
						nextShortestDistSq = shortestDistSq
						
						bestSol = targetID
						shortestDistSq = distSq
					elseif (not nextShortestDistSq) or distSq < nextShortestDistSq then
						nextBestSol = targetID
						nextShortestDistSq = distSq
					end
				end
			end
		end
	end
	return bestSol, nextBestSol
end

local function ShouldFindNewTarget(unitID, slowAimData, isUserTarget, unitIDorPos, targetZ)
	if isUserTarget then
		return false
	end
	if not slowAimData.tX then
		return false
	end
	if not targetZ then
		return true
	end
	if slowAimData.currentTarget ~= unitIDorPos then
		return true
	end
	-- Discard the next closest target attack command when the primary target is dead. The next
	-- closest target attack command is just here to set Starlight aiming in the right direction
	-- for a few frames, in the common case.
	local cmdID, _, _, cmdParam_1, cmdParam_2 = spGetUnitCurrentCommand(unitID)
	return (cmdID == CMD_ATTACK and slowAimData.nextTarget == cmdParam_1 and not cmdParam_2)
end

local function UpdateSlowAimer(unitID, slowAimData)
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = spGetUnitPosition(unitIDorPos)
		if ShouldFindNewTarget(unitID, slowAimData, isUserTarget, unitIDorPos, targetZ) then
			local newTarget, nextClosestTarget = GetTargetToClosest(unitID, slowAimData)
			if newTarget then
				local targetX, targetY, targetZ = spGetUnitPosition(newTarget)
				slowAimData.tX, slowAimData.tY, slowAimData.tZ = targetX, targetY, targetZ
				slowAimData.currentTarget = newTarget
				--Spring.Echo("trying set target")
				--Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
				-- Issue attack command rather than set weapon target directly to communicate to player.
				spGiveOrderToUnit(unitID, CMD_ATTACK, newTarget, CMD.OPT_INTERNAL)
				if nextClosestTarget then
					-- Queues two attack commands to avoid the jitter
					-- that comes from waiting for a target to be acquired
					-- so it shows up in GetUnitWeaponTarget.
					spGiveOrderToUnit(unitID, CMD_ATTACK, nextClosestTarget, CMD.OPT_SHIFT + CMD.OPT_INTERNAL)
					slowAimData.nextTarget = nextClosestTarget
				end
				--Spring.Echo("Set")
				return
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

function gadget:UnitFinished(unitID, unitDefID)
	if slowAimerDefs[unitDefID] then
		IterableMap.Add(slowAimers, unitID, 
			{
				precise = slowAimerPreciseDefs[unitDefID]
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if slowAimerDefs[unitDefID] then
		IterableMap.Remove(slowAimers, unitID)
	end
end

function gadget:GameFrame(n)
	IterableMap.Apply(slowAimers, UpdateSlowAimer)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitFinished(unitID, unitDefID)
	end
end
