
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

local spSetUnitStealth = Spring.SetUnitStealth
local spSetUnitSonarStealth = Spring.SetUnitSonarStealth

local innateStealthCache = {}

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

function gadget:UnitCloaked(unitID)
	if not HasInnateStealth(unitDefID) then
		spSetUnitStealth(unitID, true)
	end
	spSetUnitSonarStealth(unitID, true)
end

function gadget:UnitDecloaked(unitID, unitDefID)
	if not HasInnateStealth(unitDefID) then
		spSetUnitStealth(unitID, false)
	end
	spSetUnitSonarStealth(unitID, false)
end
