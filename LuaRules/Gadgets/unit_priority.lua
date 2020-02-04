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
		enabled   = true
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
	tooltip     = 'Morph&Stock Priority' .. TooltipsA[DefaultState + 1],
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
local effectiveTeamMetalReserved = {} -- Takes max storage into account
local effectiveTeamEnergyReserved = {} -- ditto for energy
local LastUnitFromFactory = {} -- LastUnitFromFactory[FactoryUnitID] = lastUnitID
local UnitOnlyEnergy = {} -- Whether a unit is only using energy for engine-default behaviour
local buildSpeedMod = {}


-- Derandomization of resource allocation. Remembers the portion of resources allocated to the unit and gives access
-- when they have a full chunk.
local UnitConPortion = {}
local UnitMiscPortion = {}

local miscResourceDrain = {} -- metal drain for custom unit added thru GG. function
local miscTeamPriorityUnits = {} --unit  that need priority handling
local MiscUnitOnlyEnergy = {} -- MiscUnitOnlyEnergy[unitID] for misc drain

local priorityTypes = {
	[CMD_PRIORITY] = {id = CMD_PRIORITY, param = "buildpriority", unitTable = UnitPriority},
	[CMD_MISC_PRIORITY] = {id = CMD_MISC_PRIORITY, param = "miscpriority", unitTable = UnitMiscPriority},
}

local ALLY_ACCESS = {allied = true}


local debugTeam = false
local debugOnUnits = false
local debugBuildUnit

GG.REPAIR_COSTS_METAL = true -- Configurable
GG.REPAIR_RESOURCE_MULT = 0.5
local REPAIR_METAL_COST_FACTOR = 0.5*GG.REPAIR_RESOURCE_MULT -- Must match energyCostFactor in modrules.

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
local spUseUnitResource   = Spring.UseUnitResource

local GetUnitCost = Spring.Utilities.GetUnitCost

local alliedTable = {allied = true}
local resourceTable = {e = 0, m = 0}

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
	local state = cmdParams[1] or 1
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

-- Misc Priority tasks can get their reduced build rate directly.
-- The external gadget is then trusted to obey the proportion which
-- they are allocated.
local function GetMiscPrioritySpendScale(unitID, teamID, onlyEnergy)

	if (teamMiscPriorityUnits[teamID] == nil) then
		teamMiscPriorityUnits[teamID] = {}
	end
	
	local scale
	if onlyEnergy then
		scale = TeamScaleEnergy[teamID]
	else
		scale = TeamScale[teamID]
	end
	
	local priorityLevel = (UnitMiscPriority[unitID] or 1) + 1

	teamMiscPriorityUnits[teamID][unitID] = priorityLevel
	
	if scale and scale[priorityLevel] then
		return scale[priorityLevel]
	end
	
	return 1 -- Units have full spending if they do not know otherwise.
end

local function CheckReserveResourceUse(teamID, onlyEnergy, resTable)
	local energyReserve = effectiveTeamEnergyReserved[teamID] or 0
	if energyReserve ~= 0 then
		local eCurr = spGetTeamResources(teamID, "energy")
		if eCurr <= energyReserve - ((resTable and resTable.e) or 0) then
			return false
		end
	end
	
	if onlyEnergy then
		return true
	end
	
	local metalReserve = effectiveTeamMetalReserved[teamID] or 0
	if metalReserve ~= 0 then
		local mCurr = spGetTeamResources(teamID, "metal")
		if mCurr <= metalReserve - ((resTable and resTable.m) or 0) then
			return false
		end
	end
	
	return true
end

-- This is the other way that Misc Priority tasks can build at the correct rate.
-- It is quite like AllowUnitBuildStep.
local function AllowMiscPriorityBuildStep(unitID, teamID, onlyEnergy, resTable)

	local conAmount = UnitMiscPortion[unitID] or math.random()

	if (teamMiscPriorityUnits[teamID] == nil) then
		teamMiscPriorityUnits[teamID] = {}
	end
	
	local scale
	if onlyEnergy then
		scale = TeamScaleEnergy[teamID]
	else
		scale = TeamScale[teamID]
	end
	
	local priorityLevel = (UnitMiscPriority[unitID] or 1) + 1
	
	teamMiscPriorityUnits[teamID][unitID] = priorityLevel
	if scale and scale[priorityLevel] then
		conAmount = conAmount + scale[priorityLevel]
		if conAmount >= 1 then
			UnitMiscPortion[unitID] = conAmount - 1
			return priorityLevel == 3 or CheckReserveResourceUse(teamID, onlyEnergy, resTable)
		else
			UnitMiscPortion[unitID] = conAmount
			return false
		end
	end
	
	return true
end

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step)
	if debugBuildUnit and debugBuildUnit[unitID] then
		Spring.Echo("AUBS", builderID, teamID, unitID, unitDefID, step, Spring.GetUnitHealth(unitID))
	end
	
	if (step <= 0) then
		--// Reclaiming and null buildpower (waited cons) aren't prioritized
		return true
	end
	
	local conAmount = UnitConPortion[builderID] or math.random()
	if (TeamPriorityUnits[teamID] == nil) then
		TeamPriorityUnits[teamID] = {}
	end
	
	local scale
	buildSpeedMod[builderID] = GG.unitRepairRate[unitID]
	if GG.unitRepairRate[unitID] then
		buildSpeedMod[builderID] = buildSpeedMod[builderID]*GG.REPAIR_RESOURCE_MULT
	end
	
	if GG.REPAIR_COSTS_METAL then
		scale = TeamScale[teamID]
	else
		if GG.unitRepairRate[unitID] then
			UnitOnlyEnergy[builderID] = true
			scale = TeamScaleEnergy[teamID]
		else
			UnitOnlyEnergy[builderID] = false
			scale = TeamScale[teamID]
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
			if not (priorityLevel == 3 or CheckReserveResourceUse(teamID)) then
				return false
			end
		else
			UnitConPortion[builderID] = conAmount
			return false
		end
	end
	
	-- Add metal cost to repairing
	if GG.REPAIR_COSTS_METAL and GG.unitRepairRate[unitID] then
		resourceTable.m = step*GetUnitCost(unitID, unitDefID)*REPAIR_METAL_COST_FACTOR
		if not spUseUnitResource(builderID, resourceTable) then
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
			local teamID = teams[i]
			debugMode = debugTeam and debugTeam[teamID]
			
			prioUnits = TeamPriorityUnits[teamID] or {}
			miscPrioUnits = teamMiscPriorityUnits[teamID] or {}
			
			local spending = {0,0,0}
			local energySpending = {0,0,0}
			
			local realEnergyOnlyPull = 0
			local scaleEnergy = TeamScaleEnergy[teamID]
			
			if debugMode then
				Spring.Echo("====== Frame " .. n .. " ======")
				if scaleEnergy then
					Spring.Echo("team " .. i .. " Initial energy only scale",
						"High", scaleEnergy[3],
						"Med", scaleEnergy[2],
						"Low", scaleEnergy[1]
					)
				end
			end
			
			for unitID, pri in pairs(prioUnits) do  --add construction priority spending
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID ~= nil then
					if UnitOnlyEnergy[unitID] then
						local buildSpeed = spGetUnitRulesParam(unitID, "buildSpeed") or UnitDefs[unitDefID].buildSpeed
						energySpending[pri] = energySpending[pri] + buildSpeed*(buildSpeedMod[unitID] or 1)
						if scaleEnergy and scaleEnergy[pri] then
							realEnergyOnlyPull = realEnergyOnlyPull + buildSpeed*(buildSpeedMod[unitID] or 1)*scaleEnergy[pri]
							
							if debugMode and debugOnUnits then
								GG.UnitEcho(unitID, "Energy Priority: " ..  pri ..
									", BP: " .. buildSpeed ..
									", Pull: " .. buildSpeed*(buildSpeedMod[unitID] or 1)*scaleEnergy[pri]
								)
							end
						end
					else
						local buildSpeed = spGetUnitRulesParam(unitID, "buildSpeed") or UnitDefs[unitDefID].buildSpeed
						spending[pri] = spending[pri] + buildSpeed*(buildSpeedMod[unitID] or 1)
						
						if debugMode and debugOnUnits then
							GG.UnitEcho(unitID, "Priority: " .. pri ..
								", BP: " ..  buildSpeed*(buildSpeedMod[unitID] or 1)
							)
						end
					end
				end
			end
			
			for unitID, miscData in pairs(miscResourceDrain) do --add misc priority spending
				local unitDefID = spGetUnitDefID(unitID)
				local pri = miscPrioUnits[unitID]
				if unitDefID ~= nil and pri then
					for index, drain in pairs(miscData) do
						if MiscUnitOnlyEnergy[unitID][index] then
							energySpending[pri] = energySpending[pri] + drain
							if scaleEnergy and scaleEnergy[pri] then
								realEnergyOnlyPull = realEnergyOnlyPull + drain*scaleEnergy[pri]
								
								if debugMode and debugOnUnits then
									GG.UnitEcho(unitID, "Misc Energy Priority " .. index .. ": " ..  pri ..
										", BP: " .. drain ..
										", Pull: " .. realEnergyOnlyPull + drain*scaleEnergy[pri]
									)
								end
							end
						else
							spending[pri] = spending[pri] + drain
							if debugMode and debugOnUnits then
								GG.UnitEcho(unitID, "Misc Priority " .. index .. ": " ..  pri ..
									", BP: " .. drain
								)
							end
						end
					end
				end
			end
			
			--SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)

			local level, mStor, fakeMetalPull, income, expense, _, _, recieved = spGetTeamResources(teamID, "metal", true)
			local elevel, eStor, fakeEnergyPull, eincome, eexpense, _, _, erecieved = spGetTeamResources(teamID, "energy", true)
			
			eincome = eincome + (spGetTeamRulesParam(teamID, "OD_energyIncome") or 0)
			
			effectiveTeamMetalReserved[teamID] = math.min(mStor - HIDDEN_STORAGE, TeamMetalReserved[teamID] or 0)
			effectiveTeamEnergyReserved[teamID] = math.min(eStor - HIDDEN_STORAGE, TeamEnergyReserved[teamID] or 0)
			
			-- Take away the constant income which was gained this frame (innate, reclaim)
			-- This is to ensure that level + total income is exactly what will be gained in the next second (if nothing is spent).
			local lumpIncome = (spGetTeamRulesParam(teamID, "OD_metalBase") or 0) +
				(spGetTeamRulesParam(teamID, "OD_metalOverdrive") or 0) + (spGetTeamRulesParam(teamID, "OD_metalMisc") or 0)
			level = level - (income - lumpIncome)/30
			
			-- Make sure the misc resoucing is constantly pulling the same value regardless of whether resources are spent
			-- If AllowUnitBuildStep returns false the constructor does not add the attempt to pull. This makes pull incorrect.
			-- The following calculations get the useful type of pull.
			local metalPull = spending[1] + spending[2] + spending[3]
			local energyPull = fakeEnergyPull + metalPull - fakeMetalPull + energySpending[1] + energySpending[2] + energySpending[3] - realEnergyOnlyPull

			spSetTeamRulesParam(teamID, "extraMetalPull", metalPull - fakeMetalPull, ALLY_ACCESS)
			spSetTeamRulesParam(teamID, "extraEnergyPull", energyPull - fakeEnergyPull, ALLY_ACCESS)
			
			if debugMode then
				if spending then
					Spring.Echo("team " .. i .. " Pull",
						"High", spending[3],
						"Med", spending[2],
						"Low", spending[1]
					)
				end
			end
			
			if debugMode then
				if energySpending then
					Spring.Echo("team " .. i .. " Energy Only Pull",
						"High", energySpending[3],
						"Med", energySpending[2],
						"Low", energySpending[1]
					)
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
					nextMetalLevel = nextMetalLevel - effectiveTeamMetalReserved[teamID]
					nextEnergyLevel = nextEnergyLevel - effectiveTeamEnergyReserved[teamID]
				end
			end
			
			if debugMode then
				if TeamScale[teamID] then
					Spring.Echo("team " .. i .. " Scale",
						"High", TeamScale[teamID][3],
						"Med", TeamScale[teamID][2],
						"Low", TeamScale[teamID][1]
					)
				end
			end
			
			if debugMode then
				if TeamScaleEnergy[teamID] then
					Spring.Echo("team " .. i .. " Energy Only Scale",
						"High", TeamScaleEnergy[teamID][3],
						"Med", TeamScaleEnergy[teamID][2],
						"Low", TeamScaleEnergy[teamID][1]
					)
				end
			end
			
		end
		
		
		teamMiscPriorityUnits = {} --reset priority list
		TeamPriorityUnits = {} --reset builder priority list (will be checked every n%32==15 th frame)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Misc priority unit handling

function AddMiscPriorityUnit(unitID) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		spInsertUnitCmdDesc(unitID, MiscCommandOrder, MiscCommandDesc)
		SetPriorityState(unitID, DefaultState, CMD_MISC_PRIORITY)
	end
end

function StartMiscPriorityResourcing(unitID, drain, energyOnly, key) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		AddMiscPriorityUnit(unitID)
	end
	if not miscResourceDrain[unitID] then
		miscResourceDrain[unitID]  = {}
		MiscUnitOnlyEnergy[unitID] = {}
	end
	key = key or 1
	miscResourceDrain[unitID][key] = drain
	MiscUnitOnlyEnergy[unitID][key] = energyOnly
end

function StopMiscPriorityResourcing(unitID, key) --remotely remove a forced priority command.
	if miscResourceDrain[unitID] then
		key = key or 1
		miscResourceDrain[unitID][key] = nil
		MiscUnitOnlyEnergy[unitID][key] = nil
	end
end

function RemoveMiscPriorityUnit(unitID) --remotely remove a forced priority command.
	if UnitMiscPriority[unitID] then
		if miscResourceDrain[unitID] then
			miscResourceDrain[unitID]  = nil
			MiscUnitOnlyEnergy[unitID] = nil
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
	if miscResourceDrain[unitID] then
		StopMiscPriorityResourcing(unitID)
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

local function toggleDebugBuild(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local unitID = tonumber(words[1])
	Spring.Echo("Debug build")
	if not unitID then
		Spring.Echo("Disabled")
		debugBuildUnit = nil
		return
	end
	
	Spring.Echo("unitID", unitID)
	debugBuildUnit = debugBuildUnit or {}
	debugBuildUnit[unitID] = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function gadget:Initialize()
	GG.AllowMiscPriorityBuildStep  = AllowMiscPriorityBuildStep
	GG.GetMiscPrioritySpendScale   = GetMiscPrioritySpendScale
	
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

	--toggleDebug(nil, nil, {"0"}, nil)
	gadgetHandler:AddChatAction("debugpri", toggleDebug, "Debugs priority.")
	gadgetHandler:AddChatAction("debugbuild", toggleDebugBuild, "Debugs build step.")
end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("mreserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID, false)
		local amount = tonumber(msg:sub(10))
		if spec or (not teamID) or (not amount) then
			return
		end
		SetMetalReserved(teamID, amount)
	end
	if msg:find("ereserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID, false)
		local amount = tonumber(msg:sub(10))
		if spec or (not teamID) or (not amount) then
			return
		end
		SetEnergyReserved(teamID, amount)
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
	
	if ((ud.isFactory or ud.isBuilder) and (ud.buildSpeed > 0 and not ud.customParams.nobuildpower)) then
		SetPriorityState(unitID, DefaultState, CMD_PRIORITY)
	else  -- not a builder priority makes no sense now
		UnitPriority[unitID] = nil
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end

end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	UnitPriority[unitID] = nil
	LastUnitFromFactory[unitID] = nil
	if UnitMiscPriority[unitID] then
		RemoveMiscPriorityUnit(unitID)
	end
end
