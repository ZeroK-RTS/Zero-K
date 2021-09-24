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
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitIsDead       = Spring.GetUnitIsDead

local constructors          = 0
local constructor           = {}
local constructorTable      = {}
local constructors          = 0


local exceptionArray = {
	[UnitDefNames["athena"].id] = true,
}
local plateCmdDesc = {
	id      = CMD_PLATE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'plate',
	cursor  = 'Plate',
	action  = 'plate',
	tooltip = 'Build a Plate of a nearby factory',
}

local wantedCommands = {
	[CMD_PLATE] = true,
}

function gadget:AllowCommand_GetWantedCommand()
	return wantedCommands
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

-- local function dump(o)
   -- if type(o) == 'table' then
      -- local s = '{ '
      -- for k,v in pairs(o) do
         -- if type(k) ~= 'number' then k = '"'..k..'"' end
         -- s = s .. '['..k..'] = ' .. dump(v) .. ','
      -- end
      -- return s .. '} '
   -- else
      -- return tostring(o)
   -- end
-- end

local plateUnitDefIDs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud and ud.isMobileBuilder and not ud.isFactory and not exceptionArray[i] then
		plateUnitDefIDs[i] = true
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	-- Don't allow non-constructors to queue terraform fallback.
	if not plateUnitDefIDs[unitDefID] then
		return false
	end
	return true
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if spGetUnitIsDead(unitID) then
		return
	end
	
	local ud = UnitDefs[unitDefID]
	-- add plate command to builders
	if plateUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, plateCmdDesc)
		local aTeam = spGetUnitAllyTeam(unitID)
		constructors = constructors + 1
		constructorTable[constructors] = unitID
		constructor[unitID]    = {allyTeam = aTeam, index = constructors}
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if constructor[unitID] then
		local index = constructor[unitID].index
		if index ~= constructors then
			constructorTable[index] = constructorTable[constructors]
		end
		constructorTable[constructors] = nil
		constructors = constructors - 1
		constructor[unitID]    = nil
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PLATE)
end

else
function gadget:Initialize()
	Spring.AssignMouseCursor("Plate", "cursorplate", true, true)
end
end