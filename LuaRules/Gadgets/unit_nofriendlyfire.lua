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
for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.customParams and wd.customParams.nofriendlyfire then
		noFFWeaponDefs[wdid] = true
		wantedWeaponList[#wantedWeaponList + 1] = wdid
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitHealth  = Spring.GetUnitHealth
local spSetUnitHealth  = Spring.SetUnitHealth

local DefensiveManeuverDefs = {
	[UnitDefNames["armsolar"].id] = true
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and noFFWeaponDefs[weaponID] then
		if attackerID ~= unitID and ((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam)) then
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
