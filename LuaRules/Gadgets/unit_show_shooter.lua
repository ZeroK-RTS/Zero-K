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

local revealedUnits = {}

for i = 0, ALLYTEAM_COUNT do
	revealedUnits[i] = {}
end

local fakeWeapons = {}
local staticWeapons = {}

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Checks for whether a fired unit should be revealed

local function CheckUnitRevealAllyTeam(unitID, x, z, allyTeamID, staticWeapon)
	local aLos = Spring.IsPosInAirLos(x, 0, z, allyTeamID)
	local los = Spring.IsPosInLos(x, 0, z, allyTeamID)
	if aLos and not los then
		revealedUnits[allyTeamID][unitID] = staticWeapon and 10 or 4 -- 5s for statics, 2s for mobiles
		Spring.SetUnitLosMask(unitID, allyTeamID, 15)
		Spring.SetUnitLosState(unitID, allyTeamID, 15)
	end
end

local function CheckUnitRevealing(unitID, staticWeapon)
	if not Spring.ValidUnitID(unitID) then
		return
	end
	local unitAllyTeamID = Spring.GetUnitAllyTeam(unitID)
	local x,_,z = Spring.GetUnitPosition(unitID)
	for allyTeamID = 0, ALLYTEAM_COUNT do
		if unitAllyTeamID ~= allyTeamID then
			CheckUnitRevealAllyTeam(unitID, x, z, allyTeamID, staticWeapon)		
		end
	end
end

local function HideUnits(n)
	if n%15 == 0 then
		for allyTeamID = 0, ALLYTEAM_COUNT do
			for unitID, data in pairs(revealedUnits[allyTeamID]) do
				if data > 1 then
					revealedUnits[allyTeamID][unitID] = data - 1
				else
					Spring.SetUnitLosMask(unitID, allyTeamID, 0)
					revealedUnits[allyTeamID][unitID] = nil
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Projectile creation method of checking unit firing

local firedUnits = {}

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if proOwnerID and not firedUnits[proOwnerID] and not fakeWeapons[weaponID] then
		CheckUnitRevealing(proOwnerID, staticWeapons[weaponID])
		firedUnits[proOwnerID] = true
	end
end

local function ClearFiredUnits(n)
	if n%15 == 1 then
		firedUnits = {}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reload time polling method of checking unit firing (WIP and probably pointless)
--
--local unitList = {}
--local unitCount = 0
--local unitMap = {}
--
--local listPos = 1
--
--local UPDATE_PERIOD = 10
--
--local function CheckUnitFiredRecently(unitID)
--	-- etc
--	--CheckUnitRevealing
--end
--
--local function IsUnitArmed(unitDefID)
--	return true
--end
--
--local function PollReloadTimes()
--	if unitCount == 0 then
--		return
--	end
--
--	for i = 1, math.max(unitCount/UPDATE_PERIOD) do
--		CheckUnitFiredRecently(unitList[listPos])
--		
--		listPos = listPos + 1
--		if listPos > unitCount then
--			listPos = 1
--		end
--	end
--end
--
--function gadget:UnitFinished(unitID, unitDefID)
--	if not IsUnitArmed(unitDefID) then
--		return
--	end
--	unitCount = unitCount + 1
--	unitList[unitCount] = unitID
--	unitMap[unitID] = unitCount
--end
--
--function gadget:UnitDestroyed(unitID)
--	if not unitMap[unitID] then
--		return
--	end
--	unitMap[unitList[unitCount]] = unitMap[unitID]
--	unitList[unitCount] = nil
--	unitMap[unitID] = nil
--	unitCount = unitCount - 1
--end
--
--function gadget:Initialize()
--	local units = Spring.GetAllUnits()
--	for i = 1, #units do
--		local udid = Spring.GetUnitDefID(units[i])
--		gadget:UnitCreated(units[i])
--	end
--end
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Shared callins

function gadget:GameFrame(n)
	--PollReloadTimes()
	ClearFiredUnits(n)
	HideUnits(n)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------