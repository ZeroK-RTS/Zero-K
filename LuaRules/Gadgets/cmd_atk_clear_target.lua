if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
  return {
	name 	= "Clear target on attack",
	desc	= "Attack commands will clear the current target.",
	author	= "Klon",
	date	= "4 Jul 2015",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = true,
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local AttackCommand = {
	[CMD.ATTACK] = true,	
	[CMD.AREA_ATTACK] =true, 
	--[CMD.DGUN] = true, --could be useful to avoid unit wonkyness but people may want to preserve their target and hit something else with dgun
}	

local COMMANDOPTIONS_SHIFT_BIT = 32

-- any attack that gets accepted into the queue will trigger. empty circle attacks etc. will not
function gadget:UnitCommand(unitID, unitDefID, teamID, id, options, params, tag)
	if AttackCommand[id] then
		if math.bit_and(options, COMMANDOPTIONS_SHIFT_BIT) == COMMANDOPTIONS_SHIFT_BIT then
			Spring.GiveOrderToUnit(unitID,CMD_QUEUE_CANCEL_TARGET_MARKER,params,COMMANDOPTIONS_SHIFT_BIT)
		else			
			Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,0) 
		end
	end
end	

function gadget:CommandFallback(unitID, unitDefID, unitTeam, id, params, options, tag)
	if id == CMD_QUEUE_CANCEL_TARGET_MARKER then
		Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,0) 		
		return {true, true}
	end
	return false
end