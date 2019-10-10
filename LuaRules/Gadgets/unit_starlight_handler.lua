--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Starlight Handler",
		desc = "Handle Starlight Satellite transfer and beam interruption",
		author = "Anarchid",
		date = "1.07.2016",
		license = "Public domain",
		layer = 21,
		enabled = true,
	}
end

local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spTransferUnit = Spring.TransferUnit

local transfers = {}
local alreadyAdded = false

GG.starlightSatelliteInvulnerable = GG.starlightSatelliteInvulnerable or {}
--local starlights = {}

local satelliteDefID = UnitDefNames["starlight_satellite"].id
local starlightDefID = UnitDefNames["mahlazer"].id
local starlightWeapons = {}
for i = 1, #UnitDefs[starlightDefID].weapons do
	local weaponDefID = UnitDefs[starlightDefID].weapons[i].weaponDef
	starlightWeapons[weaponDefID] = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Transfer handling

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	local satID = spGetUnitRulesParam(unitID, 'has_satellite')
	if not satID then
		return
	end

	transfers[satID] = newTeam
	if alreadyAdded then
		return
	end

	gadgetHandler:UpdateCallIn("GameFrame")
	alreadyAdded = true
end

function gadget:GameFrame(f)
	for satID, team in pairs(transfers) do
		spTransferUnit(satID, team, false)
		transfers[satID] = nil
	end
	alreadyAdded = false
	gadgetHandler:RemoveCallIn("GameFrame")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Beam block handling

function gadget:Explosion_GetWantedWeaponDef()
	local wantedList = {}
	for weaponDefID, _ in pairs(starlightWeapons) do
		wantedList[#wantedList + 1] = weaponDefID
	end
	return wantedList
end

function gadget:Explosion(weaponID, px, py, pz, ownerID, proID)
	if starlightWeapons[weaponID] and ownerID then
		GG.Starlight_DamageFrame[ownerID] = Spring.GetGameFrame()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if unitDefID == satelliteDefID and GG.starlightSatelliteInvulnerable[unitID] then
		return 0
	end
	return damage
end

function gadget:Initialize()
	if not alreadyAdded then
		gadgetHandler:RemoveCallIn("GameFrame")
	end
	
	--for _, unitID in pairs(Spring.GetAllUnits()) do
	--	gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	--end
	
	GG.Starlight_DamageFrame = {}
	local ud = UnitDefs[starlightDefID]
	
	for weaponDefID, _ in pairs(starlightWeapons) do
		Script.SetWatchExplosion(weaponDefID, true)
	end
end

function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID == satelliteDefID then
			Spring.DestroyUnit(unitID, false, true)
		end
	end
end
