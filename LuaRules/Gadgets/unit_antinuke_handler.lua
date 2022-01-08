--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Antinuke Handler",
    desc      = "Manages AllowWeaponInterceptTarget.",
    author    = "Google Frog",
    date      = "16 June, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local nukeDefs = {}

for unitDefID, ud in pairs(UnitDefs) do
	if ud.customParams.is_nuke then
		nukeDefs[unitDefID] = true
	end
end

local interceptorRanges = {}

for unitDefID, ud in pairs(UnitDefs) do
	if ud.customParams.nuke_coverage then
		interceptorRanges[unitDefID] = (ud.customParams.nuke_coverage)^2
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetNukeIntercepted = VFS.Include("LuaRules/Gadgets/Include/GetNukeIntercepted.lua")

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD.ATTACK] = true, [CMD.INSERT] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return nukeDefs
end

-- Allow command is to ensure that the target of the projectile is always a fixed location on the ground.
-- Otherwise Spring.GetProjectileTarget would not be able to get the attack location.
-- (or the location would have to be stored on projectile creation, I don't want to do that).
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if not nukeDefs[unitDefID] then
		return true
	end
	
	if cmdID == CMD.INSERT and cmdParams[2] == CMD.ATTACK and #cmdParams == 4 then
		-- Inserted attack command with 1 param is a unit target
		if Spring.ValidUnitID(cmdParams[4]) then
			local x,y,z = Spring.GetUnitPosition(cmdParams[4])
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {cmdParams[1], cmdParams[2], cmdParams[3], x, y, z}, cmdOptions.coded)
			return false
		end
	end
	
	if cmdID == CMD.ATTACK and #cmdParams == 1 then
		-- Attack command with 1 param is a unit target
		if Spring.ValidUnitID(cmdParams[1]) then
			local x,y,z = Spring.GetUnitPosition(cmdParams[1])
			Spring.GiveOrderToUnit(unitID, CMD.ATTACK, { x, y, z}, cmdOptions.coded)
			return false
		end
	end
	
	return true
end

function gadget:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponNum, targetProjectileID)
	
	local unitDefID = Spring.GetUnitDefID(interceptorUnitID)
	if not interceptorRanges[unitDefID] then
		return true
	end
	
	local targetType, targetData = Spring.GetProjectileTarget(targetProjectileID)
	if targetType ~= 103 then -- ASCII 'g' for ground
		-- Nukes are only allowed to target ground so if they are not something
		-- illegal is occuring. Safest to intercept them from across the map.
		return true
	end
	
	local radiusSq = interceptorRanges[unitDefID]
	
	-- Unit position, Projectile position, Target position
	local ux, _, uz = Spring.GetUnitPosition(interceptorUnitID)
	local px, _, pz = Spring.GetProjectilePosition(targetProjectileID)
	local tx, tz = targetData[1], targetData[3]
	
	return GetNukeIntercepted(ux, uz, px, pz, tx, tz, radiusSq)
end

function gadget:Initialize()
	for wdid, wd in pairs(WeaponDefs) do
		if wd.interceptor > 0 and wd.coverageRange then
			Script.SetWatchAllowTarget(wdid, true)
		end
	end
end
