--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Synced LOD",
		desc      = "Sets GG flags for other parts of synced luarules to reduce performance cost.",
		author    = "GoogleFrog",
		date      = "19 November 2022",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local unitCount = 0

local LOD_MED_THRESHOLD = 800

function gadget:GameFrame(n)
	if n%400 == 0 then
		GG.lodLevelMedium = (unitCount > LOD_MED_THRESHOLD)
	end
end

-- This is probably faster than asking for a giant table of units every X frames just to count them?
function gadget:UnitCreated(unitID, unitDefID, teamID)
	unitCount = unitCount + 1
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	unitCount = unitCount - 1
end

function gadget:Initialize()
	GG.lodLevelMedium = false
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		gadget:UnitCreated(allUnits[i], Spring.GetUnitDefID(allUnits[i]))
	end
	GG.lodLevelMedium = (unitCount > LOD_MED_THRESHOLD)
end
