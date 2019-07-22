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

local nukeDefs = {
	[UnitDefNames["staticnuke"].id] = true,
}

local interceptorRanges = {
	[UnitDefNames["staticantinuke"].id] = 2500^2,
	--[UnitDefNames["reef"].id] = 1200^2,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

local function InCircle(x,y,radiusSq)
	return x*x + y*y <= radiusSq
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
	
	-- Translate projectile position to the origin.
	ux, uz, tx, tz, px, pz = ux - px, uz - pz, tx - px, tz - pz, 0, 0
	
	-- Get direction from projectile to target
	local tDir 
	if tx == 0 then
		if tz == 0 then
			return InCircle(ux, uy, radiusSq)
		elseif tz > 0 then
			tDir = math.pi/4
		else
			tDir = math.pi*3/4
		end
	elseif tx > 0 then
		tDir = math.atan(tz/tx)
	else
		tDir = math.atan(tz/tx) + math.pi
	end
	
	-- Rotate space such that direction from projectile to target is 0
	-- The nuke projectile will travel along the positive x-axis
	local cosDir = math.cos(-tDir)
	local sinDir = math.sin(-tDir)
	ux, uz = ux*cosDir - uz*sinDir, uz*cosDir + ux*sinDir
	tx, tz = tx*cosDir - tz*sinDir, tz*cosDir + tx*sinDir
	
	-- Find intersection of antinuke range with x-axis
	-- Quadratic formula, a = 1
	local b = -2*ux
	local c = ux^2 + uz^2 - radiusSq
	local determinate = b^2 - 4*c
	if determinate < 0 then
		-- No real solutions so the circle does not intersect x-axis.
		-- This means that antinuke projectile does not cross intercept
		-- range.
		return false
	end
	
	determinate = math.sqrt(determinate)
	local leftInt = (-b - determinate)/2
	local rightInt = (-b + determinate)/2
	
	--Spring.Echo(tDir*180/math.pi)
	--Spring.Echo("Unit X: " .. ux .. ", Unit Z: " .. uz)
	--Spring.Echo("Tar X: " .. tx .. ", Tar Z: " .. tz)
	--Spring.Echo("Left: " .. leftInt .. ", Right: " .. rightInt)
	
	-- IF the nuke does not fall short of coverage AND
	-- the projectile is still within coverage
	if leftInt < tx and rightInt > 0 then
		return true
	end
	return false
end

function gadget:Initialize()
	for wdid, wd in pairs(WeaponDefs) do
		if wd.interceptor > 0 and wd.coverageRange then
			if Script.SetWatchAllowTarget then
				Script.SetWatchAllowTarget(wdid, true)
			else
				Script.SetWatchWeapon(wdid, true)
			end
		end
	end
end
