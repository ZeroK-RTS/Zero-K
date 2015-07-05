if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
  return {
	name 	= "Automatic target setting/removal",
	desc	= "replaces cmd_keep_target widget",
	author	= "Klon",
	date	= "5 Jul 2015",
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
	[CMD.FIGHT] = true,
	[CMD.GUARD] = true,
	[CMD.PATROL] = true,
}

local OPTIONS_SHIFT = 32
local OPTIONS_RIGHT = 16 -- this is used as a tag for target commands issued by this widget. 
							-- target commands issued by the user cannot have it, ever(?)

local unitHasManualTarget = {}

local function isValidUnit(unitID, unitDefID)	
	if Spring.ValidUnitID(unitID) then
		local ud = UnitDefs[unitDefID]
		return ud and not (ud.isBomber or ud.isFactory)
	end
	return false
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, id, params, options, tag, synced)

	if not options.right then
		if id == CMD_UNIT_SET_TARGET or id == CMD_UNIT_SET_TARGET_CIRCLE then 
			unitHasManualTarget[unitID] = true 				
		elseif id == CMD_UNIT_CANCEL_TARGET then
			unitHasManualTarget[unitID] = nil		
		end
	end
	
	return true	
end

function gadget:UnitCommand(unitID, unitDefID, teamID, id, options, params, tag)	
	local shifted = math.bit_and(options,OPTIONS_SHIFT) == OPTIONS_SHIFT
	-- if cmd queue is empty, treat shifted commands as non-shifted (or else <GiveOrderToUnit() recursion is not permitted> may occur)	
	if shifted then
		local cmd = Spring.GetUnitCommands(unitID)
		if cmd == nil or #cmd==0 then shifted = false end
	end
	
	if AttackCommand[id] then -- attack always overrides target
		if isValidUnit(unitID, unitDefID) then 				
			if #params == 1 then -- if this an attack on a single unit, set target on it
				if shifted then
					Spring.GiveOrderToUnit(unitID,CMD_QUEUE_SET_TARGET_MARKER,params,OPTIONS_SHIFT)
				else 
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,OPTIONS_RIGHT)
					unitHasManualTarget[unitID] = nil					
				end
			else -- if this is an attack on ground, dont set target, but clear existing target
				if shifted then 					
					Spring.GiveOrderToUnit(unitID,CMD_QUEUE_CANCEL_TARGET_MARKER,params,OPTIONS_SHIFT)					
				else
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,OPTIONS_RIGHT)
					unitHasManualTarget[unitID] = nil	
				end			
			end
		end	
		
	elseif AutoTargetCancelingCommand[id] then -- these will all preserve manual target, because no reason not to
		if isValidUnit(unitID, unitDefID) then										
			if unitHasManualTarget[unitID] == nil then
				if shifted then					
					Spring.GiveOrderToUnit(unitID,CMD_QUEUE_CANCEL_TARGET_MARKER,params,OPTIONS_SHIFT)
				else
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,OPTIONS_RIGHT)
				end
			end
		end
	end			
end

-- shifted orders set a marker in the que which gets resolved here
function gadget:CommandFallback(unitID, unitDefID, unitTeam, id, params, options, tag)	
	if id == CMD_QUEUE_SET_TARGET_MARKER then		
		Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,OPTIONS_RIGHT) 		
		unitHasManualTarget[unitID] = nil
		return {true, true}	
	elseif id == CMD_QUEUE_CANCEL_TARGET_MARKER then
		Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,OPTIONS_RIGHT) 		
		unitHasManualTarget[unitID] = nil
		return {true, true}	
	end
	return false
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if unitHasManualTarget[unitID] == true then unitHasManualTarget[unitID] = nil end
end