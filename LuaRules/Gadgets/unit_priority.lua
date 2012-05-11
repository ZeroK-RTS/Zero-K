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

local random = math.random

local spGetTeamList       = Spring.GetTeamList
local spGetTeamResources  = Spring.GetTeamResources
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
local spSetUnitRulesParam = Spring.SetUnitRulesParam


local function SetReserved(teamID, value)
	TeamReserved[teamID] = value or 0
end


local function SetPriorityState(unitID, state) 
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PRIORITY)
	if (cmdDescID) then
		CommandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, { params = CommandDesc.params, tooltip = Tooltips[1 + state%StateCount]})
		spSetUnitRulesParam(unitID, "buildpriority", state)
	end
	UnitPriority[unitID] = state	
end 



function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PRIORITY)

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		spInsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
	end

end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("mreserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID)
		local amount = msg:sub(10)
		if spec then return end
		SetReserved(teamID, amount*1)
	end	
end

function gadget:UnitCreated(UnitID, UnitDefID, TeamID, builderID) 
	local prio  = DefaultState
	if (builderID ~= nil)  then
		local unitDefID = spGetUnitDefID(builderID)
		if (unitDefID ~= nil and UnitDefs[unitDefID].isFactory) then 
			prio = UnitPriority[builderID] or DefaultState  -- inherit priorty from factory
			LastUnitFromFactory[builderID] = UnitID 
		end
	end 	
	UnitPriority[UnitID] =  prio
	CommandDesc.params[1] = prio
	spInsertUnitCmdDesc(UnitID, CommandOrder, CommandDesc)
end



function gadget:UnitFinished(unitID, unitDefID, teamID) 
	local ud = UnitDefs[unitDefID]
	
	if ((ud.isFactory or ud.builder) and ud.buildSpeed > 0) then 
		SetPriorityState(unitID, DefaultState)
	else  -- not a builder priority makes no sense now
		UnitPriority[unitID] = nil
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end 

end 

function gadget:UnitDestroyed(UnitID, unitDefID, teamID) 
	UnitPriority[UnitID] = nil
	LastUnitFromFactory[UnitID] = nil
    local ud = UnitDefs[unitDefID]
    if ud and ud.metalStorage and ud.metalStorage > 0 and TeamReserved[teamID] then
        local _, sto = spGetTeamResources(teamID, "metal")
        if sto and TeamReserved[teamID] > sto - ud.metalStorage then
            SetReserved(teamID, sto - ud.metalStorage)
        end
    end
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
		local _, _, _, _, progress = spGetUnitHealth(lastUnitID)
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
			if random() < scale[2] then 
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
		if random() < scale[1] then 
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
		local teams = spGetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			prioUnits = TeamPriorityUnits[teamID] or {}
			local prioSpending = 0
			local lowPrioSpending = 0
			for unitID, pri in pairs(prioUnits) do 
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID ~= nil then
					if pri == 2 then 
						prioSpending = prioSpending + UnitDefs[unitDefID].buildSpeed
					else 
						lowPrioSpending = lowPrioSpending + UnitDefs[unitDefID].buildSpeed
					end 
				end 
			end 
			
			SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)   

			local level, _, pull, income, expense, _, _, recieved = spGetTeamResources(teamID, "metal")
			local elevel, _, epull, eincome, eexpense, _, _, erecieved = spGetTeamResources(teamID, "energy")
			
			if TeamReserved[teamID] and (level < TeamReserved[teamID] or elevel < TeamReserved[teamID]) then -- below reserved level, low and normal no spending
				TeamScale[teamID] = {0,0}
			elseif TeamReserved[teamID] and TeamReserved[teamID] > 0 and -- approach reserved level, less low and normal spending
			(level < TeamReserved[teamID] + pull or elevel < TeamReserved[teamID] + epull) then 
                    
                -- both these values are positive and at least one is less than 1
			local mRatio = (level - TeamReserved[teamID])/pull
			local eRatio = (elevel - TeamReserved[teamID])/epull
              
			local spare
			if mRatio < eRatio then 
			    spare = (income + recieved + level) - TeamReserved[teamID] - prioSpending
			else
			    spare = (eincome + erecieved + elevel) - TeamReserved[teamID] - prioSpending
			end
			
			local normalSpending = pull - lowPrioSpending - prioSpending
			
			if spare > 0 then
			    if normalSpending <= 0 then
				 if lowPrioSpending ~= 0 then
				     TeamScale[teamID] = {0,spare/lowPrioSpending}
				 else
				     TeamScale[teamID] = {0,0}
				 end
			    elseif spare > normalSpending then
				 spare = spare - normalSpending
				 if spare > 0 and lowPrioSpending ~= 0 then
				     TeamScale[teamID] = {1,spare/lowPrioSpending}
				 else
				     TeamScale[teamID] = {1,0}
				 end
			    elseif spare > 0 then
				 TeamScale[teamID] = {spare/normalSpending,0}
			    end
			else
			    TeamScale[teamID] = {0,0}
			end
                
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
            
		SendToUnsynced("MetalReserveState", teamID, TeamReserved[teamID] or 0) 
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

local spGetLocalTeamID = Spring.GetLocalTeamID

local last_sent_in_frame = 0

function gadget:Initialize()
    gadgetHandler:AddSyncAction('MetalReserveState',WrapMetalReserveStateToLuaUI)
    gadgetHandler:AddSyncAction('PriorityStats',WrapPriorityStatsToLuaUI)
end

function WrapPriorityStatsToLuaUI(_,teamID, highPriorityBP, lowPriorityBP, gameFrame)
    if (teamID == spGetLocalTeamID() and Script.LuaUI('PriorityStats')) then
        if last_sent_in_frame ~= gameFrame then
            Script.LuaUI.PriorityStats(spGetLocalTeamID(), 0, 0)
            last_sent_in_frame = gameFrame
        else
            Script.LuaUI.PriorityStats(teamID, highPriorityBP, lowPriorityBP)
        end
    end
end

function WrapMetalReserveStateToLuaUI(_,teamID, reserve)
    if (teamID == spGetLocalTeamID() and Script.LuaUI('MetalReserveState')) then
        Script.LuaUI.MetalReserveState(teamID, reserve)
    end
end

--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------