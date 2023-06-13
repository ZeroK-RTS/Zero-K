--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Factory Parent Marker",
		desc      = "Adds a UnitRulesParam for parent factory.",
		author    = "GoogleFrog",
		date      = "19 November 2022",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local inFactory = {}

local ALLY_TABLE = {ally = true}

local factoryDefs = {}
for unitDefID, ud in pairs(UnitDefs) do
	if ud.isFactory and (not ud.customParams.notreallyafactory) and ud.buildOptions then
		factoryDefs[unitDefID] = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID then
		local builderDefID = Spring.GetUnitDefID(builderID)
		if factoryDefs[builderDefID] then
			inFactory[unitID] = true
			Spring.SetUnitRulesParam(unitID, "parentFactory", builderID, ALLY_TABLE)
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam, builderID)
	if inFactory[unitID] then
		inFactory[unitID] = nil
		Spring.SetUnitRulesParam(unitID, "parentFactory", nil, ALLY_TABLE)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

--------------------------------------------------------------------------------
