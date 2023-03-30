if not gadgetHandler:IsSyncedCode() then
	return false
end

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

local spGetUnitDefID = Spring.GetUnitDefID

local MISSILES_PER_SILO = 4

local siloDefID = UnitDefNames.staticmissilesilo.id
local missileDefIDs = {
	[UnitDefNames.tacnuke.id] = true,
	[UnitDefNames.napalmmissile.id] = true,
	[UnitDefNames.empmissile.id] = true,
	[UnitDefNames.seismic.id] = true,
	[UnitDefNames.missileslow.id] = true,
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
		Spring.SetUnitRulesParam(unitID, "missile_spawnedFrame", Spring.GetGameFrame())
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
