function widget:GetInfo()
  return {
	name 	= "Auto Target",
	desc	= "Units preserve their targets when moving, stop cancels.",
	author	= "Klon",
	date	= "13 Jul 2015",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = true,
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local AttackCommand = {
	[CMD.ATTACK] = true,	
	[CMD.AREA_ATTACK] =true,
}	

local AutoTargetCancelingCommand = {
	[CMD.STOP] = true,
	[CMD.GUARD] = true,	
}

local AlwaysCancelingCommand = {
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
}


local unitHasManualTarget = {}

local function isValidUnit(unitID, unitDefID)	
	if Spring.ValidUnitID(unitID) then
		local ud = UnitDefs[unitDefID]
		return ud and not (ud.isBomber or ud.isFactory)
	end
	return false
end

function widget:UnitCommand(unitID, unitDefID, teamID, id, options, params, tag)		
	if math.bit_and(options,CMD.OPT_INTERNAL) == CMD.OPT_INTERNAL then return end
	local opt = math.bit_or(options,CMD.OPT_RIGHT+CMD.OPT_INTERNAL)
	
	if isValidUnit(unitID, unitDefID) then
		if AttackCommand[id] then -- attack always overrides target		
			Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,opt)
		-- should check for existing target here to avoid giving unnecessary order but thats in gadget space
		-- also preserving target through fight makes little sense, as jitter will occur
		elseif AutoTargetCancelingCommand[id] and unitHasManualTarget[unitID] == nil then 
			Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,opt)
		elseif AlwaysCancelingCommand[id] then
		Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,opt)
		end			
	end
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, id, cmdTag, cmdParams, cmdOpts)
	
	if id == CMD_UNIT_SET_TARGET or id == CMD_UNIT_SET_TARGET_CIRCLE then		
		if cmdOpts.right then unitHasManualTarget[unitID] = nil			
		else unitHasManualTarget[unitID] = true
		end
	elseif id == CMD_UNIT_CANCEL_TARGET then unitHasManualTarget[unitID] = nil	
	end		
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if unitHasManualTarget[unitID] == true then unitHasManualTarget[unitID] = nil end
end
