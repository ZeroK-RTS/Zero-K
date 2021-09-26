--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Generic Plate Command",
		desc      = "Implements CMD_PLATE as a do-nothing command, behaviour is defined in LuaUI",
		author    = "DavetheBrave",
		date      = "23 September 2021",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedup
include("LuaRules/Configs/customcmds.h.lua")

if gadgetHandler:IsSyncedCode() then

local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitIsDead       = Spring.GetUnitIsDead
local spGetUnitDefID		= Spring.GetUnitDefID


local plateCmdDesc = {
	id      = CMD_PLATE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'plate',
	cursor  = 'Plate',
	action  = 'plate',
	tooltip = 'Build a Plate of a nearby factory',
}

local function CanBuildFactoryPlate(unitDefID)
	local ud = UnitDefs[unitDefID]
	local bo = ud.buildOptions
		for i = 1, #bo do
			local cp = UnitDefs[bo[i]].customParams
			if cp.parent_of_plate then
				return true
			end
		end
	return false
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if spGetUnitIsDead(unitID) then
		return
	end
	
	-- add plate command to builders
	if CanBuildFactoryPlate(unitDefID) then
		spInsertUnitCmdDesc(unitID, plateCmdDesc)
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PLATE)
end

else
----------------------------------
-------------Unsynced-------------
----------------------------------

function gadget:Initialize()
	Spring.AssignMouseCursor("Plate", "cursorplate", true, true)
end
end
