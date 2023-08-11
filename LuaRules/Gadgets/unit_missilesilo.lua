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

local siloDefs = {} -- [unitDefID] = default capacity

for unitDefID, unitDef in pairs(UnitDefs) do
	local capacity = unitDef.customParams.missile_silo_capacity
	if capacity then
		siloDefs[unitDefID] = tonumber(capacity)
	end
end

local silos = {} -- [siloUnitID] = { capacity = n, slots = {[1] = missileID1, [3] = missileID3, ...}}
local missileParents = {} -- [missileUnitID] = siloUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetSiloEntry(unitID)
	return silos[unitID]
end

local function GetFirstEmptyPad(unitID)
	local silo = silos[unitID]
	if not silo then
		return
	end

	local slots = silo.slots
	for i = 1, silo.capacity do
		if not slots[i] then
			return i
		end
	end
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
			local siloDef = siloDefs[spGetUnitDefID(v)]
			if siloDef then
				silos[v] = {capacity = siloDef, slots = {}}
			end
		end
	end
end

function gadget:Shutdown()
	GG.MissileSilo = nil
end

-- check if the silo has a free pad we can use
function gadget:AllowUnitCreation(udefID, builderID)
	if not siloDefs[spGetUnitDefID(builderID)] then
		return true
	end

	local firstPad = GetFirstEmptyPad(builderID)
	if firstPad ~= nil then
		SetSiloPadNum(builderID, firstPad)
		return true
	end
	return false, false
end

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	if siloDefs[unitDefID] then
		local missiles = GetSiloEntry(unitID).slots
		for index, missileID in pairs(missiles) do
			Spring.TransferUnit(missileID, newTeam, true)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	-- silo destroyed
	if siloDefs[unitDefID] then
		local missiles = GetSiloEntry(unitID).slots
		for index, missileID in pairs(missiles) do
			Spring.DestroyUnit(missileID, true)
		end
		return
	end

	-- missile destroyed
	local parent = missileParents[unitID]
	if parent then
		local siloEntry = GetSiloEntry(parent)
		if siloEntry then
			local slots = siloEntry.slots
			for i = 1, siloEntry.capacity do
				if slots[i] == unitID then
					slots[i] = nil
					break
				end
			end
		end
		missileParents[unitID] = nil
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	local siloDef = siloDefs[unitDefID]
	if siloDef then
		silos[unitID] = {capacity = siloDef, slots = {}}
	elseif silos[builderID] then
		Spring.SetUnitBlocking(unitID, false, false) -- non-blocking, non-collide (try to prevent pad detonations)
		Spring.SetUnitRulesParam(unitID, "missile_parentSilo", builderID)
		Spring.SetUnitRulesParam(unitID, "missile_spawnedFrame", Spring.GetGameFrame())
	end
end

--add newly finished missile to silo data
--this doesn't check half-built missiles, but there's actually no need to
function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	if siloDefs[facDefID] then
		missileParents[unitID] = facID
		-- get the pad the missile was built on from unit script, to make sure there's no discrepancy
		local env = Spring.UnitScript.GetScriptEnv(facID)
		if env then
			local pad = Spring.UnitScript.CallAsUnit(facID, env.GetPadNum)
			silos[facID].slots[pad] = unitID
		end
	end
end
