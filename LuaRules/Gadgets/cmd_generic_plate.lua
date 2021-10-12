--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Generic Plate Command",
		desc      = "Implements CMD_BUILD_PLATE as a do-nothing command, behaviour is defined in LuaUI",
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
local spGetUnitDefID        = Spring.GetUnitDefID
local plateBuilder = {}
local plateParent = {}

local plateCmdDesc = {
	id      = CMD_BUILD_PLATE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'plate',
	cursor  = 'Plate',
	action  = 'buildplate',
	tooltip = 'Build Plate: Move cursor near factory to build matching plate'
}

local function PlaceBuilderInList(defList)
	for i = 1, #defList do
		local unitDefID = defList[i]
		if not plateParent[unitDefID] then
			local cp = UnitDefs[unitDefID].customParams
			if cp.parent_of_plate then
				plateBuilder[unitDefID] = 1
			else
				plateParent[unitDefID] = 0
			end
		end
		if plateBuilder[unitDefID] == 1 then
			return true
		end
	end
	return false
end

local function CanBuildFactoryPlate(unitDefID)
	if not plateBuilder[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local buildOptions = ud.buildOptions
		plateBuilder[unitDefID] = (PlaceBuilderInList(buildOptions) and 1) or 0
	end
	return (plateBuilder[unitDefID] == 1)
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_BUILD_PLATE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	return not (cmdID == CMD_BUILD_PLATE)
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
	gadgetHandler:RegisterCMDID(CMD_BUILD_PLATE)
end

else
----------------------------------
-------------Unsynced-------------
----------------------------------

function gadget:Initialize()
	Spring.AssignMouseCursor("Plate", "cursorplate", true, true)
end

end
