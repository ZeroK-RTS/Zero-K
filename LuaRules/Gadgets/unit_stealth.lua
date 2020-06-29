if not Script.GetSynced() then
	return
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

function gadget:UnitCloaked(unitID)
	spSetUnitStealth(unitID, true)
	spSetUnitSonarStealth(unitID, true)
end

function gadget:UnitDecloaked(unitID)
	spSetUnitStealth(unitID, false)
	spSetUnitSonarStealth(unitID, false)
end
