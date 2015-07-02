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

if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitPriority",
    desc      = "Adds controls to change spending priority on constructions/repairs etc",
    author    = "Licho",
    date      = "19.4.2009", --24.2.2013
    license   = "GNU GPL, v2 or later",
	-- Must start before unit_morph.lua gadget to register GG.AddMiscPriority() first.
	-- Must be before mex_overdrive
    layer     = -5,
    enabled   = not (Game.version:find('91.0') == 1)
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
include("LuaRules/Configs/constants.lua")

local TooltipsA = {
	' Low.',
	' Normal.',
	' High.',
}
local TooltipsB = {
	[CMD_PRIORITY] = 'Construction Priority',
	[CMD_MISC_PRIORITY] = 'Morph&Stock Priority',
}
local DefaultState = 1

local CommandOrder = 123456
local CommandDesc = {
	id          = CMD_PRIORITY,
	type        = CMDTYPE.ICON_MODE,
	name        = 'Construction Priority',
	action      = 'priority',
	tooltip 	= 'Construction Priority' .. TooltipsA[DefaultState + 1],
	params      = {DefaultState, 'Low','Normal','High'}
}

local MiscCommandOrder = 123457
local MiscCommandDesc = {
	id          = CMD_MISC_PRIORITY,
	type        = CMDTYPE.ICON_MODE,
	name        = 'Morph&Stock Priority',
	action      = 'miscpriority',
	tooltip 	= 'Morph&Stock Priority' .. TooltipsA[DefaultState + 1],
	params      = {DefaultState, 'Low','Normal','High'}
}

local StateCount = #CommandDesc.params-1

local UnitPriority = {}  --  UnitPriority[unitID] = 0,1,2     priority of the unit
local UnitMiscPriority = {}  --  UnitMiscPriority[unitID] = 0,1,2     priority of the unit
local TeamPriorityUnits = {}  -- TeamPriorityUnits[TeamID][UnitID] = 0,2    which units are low/high priority builders
local teamMiscPriorityUnits = {} -- teamMiscPriorityUnits[TeamID][UnitID] = 0,2    which units are low/high priority builders
local TeamScale = {}  -- TeamScale[TeamID] = {0, 0.4, 1} how much to scale resourcing at different incomes
local TeamScaleEnergy = {} -- TeamScaleEnergy[TeamID] = {0, 0.4, 1} how much to scale energy only resourcing
local TeamMetalReserved = {} -- how much metal is reserved for high priority in each team
local TeamEnergyReserved = {} -- ditto for energy
local LastUnitFromFactory = {} -- LastUnitFromFactory[FactoryUnitID] = lastUnitID
local UnitOnlyEnergy = {} -- UnitOnlyEnergy[unitID] = true if the unit does not try to drain metal
local MiscUnitOnlyEnergy = {} -- MiscUnitOnlyEnergy[unitID] for misc drain

local checkOnlyEnergy = false -- becomes true onces every second to check for repairers

-- Derandomization of resource allocation. Remembers the portion of resources allocated to the unit and gives access
-- when they have a full chunk.
local UnitConPortion = {}
local UnitMiscPortion = {}

local miscMetalDrain = {} -- metal drain for custom unit added thru GG. function
local miscTeamPriorityUnits = {} --unit  that need priority handling
local miscTeamPull = {} -- miscTeamPull[TeamID] = pull      -- how much is pulling

do
	local teams = Spring.GetTeamList()
	for i=1,#teams do
		local teamID = teams[i]
		miscTeamPull[teamID] = 0
	end
end

local priorityTypes = {
	[CMD_PRIORITY] = {id = CMD_PRIORITY, param = "buildpriority", unitTable = UnitPriority},
	[CMD_MISC_PRIORITY] = {id = CMD_MISC_PRIORITY, param = "miscpriority", unitTable = UnitMiscPriority},
}

local ALLY_ACCESS = {allied = true}

local reportedError = false
local debugTeam = false

--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------


local function isFactory(UnitDefID)
  return UnitDefs[UnitDefID].isFactory or false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local max = math.max

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
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetTeamRulesParam = Spring.GetTeamRulesParam

local alliedTable = {allied = true}

local function SetMetalReserved(teamID, value)
	TeamMetalReserved[teamID] = value or 0
	Spring.SetTeamRulesParam(teamID, "metalReserve", value or 0, alliedTable)
end

local function SetEnergyReserved(teamID, value)
	TeamEnergyReserved[teamID] = value or 0
	Spring.SetTeamRulesParam(teamID, "energyReserve", value or 0, alliedTable)
end


local function SetPriorityState(unitID, state, prioID) 
	local cmdDescID = spFindUnitCmdDesc(unitID, prioID)
	if (cmdDescID) then
		CommandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, { params = CommandDesc.params, tooltip = TooltipsB[prioID] .. TooltipsA[1 + state%StateCount]})
		spSetUnitRulesParam(unitID, priorityTypes[prioID].param, state, ALLY_ACCESS)
	end
	priorityTypes[prioID].unitTable[unitID] = state	
end 

function PriorityCommand(unitID, cmdID, cmdParams, cmdOptions)
	local state = cmdParams[1]
	if cmdOptions and (cmdOptions.right) then 
		state = state - 2
	end
	state = state % StateCount

	SetPriorityState(unitID, state, cmdID)
	
	local lastUnitID = LastUnitFromFactory[unitID]  
	if lastUnitID ~= nil then 
		local _, _, _, _, progress = spGetUnitHealth(lastUnitID)
		if (progress ~= nil and progress < 1) then  -- we are building some unit ,set its priority too 
			SetPriorityState(lastUnitID, state, cmdID)
		end 
	end 
end


function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_PRIORITY] = true, [CMD_MISC_PRIORITY] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_PRIORITY or cmdID == CMD_MISC_PRIORITY) then
		PriorityCommand(unitID, cmdID, cmdParams, cmdOptions)  
		return false  -- command was used
	end
	return true  -- command was not used
end

function gadget:CommandFallback(unitID, unitDefID, teamID,
                                cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_PRIORITY) then
    return false  -- command was not used
  end
  PriorityCommand(unitID, cmdParams, cmdOptions)  
  return true, true  -- command was used, remove it
end

local function AllowMiscBuildStep(unitID,teamID,onlyEnergy)

	local conAmount = UnitMiscPortion[unitID] or math.random()

	if (teamMiscPriorityUnits[teamID] == nil) then 
		teamMiscPriorityUnits[teamID] = {} 
	end
	
	local scale
	if MiscUnitOnlyEnergy[unitID] then
		scale = TeamScaleEnergy[teamID]
	else
		scale = TeamScale[teamID]
	end
	
	if checkOnlyEnergy then
		MiscUnitOnlyEnergy[unitID] = onlyEnergy
	end
	
	local priorityLevel = (UnitMiscPriority[unitID] or 1) + 1
	
	teamMiscPriorityUnits[teamID][unitID] = priorityLevel
	if scale and scale[priorityLevel] then 
		conAmount = conAmount + scale[priorityLevel]
		if conAmount >= 1 then  
			UnitMiscPortion[unitID] = conAmount - 1
			return true
		else 
			UnitMiscPortion[unitID] = conAmount
			return false
		end	
	end 
	
	return true
end

function CheckMiscPriorityBuildStep(unitID, teamID, toSpend)
	return AllowMiscBuildStep(unitID,teamID)
end

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if (step<0) then
		--// Reclaiming isn't prioritized
		return true
	end
	
	local conAmount = UnitConPortion[builderID] or math.random()
	if (TeamPriorityUnits[teamID] == nil) then 
		TeamPriorityUnits[teamID] = {} 
	end
	
	local scale
	if UnitOnlyEnergy[builderID] then
		scale = TeamScaleEnergy[teamID]
	else
		scale = TeamScale[teamID]
	end
	
	if checkOnlyEnergy then
		local _,_,inBuild = spGetUnitIsStunned(unitID)
		if inBuild then
			UnitOnlyEnergy[builderID] = false
		else
			UnitOnlyEnergy[builderID] = (spGetUnitRulesParam(unitID, "repairRate") or 1)
		end
	end
	
	local priorityLevel 
	if (UnitPriority[unitID] == 0 or (UnitPriority[builderID] == 0 and (UnitPriority[unitID] or 1) == 1 )) then
		priorityLevel = 1
	elseif (UnitPriority[unitID] == 2 or (UnitPriority[builderID] == 2 and (UnitPriority[unitID] or 1) == 1))  then
		priorityLevel = 3
	else
		priorityLevel = 2
	end
	
	TeamPriorityUnits[teamID][builderID] = priorityLevel
	if scale and scale[priorityLevel] then 
		-- scale is a ratio between available-resource and desired-spending.
		conAmount = conAmount + scale[priorityLevel]
		if conAmount >= 1 then  
			UnitConPortion[builderID] = conAmount - 1
			return true
		else 
			UnitConPortion[builderID] = conAmount
			return false
		end		
	end
	return true
end

function gadget:GameFrame(n)

	if n % TEAM_SLOWUPDATE_RATE == 1 then 
		local prioUnits, miscPrioUnits
		
		local debugMode
		local teams = spGetTeamList()
		for i=1,#teams do
			
			debugMode = debugTeam and debugTeam[i]
			
			local teamID = teams[i]
			prioUnits = TeamPriorityUnits[teamID] or {}
			miscPrioUnits = teamMiscPriorityUnits[teamID] or {}
			
			local spending = {0,0,0}
			local energySpending = {0,0,0}
			
			local realEnergyOnlyPull = 0
			local scaleEnergy = TeamScaleEnergy[teamID]
			
			if debugMode then
				Spring.Echo("====== Frame " .. n .. " ======")
				Spring.Echo("team " .. i .. " Initial energy only scale:")
				if scaleEnergy then
					Spring.Echo("High: " .. (scaleEnergy[3] or "nil"))
					Spring.Echo("Med: " .. (scaleEnergy[2] or "nil"))
					Spring.Echo("Low: " .. (scaleEnergy[1] or "nil"))
				end
			end
			
			for unitID, pri in pairs(prioUnits) do  --add construction priority spending
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID ~= nil then
					if UnitOnlyEnergy[unitID] then
						local buildSpeed = spGetUnitRulesParam(unitID, "buildSpeed") or UnitDefs[unitDefID].buildSpeed
						energySpending[pri] = energySpending[pri] + buildSpeed*UnitOnlyEnergy[unitID]
						if scaleEnergy and scaleEnergy[pri] then
							realEnergyOnlyPull = realEnergyOnlyPull + buildSpeed*UnitOnlyEnergy[unitID]*scaleEnergy[pri]
							
							if debugMode then
								GG.UnitEcho(unitID, "Energy Priority: " ..  pri ..
									", BP: " .. buildSpeed .. 
									", Pull: " .. buildSpeed*UnitOnlyEnergy[unitID]*scaleEnergy[pri]
								)
							end
						end
					else
						local buildSpeed = spGetUnitRulesParam(unitID, "buildSpeed") or UnitDefs[unitDefID].buildSpeed
						spending[pri] = spending[pri] + buildSpeed
						
						if debugMode then
							GG.UnitEcho(unitID, "Priority: " .. pri ..
								", BP: " .. buildSpeed
							)
						end
					end
				end 
			end
			
			for unitID, drain in pairs(miscMetalDrain) do --add misc priority spending
				local unitDefID = spGetUnitDefID(unitID)
				local pri = miscPrioUnits[unitID]
				if unitDefID ~= nil and pri then
					if MiscUnitOnlyEnergy[unitID] then
						energySpending[pri] = energySpending[pri] + drain
						if scaleEnergy and scaleEnergy[pri] then
							realEnergyOnlyPull = realEnergyOnlyPull + drain*scaleEnergy[pri]
							
							if debugMode then
								GG.UnitEcho(unitID, "Misc Energy Priority: " ..  pri ..
									", BP: " .. drain .. 
									", Pull: " .. realEnergyOnlyPull + drain*scaleEnergy[pri]
								)
							end
						end
					else
						spending[pri] = spending[pri] + drain
						if debugMode then
							GG.UnitEcho(unitID, "Misc Priority: " .. pri ..
								", BP: " .. drain
							)
						end
					end
				end 
			end 
			
			--SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)   

			local level, _, fakeMetalPull, income, expense, _, _, recieved = spGetTeamResources(teamID, "metal", true)
			local elevel, _, fakeEnergyPull, eincome, eexpense, _, _, erecieved = spGetTeamResources(teamID, "energy", true)
			
			-- Take away the constant income which was gained this frame (innate, reclaim)
			-- This is to ensure that level + total income is exactly what will be gained in the next second (if nothing is spent).
			local mexIncome = (spGetTeamRulesParam(teamID, "OD_myBase") or 0) + (spGetTeamRulesParam(teamID, "OD_myOverdrive") or 0)
			level = level - (income - mexIncome)/30
			
			-- Make sure the misc resoucing is constantly pulling the same value regardless of whether resources are spent
			local metalPull = spending[1] + spending[2] + spending[3]
			local energyPull = fakeEnergyPull + metalPull - fakeMetalPull + energySpending[1] + energySpending[2] + energySpending[3] - realEnergyOnlyPull

			spSetTeamRulesParam(teamID, "extraMetalPull", metalPull - fakeMetalPull, ALLY_ACCESS)
			spSetTeamRulesParam(teamID, "extraEnergyPull", energyPull - fakeEnergyPull, ALLY_ACCESS)
			
			if debugMode then
				Spring.Echo("team " .. i .. " Pull:")
				if scaleEnergy then
					Spring.Echo("High: " .. (spending[3] or "nil"))
					Spring.Echo("Med: " .. (spending[2] or "nil"))
					Spring.Echo("Low: " .. (spending[1] or "nil"))
				end
			end
			
			if debugMode then
				Spring.Echo("team " .. i .. " Energy Only Pull:")
				if scaleEnergy then
					Spring.Echo("High: " .. (energySpending[3] or "nil"))
					Spring.Echo("Med: " .. (energySpending[2] or "nil"))
					Spring.Echo("Low: " .. (energySpending[1] or "nil"))
				end
			end
			
			if debugMode then
				Spring.Echo("team " .. i .. " old resource levels:")
				if scaleEnergy then
					Spring.Echo("nextMetalLevel: " .. (level or "nil"))
					Spring.Echo("nextEnergyLevel: " .. (elevel or "nil"))
				end
			end
			
			-- How much of each resource there is to spend in the next second.
			local nextMetalLevel = (income + recieved + level)
			local nextEnergyLevel = (eincome + erecieved + elevel)
			
			if debugMode then
				Spring.Echo("team " .. i .. " new resource levels:")
				if scaleEnergy then
					Spring.Echo("nextMetalLevel: " .. (nextMetalLevel or "nil"))
					Spring.Echo("nextEnergyLevel: " .. (nextEnergyLevel or "nil"))
				end
			end
			
			TeamScale[teamID] = {}
			TeamScaleEnergy[teamID] = {}
			
			for pri = 3, 1, -1 do
				local metalDrain = spending[pri]
				local energyDrain = spending[pri] + energySpending[pri]
				--if i == 1 then
				--	Spring.Echo(pri .. " energyDrain " .. energyDrain)
				--	Spring.Echo(pri .. " nextEnergyLevel " .. nextEnergyLevel)
				--end
				
				if metalDrain > 0 and energyDrain > 0 and (nextMetalLevel <= metalDrain or nextEnergyLevel <= energyDrain) then
					-- both these values are positive and at least one is less than 1
					local mRatio = max(0,nextMetalLevel)/metalDrain
					local eRatio = max(0,nextEnergyLevel)/energyDrain
				
					local spare
					if mRatio < eRatio then 
						-- mRatio is lower so we are stalling metal harder.
						-- Set construction scale limited by metal.
						TeamScale[teamID][pri] = mRatio
						
						nextEnergyLevel = nextEnergyLevel - nextMetalLevel
						nextMetalLevel = 0
						
						-- Use leftover energy for energy-only tasks.
						energyDrain = energySpending[pri]
						if energyDrain > 0 and nextEnergyLevel <= energyDrain then
							eRatio = nextEnergyLevel/energyDrain
							TeamScaleEnergy[teamID][pri] = eRatio
							nextEnergyLevel = 0
						else
							TeamScaleEnergy[teamID][pri] = 1
							nextEnergyLevel = nextEnergyLevel - energyDrain
						end
					else
						-- eRatio is lower so we are stalling energy harder.
						-- Set scale for build and repair equally and limit by energy.
						TeamScale[teamID][pri] = eRatio
						TeamScaleEnergy[teamID][pri] = eRatio
						
						nextMetalLevel = nextMetalLevel - nextEnergyLevel
						nextEnergyLevel = 0
					end
				elseif energyDrain > 0 and nextEnergyLevel <= energyDrain then
					local eRatio = max(0,nextEnergyLevel)/energyDrain
					-- Set scale for build and repair equally and limit by energy.
					TeamScale[teamID][pri] = eRatio
					TeamScaleEnergy[teamID][pri] = eRatio
					
					nextMetalLevel = nextMetalLevel - nextEnergyLevel
					nextEnergyLevel = 0
				else
					TeamScale[teamID][pri] = 1
					TeamScaleEnergy[teamID][pri] = 1
					
					nextMetalLevel = nextMetalLevel - metalDrain
					nextEnergyLevel = nextEnergyLevel - energyDrain
				end
			
				if pri == 3 then
					nextMetalLevel = nextMetalLevel - (TeamMetalReserved[teamID] or 0)
					nextEnergyLevel = nextEnergyLevel - (TeamEnergyReserved[teamID] or 0)
				end
			end
			
			if debugMode then
				Spring.Echo("team " .. i .. " Scale:")
				if scaleEnergy then
					Spring.Echo("High: " .. (TeamScale[teamID][3] or "nil"))
					Spring.Echo("Med: " .. (TeamScale[teamID][2] or "nil"))
					Spring.Echo("Low: " .. (TeamScale[teamID][1] or "nil"))
				end
			end
			
			if debugMode then
				Spring.Echo("team " .. i .. " Energy Only Scale:")
				if scaleEnergy then
					Spring.Echo("High: " .. (TeamScaleEnergy[teamID][3] or "nil"))
					Spring.Echo("Med: " .. (TeamScaleEnergy[teamID][2] or "nil"))
					Spring.Echo("Low: " .. (TeamScaleEnergy[teamID][1] or "nil"))
				end
			end
			
		end
		
		
		teamMiscPriorityUnits = {} --reset priority list
		TeamPriorityUnits = {} --reset builder priority list (will be checked every n%32==15 th frame) 
		
		checkOnlyEnergy = false
	end
	
	if n % TEAM_SLOWUPDATE_RATE == 0 then
		checkOnlyEnergy = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Misc priority unit handling

function AddMiscPriorityUnit(unitID,teamID) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		spInsertUnitCmdDesc(unitID, MiscCommandOrder, MiscCommandDesc)
		SetPriorityState(unitID, DefaultState, CMD_MISC_PRIORITY)
	end
end

function StartMiscPriorityResourcing(unitID,teamID,metalDrain) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		AddMiscPriorityUnit(unitID,teamID)
	end
	miscTeamPull[teamID] = miscTeamPull[teamID] + metalDrain
	miscMetalDrain[unitID] = metalDrain
end

function StopMiscPriorityResourcing(unitID,teamID) --remotely remove a forced priority command.
	miscTeamPull[teamID] = miscTeamPull[teamID] - (miscMetalDrain[unitID] or 0)
	if (not reportedError) and (not miscMetalDrain[unitID]) then
		Spring.Echo("StopMiscPriorityResourcing nil miscMetalDrain")
		reportedError = true
	end
	miscMetalDrain[unitID] = nil
end

function RemoveMiscPriorityUnit(unitID,teamID) --remotely remove a forced priority command.
	if UnitMiscPriority[unitID] then
		if miscMetalDrain[unitID] then
			StopMiscPriorityResourcing(unitID,teamID)
		end
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_MISC_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
			spSetUnitRulesParam(unitID, "miscpriority", 1) --reset to normal priority so that overhead icon doesn't show wrench
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if miscMetalDrain[unitID] then
		StopMiscPriorityResourcing(unitID,oldTeamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Debug

local function toggleDebug(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then 
		return
	end
	local teamID = tonumber(words[1])
	Spring.Echo("Debug priority for team " .. (teamID or "nil"))
	if teamID then
		if not debugTeam then
			debugTeam = {}
		end
		if debugTeam[teamID] then
			debugTeam[teamID] = nil
			if #debugTeam == 0 then
				debugTeam = {}
			end
			Spring.Echo("Disabled")
		else
			debugTeam[teamID] = true
			Spring.Echo("Enabled")
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function gadget:Initialize()
	GG.CheckMiscPriorityBuildStep  = CheckMiscPriorityBuildStep
	GG.AddMiscPriorityUnit         = AddMiscPriorityUnit
	GG.StartMiscPriorityResourcing = StartMiscPriorityResourcing
	GG.StopMiscPriorityResourcing  = StopMiscPriorityResourcing
	GG.RemoveMiscPriorityUnit      = RemoveMiscPriorityUnit

	gadgetHandler:RegisterCMDID(CMD_PRIORITY)
	gadgetHandler:RegisterCMDID(CMD_MISC_PRIORITY)

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		spInsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
	end

	gadgetHandler:AddChatAction("debugpri", toggleDebug, "Debugs priority.")
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
	
	if ((ud.isFactory or ud.isBuilder) and ud.buildSpeed > 0) then 
		SetPriorityState(unitID, DefaultState, CMD_PRIORITY)
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
	if UnitMiscPriority[unitID] then
		RemoveMiscPriorityUnit(unitID,teamID)
	end
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