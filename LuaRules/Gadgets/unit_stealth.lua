
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:GetInfo()
	return {
		name      = "UnitStealth",
		desc      = "Adds passive unit stealth capability",
		author    = "Sprung",
		date      = "2016-12-15",
		license   = "PD",
		layer     = 0,
		enabled   = true,
	}
end

-- Invisible units are draw with radar wobble offset in prior engine versions
local FIX_FADE_WOBBLE = not Script.IsEngineMinVersion(2025, 6, 8)

local spSetUnitStealth = Spring.SetUnitStealth
local spSetUnitSonarStealth = Spring.SetUnitSonarStealth

local unitErrorParams = {}
local nextSet = false

local innateStealthCache = {}
local allyTeams = Spring.GetAllyTeamList()

local function HasInnateStealth(unitDefID)
	if not unitDefID then
		return false
	end
	if not innateStealthCache[unitDefID] then
		local hasStealth = UnitDefs[unitDefID].stealth
		innateStealthCache[unitDefID] = (hasStealth and 1) or 0
	end
	return innateStealthCache[unitDefID] == 1
end

function gadget:UnitCreated(unitID, unitDefID)
	if HasInnateStealth(unitDefID) then
		spSetUnitStealth(unitID, true)
		for i = 1, #allyTeams do
			Spring.SetUnitLosMask(unitID, allyTeams[i], 2)
		end
	end
end

function gadget:GameFrame()
	if not nextSet then
		return
	end
	for i = 1, #nextSet do
		local unitID = nextSet[i]
		if Spring.ValidUnitID(unitID) then
			if not unitErrorParams[unitID] then
				local a, b, c, d, e, f = Spring.GetUnitPosErrorParams(unitID)
				unitErrorParams[unitID] = {a, b, c, d, e, f}
			end
			Spring.SetUnitPosErrorParams(unitID, 0, 0, 0, 0, 0, 0)
		end
	end
	nextSet = false
end

function gadget:UnitCloaked(unitID)
	if FIX_FADE_WOBBLE then
		nextSet = nextSet or {}
		nextSet[#nextSet + 1] = unitID
	end
	if not HasInnateStealth(unitDefID) then
		spSetUnitStealth(unitID, true)
	end
	spSetUnitSonarStealth(unitID, true)
end

function gadget:UnitDecloaked(unitID, unitDefID)
	if FIX_FADE_WOBBLE then
		if unitErrorParams[unitID] then
			local p = unitErrorParams[unitID]
			Spring.SetUnitPosErrorParams(unitID, p[1], p[2], p[3], p[4], p[5], p[6])
			unitErrorParams[unitID] = nil
		end
	end
	if not HasInnateStealth(unitDefID) then
		spSetUnitStealth(unitID, false)
	end
	spSetUnitSonarStealth(unitID, false)
end

function gadget:UnitDestroyed(unitID)
	unitErrorParams[unitID] = nil
end
