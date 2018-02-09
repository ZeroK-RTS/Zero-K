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

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Unit Behaviour'
options = {
	keepTarget = {
		name = "Keep overridden attack target",
		type = "bool",
		value = true,
		desc = "Units with an attack command will proritize their target until a canceling command is given.",
		noHotkey = true,
	},
	removeTarget = {
		name = "Stop clears target",
		type = "bool",
		value = true,
		desc = "Issuing the commands Stop, Fight, Guard, Patrol and Attack cancel priority target orders.",
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local keepTargetDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	keepTargetDefs[i] = not (ud.isBomber or ud.isFactory or ud.customParams.reallyabomber)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function isValidUnit(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and Spring.ValidUnitID(unitID) then
		return keepTargetDefs[unitDefID]
	end
	return false
end

local TargetKeepingCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_RAW_BUILD] = true,
	[CMD_JUMP] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[CMD_AREA_MEX] = true,
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

function widget:CommandNotify(id, params, cmdOptions)
	if TargetKeepingCommand[id] and options.keepTarget.value then
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]
			if isValidUnit(unitID) then
				local cmd = Spring.GetCommandQueue(unitID, 1)
				if cmd and #cmd ~= 0 and cmd[1].id == CMD.ATTACK and #cmd[1].params == 1 and not cmd[1].options.internal then
					Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, cmd[1].params, CMD.OPT_INTERNAL)
				end
			end
		end
	elseif TargetCancelingCommand[id] and options.removeTarget.value then
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]
			Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,0)
		end
	end
	return false
end

function widget:UnitCommandNotify(unitID, cmdID, cmdParams, cmdOpts)
	if TargetKeepingCommand[cmdID] and options.keepTarget.value then
		if isValidUnit(unitID) then
			local cmd = Spring.GetCommandQueue(unitID, 1)
			if cmd and #cmd ~= 0 and cmd[1].id == CMD.ATTACK and #cmd[1].params == 1 and not cmd[1].options.internal then
				Spring.GiveOrderToUnit(unitID, CMD_UNIT_SET_TARGET, cmd[1].params, CMD.OPT_INTERNAL)
			end
		end
	elseif TargetCancelingCommand[cmdID] and options.removeTarget.value then
		Spring.GiveOrderToUnit(unitID, CMD_UNIT_CANCEL_TARGET,cmdParams, 0)
	end
	return false
end
