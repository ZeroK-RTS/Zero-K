-- $Id: unit_mex_overdrive.lua 4550 2009-05-05 18:07:29Z licho $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if not (gadgetHandler:IsSyncedCode()) then
	return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Mex Control with energy link",
    desc      = "Controls mex overload and energy link grid",
    author    = "Licho, Google Frog (pylon conversion)",
    date      = "16.5.2008 (OD date)",
    license   = "GNU GPL, v2 or later",
    layer     = -4,   -- OD grid circles must be drawn before lava drawing gadget some maps have (which has layer = -3)
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mexDefs = {}
--local energyDefs = {}
local pylonDefs = {}
local generatorDefs = {}
local odSharingModOptions = (Spring.GetModOptions()).overdrivesharingscheme or "investmentreturn"

local enableEnergyPayback = ((odSharingModOptions == "investmentreturn") or (odSharingModOptions == "investmentreturn_od"))
local enableMexPayback = ((odSharingModOptions == "investmentreturn") or (odSharingModOptions == "investmentreturn_base"))

include("LuaRules/Configs/constants.lua")
include("LuaRules/Configs/mex_overdrive.lua")

for i = 1, #UnitDefs do
	local udef = UnitDefs[i]
	if (udef.customParams.ismex) then
		mexDefs[i] = true
	end
	local pylonRange = tonumber(udef.customParams.pylonrange) or 0
	if pylonRange > 0 then
		pylonDefs[i] = {
			range = pylonRange or DEFAULT_PYLON_RANGE,
			neededLink = tonumber(udef.customParams.neededlink) or false,
			keeptooltip = udef.customParams.keeptooltip or false,
		}
	end
	local metalIncome = tonumber(udef.customParams.income_metal) or 0
	local energyIncome = tonumber(udef.customParams.income_energy) or 0
	local isWind = (udef.customParams.windgen and true) or false
	if metalIncome > 0 or energyIncome > 0 or isWind then
		generatorDefs[i] = {
			metalIncome = metalIncome,
			energyIncome = energyIncome,
		}
	end
end

local alliedTrueTable = {allied = true}
local inlosTrueTable = {inlos = true}

local sentErrorWarning = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


Spring.SetGameRulesParam("lowpower",1)

local MEX_DIAMETER = Game.extractorRadius*2

local function paybackFactorFunction(repayRatio)
	-- Must map [0,1) to (0,1]
	-- Must not have any sequences on the domain that converge to 0 in the codomain.
	local repay =  0.35 - repayRatio*0.25
	if repay > 0.33 then
		return 0.33
	else
		return repay
	end
end


local PAYBACK_FACTOR = 0.5

local paybackDefs = { -- cost is how much to pay back
	[UnitDefNames["armwin"].id] = {cost = UnitDefNames["armwin"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["armsolar"].id] = {cost = UnitDefNames["armsolar"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["armfus"].id] = {cost = UnitDefNames["armfus"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["cafus"].id] = {cost = UnitDefNames["cafus"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["geo"].id] = {cost = UnitDefNames["geo"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["amgeo"].id] = {cost = UnitDefNames["amgeo"].metalCost*PAYBACK_FACTOR},
}

--local PYLON_ENERGY_RANGESQ = 160000
--local PYLON_LINK_RANGESQ = 40000
--local PYLON_MEX_RANGESQ = 10000
--local PYLON_MEX_LIMIT = 100

--local CMD_MEXE = 30666

local spammedError = false
local debugMode = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local sqrt  = math.sqrt
local min   = math.min
local max   = math.max

local spValidUnitID       = Spring.ValidUnitID
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitTeam       = Spring.GetUnitTeam
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitStates     = Spring.GetUnitStates
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitResources  = Spring.GetUnitResources
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spCallCOBScript     = Spring.CallCOBScript
local spSetTeamRulesParam = Spring.SetTeamRulesParam

local spGetTeamResources  = Spring.GetTeamResources
local spAddTeamResource   = Spring.AddTeamResource
local spUseTeamResource   = Spring.UseTeamResource
local spGetTeamInfo       = Spring.GetTeamInfo

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local mexes = {}   -- mexes[teamID][gridID][unitID] == mexMetal
local mexByID = {} -- mexByID[unitID] = {gridID, allyTeamID, refundTeamID, refundTime, refundTotal, refundSoFar}

local pylon = {} -- pylon[allyTeamID][unitID] = {gridID,mexes,mex[unitID],x,z,overdrive, nearPlant[unitID],nearPylon[unitID], color}
local pylonList = {} -- pylon[allyTeamID] = {data = {[1] = unitID, [2] = unitID, ...}, count = number}

local generator = {} -- generator[allyTeamID][teamID][unitID] = {generatorListID, metalIncome, energyIncome}
local generatorList = {} -- generator[allyTeamID][teamID] = {data  = {[1] = unitID, [2] = unitID, ...}, count = number}
local resourceGenoratingUnit = {}

local pylonGridQueue = false -- pylonGridQueue[unitID] = true

local unitPaybackTeamID = {} -- indexed by unitID, tells unit which team gets it's payback.
local teamPayback = {} -- teamPayback[teamID] = {count = 0, toRemove = {}, data = {[1] = {unitID = unitID, cost = costOfUnit, repaid = howMuchHasBeenRepaid}}}

local allyTeamInfo = {} 

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		pylon[allyTeamID] = {}
		pylonList[allyTeamID] = {data = {}, count = 0}
		generator[allyTeamID] = {}
		generatorList[allyTeamID] = {}
		mexes[allyTeamID] = {}
		mexes[allyTeamID][0] = {}

		allyTeamInfo[allyTeamID] = {
			--plant = {},
			mexMetal = 0,
			mexSquaredSum = 0, 
			mexCount = 0, 
			grids = 0, 
			grid = {}, -- pylon[unitID], plant[unitID], mexMetal, mexSquaredSum
			nilGrid = {},
			team = {},
			teams = 0,
		}

		local teamList = Spring.GetTeamList(allyTeamID)
		for j = 1, #teamList do
			local teamID = teamList[j]
			allyTeamInfo[allyTeamID].teams = allyTeamInfo[allyTeamID].teams + 1
			allyTeamInfo[allyTeamID].team[allyTeamInfo[allyTeamID].teams] = teamID
			
			generator[allyTeamID][teamID] = {}
			generatorList[allyTeamID][teamID] = {data = {}, count = 0}
		end
	end
end
 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Awards

GG.Overdrive_allyTeamResources = {}
local lastAllyTeamResources = {} -- 1 second lag for resource updates

local function sendAllyTeamInformationToAwards(allyTeamID, summedBaseMetal, summedOverdrive, allyTeamEnergyIncome, ODenergy, wasteEnergy)
	local last = lastAllyTeamResources[allyTeamID] or {}
	GG.Overdrive_allyTeamResources[allyTeamID] = {
		baseMetal = summedBaseMetal,
		overdriveMetal = last.overdriveMetal or 0,
		baseEnergy = allyTeamEnergyIncome,
		overdriveEnergy = last.overdriveEnergy or 0,
		wasteEnergy = last.wasteEnergy or 0,
	}
	lastAllyTeamResources[allyTeamID] = {
		overdriveMetal = summedOverdrive,
		overdriveEnergy = ODenergy,
		wasteEnergy = wasteEnergy,
	}
end


GG.Overdrive_teamResources = {}
local lastTeamResources = {} -- 1 second lag for resource updates

local function sendTeamInformationToAwards(teamID, baseMetal, overdriveMetal, overdriveEnergyChange)
	local last = lastTeamResources[teamID] or {}
	GG.Overdrive_teamResources[teamID] = {
		baseMetal = baseMetal,
		overdriveMetal = last.overdriveMetal or 0,
		overdriveEnergyChange = last.overdriveEnergyChange or 0,
	}
	lastTeamResources[teamID] = {
		overdriveMetal = overdriveMetal,
		overdriveEnergyChange = overdriveEnergyChange,
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Debug Functions
 
 function TableEcho(data, indent)
	indent = indent or ""
	for name, v in pairs(data) do
		local ty =  type(v)
		if ty == "table" then
			Spring.Echo(indent .. name .. " = {")
			TableEcho(v, indent .. "    ")
			--Spring.Echo(indent .. "}")
		elseif ty == "boolean" then
			Spring.Echo(indent .. name .. " = " .. (v and "true" or "false"))
		else
			Spring.Echo(indent .. name .. " = " .. v)
		end
	end
end

function UnitEcho(unitID, st)
	st = st or unitID
	if Spring.ValidUnitID(unitID) then
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid unitID")
		Spring.Echo(unitID)
	end
end
 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- local functions

local function energyToExtraM(energy)  
	return sqrt(energy)*0.25
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Information Sharing to Widget functions

local privateTable = {private = true}
local previousData = {}

local function SetTeamEconomyRulesParams(
			teamID, activeCount, -- TeamID of the team as well as number of active allies.
			
			summedBaseMetal, -- AllyTeam base metal extrator income
			summedOverdrive, -- AllyTeam overdrive income
			allyTeamMiscMetalIncome, -- AllyTeam constructor income
			
			allyTeamEnergyIncome, -- AllyTeam total energy generator income
			overdriveEnergySpending, -- AllyTeam energy spent on overdrive
			energyWasted, -- AllyTeam energy excess
			
			baseShare, -- Team share of base metal extractor income
			odShare, -- Team share of overdrive income
			miscShare, -- Team share of constructor metal income
			
			energyIncome, -- Total energy generator income
			overdriveEnergyNet, -- Amount of energy spent or recieved due to overdrive and income
			overdriveEnergyChange) -- real change in energy due to overdrive

	if previousData[teamID] then
		local pd = previousData[teamID]		
		spSetTeamRulesParam(teamID, "OD_allies",               pd.activeCount, privateTable)
		
		spSetTeamRulesParam(teamID, "OD_team_metalBase",       pd.summedBaseMetal, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_metalOverdrive",  pd.summedOverdrive, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_metalMisc",       pd.allyTeamMiscMetalIncome, privateTable)
		
		spSetTeamRulesParam(teamID, "OD_team_energyIncome",    pd.allyTeamEnergyIncome, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_energyOverdrive", pd.overdriveEnergySpending, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_energyWaste",     pd.energyWasted, privateTable)
		
		spSetTeamRulesParam(teamID, "OD_metalBase",       pd.baseShare, privateTable)
		spSetTeamRulesParam(teamID, "OD_metalOverdrive",  pd.odShare, privateTable)
		spSetTeamRulesParam(teamID, "OD_metalMisc",       pd.miscShare, privateTable)
		
		spSetTeamRulesParam(teamID, "OD_energyIncome",    pd.energyIncome, privateTable)
		spSetTeamRulesParam(teamID, "OD_energyOverdrive", pd.overdriveEnergyNet, privateTable)
		spSetTeamRulesParam(teamID, "OD_energyChange",    pd.overdriveEnergyChange, privateTable)
		
		spSetTeamRulesParam(teamID, "OD_RoI_metalDue",    teamPayback[teamID].metalDueOD, privateTable)
		spSetTeamRulesParam(teamID, "OD_base_metalDue",   teamPayback[teamID].metalDueBase, privateTable)
	else
		previousData[teamID] = {}
	end
	
	local pd = previousData[teamID]	 
	
	pd.activeCount = activeCount
	
	pd.summedBaseMetal = summedBaseMetal
	pd.summedOverdrive = summedOverdrive
	pd.allyTeamMiscMetalIncome = allyTeamMiscMetalIncome
	
	pd.allyTeamEnergyIncome = allyTeamEnergyIncome
	pd.overdriveEnergySpending = overdriveEnergySpending
	pd.energyWasted = energyWasted
	
	pd.baseShare = baseShare
	pd.odShare = odShare
	pd.miscShare = miscShare
	
	pd.energyIncome = energyIncome
	pd.overdriveEnergyNet = overdriveEnergyNet
	pd.overdriveEnergyChange = overdriveEnergyChange
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- PYLONS

local function AddPylonToGrid(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]

	if debugMode then
		Spring.Echo("AddPylonToGrid " .. unitID)
	end
	
	local newGridID = 0
	local attachedGrids = 0
	local attachedGrid = {}
	local attachedGridID = {}
	
	--check for nearby pylons
	local ownRange = pylon[allyTeamID][unitID].linkRange
	local list = pylonList[allyTeamID]
	for i = 1, list.count do
		local pid = list.data[i]
		local pylonData = pylon[allyTeamID][pid]
		if pylonData then
			if pid ~= unitID and (pylonData.x-pX)^2 + (pylonData.z-pZ)^2 <= (pylonData.linkRange+ownRange)^2  and pylonData.gridID ~= 0 and pylonData.active then
				pylon[allyTeamID][unitID].nearPylon[pid] = true
				if not attachedGridID[pylonData.gridID] then
					attachedGrids = attachedGrids + 1
					
					attachedGrid[attachedGrids] = pylonData.gridID
					attachedGridID[pylonData.gridID] = true
				end
			end
		elseif not spammedError then
			Spring.Echo("Pylon problem detected in AddPylonToGrid.")
		end
	end
	
	if attachedGrids == 0 then -- create a new grid
		local foundSpot = false
		for i = 1, ai.grids  do
			if ai.nilGrid[i] then
				ai.grid[i] = {
					pylon = {},
					--plant = {},
					mexMetal = 0,
					mexSquaredSum = 0,
				}
				newGridID = i
				ai.nilGrid[i] = false
				foundSpot = true
				break
			end
		end
		if not foundSpot then
			ai.grids = ai.grids + 1
			newGridID = ai.grids
			ai.grid[ai.grids] = {
				pylon = {},
				--plant = {},
				mexMetal = 0,
				mexSquaredSum = 0,
			}
			mexes[allyTeamID][newGridID] = {}
		end
		
	else -- add to an existing grid
		newGridID = attachedGrid[1]
		for i = 2, attachedGrids do -- merge grids if it attaches to 2 or more
			local oldGridID = attachedGrid[i]
			for pid,_ in pairs(ai.grid[oldGridID].pylon) do
				local pylonData = pylon[allyTeamID][pid]
				pylonData.gridID = newGridID
				--NOTE: since mex became a pylon it no longer store list of mex, now only store itself as mex
				if pylonData.mex then
					local mid = pid
					mexes[allyTeamID][newGridID][mid] = mexes[allyTeamID][oldGridID][mid]
					mexByID[mid].gridID = newGridID
					mexes[allyTeamID][oldGridID][mid] = nil
				end
				ai.grid[newGridID].pylon[pid] = true
				spSetUnitRulesParam(pid,"gridNumber",newGridID,alliedTrueTable)
			end
			--[[for eid,_ in pairs(ai.grid[oldGridID].plant) do
				ai.grid[newGridID].plant[eid] = true
			end--]]
			ai.grid[newGridID].mexMetal = ai.grid[newGridID].mexMetal + ai.grid[oldGridID].mexMetal
			ai.grid[newGridID].mexSquaredSum = ai.grid[newGridID].mexSquaredSum + ai.grid[oldGridID].mexSquaredSum
			ai.nilGrid[oldGridID] = true
		end
	end
	
	ai.grid[newGridID].pylon[unitID] = true
	pylon[allyTeamID][unitID].gridID = newGridID
	spSetUnitRulesParam(unitID,"gridNumber",newGridID,alliedTrueTable)
	
	-- add econ to new grid
	-- mexes
	if pylon[allyTeamID][unitID].mex then
		local mid = unitID
		local orgMetal = mexes[allyTeamID][0][mid]
		ai.mexMetal = ai.mexMetal + orgMetal
		ai.mexSquaredSum = ai.mexSquaredSum + (orgMetal * orgMetal)
		
		ai.grid[newGridID].mexMetal = ai.grid[newGridID].mexMetal + orgMetal
		ai.grid[newGridID].mexSquaredSum = ai.grid[newGridID].mexSquaredSum + (orgMetal * orgMetal)
		
		mexes[allyTeamID][newGridID][mid] = orgMetal
		mexByID[mid].gridID = newGridID
		mexes[allyTeamID][0][mid] = nil
	end
	
	-- energy
	--[[for eid,_ in pairs(pylon[allyTeamID][unitID].nearEnergy) do
		ai.grid[newGridID].plant[eid] = true
	end--]]
end

local function QueueAddPylonToGrid(unitID)
	if debugMode then
		Spring.Echo("QueueAddPylonToGrid " .. unitID)
	end
	if not pylonGridQueue then
		pylonGridQueue = {}
	end
	pylonGridQueue[unitID] = true
end

local function RemovePylonsFromGridQueue(unitID)
	if debugMode then
		Spring.Echo("RemovePylonsFromGridQueue " .. unitID)
	end
	if pylonGridQueue then
		pylonGridQueue[unitID] = nil
	end
end

local function AddPylon(unitID, unitDefID, range)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]

	if pylon[allyTeamID][unitID] then
		return
	end
	
	pylon[allyTeamID][unitID] = {
		gridID = 0,
		--mexes = 0,
		mex = (mexByID[unitID] and true) or false,
		nearPylon = {},
		linkRange = range,
		mexRange = 10,
		--nearEnergy = {},
		x = pX,
		z = pZ,
		neededLink = pylonDefs[unitDefID].neededLink,
		active = true,
	}
	
	local list = pylonList[allyTeamID]
	list.count = list.count + 1
	list.data[list.count] = unitID
	
	pylon[allyTeamID][unitID].listID = list.count
	
	if debugMode then
		Spring.Echo("AddPylon " .. unitID)
		UnitEcho(unitID, list.count .. ", " .. unitID)
	end
	
	-- check for mexes
	--[[
	if unitOverdrive then 
		for mid, orgMetal in pairs(mexes[allyTeamID][0]) do
			local mX,_,mZ = spGetUnitPosition(mid)
			if (mid == unitID) then -- mex as pylon
			--if (pX-mX)^2 + (pZ-mZ)^2 <= range^2 and not takenMexId[mid] then
			
				--pylon[allyTeamID][unitID].mexes = pylon[allyTeamID][unitID].mexes + 1
				pylon[allyTeamID][unitID].mex = true
				--takenMexId[mid] = true
				
				--if pylon[allyTeamID][unitID].mexes >= PYLON_MEX_LIMIT then
				--	break
				--end
			end
		end
	end
	--]]
	
	-- check for energy
	--[[
	for eid, state in pairs(ai.plant) do
		if (state == 0) then
			local eX,_,eZ = spGetUnitPosition(eid)
			if (pX-eX)^2 + (pZ-eZ)^2 < PYLON_ENERGY_RANGESQ then
				ai.plant[eid] = 1
				pylon[allyTeamID][unitID].nearEnergy[eid] = true
			end
		end
	end
	--]]
	
	QueueAddPylonToGrid(unitID)
end

local function DestroyGrid(allyTeamID,oldGridID)
	local ai = allyTeamInfo[allyTeamID]
	
	if debugMode then
		Spring.Echo("DestroyGrid " .. oldGridID)
	end
	
	for pid,_ in pairs(ai.grid[oldGridID].pylon) do
		pylon[allyTeamID][pid].gridID = 0
		pylon[allyTeamID][pid].nearPylon = {}
		
		if (pylon[allyTeamID][pid].mex) then
			local mid = pid
			local orgMetal = mexes[allyTeamID][oldGridID][mid]
			mexes[allyTeamID][oldGridID][mid] = nil
			mexes[allyTeamID][0][mid] = orgMetal
			mexByID[mid].gridID = 0

			ai.mexCount = ai.mexCount - 1
			ai.mexMetal = ai.mexMetal - orgMetal
			ai.mexSquaredSum = ai.mexSquaredSum - (orgMetal * orgMetal)
		end
	end
	
	ai.nilGrid[oldGridID] = true
end

local function ReactivatePylon(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	if debugMode then
		Spring.Echo("ReactivatePylon " .. unitID)
	end
	
	--local pX,_,pZ = spGetUnitPosition(unitID)
	
	pylon[allyTeamID][unitID].active = true

	-- check for energy
	--[[
	for eid, state in pairs(ai.plant) do
		if state == 0 then
			local eX,_,eZ = spGetUnitPosition(eid)
			if (pX-eX)^2 + (pZ-eZ)^2 < PYLON_ENERGY_RANGESQ then
				state = 1
				pylon[allyTeamID][unitID].nearEnergy[eid] = true
			end
		end
	
	end
	--]]
	
	QueueAddPylonToGrid(unitID)
end

local function DeactivatePylon(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	if debugMode then
		Spring.Echo("DeactivatePylon " .. unitID)
	end
	
	RemovePylonsFromGridQueue(unitID)
	
	local oldGridID = pylon[allyTeamID][unitID].gridID
	if oldGridID ~= 0 then
		local pylonMap = ai.grid[oldGridID].pylon
		local energyList = pylon[allyTeamID][unitID].nearEnergy
		
		DestroyGrid(allyTeamID,oldGridID)
		
		for pid,_ in pairs(pylonMap) do
			if (pid ~= unitID) then
				QueueAddPylonToGrid(pid)
			end
		end
	end
	
	pylon[allyTeamID][unitID].active = false
end

local function RemovePylon(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	
	if debugMode then
		Spring.Echo("RemovePylon start " .. unitID)
		TableEcho(pylonList[allyTeamID])
		TableEcho(pylon[allyTeamID])
	end
	
	RemovePylonsFromGridQueue(unitID)
	
	if not pylon[allyTeamID][unitID] then
		--Spring.Echo("RemovePylon not pylon[allyTeamID][unitID] " .. unitID)
		return
	end
	
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	local oldGridID = pylon[allyTeamID][unitID].gridID
	local activeState = pylon[allyTeamID][unitID].active
	
	local isMex = pylon[allyTeamID][unitID].mex
	
	if activeState and oldGridID ~= 0 then
		local pylonMap = ai.grid[oldGridID].pylon
		local energyList = pylon[allyTeamID][unitID].nearEnergy
	
		DestroyGrid(allyTeamID,oldGridID)
		
		for pid,_ in pairs(pylonMap) do
			if (pid ~= unitID) then
				QueueAddPylonToGrid(pid)
			end
		end	
	end
	
	local list = pylonList[allyTeamID]
	local listID = pylon[allyTeamID][unitID].listID
	list.data[listID] = list.data[list.count]
	pylon[allyTeamID][list.data[listID]].listID = listID
	list.data[list.count] = nil
	list.count = list.count - 1
	pylon[allyTeamID][unitID] = nil
	
	-- mexes
	if isMex then
		local mid = unitID
		local orgMetal = mexes[allyTeamID][0][mid]
		mexes[allyTeamID][0][mid] = nil

		local teamID = mexByID[unitID].refundTeamID
		if teamID then
			teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - mexByID[unitID].refundTotal + mexByID[unitID].refundSoFar
		end
		mexByID[unitID] = nil
		local mexGridID = oldGridID --Note: mexGridID is oldGridID of this pylon because mex is this pylon
		-- takenMexId[unitID] = false
		
		mexes[allyTeamID][mexGridID][mid] = orgMetal
		mexByID[unitID].gridID = mexGridID
		if mexGridID ~= 0 then
			local ai = allyTeamInfo[allyTeamID]
			ai.mexCount = ai.mexCount + 1
			ai.mexMetal = ai.mexMetal + orgMetal
			ai.mexSquaredSum = ai.mexSquaredSum + (orgMetal * orgMetal)
			ai.grid[mexGridID].mexMetal = ai.grid[mexGridID].mexMetal + orgMetal
			ai.grid[mexGridID].mexSquaredSum = ai.grid[mexGridID].mexSquaredSum + (orgMetal * orgMetal)
		end
	end
	
	if debugMode then
		Spring.Echo("RemovePylon end " .. unitID)
		TableEcho(pylonList[allyTeamID])
		TableEcho(pylon[allyTeamID])
	end
	
end

local function AddPylonsInQueueToGrid()
	if pylonGridQueue then
		for pid,_ in pairs(pylonGridQueue) do
			AddPylonToGrid(pid)
		end
		pylonGridQueue =false
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- PAYBACK

-- teamPayback[teamID] = {count = 0, toRemove = {}, data = {[1] = {unitID = unitID, cost = costOfUnit, repaid = howMuchHasBeenRepaid}}}

local function AddEnergyToPayback(unitID, unitDefID, unitTeam)
	if unitPaybackTeamID[unitID] then
		-- Only add units to payback once.
		return
	end
	local def = paybackDefs[unitDefID]
	unitPaybackTeamID[unitID] = unitTeam
	
	local teamData = teamPayback[unitTeam]
	teamData.count = teamData.count + 1
	teamData.data[teamData.count] = {
		unitID = unitID,
		cost = def.cost,
		repaid = 0,
	}
	teamData.metalDueOD = teamData.metalDueOD + def.cost
end

local function RemoveEnergyToPayback(unitID, unitDefID)
	local unitTeam = unitPaybackTeamID[unitID]
	if unitTeam then -- many energy pieces will not have a payback when destroyed
		local teamData = teamPayback[unitTeam]
		teamData.toRemove[unitID] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Overdrive and resource handling

local function OptimizeOverDrive(allyTeamID,allyTeamData,allyE,maxGridCapacity)
	
	local summedMetalProduction = 0
	local summedBaseMetal = 0
	local summedOverdrive = 0
	
	local maxedMetalProduction = 0
	local maxedBaseMetal = 0
	local maxedOverdrive = 0
    
    
	local allyMetal = allyTeamData.mexMetal
	local allyMetalSquared = allyTeamData.mexSquaredSum
	local allyTeamMexes = mexes[allyTeamID]
	
	local energyWasted = allyE
	
	local gridEnergySpent = {}
	local gridMetalGain = {}
	
	local mexBaseMetal = {}
	local privateBaseMetal = {}

	local reCalc = true
	local maxedGrid = {}
	while reCalc do	-- calculate overdrive for as long as a new grid is not maxed
		reCalc = false
		for i = 1, allyTeamData.grids do -- loop through grids
			if not (maxedGrid[i] or allyTeamData.nilGrid[i]) then -- do not check maxed grids
				gridEnergySpent[i] = 0
				gridMetalGain[i] = 0
				for unitID, orgMetal in pairs(allyTeamMexes[i]) do -- loop mexes
					local stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
					if stunned_or_inbuld then
						orgMetal = 0
					end
					local incomeFactor = spGetUnitRulesParam(unitID, "resourceGenerationFactor") or 1
					if incomeFactor then
						orgMetal = orgMetal*incomeFactor
					end
					local mexE = 0
					if (allyMetalSquared > 0) then -- divide energy in ratio given by squared metal from mex
						mexE = allyE*(orgMetal * orgMetal)/ allyMetalSquared --the fraction of E to be consumed with respect to all other Mex
						energyWasted = energyWasted-mexE --leftover E minus Mex usage
						gridEnergySpent[i] = gridEnergySpent[i] + mexE
						-- if a grid is being too overdriven it has become maxed.
						-- the grid's mexSqauredSum is used for best distribution
						if gridEnergySpent[i] > maxGridCapacity[i] then --final Mex to be looped since we are out of E to OD the rest of the Mex
							gridMetalGain[i] = 0
							local gridE = maxGridCapacity[i]
							local gridMetalSquared = allyTeamData.grid[i].mexSquaredSum
							if gridMetalSquared <= 0 and not sentErrorWarning then
								Spring.Echo("** Warning: gridMetalSquared <= 0 **")
								Spring.Echo(gridMetalSquared)
								sentErrorWarning = true
							end
							
							gridEnergySpent[i] = maxGridCapacity[i]
                            
							summedMetalProduction = 0
                            summedBaseMetal = 0
							summedOverdrive = 0
                            
							maxedGrid[i] = true
							reCalc = true
							allyE = allyE - gridE
							energyWasted = allyE
							for unitID, orgMetal in pairs(allyTeamMexes[i]) do --re-distribute the grid energy to Mex (again! except taking account the limited energy of the grid)
								local stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
								if stunned_or_inbuld then
									orgMetal = 0
								end
								local incomeFactor = spGetUnitRulesParam(unitID,"resourceGenerationFactor")
								if incomeFactor then
									orgMetal = orgMetal*incomeFactor
								end
								local mexE = gridE*(orgMetal * orgMetal)/ gridMetalSquared 
								local metalMult = energyToExtraM(mexE)
								local thisMexM = orgMetal + orgMetal * metalMult
								
								spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5, inlosTrueTable)
								spSetUnitRulesParam(unitID, "overdrive_energyDrain", mexE, inlosTrueTable)
								spSetUnitRulesParam(unitID, "current_metalIncome", thisMexM, inlosTrueTable)
								spSetUnitRulesParam(unitID, "overdrive_proportion", metalMult, inlosTrueTable)
 
								maxedMetalProduction = maxedMetalProduction + thisMexM
								maxedBaseMetal = maxedBaseMetal + orgMetal
                                maxedOverdrive = maxedOverdrive + orgMetal * metalMult
                                
								allyMetalSquared = allyMetalSquared - orgMetal * orgMetal
								gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
								
								if mexByID[unitID].refundTeamID then
									mexBaseMetal[unitID] = orgMetal
								end
							end
							break --finish distributing energy to 1 grid, go to next grid
						end
					end 
					
					local metalMult = energyToExtraM(mexE)
					local thisMexM = orgMetal + orgMetal * metalMult
					
					spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5, inlosTrueTable)
					spSetUnitRulesParam(unitID, "overdrive_energyDrain", mexE, inlosTrueTable)
					spSetUnitRulesParam(unitID, "current_metalIncome", thisMexM, inlosTrueTable)
					spSetUnitRulesParam(unitID, "overdrive_proportion", metalMult, inlosTrueTable)
					
					summedMetalProduction = summedMetalProduction + thisMexM
					summedBaseMetal = summedBaseMetal + orgMetal
                    summedOverdrive = summedOverdrive + orgMetal * metalMult
                    
					gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
					
					if mexByID[unitID].refundTeamID then
						mexBaseMetal[unitID] = orgMetal
					end
				end
				
				if reCalc then
					break
				end
			end
		end
	end
	
	for unitID, value in pairs(mexBaseMetal) do
		local teamID = mexByID[unitID].refundTeamID
		local private_share = value*MEX_REFUND_SHARE*mexByID[unitID].refundTime/mexByID[unitID].refundTimeTotal
		privateBaseMetal[teamID] = (privateBaseMetal[teamID] or 0) + private_share
		teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - private_share

		mexByID[unitID].refundTime = mexByID[unitID].refundTime - 1
		mexByID[unitID].refundSoFar = mexByID[unitID].refundSoFar + private_share
		if mexByID[unitID].refundTime <= 0 then
			mexByID[unitID].refundTeamID = nil
			mexByID[unitID].refundTime = nil
			teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - mexByID[unitID].refundTotal + mexByID[unitID].refundSoFar
		end
	end
	
	if energyWasted < 0.01 then
		energyWasted = 0
	end

	return energyWasted,
		summedMetalProduction + maxedMetalProduction,
		summedBaseMetal + maxedBaseMetal,
        summedOverdrive + maxedOverdrive,
		gridEnergySpent,
		gridMetalGain,
		privateBaseMetal
end

local function teamEcho(team, st)
    if team == 0 then
        Spring.Echo(st)
    end
end

local lastTeamOverdriveSpending = {}

function gadget:GameFrame(n)
	if (n%TEAM_SLOWUPDATE_RATE == 1) then
		for allyTeamID, allyTeamData in pairs(allyTeamInfo) do 
			--// Check if pylons changed their active status (emp, reverse-build, ..)
			local list = pylonList[allyTeamID]
			for i = 1, list.count do
				local unitID = list.data[i]
				local pylonData = pylon[allyTeamID][unitID]
				if pylonData then
					if spValidUnitID(unitID) then
						local stunned_or_inbuld = spGetUnitIsStunned(unitID) or 
							(spGetUnitRulesParam(unitID,"disarmed") == 1) or 
							(spGetUnitRulesParam(unitID,"morphDisable") == 1)
						local states = spGetUnitStates(unitID)
						local currentlyActive = (not stunned_or_inbuld) and ((states and states.active) or pylonData.neededLink)
						if (currentlyActive) and (not pylonData.active) then
							ReactivatePylon(unitID)
						elseif (not currentlyActive) and (pylonData.active) then
							DeactivatePylon(unitID)
						end
					end
				elseif not spammedError then
					Spring.Echo("Pylon problem detected in status check.")
				end
			end
			
			AddPylonsInQueueToGrid()

			--// Calculate total energy and other metal income from structures and units
			-- Does not include reclaim
			local teamEnergy = {}
			
			local allyTeamEnergyIncome = 0
			local allyTeamExpense = 0
			local allyTeamEnergySpare = 0
			local allyTeamPositiveSpare = 0
			local allyTeamNegativeSpare = 0
			local allyTeamEnergyCurrent = 0
			local allyTeamEnergyMax = 0
			
			local allyTeamMiscMetalIncome = 0
			
			local sumInc = 0
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				
				-- Calculate total energy and misc. metal income from units and structures
				local genList = generatorList[allyTeamID][teamID]
				local gen = generator[allyTeamID][teamID]
				local sumMetal = 0
				local sumEnergy = 0
				for i = 1, genList.count do 
					local unitID = genList.data[i]
					local data = gen[unitID]
					if spValidUnitID(unitID) then
						if spGetUnitRulesParam(unitID, "isWind") then
							local energy = spGetUnitRulesParam(unitID,"current_energyIncome") or 0
							sumEnergy = sumEnergy + energy
						else
							local stunned_or_inbuld = spGetUnitIsStunned(unitID)
							local states = spGetUnitStates(unitID)
							local currentlyActive = not stunned_or_inbuld
							metal, energy = 0, 0, 0
							if currentlyActive then
								local incomeFactor = spGetUnitRulesParam(unitID,"resourceGenerationFactor") or 1
								metal  = data.metalIncome*incomeFactor
								energy = data.energyIncome*incomeFactor 
								
								sumMetal = sumMetal + metal
								sumEnergy = sumEnergy + energy
							end
							spSetUnitRulesParam(unitID, "current_metalIncome", metal, inlosTrueTable)
							spSetUnitRulesParam(unitID, "current_energyIncome", energy, inlosTrueTable)
						end
					end
				end
				
				-- Collect energy information and contribute to ally team data.
				teamEnergy[teamID] = {}
				local te = teamEnergy[teamID]
				te.cur, te.max, te.pull, _, te.exp, _, te.sent, te.rec = spGetTeamResources(teamID, "energy")
				te.exp = math.max(0, te.exp - (lastTeamOverdriveSpending[teamID] or 0))
				
				te.max = te.max - HIDDEN_STORAGE
				te.inc = sumEnergy -- Income only from energy structures and constructors. Possibly add reclaim here
				
				allyTeamMiscMetalIncome = allyTeamMiscMetalIncome + sumMetal
				allyTeamEnergyIncome = allyTeamEnergyIncome + sumEnergy
				allyTeamEnergyCurrent = allyTeamEnergyCurrent + te.cur
				allyTeamEnergyMax = allyTeamEnergyMax + te.max
				allyTeamExpense = allyTeamExpense + te.exp
				
				te.spare = te.inc - te.exp
				allyTeamEnergySpare = allyTeamEnergySpare + te.spare
				allyTeamPositiveSpare = allyTeamPositiveSpare + max(0, te.spare)
				allyTeamNegativeSpare = allyTeamNegativeSpare + max(0, -te.spare)
			end
			
			-- This is how much energy will be spent on overdrive. It remains to determine how much
			-- is spent by each player.
			local energyForOverdrive = max(0, allyTeamEnergySpare)*max(0, min(1, allyTeamEnergyCurrent/allyTeamEnergyMax))

			-- The following inequality holds:
			-- energyForOverdrive <= allyTeamEnergySpare <= allyTeamPositiveSpare
			-- which means the redistribution is guaranteed to work

			--// Spend energy on overdrive and redistribute energy to stallers.
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				if te.spare > 0 then
					-- Teams with spare energy spend their energy proportional to how much is needed for overdrive.
					te.overdriveEnergyNet = -te.spare*energyForOverdrive/allyTeamPositiveSpare
					-- Note that this value is negative
				else
					te.overdriveEnergyNet = 0
				end
			end
			
			-- Check for consistency.
			--local totalNet = 0
			--for i = 1, allyTeamData.teams do 
			--	local teamID = allyTeamData.team[i]
			--	local te = teamEnergy[teamID]
			--	totalNet = totalNet + te.overdriveEnergyNet
			--end
			--teamEcho(allyTeamID, totalNet .. "   " .. energyForOverdrive)
			
			--// Calculate Per-Grid Energy
			local maxGridCapacity = {}
			for i = 1, allyTeamData.grids do
				maxGridCapacity[i] = 0
				if not allyTeamData.nilGrid[i] then
					for unitID,_ in pairs(allyTeamData.grid[i].pylon) do
						local stunned_or_inbuild = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1) or (spGetUnitRulesParam(unitID,"morphDisable") == 1)
						if (not stunned_or_inbuild) then
							local income = spGetUnitRulesParam(unitID, "current_energyIncome") or 0
							maxGridCapacity[i] = maxGridCapacity[i] + income
						end
					end
				end
			end
			
			--// check if pylons disable due to low grid power (eg weapons)
			local list = pylonList[allyTeamID]
			for i = 1, list.count do
				local unitID = list.data[i]
				local pylonData = pylon[allyTeamID][unitID]
				if pylonData then
					if pylonData.neededLink then
						if pylonData.gridID == 0 or pylonData.neededLink > maxGridCapacity[pylonData.gridID] then
							spSetUnitRulesParam(unitID,"lowpower",1, inlosTrueTable)
						else
							spSetUnitRulesParam(unitID,"lowpower",0, inlosTrueTable)
						end
					end
				elseif not spammedError then
					Spring.Echo("Pylon problem detected in low power check.")
				end
			end

			--// Use the free Grid-Energy for Overdrive
			local energyWasted, summedMetalProduction, summedBaseMetal, summedOverdrive, 
				gridEnergySpent, gridMetalGain, privateBaseMetal = 
					OptimizeOverDrive(allyTeamID,allyTeamData,energyForOverdrive,maxGridCapacity)
			
			local overdriveEnergySpending = energyForOverdrive - energyWasted
			--// Refund excess energy from overdrive and overfull storages.
			local totalFreeStorage = 0
			local energyToRefund = energyWasted
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				-- Storage capacing + eexpected spending is the maximun allowed storage.
				te.freeStorage = te.max + te.exp - te.cur
				if te.freeStorage > 0 then
					totalFreeStorage = totalFreeStorage + te.freeStorage
				else
					energyToRefund = energyToRefund - te.freeStorage
					te.overdriveEnergyNet = te.overdriveEnergyNet + te.freeStorage
					te.freeStorage = 0
				end
			end 

			if totalFreeStorage > energyToRefund then
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					te.overdriveEnergyNet = te.overdriveEnergyNet + energyToRefund*te.freeStorage/totalFreeStorage
                end
				energyWasted = 0
			else
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					te.overdriveEnergyNet = te.overdriveEnergyNet + te.freeStorage
				end
				energyWasted = energyToRefund - totalFreeStorage
			end	
			
			--// Income For non-Gridded mexes
			for unitID, orgMetal in pairs(mexes[allyTeamID][0]) do
				local stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
				if stunned_or_inbuld then
					orgMetal = 0
				end
				summedBaseMetal = summedBaseMetal + orgMetal
                
				spSetUnitRulesParam(unitID, "overdrive", 1, inlosTrueTable)
				spSetUnitRulesParam(unitID, "overdrive_energyDrain", 0, inlosTrueTable)
				spSetUnitRulesParam(unitID, "current_metalIncome", orgMetal, inlosTrueTable)
				spSetUnitRulesParam(unitID, "overdrive_proportion", 0, inlosTrueTable)
				
				if mexByID[unitID].refundTeamID then
					local teamID = mexByID[unitID].refundTeamID
					local private_share = orgMetal*MEX_REFUND_SHARE*mexByID[unitID].refundTime/mexByID[unitID].refundTimeTotal
					privateBaseMetal[teamID] = (privateBaseMetal[teamID] or 0) + private_share
					teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - private_share
					mexByID[unitID].refundTime = mexByID[unitID].refundTime - 1
					mexByID[unitID].refundSoFar = mexByID[unitID].refundSoFar + private_share
					if mexByID[unitID].refundTime <= 0 then
						mexByID[unitID].refundTeamID = nil
						mexByID[unitID].refundTime = nil
						teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - mexByID[unitID].refundTotal + mexByID[unitID].refundSoFar
					end
				end

				summedMetalProduction = summedMetalProduction + orgMetal
			end
			
			--// Update pylon tooltips
			local list = pylonList[allyTeamID]
			for i = 1, list.count do
				local unitID = list.data[i]
				local pylonData = pylon[allyTeamID][unitID]
				if pylonData then
					local grid = pylonData.gridID
					local gridEfficiency = -1
					if grid ~= 0 then
						if gridMetalGain[grid] > 0 then 
							gridEfficiency = gridEnergySpent[grid]/gridMetalGain[grid]
						else 
							gridEfficiency = 0
						end
					end 
					
					spSetUnitRulesParam(unitID, "gridefficiency", gridEfficiency, alliedTrueTable)
					
					if not pylonData.mex then
						local unitDefID = spGetUnitDefID(unitID)
						local unitDef = unitDefID and UnitDefs[unitDefID]
						if not unitDef then
							if not spammedError then
								Spring.Log(gadget:GetInfo().name, LOG.ERROR, "unitDefID missing for pylon")
								spammedError = true
							end
						else
							if not pylonDefs[unitDefID].keeptooltip then
								if grid ~= 0 then
									spSetUnitRulesParam(unitID, "OD_gridCurrent", gridEnergySpent[grid], alliedTrueTable)
									spSetUnitRulesParam(unitID, "OD_gridMaximum", maxGridCapacity[grid], alliedTrueTable)
									spSetUnitRulesParam(unitID, "OD_gridMetal", gridMetalGain[grid], alliedTrueTable)
								else
									spSetUnitRulesParam(unitID, "OD_gridCurrent", -1, alliedTrueTable)
								end
							end
						end
					end
				elseif not spammedError then
					Spring.Echo("Pylon problem detected in tooltip update.")
				end
			end

			--// Share Overdrive Metal
			if GG.Lagmonitor_activeTeams then
				local activeTeams = GG.Lagmonitor_activeTeams[allyTeamID]
				local activeCount = activeTeams.count or 1
				local summedBaseMetalAfterPrivate = summedBaseMetal
				
				-- Extra base share from mex production
				for i = 1, allyTeamData.teams do  -- calculate active team OD sum
					local teamID = allyTeamData.team[i]
					if privateBaseMetal[teamID] then
						summedBaseMetalAfterPrivate = summedBaseMetalAfterPrivate - privateBaseMetal[teamID]
					end
				end 
				
				--Spring.Echo(allyTeamID .. " energy sum " .. teamODEnergySum)
	
				sendAllyTeamInformationToAwards(allyTeamID, summedBaseMetal, summedOverdrive, allyTeamEnergyIncome, ODenergy, energyWasted)
				
				-- Payback from energy production
				
				local summedOverdriveMetalAfterPayback = summedOverdrive
				local teamPacybackOD = {}
				if enableEnergyPayback then
					for i = 1, allyTeamData.teams do 
						local teamID = allyTeamData.team[i]
						if activeTeams[teamID] then
							local te = teamEnergy[teamID]
							teamPacybackOD[teamID] = 0
							
							local paybackInfo = teamPayback[teamID]
							if paybackInfo then
								local data = paybackInfo.data
								local toRemove = paybackInfo.toRemove
								local j = 1
								while j <= paybackInfo.count do
									local unitID = data[j].unitID
									local removeNow = toRemove[unitID]
			
									if not removeNow then
										if spValidUnitID(unitID) then
											local inc = spGetUnitRulesParam(unitID, "current_energyIncome") or 0
											if inc > 0 then
												local repayRatio = data[j].repaid/data[j].cost
												if repayRatio < 1 then
													local repayMetal = inc/allyTeamEnergyIncome * summedOverdrive * paybackFactorFunction(repayRatio)
													data[j].repaid = data[j].repaid + repayMetal
													summedOverdriveMetalAfterPayback = summedOverdriveMetalAfterPayback - repayMetal
													teamPacybackOD[teamID] = teamPacybackOD[teamID] + repayMetal
													paybackInfo.metalDueOD = paybackInfo.metalDueOD - repayMetal
													--Spring.Echo("Repaid " .. data[j].repaid)
												else
													removeNow = true
												end
											end
										else
											-- This should never happen in theory
											removeNow = true
										end
									end
									
									if removeNow then
										paybackInfo.metalDueOD = paybackInfo.metalDueOD + data[j].repaid - data[j].cost
										data[j] = data[paybackInfo.count]
										if toRemove[unitID] then
											toRemove[unitID] = nil
										end
										data[paybackInfo.count] = nil
										paybackInfo.count = paybackInfo.count - 1
									else
										j = j + 1
									end
								end
							end
						end
					end
				end
				
				
				-- Make changes to team resources
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					
					--// Energy
					-- Inactive teams still interact normally with energy for a few reasons:
					-- * Energy shared to them would disappear otherwise.
					-- * If they have reclaim (somehow) then they could build up storage without sharing.
					if te.overdriveEnergyNet + te.inc > 0 then
						spAddTeamResource(teamID, "e", te.overdriveEnergyNet + te.inc)
						lastTeamOverdriveSpending[teamID] = 0
					elseif te.overdriveEnergyNet + te.inc < 0 then
						spUseTeamResource(teamID, "e", -(te.overdriveEnergyNet + te.inc))
						lastTeamOverdriveSpending[teamID] = -(te.overdriveEnergyNet + te.inc)
					end
					
					-- Metal
					local odShare = 0
					local baseShare = 0
					local miscShare = 0
					
					local metalSplit = (activeCount >= 1 and activeCount) or allyTeamData.teams
					
					if activeTeams[teamID] or activeCount == 0 then
						odShare = (summedOverdriveMetalAfterPayback / metalSplit + (teamPacybackOD[teamID] or 0)) or 0
						baseShare = (summedBaseMetalAfterPrivate / metalSplit + (privateBaseMetal[teamID] or 0)) or 0
						miscShare = allyTeamMiscMetalIncome / metalSplit
					end
					
					sendTeamInformationToAwards(teamID, baseShare, odShare, te.overdriveEnergyNet)
					
					spAddTeamResource(teamID, "m", odShare + baseShare + miscShare)
					--Spring.Echo(teamID .. " got odShare " .. odShare)
					SetTeamEconomyRulesParams(
						teamID, metalSplit, -- TeamID of the team as well as number of active allies.
						
						summedBaseMetal, -- AllyTeam base metal extrator income
						summedOverdrive, -- AllyTeam overdrive income
						allyTeamMiscMetalIncome, -- AllyTeam constructor income
						
						allyTeamEnergyIncome, -- AllyTeam total energy income (everything)
						overdriveEnergySpending, -- AllyTeam energy spent on overdrive
						energyWasted, -- AllyTeam energy excess
						
						baseShare, -- Team share of base metal extractor income
						odShare, -- Team share of overdrive income
						miscShare, -- Team share of constructor metal income
						
						te.inc, -- Non-reclaim energy income for the team
						te.overdriveEnergyNet, -- Amount of energy spent or recieved due to overdrive and income
						te.overdriveEnergyNet + te.inc -- real change in energy due to overdrive
					)
				end 
			else
				Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Lag monitor doesn't work so Overdrive is STUFFED")
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- MEXES

local function TransferMexRefund(unitID, newTeamID)
	if newTeamID and mexByID[unitID].refundTeamID then
		local oldTeamID = mexByID[unitID].refundTeamID
		local remainingPayback = mexByID[unitID].refundTotal - mexByID[unitID].refundSoFar
		mexByID[unitID].refundTeamID = newTeamID
		teamPayback[oldTeamID].metalDueBase = teamPayback[oldTeamID].metalDueBase - remainingPayback
		teamPayback[newTeamID].metalDueBase = teamPayback[newTeamID].metalDueBase + remainingPayback
	end
end

local function AddMex(unitID, teamID, metalMake)
	if (metalMake or 0) <= 0 then
		return
	end
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if (allyTeamID) then
		mexByID[unitID] = {gridID = 0, allyTeamID = allyTeamID}
		
		if teamID and enableMexPayback then
			local refundTime = 400/metalMake
			mexByID[unitID].refundTeamID = teamID
			mexByID[unitID].refundTime = refundTime
			mexByID[unitID].refundTimeTotal = refundTime
			mexByID[unitID].refundTotal = metalMake*refundTime*MEX_REFUND_SHARE*0.5
			mexByID[unitID].refundSoFar = 0
			teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase + mexByID[unitID].refundTotal
		end
		
		spSetUnitRulesParam(unitID, "current_metalIncome", metalMake, inlosTrueTable)
		local mexGridID = 0
		local pylonData = pylon[allyTeamID][unitID]
		if pylonData then
			pylonData.mex = true --in case some magical case where pylon was initialized as not mex, then became mex?
			mexGridID = pylonData.gridID
		end
		mexes[allyTeamID][mexGridID][unitID] = metalMake
		mexByID[unitID].gridID = mexGridID
		if mexGridID ~= 0 then
			local ai = allyTeamInfo[allyTeamID]
			ai.mexCount = ai.mexCount + 1
			ai.mexMetal = ai.mexMetal + metalMake
			ai.mexSquaredSum = ai.mexSquaredSum + (metalMake * metalMake)
			ai.grid[mexGridID].mexMetal = ai.grid[mexGridID].mexMetal + metalMake
			ai.grid[mexGridID].mexSquaredSum = ai.grid[mexGridID].mexSquaredSum + (metalMake * metalMake)
		end
	end
end

local function RemoveMex(unitID)
	local gridID = 0
	local mex = mexByID[unitID]
	
	if mex and mexes[mex.allyTeamID][mex.gridID][unitID] then
				
		local orgMetal = mexes[mex.allyTeamID][mex.gridID][unitID]
		local ai = allyTeamInfo[mex.allyTeamID]
		local g = ai.grid[mex.gridID]
		
		if mex.gridID ~= 0 then
			g.mexMetal = g.mexMetal - orgMetal
			g.mexSquaredSum = g.mexSquaredSum - (orgMetal * orgMetal)
			ai.mexCount = ai.mexCount - 1
			ai.mexMetal = ai.mexMetal - orgMetal
			ai.mexSquaredSum = ai.mexSquaredSum - (orgMetal * orgMetal)
		end
		local pylonData = pylon[mex.allyTeamID][unitID]
		if pylonData then
			pylonData.mex = nil --for some magical case where mex is to be removed but the pylon not?
		end
		mexes[mex.allyTeamID][mex.gridID][unitID] = nil

		local teamID = mexByID[unitID].refundTeamID
		if teamID then
			teamPayback[teamID].metalDueBase = teamPayback[teamID].metalDueBase - mexByID[unitID].refundTotal + mexByID[unitID].refundSoFar
		end
		mexByID[unitID] = nil
		
	else
		local x,_,z = spGetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,0,z,"inconsistent mex entry 124125_1")
	end
	
	for allyTeam, _ in pairs(mexes) do
		for i = 0, allyTeamInfo[allyTeam].grids do
			if (mexes[allyTeam][i][unitID] ~= nil) then
				local x,_,z = spGetUnitPosition(unitID)
				Spring.MarkerAddPoint(x,0,z,"inconsistent mex entry 124125_0")
			end
		end
	end

end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- RESOURCE GENERATORS

local function AddResourceGenerator(unitID, unitDefID, teamID, allyTeamID)
	allyTeamID = allyTeamID or spGetUnitAllyTeam(unitID)
	teamID = teamID or spGetUnitTeam(unitID)
	
	if generator[allyTeamID][teamID][unitID] then
		--return
	end
	
	if unitDefID and generatorDefs[unitDefID] then
		local defData = generatorDefs[unitDefID]
		if spGetUnitRulesParam(unitID, "isWind") then
			generator[allyTeamID][teamID][unitID] = {
				isWind = defData.isWind
			}
		else
			generator[allyTeamID][teamID][unitID] = {
				metalIncome = spGetUnitRulesParam(unitID, "wanted_metalIncome") or defData.metalIncome,
				energyIncome = spGetUnitRulesParam(unitID, "wanted_energyIncome") or defData.energyIncome,
			}
		end
	else
		generator[allyTeamID][teamID][unitID] = {
			metalIncome = spGetUnitRulesParam(unitID, "wanted_metalIncome") or 0,
			energyIncome = spGetUnitRulesParam(unitID, "wanted_energyIncome") or 0,
		}
	end
	
	local list = generatorList[allyTeamID][teamID]
	list.count = list.count + 1
	list.data[list.count] = unitID
	
	generator[allyTeamID][teamID][unitID].listID = list.count	
	resourceGenoratingUnit[unitID] = true
end

local function Overdrive_AddUnitResourceGeneration(unitID, metal, energy)
	if not unitID then
		return
	end
	local teamID = Spring.GetUnitTeam(unitID)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	
	if not teamID or not generator[allyTeamID] or not generator[allyTeamID][teamID] then
		return
	end
	
	if not generator[allyTeamID][teamID][unitID] then
		AddResourceGenerator(unitID, unitDefID, teamID, allyTeamID)
	end
	
	local genData = generator[allyTeamID][teamID][unitID]
	
	local metalIncome = math.max(0, genData.metalIncome + metal)
	local energyIncome = math.max(0, genData.energyIncome + energy)
	
	genData.metalIncome = metalIncome
	genData.energyIncome = energyIncome
	
	spSetUnitRulesParam(unitID, "wanted_metalIncome", metalIncome, inlosTrueTable)
	spSetUnitRulesParam(unitID, "wanted_energyIncome", energyIncome, inlosTrueTable)
end

local function RemoveResourceGenerator(unitID, unitDefID, teamID, allyTeamID)
	allyTeamID = allyTeamID or spGetUnitAllyTeam(unitID)
	teamID = teamID or spGetUnitTeam(unitID)
	
	resourceGenoratingUnit[unitID] = false
	
	if not generator[allyTeamID][teamID][unitID] then
		--return
	end
	
	local list = generatorList[allyTeamID][teamID]
	local listID = generator[allyTeamID][teamID][unitID].listID
	list.data[listID] = list.data[list.count]
	generator[allyTeamID][teamID][list.data[listID]].listID = listID
	list.data[list.count] = nil
	list.count = list.count - 1
	generator[allyTeamID][teamID][unitID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function OverdriveDebugToggle()
	if Spring.IsCheatingEnabled() then
		debugMode = not debugMode
		if debugMode then
			local allyTeamList = Spring.GetAllyTeamList()
			for i=1,#allyTeamList do
				local allyTeamID = allyTeamList[i]
				local list = pylonList[allyTeamID]
				for i = 1, list.count do
					local unitID = list.data[i]
					UnitEcho(unitID, i .. ", " .. unitID)
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
	
	GG.Overdrive_AddUnitResourceGeneration = Overdrive_AddUnitResourceGeneration
	
	_G.pylon = pylon
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if (mexDefs[unitDefID]) then
			local inc = spGetUnitRulesParam(unitID, "mexIncome")
			AddMex(unitID, false, inc)
		end
		if (pylonDefs[unitDefID]) then
			AddPylon(unitID, unitDefID, pylonDefs[unitDefID].range)
		end
		if (generatorDefs[unitDefID]) or spGetUnitRulesParam(unitID, "wanted_energyIncome") then
			AddResourceGenerator(unitID, unitDefID)
		end
	end
	
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		teamPayback[teamList[i]] = {
			metalDueOD = 0,
			metalDueBase = 0,
			count = 0,
			toRemove = {},
			data = {},
		}
	end

	gadgetHandler:AddChatAction("odb",OverdriveDebugToggle,"Toggles debug mode for overdrive.")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (mexDefs[unitDefID]) then
		local inc = spGetUnitRulesParam(unitID, "mexIncome")
		AddMex(unitID, unitTeam, inc)
	end
	if pylonDefs[unitDefID] then
		AddPylon(unitID, unitDefID, pylonDefs[unitDefID].range)
	end
	if (generatorDefs[unitDefID]) or spGetUnitRulesParam(unitID, "wanted_energyIncome") then
		AddResourceGenerator(unitID, unitDefID, unitTeam)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if paybackDefs[unitDefID] and enableEnergyPayback then
		AddEnergyToPayback(unitID, unitDefID, unitTeam)
	end
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeamID)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (mexDefs[unitDefID]) then 
			local inc = spGetUnitRulesParam(unitID, "mexIncome")
			AddMex(unitID, false, inc)
		end
		
		if pylonDefs[unitDefID] then
			AddPylon(unitID, unitDefID, pylonDefs[unitDefID].range)
			--Spring.Echo(spGetUnitAllyTeam(unitID) .. "  " .. newAllyTeam)
		end
	else
		if (mexDefs[unitDefID]) then 
			TransferMexRefund(unitID, teamID)
		end
	end
	
	if (generatorDefs[unitDefID]) or spGetUnitRulesParam(unitID, "wanted_energyIncome") then
		AddResourceGenerator(unitID, unitDefID, teamID, newAllyTeamID)
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeamID)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (mexDefs[unitDefID] and mexByID[unitID]) then 
			RemoveMex(unitID)
		end
		
		if pylonDefs[unitDefID] then
			RemovePylon(unitID)
		end
		
		if paybackDefs[unitDefID] and enableEnergyPayback then
			RemoveEnergyToPayback(unitID, unitDefID)
		end
	end
	
	if generatorDefs[unitDefID] or resourceGenoratingUnit[unitID] then
		RemoveResourceGenerator(unitID, unitDefID, oldTeamID, oldAllyTeamID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (mexDefs[unitDefID] and mexByID[unitID]) then  
		RemoveMex(unitID)
	end
	if (pylonDefs[unitDefID]) then
		RemovePylon(unitID)
	end
	if paybackDefs[unitDefID] and enableEnergyPayback then
		RemoveEnergyToPayback(unitID, unitDefID)
	end
	if generatorDefs[unitDefID] or resourceGenoratingUnit[unitID] then
		RemoveResourceGenerator(unitID, unitDefID, unitTeam)
	end
end

-------------------------------------------------------------------------------------
