--[[
remaining issues:
- some things that should keep or remove target don't: building things, cloaking?, ... setting target when attacking would fix part of this
- doesn't work with queues, needs synched
- empty area commands trigger can trigger set/remove, but shouldnt. (because this runs in CommandNotify(), where these arent filtered out yet)
--]]

function widget:GetInfo()
  return {
    name      = "Keep Target",
    desc      = "Simple and slowest usage of target on the move",
    author    = "Google Frog, Klon",
    date      = "29 Sep 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Unit Behaviour'
options_order = {'keepTarget', 'keepTargetBombers', 'removeTarget'}
options = {
	keepTarget = {
		name = "Prioritise overridden attack target",
		type = "bool",
		value = true,
		desc = "Cancelling an attack command by issuing a movement command continues prioritising the target of the previous attack command.",
		noHotkey = true,
	},
	keepTargetBombers = {
		name = "Prioritise overridden attack for bombers",
		type = "bool",
		value = false,
		desc = "Also enables the behaviour of 'Prioritise overridden attack target' for bombers and Blastwing.",
		noHotkey = true,
	},
	removeTarget = {
		name = "Stop clears target",
		type = "bool",
		value = true,
		desc = "Target prioritisation is reset by Stop, Fight, Guard, Patrol and Attack commands.",
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local keepTargetDefs = {}
local isFactory = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	keepTargetDefs[i] = not (ud.isBomberAirUnit or ud.isFactory or ud.customParams.reallyabomber or ud.customParams.avoid_sticky_keep_target)
	isFactory[i] = ud.isFactory
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function isValidUnit(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and Spring.ValidUnitID(unitID) then
		if options.keepTargetBombers.value then
			return not isFactory[unitDefID]
		end
		return keepTargetDefs[unitDefID]
	end
	return false
end

local TargetIssuingCommand = {
	[CMD.ATTACK] = true,
}

local SUC = Spring.Utilities.CMD
local TargetKeepingCommand = {
	[CMD.MOVE] = true,
	[SUC.RAW_MOVE] = true,
	[SUC.RAW_BUILD] = true,
	[SUC.JUMP] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[SUC.AREA_MEX] = true,
	[SUC.AREA_TERRA_MEX] = true,
	[CMD.LOAD_UNITS] = true,
	[CMD.UNLOAD_UNITS] = true,
	[CMD.LOAD_ONTO] = true,
	[CMD.UNLOAD_UNIT] = true,
}

local TargetCancelingCommand = {
	[CMD.STOP] = true,
	[CMD.ATTACK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.FIGHT] = true,
	[CMD.GUARD] = true,
	[CMD.PATROL] = true,
}

local orderParamTable = {0}
local CMD_OPT_INTERNAL = CMD.OPT_INTERNAL
local CMD_OPT_CTRL     = CMD.OPT_CTRL
local CMD_UNIT_SET_TARGET    = SUC.UNIT_SET_TARGET
local CMD_UNIT_CANCEL_TARGET = SUC.UNIT_CANCEL_TARGET
function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if TargetKeepingCommand[cmdID] and options.keepTarget.value then
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]
			if isValidUnit(unitID) then
				local currCmdID, cmdOpts, _, cmdParam1, cmdParam2 = Spring.GetUnitCurrentCommand(unitID)
				if currCmdID == CMD.ATTACK and not cmdParam2 and (cmdOpts % (2*CMD_OPT_INTERNAL) < CMD_OPT_INTERNAL) and (cmdOpts % (2*CMD_OPT_CTRL) < CMD_OPT_CTRL) then
					orderParamTable[1] = cmdParam1
					Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, orderParamTable, CMD_OPT_INTERNAL)
				end
			end
		end
	elseif TargetIssuingCommand[cmdID] and options.keepTarget.value and (not cmdOptions.shift and not cmdOptions.ctrl) and cmdParams and #cmdParams == 1 then
		local units = Spring.GetSelectedUnits()
		orderParamTable[1] = cmdParams[1]
		for i = 1, #units do
			local unitID = units[i]
			if isValidUnit(unitID) then
				Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, orderParamTable, CMD_OPT_INTERNAL)
			end
		end
		--Spring.GiveOrderToUnitArray(units, CMD_UNIT_SET_TARGET, orderParamTable, CMD_OPT_INTERNAL)
	elseif TargetCancelingCommand[cmdID] and options.removeTarget.value and not (cmdOptions and cmdOptions.shift) then
		local units = Spring.GetSelectedUnits()
		Spring.GiveOrderToUnitArray(units, CMD_UNIT_CANCEL_TARGET, cmdParams, 0)
	end
	return false
end

function widget:UnitCommandNotify(unitID, cmdID, cmdParams, cmdOpts)
	if TargetKeepingCommand[cmdID] and options.keepTarget.value then
		if isValidUnit(unitID) then
			local currCmdID, currCmdOpts, _, cmdParam1, cmdParam2 = Spring.GetUnitCurrentCommand(unitID)
			if currCmdID == CMD.ATTACK and not cmdParam2 and (currCmdOpts % (2*CMD_OPT_INTERNAL) < CMD_OPT_INTERNAL) then
				orderParamTable[1] = cmdParam1
				Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, orderParamTable, CMD_OPT_INTERNAL)
			end
		end
	elseif TargetIssuingCommand[cmdID] and options.keepTarget.value and (not (cmdOptions and cmdOptions.shift)) and cmdParams and #cmdParams == 1 then
		if isValidUnit(unitID) then
			orderParamTable[1] = cmdParams[1]
			Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, orderParamTable, CMD_OPT_INTERNAL)
		end
	elseif TargetCancelingCommand[cmdID] and options.removeTarget.value then
		Spring.GiveOrderToUnit(unitID, CMD_UNIT_CANCEL_TARGET, cmdParams, 0)
	end
	return false
end
