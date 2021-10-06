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
local defIDCache = {}

local plateCmdDesc = {
	id      = CMD_PLATE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'plate',
	cursor  = 'Plate',
	action  = 'plate',
	tooltip = 'Build a Plate of a nearby factory',
}

function addToSet(set, key)
    set[key] = true
end

function setContains(set, key)
    return set[key] ~= nil
end

local function CanBuildFactoryPlate(unitDefID)
	if not (setContains(defIDCache, {unitDefID, true}) or setContains(defIDCache, {unitDefID, false})) then
		local ud = UnitDefs[unitDefID]
		local bo = ud.buildOptions
			for i = 1, #bo do
				local cp = UnitDefs[bo[i]].customParams
				if cp.parent_of_plate then
					addToSet(defIDCache, {unitDefID, true})
					return true
				end
			end
		addToSet(defIDCache, {unitDefID, false})
		return false
	else
		if setContains(defIDCache, {unitDefID, true}) then
			return true
		else
			return false
		end
	end
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
