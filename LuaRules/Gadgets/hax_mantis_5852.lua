--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo() 
	return {
		name      = "Mantis 5852",
		desc      = "Workaround https://springrts.com/mantis/view.php?id=5852",
		author    = "GoogleFrog",
		date      = "11 December 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = not Spring.Utilities.IsCurrentVersionNewerThan(104, 92),
	} 
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Configuration

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local holdPositionUnits = IterableMap.New()

local CMD_ATTACK        = CMD.ATTACK
local spGetUnitStates   = Spring.GetUnitStates
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitLosState = Spring.GetUnitLosState
local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange

local UPDATE_PERIOD = 15
local RANGE_LEEWAY  = 5

-- Units aim from pieces, not their midpoints.
local bonusDefs = {
	spidercrabe = 12
}
local exceptions = {
	spidercrabe = true
}

local heightBonus = {}
local mobileLandSeaOrGunship = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local movetype = Spring.Utilities.getMovetype(ud)
	if (not exceptions[ud.name]) and (movetype == 1 or movetype == 2) then -- Gunship, land or sea.
		mobileLandSeaOrGunship[i] = true
		if bonusDefs[ud.name] then
			heightBonus[i] = bonusDefs[ud.name]
		end
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Utilities

local function GetTargetPositions(targetID)
	local _, by, _, _, _, _, ax, ay, az = spGetUnitPosition(targetID, true, true)
	return by, ax, ay, az
end

local function GetTargetPositionWithWobble(targetID, data)
	local visibility = spGetUnitLosState(targetID, data.allyTeamID, false)
	if visibility.radar and not visibility.los then
		return CallAsTeam(data.teamID, GetTargetPositions, targetID)
	end
	return GetTargetPositions(targetID)
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Periodic Checking

local function ValidTargetID(targetID)
	if not targetID or not Spring.ValidUnitID(targetID) then
		return false
	end
	-- I could disable handling against turrets but Spring does not move units close enough
	-- when they have ballistic trajectories shooting up a hill.
	local unitDefID = Spring.GetUnitDefID(targetID)
	return unitDefID and mobileLandSeaOrGunship[unitDefID]
end

local function CheckMoveGoalUpdate(unitID, data)
	if data.needInit then
		local weaponNum = Spring.GetUnitRulesParam(unitID, "primary_weapon_range")
		if weaponNum then
			data.weaponNumOverride = weaponNum
		end
		data.needInit = nil
	end
	
	local states = spGetUnitStates(unitID)
	if (not states) then
		return true -- remove
	end
	if (states.movestate ~= 0) then
		return
	end
	
	local cQueue = spGetCommandQueue(unitID, 1)
	if (not cQueue) then
		return true -- remove
	end
	if not (cQueue[1] and cQueue[1].id == CMD_ATTACK and #cQueue[1].params == 1) then
		return
	end
	
	local targetID = cQueue[1].params[1]
	if not ValidTargetID(targetID) then
		return
	end
	local by, ax, ay, az = GetTargetPositionWithWobble(targetID, data)
	local _, _, _, ux, uy, uz = spGetUnitPosition(unitID, true)
	
	if not (ax and ux) then
		return
	end
	local x, y, z = ax - ux, ay - uy - (heightBonus[data.unitDefID] or 0), az - uz
	
	if data.oldX == x and data.oldY == y and data.oldZ == z then
		return
	end
	
	data.oldX, data.oldY, data.oldZ = x, y, z
	local range = GetEffectiveWeaponRange(data.unitDefID, -y, data.weaponNumOverride)
	--Spring.Echo("range", range, math.sqrt(x^2 + z^2))
	if range and (x^2 + z^2 < (range - RANGE_LEEWAY)^2) then
		return
	end
	Spring.SetUnitMoveGoal(unitID, ax, by, az, range - RANGE_LEEWAY)
end

function gadget:GameFrame(n)
	if n%UPDATE_PERIOD ~= 0 then
		return
	end
	holdPositionUnits.Apply(CheckMoveGoalUpdate)
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Handler

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if mobileLandSeaOrGunship[unitDefID] then
		holdPositionUnits.Add(unitID, 
			{
				unitDefID = unitDefID,
				needInit = true,
				teamID = teamID,
				allyTeamID = Spring.GetUnitAllyTeam(unitID),
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	holdPositionUnits.Remove(unitID)
end

-- note: Taken comes before Given
function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeamID)
	local data = holdPositionUnits.Get(unitID)
	if data then
		data.teamID = newTeam
		data.allyTeamID = Spring.GetUnitAllyTeam(unitID) or data.allyTeamID
	end
end

function gadget:Initialize()
	Spring.Echo("Hax Mantis 5852 Enabled") -- Intentional
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end
