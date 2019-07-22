-- $Id: unit_nofriendlyfire.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Friendly Fire",
    desc      = "Adds the nofriendlyfire custom param",
    author    = "quantum",
    date      = "June 24, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -999,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local wantedWeaponList = {}

local noFFWeaponDefs = {}

--[[ Units can die before their projectiles hit, so to know whether a damage instance is friendly fire
     we need to read the teamID from the projectile. But again: projectiles with slow explosions can be
     cleaned up before the explosion finishes. Fortunately the old projectileID is still passed to the
     UnitPreDamaged callin which makes it possible to cache these values in ProjectileCreated and only
     remove them after the explosion is sure to have dissipated. ]]

local haxMAX_EXPLOSION_DURATION = 128 -- frames; magic value from engine source
local haxWeapons = {} -- [weaponDefID] = true
local haxProjectiles = {} -- [projID] = teamID
local haxCleanupNow,  haxCleanupNowCount  = {}, 0 -- { [index] = projID }
local haxCleanupNext, haxCleanupNextCount = {}, 0

for wdid = 1, #WeaponDefs do
	local wdcp = WeaponDefs[wdid].customParams
	if wdcp and wdcp.nofriendlyfire then
		noFFWeaponDefs[wdid] = true
		wantedWeaponList[#wantedWeaponList + 1] = wdid

		if wdcp.nofriendlyfire == "needs hax" then
			haxWeapons[wdid] = true
			if Script.SetWatchProjectile then
				Script.SetWatchProjectile(wdid, true)
			else
				Script.SetWatchWeapon(wdid, true)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied      = Spring.AreTeamsAllied
local spGetProjectileTeamID = Spring.GetProjectileTeamID
local spGetUnitHealth       = Spring.GetUnitHealth
local spSetUnitHealth       = Spring.SetUnitHealth

local DefensiveManeuverDefs = {
	[UnitDefNames["energysolar"].id] = true
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:ProjectileCreated(projID, unitID, weaponDefID)
	if not haxWeapons[weaponDefID] then
		return
	end
	haxProjectiles[projID] = spGetProjectileTeamID(projID)
end

function gadget:ProjectileDestroyed(projID)
	if not haxProjectiles[projID] then
		return
	end

	-- cannot cleanup immediately since the whole point is to
	-- access data after projectile has been cleaned up by engine
	haxCleanupNextCount = haxCleanupNextCount + 1
	haxCleanupNext[haxCleanupNextCount] = projID
end

function gadget:GameFrame(n)
	if n % haxMAX_EXPLOSION_DURATION ~= 0 then
		return
	end

	for i = 1, haxCleanupNowCount do
		haxProjectiles[haxCleanupNow[i]] = nil
	end

	local temp = haxCleanupNow
	haxCleanupNow = haxCleanupNext
	haxCleanupNext = temp
	haxCleanupNowCount = haxCleanupNextCount
	haxCleanupNextCount = 0
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam, projectileID)
	if weaponID and noFFWeaponDefs[weaponID] then
		attackerTeam = attackerTeam or haxProjectiles[projectileID]
		if not attackerTeam then
			Spring.Echo(" OUTLAWFHTAGN ") -- some unique string I can search infologs for to track the bug's existence (too trivial for LUA_ERRRUN)
			attackerTeam = unitTeam
		end
		if attackerID ~= unitID and spAreTeamsAllied(unitTeam, attackerTeam) then
			return 0, 0
		elseif unitDefID and DefensiveManeuverDefs[unitDefID] then
			local env = Spring.UnitScript.GetScriptEnv(unitID)
			if env then
				Spring.UnitScript.CallAsUnit(unitID,env.HitByWeaponGadget)
			end
		end
	end
  
	return damage
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
