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
local plateBuilder = {}
local plateParent = {}

local plateCmdDesc = {
	id      = CMD_PLATE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'plate',
	cursor  = 'Plate',
	action  = 'plate',
	tooltip = 'Build Plate: Move cursor near factory to build matching plate'
}

local function CanBuildFactoryPlate(unitDefID)
	if not plateBuilder[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local bo = ud.buildOptions
		plateBuilder[unitDefID] = 0
		for i = 1, #bo do
			local boDefID = bo[i]
			if not plateParent[boDefID] then
				local cp = UnitDefs[boDefID].customParams
				if cp.parent_of_plate then
					plateParent[boDefID] = 1
					plateBuilder[unitDefID] = 1
				else
					plateParent[boDefID] = 0
				end
			end
			if plateParent[boDefID] == 1 then
				plateBuilder[unitDefID] = 1
			end
		end
	end
	return (plateBuilder[unitDefID] == 1)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
		if spGetUnitIsDead(unitID) then
			return
		end

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
