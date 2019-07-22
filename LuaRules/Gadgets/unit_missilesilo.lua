--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "Missile Silo Controller",
		desc      = "Handles missile silos",
		author    = "KingRaptor (L.J. Lim)",
		date      = "31 August 2010",
		license   = "Public domain",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

local SAVE_FILE = "Gadgets/unit_missilesilo.lua"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID = Spring.GetUnitDefID

local MISSILES_PER_SILO = 4

local siloDefID = UnitDefNames.staticmissilesilo.id
local missileDefIDs = {
	[UnitDefNames.tacnuke.id] = true,
	[UnitDefNames.napalmmissile.id] = true,
	[UnitDefNames.empmissile.id] = true,
	[UnitDefNames.seismic.id] = true,
}

local silos = {} -- [siloUnitID] = {[1] = missileID1, [3] = missileID3, ...}
local missileParents = {} -- [missileUnitID] = siloUnitID
local missilesToDestroy
local missilesToTransfer = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetSiloEntry(unitID)
	return silos[unitID]
end

local function GetFirstEmptyPad(unitID)
	if not silos[unitID] then
		return nil
	end
	for i = 1, MISSILES_PER_SILO do
		if silos[unitID][i] == nil then
			return i
		end
	end
	return nil
end

local function DestroyMissile(unitID, unitDefID)
	gadget:UnitDestroyed(unitID, unitDefID)
end

local function SetSiloPadNum(siloID, padNum)
	local env = Spring.UnitScript.GetScriptEnv(siloID)
	Spring.UnitScript.CallAsUnit(siloID, env.SetPadNum, padNum)
end

-- this makes sure the object references are up to date
local function UpdateSaveReferences()
	_G.missileSiloSaveTable = {
		silos = silos,
		missileParents = missileParents,
		missilesToDestroy = missilesToDestroy,
		missilesToTransfer = missilesToTransfer
	}
end
UpdateSaveReferences()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:Initialize()
	GG.MissileSilo = {
		GetSiloEntry = GetSiloEntry,
		GetFirstEmptyPad = GetFirstEmptyPad,
		DestroyMissile = DestroyMissile
	}
	
	-- partial /luarules reload support
	-- it'll lose track of any missiles already built (meaning you can stack new missiles on them, and they don't die when the silo does)
	if Spring.GetGameFrame() > 1 then
		local unitList = Spring.GetAllUnits()
		for i, v in pairs(unitList) do
			if spGetUnitDefID(v) == siloDefID then
				silos[v] = {}
			end
		end
	end
end

function gadget:Shutdown()
	GG.MissileSilo = nil
end

function gadget:GameFrame(n)
	if missilesToDestroy then
		for i = 1, #missilesToDestroy do
			if missilesToDestroy[i] and Spring.ValidUnitID(missilesToDestroy[i]) then
				Spring.DestroyUnit(missilesToDestroy[i], true)
			end
		end
		missilesToDestroy = nil
	end

	for uid, team in pairs(missilesToTransfer) do
		Spring.TransferUnit(uid, team, false)
		missilesToTransfer[uid] = nil
	end
end

-- check if the silo has a free pad we can use
function gadget:AllowUnitCreation(udefID, builderID)
	if (spGetUnitDefID(builderID) ~= siloDefID) then return true end
	local firstPad = GetFirstEmptyPad(builderID)
	if firstPad ~= nil then
		SetSiloPadNum(builderID, firstPad)
		return true
	end
	return false
end

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	if unitDefID == siloDefID then
		local missiles = GetSiloEntry(unitID)
		for index, missileID in pairs(missiles) do
			missilesToTransfer[missileID] = newTeam
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	-- silo destroyed
	if unitDefID == siloDefID then
		local missiles = GetSiloEntry(unitID)
		missilesToDestroy = missilesToDestroy or {}
		for index, missileID in pairs(missiles) do
			missilesToDestroy[#missilesToDestroy + 1] = missileID
		end
	-- missile destroyed
	elseif missileDefIDs[unitDefID] then
		local parent = missileParents[unitID]
		if parent then
			local siloEntry = GetSiloEntry(parent)
			if siloEntry then
				for i = 1, MISSILES_PER_SILO do
					if siloEntry[i] == unitID then
						siloEntry[i] = nil
						break
					end
				end
			end
		end
		missileParents[unitID] = nil
	end
end



function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitDefID == siloDefID then
		silos[unitID] = {}
	elseif silos[builderID] then
		Spring.SetUnitBlocking(unitID, false, false) -- non-blocking, non-collide (try to prevent pad detonations)
		Spring.SetUnitRulesParam(unitID, "missile_parentSilo", builderID)
		local spawnedFrame = (Spring.GetGameRulesParam("totalSaveGameFrame") or 0) + Spring.GetGameFrame()
		Spring.SetUnitRulesParam(unitID, "missile_spawnedFrame", spawnedFrame)
	end
end

--add newly finished missile to silo data
--this doesn't check half-built missiles, but there's actually no need to
function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	if facDefID == siloDefID then
		missileParents[unitID] = facID
		-- get the pad the missile was built on from unit script, to make sure there's no discrepancy
		local env = Spring.UnitScript.GetScriptEnv(facID)
		if env then
			local pad = Spring.UnitScript.CallAsUnit(facID, env.GetPadNum)
			silos[facID][pad] = unitID
		end
	end
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Missile Silo", SAVE_FILE) or {}
	
	missileParents = GG.SaveLoad.GetNewUnitIDKeys(loadData.missileParents or {})
	missileParents = GG.SaveLoad.GetNewUnitIDValues(missileParents)
	
	missilesToDestroy = GG.SaveLoad.GetNewUnitIDValues(loadData.missilesToDestroy or {})
	missilesToTransfer = GG.SaveLoad.GetNewUnitIDValues(loadData.missilesToTransfer or {})
	
	silos = GG.SaveLoad.GetNewUnitIDKeys(loadData.silos or {})
	for siloID, missiles in pairs(silos) do
		for i = 1, MISSILES_PER_SILO do
			if missiles[i] ~= nil then
				missiles[i] = GG.SaveLoad.GetNewUnitID(missiles[i])
				Spring.SetUnitRulesParam(missiles[i], "missile_parentSilo", siloID)
			end
		end
		SetSiloPadNum(siloID, GetFirstEmptyPad(siloID))
	end
	
	UpdateSaveReferences()
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, Spring.Utilities.MakeRealTable(SYNCED.missileSiloSaveTable, "Missile silo"))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
