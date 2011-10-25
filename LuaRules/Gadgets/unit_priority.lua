-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--
--  Copyright (C) 2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitPriority",
    desc      = "Adds controls to change spending priority on constructions/repairs etc",
    author    = "Licho",
    date      = "19.4.2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local Tooltips = {
	'Construction Low priority.',
	'Construction Normal priority.',
	'Construction High priority.',
}
local DefaultState = 1
local CommandOrder = 123456
local CommandDesc = {
		id          = CMD_PRIORITY,
		type        =  CMDTYPE.ICON_MODE,
		name        = 'Priority',
		action      = 'priority',
		tooltip 	= Tooltips[DefaultState + 1],
		params      = {DefaultState, 'Low','Normal','High'}
	}
local StateCount = #CommandDesc.params-1


local UnitPriority = {}  --  UnitPriority[unitID] = 0,1,2     priority of the unit
local TeamPriorityUnits = {}  -- TeamPriorityUnits[TeamID][UnitID] = 0,2    which units are low/high priority builders
local TeamScale = {}  -- TeamScale[TeamID]= {0.1, 0.4}   how much to scale down production of lnormal and low prirotity units
local TeamReserved = {} -- how much metal is reserved for high priority in each team
local LastUnitFromFactory = {} -- LastUnitFromFactory[FactoryUnitID] = lastUnitID


--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------


local function isFactory(UnitDefID)
  return UnitDefs[UnitDefID].isFactory or false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

local function ChangeReserved(teamID, change) 
	TeamReserved[teamID] = (TeamReserved[teamID] or 0) + change
end 

local function SetReserved(teamID, value)
	TeamReserved[teamID] = value or 0
end


local function SetPriorityState(unitID, state) 
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_PRIORITY)
	if (cmdDescID) then
		CommandDesc.params[1] = state
		Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = CommandDesc.params, tooltip = Tooltips[1 + state%StateCount]})
	end
	UnitPriority[unitID] = state	
end 



function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PRIORITY)

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		Spring.InsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
	end

end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("mreserve:",1,true) then
		local _,_,spec,teamID = Spring.GetPlayerInfo(playerID)
		local amount = msg:sub(10)
		if spec then return end
		local storage = select(2,Spring.GetTeamResources(teamID, "metal"))
		SetReserved(teamID, storage*amount)
	end	
end

function gadget:UnitCreated(UnitID, UnitDefID, TeamID, builderID) 
	local prio  = DefaultState
	if (builderID ~= nil)  then
		local unitDefID = Spring.GetUnitDefID(builderID)
		if (unitDefID ~= nil and UnitDefs[unitDefID].isFactory) then 
			prio = UnitPriority[builderID] or DefaultState  -- inherit priorty from factory
			LastUnitFromFactory[builderID] = UnitID 
		end
	end 	
	UnitPriority[UnitID] =  prio
	CommandDesc.params[1] = prio
	Spring.InsertUnitCmdDesc(UnitID, CommandOrder, CommandDesc)
end



function gadget:UnitFinished(unitID, unitDefID, teamID) 
	local ud = UnitDefs[unitDefID]
	
	if ((ud.isFactory or ud.builder) and ud.buildSpeed > 0) then 
		SetPriorityState(unitID, DefaultState)
	else  -- not a builder priority makes no sense now
		UnitPriority[unitID] = nil
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_PRIORITY)
		if (cmdDescID) then
			Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end 

end 

function gadget:UnitDestroyed(UnitID, unitDefID, teamID) 
	UnitPriority[UnitID] = nil
	LastUnitFromFactory[UnitID] = nil
end


function PriorityCommand(unitID, cmdParams, cmdOptions)
	local state = cmdParams[1]
	if (cmdOptions.right) then 
		state = state - 2
	end
	state = state % StateCount

	SetPriorityState(unitID, state)
	
	local lastUnitID = LastUnitFromFactory[unitID]  
	if lastUnitID ~= nil then 
		local _, _, _, _, progress   = Spring.GetUnitHealth(lastUnitID)
		if (progress ~= nil and progress < 1) then  -- we are building some unit ,set its priority too 
			SetPriorityState(lastUnitID, state)
		end 
	end 
end


function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_PRIORITY) then
    return true  -- command was not used
  end
  PriorityCommand(unitID, cmdParams, cmdOptions)  
  return false  -- command was used
end


function gadget:CommandFallback(unitID, unitDefID, teamID,
                                cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_PRIORITY) then
    return false  -- command was not used
  end
  PriorityCommand(unitID, cmdParams, cmdOptions)  
  return true, true  -- command was used, remove it
end



function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if (step<0) then
		--// Reclaiming isn't prioritized
		return true
	end

	if (UnitPriority[builderID] == 0 or (UnitPriority[unitID] == 0 and (UnitPriority[builderID] or 1) == 1 )) then -- priority none
		if (TeamPriorityUnits[teamID] == nil) then TeamPriorityUnits[teamID] = {} end
		TeamPriorityUnits[teamID][builderID] = 0
		local scale = TeamScale[teamID]
		if scale ~= nil then 
			if math.random() < scale[2] then 
				return true
			else 
				return false
			end		
		end
		return true
	end

	if (UnitPriority[builderID] == 2 or (UnitPriority[unitID] == 2 and (UnitPriority[builderID] or 1) == 1)) then  -- priority high
		if (TeamPriorityUnits[teamID] == nil) then TeamPriorityUnits[teamID] = {} end
		TeamPriorityUnits[teamID][builderID] = 2		
		return true
	end 
	
	local scale = TeamScale[teamID]
	if scale ~= nil then 
		if math.random() < scale[1] then 
			return true
		else 
			return false
		end
	end 
	
		
	return true
end


function gadget:GameFrame(n) 
	if n % 32 == 15 then 
		TeamScale = {}
	
		for _,teamID in ipairs(Spring.GetTeamList()) do 
			prioUnits = TeamPriorityUnits[teamID] or {}
			local prioSpending = 0
			local lowPrioSpending = 0
			for unitID, pri in pairs(prioUnits) do 
				local unitDefID = Spring.GetUnitDefID(unitID)
				if unitDefID ~= nil then
					if pri == 2 then 
						prioSpending = prioSpending + UnitDefs[unitDefID].buildSpeed
					else 
						lowPrioSpending = lowPrioSpending + UnitDefs[unitDefID].buildSpeed
					end 
				end 
			end 
			
			SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)   

			local level, _, pull, income, expense, _, _, recieved = Spring.GetTeamResources(teamID, "metal")
			local elevel, _, epull, eincome, eexpense, _, _, erecieved = Spring.GetTeamResources(teamID, "energy")
			
			if (level < (TeamReserved[teamID] or 0)) then  -- below reserved level, low and normal no spending
					TeamScale[teamID] = {0,0}
			elseif (prioSpending > 0 or lowPrioSpending > 0) then
				
				local normalSpending = pull - lowPrioSpending
				
				if pull > expense and level < expense and prioSpending < pull then 
					TeamScale[teamID] = {
						(income + recieved - prioSpending) / (pull - prioSpending - lowPrioSpending),  -- m stall  scale
						(income + recieved - normalSpending) / (lowPrioSpending)  -- m stall low scale
					}
					--Spring.Echo ("m_stall" .. TeamScale[teamID])
				elseif epull > eexpense and elevel < eexpense and prioSpending < epull then 
					TeamScale[teamID] = {				
						(eincome + erecieved - prioSpending) / (epull - prioSpending - lowPrioSpending),  -- e stall  scale
						(eincome + erecieved - normalSpending) / (lowPrioSpending)  -- e stall low scale
					}
				end 
			end
		end

		TeamPriorityUnits = {}
		SendToUnsynced("PriorityStats", nil,  0, 0, n)   
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--  END SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

local last_sent_in_frame = 0

function gadget:Initialize()
  gadgetHandler:AddSyncAction('PriorityStats',WrapToLuaUI)
end

function WrapToLuaUI(_,teamID, highPriorityBP, lowPriorityBP, gameFrame)
  if (teamID == nil and last_sent_in_frame ~= gameFrame) then 
	if (Script.LuaUI('PriorityStats')) then
		Script.LuaUI.PriorityStats(Spring.GetLocalTeamID(), 0, 0)
	end
	last_sent_in_frame = gameFrame
  else 
	if (teamID ~= Spring.GetLocalTeamID()) then return end
	if (Script.LuaUI('PriorityStats')) then
		Script.LuaUI.PriorityStats(teamID, highPriorityBP, lowPriorityBP)
	end
	last_sent_in_frame = gameFrame
  end 
end


--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------