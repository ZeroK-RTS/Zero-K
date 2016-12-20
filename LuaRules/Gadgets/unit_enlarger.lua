function gadget:GetInfo()
	return {
		name    = "Unit Enlarger",
		desc    = "Scales units physically and graphically",
		author  = "Rafal",
		date    = "May 2015",
		license = "GNU LGPL, v2.1 or later",
		layer   = 0,
		enabled = false
	}
end

--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------

CMD_DECREASE_SIZE = 33500
CMD_INCREASE_SIZE = 33501

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitTeam       = Spring.GetUnitTeam
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spSetUnitRulesParam = Spring.SetUnitRulesParam

local decreaseSizeCmdDesc = {
	id      = CMD_DECREASE_SIZE,
	name    = "Decrease size",
	action  = "decrease_size",
	type    = CMDTYPE.ICON,
	tooltip = "Decrease physical unit size",
}

local increaseSizeCmdDesc = {
	id      = CMD_INCREASE_SIZE,
	name    = "Increase size",
	action  = "increase_size",
	type    = CMDTYPE.ICON,
	tooltip = "Increase physical unit size",
}

local LOS_ACCESS = { inlos = true }

local unitData = {}

-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	--gadgetHandler:RegisterCMDID (CMD_DECREASE_SIZE)
	--gadgetHandler:RegisterCMDID (CMD_INCREASE_SIZE)

	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		local udID = spGetUnitDefID(unitID)
		local team = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, udID, team)
	end
end

function gadget:UnitCreated(unitID, unitDefID, team)
	--if UnitDefs[unitDefID].commander then
		--spInsertUnitCmdDesc(unitID, decreaseSizeCmdDesc)
		--spInsertUnitCmdDesc(unitID, increaseSizeCmdDesc)
	--end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitData[unitID] = nil
end

--[[
function gadget:AllowCommand_GetWantedCommand()
	return {
		[CMD_DECREASE_SIZE] = true,
		[CMD_INCREASE_SIZE] = true
	}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if (cmdID == CMD_DECREASE_SIZE or cmdID == CMD_INCREASE_SIZE) then
		if (not unitData[unitID]) then
			unitData[unitID] = { scale = 1.0 }
		end

		local data = unitData[unitID]
		local prevScale = data.scale

		if (cmdID == CMD_DECREASE_SIZE) then
			data.scale = prevScale - 0.2
		else
			data.scale = prevScale + 0.2
		end

		spSetUnitRulesParam( unitID, "physical_scale", data.scale, LOS_ACCESS )

		if (prevScale == 1.0) then
			SendToUnsynced( "Enlarger_SetUnitLuaDraw", unitID, true )
			--spurSetUnitLuaDraw (unitID, true);
		elseif (data.scale == 1.0) then
			--spurSetUnitLuaDraw (unitID, false);
		end

		return false
	end
	return true
end
]]

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

local spurSetUnitLuaDraw  = Spring.UnitRendering.SetUnitLuaDraw
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitPosition   = Spring.GetUnitPosition

local glTranslate = gl.Translate
local glScale     = gl.Scale

--------------------------------------------------------------------------------

local function SetUnitLuaDraw(_, unitID, enabled)
	spurSetUnitLuaDraw (unitID, enabled)
end

function gadget:Initialize()
	Spring.UnitRendering.SetUnitLuaDraw (1, true);
	gadgetHandler:AddSyncAction("Enlarger_SetUnitLuaDraw", SetUnitLuaDraw)
end

function gadget:Shutdown()
	gadgetHandler.RemoveSyncAction("Enlarger_SetUnitLuaDraw")
end


function gadget:DrawUnit(unitID, drawMode)
	local scale = spGetUnitRulesParam( unitID, "physical_scale" );

	if (scale and scale ~= 1.0) then
		local bx, by, bz = spGetUnitPosition(unitID)

		--glTranslate( -bx, -by, -bz )
		glScale( scale, scale, scale )
		--glTranslate( bx, by, bz )
	end

	return false
end

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
end
