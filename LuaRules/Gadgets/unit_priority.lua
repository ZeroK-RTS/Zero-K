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
    date      = "19.4.2009", --24.2.2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
include("LuaRules/Configs/constants.lua")

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
local TeamMetalReserved = {} -- how much metal is reserved for high priority in each team
local TeamEnergyReserved = {} -- ditto for energy
local LastUnitFromFactory = {} -- LastUnitFromFactory[FactoryUnitID] = lastUnitID

local morphBuildSpeed = {} --buildspeed for custom unit added thru GG. function
local morphAllowBuildStep = {} --
local morphTeamPriorityUnits = {} --unit morph that need priority handling

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


local function SetMetalReserved(teamID, value)
	TeamMetalReserved[teamID] = value or 0
end

local function SetEnergyReserved(teamID, value)
	TeamEnergyReserved[teamID] = value or 0
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
		SetMetalReserved(teamID, amount*1)
	end	
	if msg:find("ereserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID)
		local amount = msg:sub(10)
		if spec then return end
		SetEnergyReserved(teamID, amount*1)
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
    if ud then
		if ud.metalStorage and ud.metalStorage > 0 and TeamMetalReserved[teamID] then
			local _, sto = spGetTeamResources(teamID, "metal")
			if sto and TeamMetalReserved[teamID] > sto - ud.metalStorage then
				SetMetalReserved(teamID, sto - ud.metalStorage)
			end
		end
		if ud.energyStorage and ud.energyStorage > 0 and TeamEnergyReserved[teamID] then
			local _, sto = spGetTeamResources(teamID, "energy") - HIDDEN_STORAGE
			if sto and TeamEnergyReserved[teamID] > sto - ud.energyStorage then
				SetEnergyReserved(teamID, sto - ud.energyStorage)
			end
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

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step,morph) 
	if (step<0) then
		--// Reclaiming isn't prioritized
		return true
	end

	if (UnitPriority[unitID] == 0 or (UnitPriority[builderID] == 0 and (UnitPriority[unitID] or 1) == 1 )) then -- priority none/low
		if morph == nil then
			if (TeamPriorityUnits[teamID] == nil) then TeamPriorityUnits[teamID] = {} end
			TeamPriorityUnits[teamID][builderID] = 0
		else
			if (morphTeamPriorityUnits[teamID] == nil) then morphTeamPriorityUnits[teamID] = {} end
			morphTeamPriorityUnits[teamID][unitID] = 0
		end
		local scale = TeamScale[teamID]
		if scale ~= nil then 
			if random() < scale[2] then  --if scale[2] is less than 1 then it has less chance of success. scale[2] is a ratio between available-resource and desired-spending.  scale[2] is less than 1 when desired-spending is bigger than available-resources.
				return true
			else 
				return false
			end		
		end
		return true
	end

	if (UnitPriority[unitID] == 2 or (UnitPriority[builderID] == 2 and (UnitPriority[unitID] or 1) == 1)) then  -- priority high
		if morph == nil then
			if (TeamPriorityUnits[teamID] == nil) then TeamPriorityUnits[teamID] = {} end
			TeamPriorityUnits[teamID][builderID] = 2
		else
			if (morphTeamPriorityUnits[teamID] == nil) then morphTeamPriorityUnits[teamID] = {} end
			morphTeamPriorityUnits[teamID][unitID] = 2
		end
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
	for unitID, _ in pairs(morphBuildSpeed) do --update morphAllowBuildStep when available. (is updated before prioSpending code below)
		local teamID = Spring.GetUnitTeam(unitID)
		morphAllowBuildStep[unitID] = gadget:AllowUnitBuildStep(unitID, teamID, unitID, -1, 1, true)
	end
	if n % 32 == 15 then 
		TeamScale = {}
		local teams = spGetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			prioUnits = TeamPriorityUnits[teamID] or {}
			local prioSpending = 0
			local lowPrioSpending = 0
			for unitID, pri in pairs(prioUnits) do  --add construction priority spending
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID ~= nil then
					if pri == 2 then 
						prioSpending = prioSpending + UnitDefs[unitDefID].buildSpeed
					else 
						lowPrioSpending = lowPrioSpending + UnitDefs[unitDefID].buildSpeed
					end 
				end 
			end
			for unitID, _ in pairs(morphBuildSpeed) do --add morph priority spending
				local unitDefID = spGetUnitDefID(unitID)
				local morphPriority = morphTeamPriorityUnits[teamID] and morphTeamPriorityUnits[teamID][unitID]
				if unitDefID ~= nil and morphPriority then
					if morphPriority == 2 then 
						prioSpending = prioSpending + morphBuildSpeed[unitID]
					else 
						lowPrioSpending = lowPrioSpending + morphBuildSpeed[unitID]
					end 
				end 
			end 
			
			SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)   

			local level, _, pull, income, expense, _, _, recieved = spGetTeamResources(teamID, "metal")
			local elevel, _, epull, eincome, eexpense, _, _, erecieved = spGetTeamResources(teamID, "energy")
			
			if (TeamMetalReserved[teamID] and level < TeamMetalReserved[teamID]) or (TeamEnergyReserved [teamID] and elevel < TeamEnergyReserved[teamID]) then 
				-- below reserved level, low and normal no spending
				TeamScale[teamID] = {0,0}
			elseif (TeamMetalReserved[teamID] and TeamMetalReserved[teamID] > 0 and level < TeamMetalReserved[teamID] + pull) or 
					(TeamEnergyReserved[teamID] and TeamEnergyReserved[teamID] > 0 and elevel < TeamEnergyReserved[teamID] + epull) then -- approach reserved level, less low and normal spending
                    
                -- both these values are positive and at least one is less than 1
				local mRatio = (level - (TeamMetalReserved[teamID] or 0))/pull
				local eRatio = (elevel - (TeamEnergyReserved[teamID] or 0))/epull
				  
				local spare
				if mRatio < eRatio then 
					spare = (income + recieved + level) - (TeamMetalReserved[teamID] or 0) - prioSpending
				else
					spare = (eincome + erecieved + elevel) - (TeamEnergyReserved[teamID] or 0) - prioSpending
				end
			
				local normalSpending = pull - lowPrioSpending - prioSpending
				
				if spare > 0 then
					if normalSpending <= 0 then
					 if lowPrioSpending ~= 0 then
						 TeamScale[teamID] = {0,spare/lowPrioSpending} --no normal spending, but mixed chance for low priority spending
					 else
						 TeamScale[teamID] = {0,0} --no normal spending, and no low priority spending, only hi-priority spending
					 end
					elseif spare > normalSpending then
					 spare = spare - normalSpending
					 if spare > 0 and lowPrioSpending ~= 0 then
						 TeamScale[teamID] = {1,spare/lowPrioSpending} --full normal spending, and mixed chance low-priority spending
					 else
						 TeamScale[teamID] = {1,0} --full normal spending, but no low-priority spending
					 end
					elseif spare > 0 then
					 TeamScale[teamID] = {spare/normalSpending,0} --mixed chance normal spending, and no low-priority spending
					end
				else
					TeamScale[teamID] = {0,0} --no  normal spending, no low-Priority spending
				end
                
			elseif (prioSpending > 0 or lowPrioSpending > 0) then --normal situation, or no reserve
				
				local normalSpending = pull - lowPrioSpending
				
				if pull > expense and level < expense and prioSpending < pull then 
					TeamScale[teamID] = {
						(income + recieved - prioSpending) / (pull - prioSpending - lowPrioSpending),  -- m stall  scale . spareNormal/normal-priority-spending
						(income + recieved - normalSpending) / (lowPrioSpending)  -- m stall low scale . spareLow/low-priority-spending
					}
					--Spring.Echo ("m_stall" .. TeamScale[teamID])
				elseif epull > eexpense and elevel < eexpense and prioSpending < epull then 
					TeamScale[teamID] = {				
						(eincome + erecieved - prioSpending) / (epull - prioSpending - lowPrioSpending),  -- e stall  scale
						(eincome + erecieved - normalSpending) / (lowPrioSpending)  -- e stall low scale
					}
				end 
			end
            
		SendToUnsynced("ReserveState", teamID, TeamMetalReserved[teamID] or 0, TeamEnergyReserved[teamID] or 0) 
		end
		morphTeamPriorityUnits = {} --reset morpher priority list
		TeamPriorityUnits = {} --reset builder priority list (will be checked every n%32==15 th frame)
		SendToUnsynced("PriorityStats", nil,  0, 0, n)   
	end
end

--------------------------------------------------------------------------------
function GG.AddMorphPriority(unitID,buildSpeed) --remotely add a priority command.
	local unitDefID = Spring.GetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	if ud and (not ((ud.isFactory or ud.builder) and ud.buildSpeed > 0)) then --if unit not suppose to have Priority command, then: force add priority command
		spInsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
		SetPriorityState(unitID, DefaultState)
	end
	morphBuildSpeed[unitID]=buildSpeed
	morphAllowBuildStep[unitID]=false
end

function GG.RemoveMorphPriority(unitID) --remotely remove a forced priority command.
	local unitDefID = Spring.GetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	if ud and (not ((ud.isFactory or ud.builder) and ud.buildSpeed > 0)) then --if not suppose to have Priority command, then: remove priority command
		UnitPriority[unitID] = nil --clear build priority for this unit because we assume morpher no longer needed it (because only needed for unit under construction)
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
			spSetUnitRulesParam(unitID, "buildpriority", 1) --reset to normal priority so that overhead icon doesn't show wrench
		end			
	end
	morphBuildSpeed[unitID] = nil
	morphAllowBuildStep[unitID]= nil
end

function GG.CheckMorphBuildStep(unitID)
	return morphAllowBuildStep[unitID] --tell unit_morph.lua about this morph status: allow/pause?
end
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
    gadgetHandler:AddSyncAction('ReserveState',WrapReserveStateToLuaUI)
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

function WrapReserveStateToLuaUI(_,teamID, metalReserve, energyReserve)
    if (teamID == spGetLocalTeamID() and Script.LuaUI('ReserveState')) then
        Script.LuaUI.ReserveState(teamID, metalReserve, energyReserve)
    end
end

--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------