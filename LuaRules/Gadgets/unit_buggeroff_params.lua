--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Buggeroff Params",
		desc      = "Puts Spring.SetFactoryBuggerOff in customParams.",
		author    = "GoogleFrog",
		date      = "26 November 2022",
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

local DEFAULT_RADIUS = 35
local DEFAULT_OFFSET = 35

DEFAULT_RADIUS = 35
DEFAULT_OFFSET = 35

local buggeroffDefs = {}
for unitDefID, ud in pairs(UnitDefs) do
	if ud.isFactory and (not ud.customParams.notreallyafactory) and ud.buildOptions then
		buggeroffDefs[unitDefID] = {
			radius = tonumber(ud.customParams.buggeroff_radius or DEFAULT_RADIUS) or DEFAULT_RADIUS,
			offset = tonumber(ud.customParams.buggeroff_offset or DEFAULT_OFFSET) or DEFAULT_OFFSET,
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if buggeroffDefs[unitDefID] then
		local def = buggeroffDefs[unitDefID]
		Spring.SetFactoryBuggerOff(unitID, true, def.offset, def.radius)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

--------------------------------------------------------------------------------
