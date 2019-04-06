--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Show Shooter",
		desc     = "Reveals a unit if it shoots its weapon while in air LOS.",
		author	 = "Google Frog",
		date     = "28 October 2015",
		license	 = "GNU GPL, v2 or later",
		layer    = 0,
		enabled  = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local ALLYTEAM_COUNT = #(Spring.GetAllyTeamList()) - 1 -- Because allyTeams start at 0
local SLOW_UPDATE = 15

local STATIC_SHOW_TIME = 10 -- 5 seconds
local MOBILE_SHOW_TIME = 4.5 -- 2.5 seconds

local fakeWeapons = {}   -- WeaponDefs which are for hax.
local staticWeapons = {} -- WeaponDefs which are on turrets.
local noDecloakWeapons = {[WeaponDefNames["cloaksnipe_shockrifle"].id] = true}

for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.name:find("bogus") or wd.name:find("fake") then
		fakeWeapons[i] = true
	end
end

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isImmobile and ud.weapons then
		for j = 1, #ud.weapons do
			staticWeapons[ud.weapons[j].weaponDef] = true
		end
	end
end

-- These are the units which have been revealed and are waiting to be re-hidden
local revealedUnits = {}

for i = 0, ALLYTEAM_COUNT do
	revealedUnits[i] = {}
end

-- Units which have already had their reveal state checked since last slow update.
local firedUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Checks for whether a fired unit should be revealed

local function CheckUnitRevealAllyTeam(unitID, x, z, allyTeamID, weaponID)
	-- Position check is used because there is no concept of a unit being "in air LOS".
	-- A unit is either revealed or not revealed.
	local aLos = Spring.IsPosInAirLos(x, 0, z, allyTeamID)
	local los = Spring.IsPosInLos(x, 0, z, allyTeamID)
	
	-- Don't reveal units which are already in LOS. Waste of time to do so.
	if aLos and not los then
		if noDecloakWeapons[weaponID] and Spring.GetUnitIsCloaked(unitID) then
			return
		end
		revealedUnits[allyTeamID][unitID] = staticWeapons[weaponID] and STATIC_SHOW_TIME or MOBILE_SHOW_TIME
		Spring.SetUnitLosMask(unitID, allyTeamID, 15)  -- Prevents engine slow update from modifying state.
		Spring.SetUnitLosState(unitID, allyTeamID, 15) -- Sets the unit to be fully visible.
	end
end

local function CheckUnitRevealing(unitID, weaponID)
	if not Spring.ValidUnitID(unitID) then
		return
	end
	local unitAllyTeamID = Spring.GetUnitAllyTeam(unitID)
	local x,_,z = Spring.GetUnitPosition(unitID)
	
	-- Check each allyTeam individually for FFA purposes.
	for allyTeamID = 0, ALLYTEAM_COUNT do
		if unitAllyTeamID ~= allyTeamID then
			CheckUnitRevealAllyTeam(unitID, x, z, allyTeamID, weaponID)		
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Projectile creation method of checking unit firing

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if proOwnerID and not firedUnits[proOwnerID] and not fakeWeapons[weaponID] then
		CheckUnitRevealing(proOwnerID, weaponID)
		firedUnits[proOwnerID] = true -- Do not check the unit again until the next slow update.
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Updates

local function RevealedUnitTimeout(n)
	if n%SLOW_UPDATE == 0 then
		for allyTeamID = 0, ALLYTEAM_COUNT do
			for unitID, data in pairs(revealedUnits[allyTeamID]) do
				if data > 1 then
					revealedUnits[allyTeamID][unitID] = data - 1
				else
					Spring.SetUnitLosMask(unitID, allyTeamID, 0) -- Releasing mask reverts LOS to engine control.
					revealedUnits[allyTeamID][unitID] = nil
				end
			end
		end
	end
end

local function ClearFiredUnits(n)
	if n%SLOW_UPDATE == 1 then
		firedUnits = {}
	end
end

function gadget:GameFrame(n)
	ClearFiredUnits(n)
	RevealedUnitTimeout(n)
end

-- TODO Replace SetWatchProjectile with a notifier in LUS.Shot or LUS.BlockShot. Perhaps this could be added to unit_script.lua.
function gadget:Initialize()
	for weaponID,wd in pairs(WeaponDefs) do
		if wd.customParams and wd.customParams.is_unit_weapon then
			if Script.SetWatchProjectile then
				Script.SetWatchProjectile(weaponID, true)
			else
				Script.SetWatchWeapon(weaponID, true)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------