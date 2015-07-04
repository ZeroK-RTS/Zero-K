function widget:GetInfo()
  return {
    name      = "Keep Target",
    desc      = "Simple and slowest usage of target on the move",
    author    = "Google Frog, Klon",
    date      = "3 Jul 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

-- included CMD.DGUN because of the wonky way some units with dgun behave when dgunning something other than their current target
-- (most notably dante)
-- will not override manual target

local AttackCommand = {
	[CMD.ATTACK] = true,
	[CMD.DGUN] = true,
	[CMD.AREA_ATTACK] =true, -- does it need to be here?
}	

local TargetCancelingCommand = {
	[CMD.STOP] = true,
	[CMD.FIGHT] = true,
	[CMD.GUARD] = true,
	[CMD.PATROL] = true,
}

local TargetOverrideCommand = {
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
}

local COMMANDOPTIONS_SHIFT_BIT = 32

--[[
	0? = "coded"  (int)
	0 = "internal", -- this does not really make sense. maybe the value got lost somewhere along the way
	4 = "meta",
	16 = "right",
	32 = "shift",
	64 = "ctrl",
	128 = "alt",
]]--



local unitsWithWeakTargetLink = {}
local myTeamID

local function isValidUnit(unitID, unitDefID)	
	if Spring.ValidUnitID(unitID) then
		local ud = UnitDefs[unitDefID]
		return ud and not (ud.isBomber or ud.isFactory)
	end
	return false
end

function widget:initialize()
	myTeamID = Spring.GetMyTeamID()
end

-- cannot check for internal flag anymore because it seems to be zero in the bitfield, same as no flag at all. doesn't seem to matter tho 
function widget:UnitCommand(unitID, unitDefID, teamID, id, options, params, tag)	
	if not teamID == myTeamID then return end -- not sure this is needed?
	
	if AttackCommand[id] then
		if isValidUnit(unitID, unitDefID) then				
			if #params == 1 then			
					-- if this is a shift-attack order, only set target if it is the first order in queue
					-- setting target for an attack further down the line could lead to suicidal unit behaviour 			
				if math.bit_and(options,COMMANDOPTIONS_SHIFT_BIT) == COMMANDOPTIONS_SHIFT_BIT then 
					local cmd = Spring.GetUnitCommands(unitID)
					if not cmd or #cmd<1 then
						Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,{internal=true})
						unitsWithWeakTargetLink[unitID] = true
					end
					
				else
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,{internal=true})
					unitsWithWeakTargetLink[unitID] = true
				end
				
			elseif unitsWithWeakTargetLink[unitID] then -- if attacking anything other than exactly 1 unit, remove existing auto target
				if math.bit_and(options,COMMANDOPTIONS_SHIFT_BIT) == COMMANDOPTIONS_SHIFT_BIT then -- unless we are queing it somewhere after an existing attack order
					local cmdQ = Spring.GetUnitCommands(unitID)
					local hasAttackOrder = false
					for cmd, t in ipairs(cmdQ) do
						if AttackCommand[t.id] and #t.params==1 then hasAttackOrder = true end
					end
					if not hasAttackOrder then
						Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,{internal=true})
						unitsWithWeakTargetLink[unitID] = nil
					end
					
				else					
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,{internal=true})
					unitsWithWeakTargetLink[unitID] = nil				
				end
			end
		end	
		
	elseif TargetCancelingCommand[id] then -- shifted stop commands never get here
		if unitsWithWeakTargetLink[unitID] then 
			if isValidUnit(unitID, unitDefID) then										
				if math.bit_and(options,COMMANDOPTIONS_SHIFT_BIT) ~= COMMANDOPTIONS_SHIFT_BIT or id == CMD.STOP then
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,{internal=true})
					unitsWithWeakTargetLink[unitID] = nil						
				
				else -- if there is an attack command somewhere down the line we keep its target if we are queueing a fight, guard, patrol after it										
					local cmdQ = Spring.GetUnitCommands(unitID) 
					local hasAttackOrder = false
					for cmd, t in ipairs(cmdQ) do
						if AttackCommand[t.id] and #t.params==1 then hasAttackOrder = true end
					end
					if not hasAttackOrder then
						Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,{internal=true})
						unitsWithWeakTargetLink[unitID] = nil
					end	
				end
			end
		end
		
	elseif TargetOverrideCommand[id] then
		if unitsWithWeakTargetLink[unitID] then 
			if isValidUnit(unitID, unitDefID) then					
				unitsWithWeakTargetLink[unitID] = nil			
			end
		end	
	end	
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if unitsWithWeakTargetLink[unitID] then unitsWithWeakTargetLink[unitID] = nil end
end