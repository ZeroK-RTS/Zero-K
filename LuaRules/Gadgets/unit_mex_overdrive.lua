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
local odSharingModOptions = (Spring.GetModOptions()).overdrivesharingscheme

local enableEnergyPayback = ((odSharingModOptions == "investmentreturn") or (odSharingModOptions == "investmentreturn_od"))
local enableMexPayback = ((odSharingModOptions == "investmentreturn") or (odSharingModOptions == "investmentreturn_base"))

-- this is "fun" mod
local OreMexModOption = tonumber((Spring.GetModOptions()).oremex) or 0 -- Red Annihilation mexes, no harvesters though, use cons/coms to reclaim ore.

include("LuaRules/Configs/constants.lua")
include("LuaRules/Configs/mex_overdrive.lua")

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (udef.customParams.ismex) then
		mexDefs[i] = true
	end
	if (tonumber(udef.customParams.pylonrange) or 0 > 0) then
		pylonDefs[i] = {
			range = tonumber(udef.customParams.pylonrange) or DEFAULT_PYLON_RANGE,
			extractor = (udef.customParams.ismex and true or false),
			neededLink = tonumber(udef.customParams.neededlink) or false,
			keeptooltip = udef.customParams.keeptooltip or false,
		}
	end
		
end

local alliedTrueTable = {allied = true}
local inlosTrueTable = {inlos = true}

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
local round = math.round
local min   = math.min
local max   = math.max

local spValidUnitID       = Spring.ValidUnitID
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitStates     = Spring.GetUnitStates
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitResources  = Spring.GetUnitResources
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetUnitTooltip    = Spring.SetUnitTooltip
local spCallCOBScript     = Spring.CallCOBScript
local spSetTeamRulesParam = Spring.SetTeamRulesParam

local spGetTeamResources  = Spring.GetTeamResources
local spAddTeamResource   = Spring.AddTeamResource
local spUseTeamResource   = Spring.UseTeamResource
local spGetTeamInfo       = Spring.GetTeamInfo

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local notDestroyed = {}

local mexes = {}   -- mexes[teamID][gridID][unitID] == mexMetal
local mexByID = {} -- mexByID[unitID] = {gridID, allyTeamID, refundTeamID, refundTime, refundTotal, refundSoFar}

local lowPowerUnits = {inner = {count = 0, units = {}}}

local pylon = {} -- pylon[allyTeamID][unitID] = {gridID,mexes,mex[unitID],x,z,overdrive, nearPlant[unitID],nearPylon[unitID], color}
local pylonList = {} -- pylon[allyTeamID] = {data = {[1] = unitID, [2] = unitID, ...}, count}

local pylonGridQueue = false -- pylonGridQueue[unitID] = true

local unitPaybackTeamID = {} -- indexed by unitID, tells unit which team gets it's payback.
local teamPayback = {} -- teamPayback[teamID] = {count = 0, toRemove = {}, data = {[1] = {unitID = unitID, cost = costOfUnit, repaid = howMuchHasBeenRepaid}}}

local allyTeamInfo = {} 

local setOreIncome = function(_,_,_) end
GG.oreIncome = {}

do
  local allyTeamList = Spring.GetAllyTeamList()
  for i=1,#allyTeamList do
	local allyTeamID = allyTeamList[i]
	pylon[allyTeamID] = {}
	pylonList[allyTeamID] = {data = {}, count = 0}
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
	for j=1,#teamList do
		local teamID = teamList[j]
		allyTeamInfo[allyTeamID].teams = allyTeamInfo[allyTeamID].teams + 1
		allyTeamInfo[allyTeamID].team[allyTeamInfo[allyTeamID].teams] = teamID
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

local function SetTeamEconomyRulesParams(teamID, allies, energyWasted, energyForOverdrive, totalMetalIncome, 
		baseMetal, overdriveMetal, myBase, myOverdrive, energyChange, teamEnergyIncome)
	spSetTeamRulesParam(teamID, "OD_allies",  allies, privateTable)
	spSetTeamRulesParam(teamID, "OD_energyWasted",  energyWasted, privateTable)
	spSetTeamRulesParam(teamID, "OD_energyForOverdrive",  energyForOverdrive, privateTable)
	--spSetTeamRulesParam(teamID, "OD_totalMetalIncome",  totalIncome, privateTable)
	spSetTeamRulesParam(teamID, "OD_baseMetal",  baseMetal, privateTable)
	spSetTeamRulesParam(teamID, "OD_overdriveMetal",  overdriveMetal, privateTable)
	spSetTeamRulesParam(teamID, "OD_myBase",  myBase, privateTable)
	spSetTeamRulesParam(teamID, "OD_myOverdrive",  myOverdrive, privateTable)
	spSetTeamRulesParam(teamID, "OD_energyChange",  energyChange, privateTable)
	spSetTeamRulesParam(teamID, "OD_teamEnergyIncome",  teamEnergyIncome, privateTable)
	spSetTeamRulesParam(teamID, "OD_RoI_metalDue",  teamPayback[teamID].metalDueOD, privateTable)
	spSetTeamRulesParam(teamID, "OD_base_metalDue",  teamPayback[teamID].metalDueBase, privateTable)
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

local function AddPylon(unitID, unitDefID, isMex, range)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]

	if pylon[allyTeamID][unitID] then
		return
	end
	
	pylon[allyTeamID][unitID] = {
		gridID = 0,
		--mexes = 0,
		mex = isMex,
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
					local incomeFactor = spGetUnitRulesParam(unitID,"mexincomefactor")
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
								local incomeFactor = spGetUnitRulesParam(unitID,"mexincomefactor")
								if incomeFactor then
									orgMetal = orgMetal*incomeFactor
								end
								local mexE = gridE*(orgMetal * orgMetal)/ gridMetalSquared 
								local metalMult = energyToExtraM(mexE)
								spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5, alliedTrueTable)
								local thisMexM = orgMetal + orgMetal * metalMult
								spSetUnitRulesParam(unitID, "mex_income", thisMexM, alliedTrueTable)
 
								maxedMetalProduction = maxedMetalProduction + thisMexM
								maxedBaseMetal = maxedBaseMetal + orgMetal
                                maxedOverdrive = maxedOverdrive + orgMetal * metalMult
                                
								allyMetalSquared = allyMetalSquared - orgMetal * orgMetal
								gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
								
								if mexByID[unitID].refundTeamID then
									mexBaseMetal[unitID] = orgMetal
								end
								
								local unitDefID = spGetUnitDefID(unitID)
								if not pylonDefs[unitDefID].keeptooltip then
									local unitDef = UnitDefs[unitDefID]
									if unitDef then
										spSetUnitTooltip(unitID,"Makes: " .. round(orgMetal,2) .. " + Overdrive: +" .. round(metalMult*100,0) .. "%  \nEnergy: -" .. round(mexE,2))
										setOreIncome(unitID, thisMexM) -- this function does nothing if oremex==0 (line ~142)
									else
										if not spammedError then
											Spring.Echo("unitDefID missing for maxxed metal extractor")
											spammedError = true
										end
									end
								end
							end
							break --finish distributing energy to 1 grid, go to next grid
						end
					end 
					
					local metalMult = energyToExtraM(mexE)
					spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5, alliedTrueTable)
					local thisMexM = orgMetal + orgMetal * metalMult
					spSetUnitRulesParam(unitID, "mex_income", thisMexM, alliedTrueTable)
					
					summedMetalProduction = summedMetalProduction + thisMexM
					summedBaseMetal = summedBaseMetal + orgMetal
                    summedOverdrive = summedOverdrive + orgMetal * metalMult
                    
					gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
					
					if mexByID[unitID].refundTeamID then
						mexBaseMetal[unitID] = orgMetal
					end
					
					local unitDefID = spGetUnitDefID(unitID)
					if not pylonDefs[unitDefID].keeptooltip then
						local unitDef = UnitDefs[unitDefID]
						if unitDef then
							if (metalMult < 1.5) then
								spSetUnitTooltip(unitID,"Makes: " .. round(orgMetal,2) .. " + Overdrive: +" .. round(metalMult*100,0) .. "%  Energy: -" .. round(mexE,2))
							else
								spSetUnitTooltip(unitID,"Makes: " .. round(orgMetal,2) .. " + Overdrive: +" .. round(metalMult*100,0) .. "%  Energy: -" .. round(mexE,2) .. " \nConnect more energy sources to produce additional metal")
							end
							setOreIncome(unitID, thisMexM) -- this function does nothing if oremex==0 (line ~142)
						else
							if not spammedError then
								Spring.Echo("unitDefID missing for metal extractor")
								spammedError = true
							end
						end
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

local function changeTeamEnergy(team, energy)
    team.totalChange = team.totalChange + energy
	team.eCur = team.eCur + energy
end

local function keepTeamEnergyBelowMax(team)
    if team.eCur > team.eMax - HIDDEN_STORAGE then
        local change = (team.eMax - HIDDEN_STORAGE) - team.eCur
        changeTeamEnergy(team, change)
        return -change
    end
    return 0
end

local lastTeamNe = {}
function gadget:GameFrame(n)
	if (n%TEAM_SLOWUPDATE_RATE == 1) then
		lowPowerUnits.inner = {count = 0, units = {}}
		for allyTeamID, allyTeamData in pairs(allyTeamInfo) do 
			
			--// Check if pylons changed their active status (emp, reverse-build, ..)
			local list = pylonList[allyTeamID]
			for i = 1, list.count do
				local unitID = list.data[i]
				local pylonData = pylon[allyTeamID][unitID]
				if pylonData then
					if spValidUnitID(unitID) then
						local stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
						local states = spGetUnitStates(unitID)
						local currentlyActive = (not stunned_or_inbuld) and states and states.active
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
			
			local allyE = 0
			local allyEExcess = 0
			local allyEMissing = 0
			local teamEnergy = {}
			local allyTeamEnergyIncome = 0

			--// Calculate total income - tax 95% of energy income 
			local sumInc = 0
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				teamEnergy[teamID] = {totalChange = 0, num = teamID}
				local te = teamEnergy[teamID]
				te.eCur, te.eMax, te.ePull, te.eInc, te.eExp, _, te.eSent, te.eRec = spGetTeamResources(teamID, "energy")
				local incTakeNE = (lastTeamNe[teamID] and lastTeamNe[teamID] > 0 and te.eInc -lastTeamNe[teamID]) or te.eInc
                allyTeamEnergyIncome = allyTeamEnergyIncome + incTakeNE
				if (te.eCur ~= nil) then 
					te.eTax = incTakeNE * max(0, min(1, (te.eCur - te.eInc) / (te.eMax - HIDDEN_STORAGE))) -- don't take more than you make!
					if te.eCur - te.eTax > te.eMax - HIDDEN_STORAGE then
                        te.eTax = te.eCur - (te.eMax - HIDDEN_STORAGE)
                    end
                    if (te.eTax > 0) then 
						sumInc = sumInc + te.eTax 
					end 
                    --teamEcho(teamID, teamID .. ",   Tax: " .. te.eTax .. ",   Inc: " .. incTakeNE .. ",   Cur: " .. te.eCur)
				end 
			end 
			--Spring.Echo("sumInc: " .. sumInc)
			
			--// Distribute taxes evenly - apply "change" on individual teams 
			local share = sumInc / allyTeamData.teams
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				if (te.eCur ~= nil) then 
					if (te.eTax < 0) then 
                        te.eTax = 0 
                    end 
					
					te.taxChange = share - te.eTax 
					--teamEcho(teamID, teamID .. ",   taxChange: " .. te.taxChange)
					changeTeamEnergy(te, te.taxChange)
                    allyEExcess = allyEExcess + keepTeamEnergyBelowMax(te)
				end 
			end 
			
			local teamODEnergy = {}
			
			--// Calculate overdrive energy excess 
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				if (te.eCur ~= nil) then 
                    -- Disregared spending last step can never exceed actual spending
                    local inc = te.eInc - te.eExp - (lastTeamNe[teamID] or 0)
                    --teamEcho(teamID, teamID .. ",   NE: " .. (lastTeamNe[teamID] or 0))
                    --teamEcho(teamID, teamID .. ",   REAL: " .. te.eInc .. "   -" .. te.eExp)
                    --teamEcho(teamID, teamID .. ",   INC: " .. inc)
					if (inc > 0) then  
						local fillRatio = max(0, (te.eCur - te.eInc) / (te.eMax - HIDDEN_STORAGE))
						local ne = inc * fillRatio   -- actual energy used for overdrive depends on fill ratio. At 50% of storage, 50% of income is used 
                        --teamEcho(teamID, teamID .. ",   CUR: " .. te.eCur .. ",   MAX: " .. te.eMax  .. ",   HIDE: " .. HIDDEN_STORAGE)
                        --teamEcho(teamID, teamID .. ",   INC: " .. inc .. ",   FR: " .. fillRatio )
                        allyEExcess  = allyEExcess + ne
						changeTeamEnergy(te, -ne)
					end 
				end 			
			end 

			allyE = allyEExcess
			
			--// Calculate Per-Grid Energy
			local maxGridCapacity = {}
			for i = 1, allyTeamData.grids do
				maxGridCapacity[i] = 0
				if not allyTeamData.nilGrid[i] then
					for unitID,_ in pairs(allyTeamData.grid[i].pylon) do
						local stunned_or_inbuild = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
						if (not stunned_or_inbuild) then
							local _,_,em,eu = spGetUnitResources(unitID)
							maxGridCapacity[i] = maxGridCapacity[i] + (em or 0) - (eu or 0)
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
							lowPowerUnits.inner.count = lowPowerUnits.inner.count + 1
							lowPowerUnits.inner.units[lowPowerUnits.inner.count] = unitID
						else
							spSetUnitRulesParam(unitID,"lowpower",0, inlosTrueTable)
						end
					end
				elseif not spammedError then
					Spring.Echo("Pylon problem detected in low power check.")
				end
			end

			--// Use the free Grid-Energy for Overdrive
			local energyWasted, summedMetalProduction, summedBaseMetal, summedOverdrive, gridEnergySpent, 
					gridMetalGain, privateBaseMetal = OptimizeOverDrive(allyTeamID,allyTeamData,allyE,maxGridCapacity)
			
			local ODenergy = allyE - energyWasted

			--// Refund excess energy
			local totalFreeStorage = 0
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				totalFreeStorage = totalFreeStorage + te.eMax - HIDDEN_STORAGE - te.eCur
			end 
			
			if totalFreeStorage > energyWasted then
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					--Spring.Echo(teamID .. ",   Refund: " .. energyWasted*( te.eMax - HIDDEN_STORAGE - te.eCur)/totalFreeStorage)
					changeTeamEnergy(te, energyWasted*( te.eMax - HIDDEN_STORAGE - te.eCur)/totalFreeStorage)
					--spAddTeamResource(teamID, "e", energyWasted*( eMax - HIDDEN_STORAGE - eCur)/totalFreeStorage)
                end
				energyWasted = 0
			else
                local totalRealInc = 0
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
                    totalRealInc = totalRealInc + te.eInc
					--Spring.Echo(teamID .. ",   Refund fill: " .. te.eMax - HIDDEN_STORAGE - te.eCur)
                    changeTeamEnergy(te, te.eMax - HIDDEN_STORAGE - te.eCur)
					--spAddTeamResource(teamID, "e", ( eMax - HIDDEN_STORAGE - eCur))
				end
				energyWasted = energyWasted - totalFreeStorage
			end	
			
			--// change team energy
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
                lastTeamNe[teamID] = te.totalChange - (te.taxChange or 0)
                --teamEcho(teamID, teamID .. ",   Real E Change: " .. te.totalChange)
				if te.totalChange > 0 then
					spAddTeamResource(teamID, "e", te.totalChange)
					teamODEnergy[teamID] = 0 
				elseif te.totalChange < 0 then
					spUseTeamResource(teamID, "e", -te.totalChange)
					teamODEnergy[teamID] = -te.totalChange
				end
			end 
			
			--// Income For non-Gridded mexes
			for unitID, orgMetal in pairs(mexes[allyTeamID][0]) do
				local stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
				if stunned_or_inbuld then
					orgMetal = 0
				end
				summedBaseMetal = summedBaseMetal + orgMetal
                
				spSetUnitRulesParam(unitID, "overdrive", 1, alliedTrueTable)
				spSetUnitRulesParam(unitID, "mex_income", orgMetal, alliedTrueTable)
				
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
				local unitDefID = spGetUnitDefID(unitID)
				local pylonDef = pylonDefs[unitDefID]
				if pylonDef and not pylonDef.keeptooltip then
					local unitDef = UnitDefs[unitDefID]
					if unitDef then
						spSetUnitTooltip(unitID,"Metal Extractor - Makes: " .. round(orgMetal,2) .. " Not connected to Grid")
					else
						if not spammedError then
							Spring.Log(gadget:GetInfo().name, LOG.ERROR, "unitDefID missing for ungridded mex")
							spammedError = true
						end
					end
				end
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
									spSetUnitTooltip(unitID,"GRID: "  .. round(gridEnergySpent[grid],2) .. "/" .. round(maxGridCapacity[grid],2) .. "E => " .. round(gridMetalGain[grid],2).."M")
								else
									spSetUnitTooltip(unitID,unitDef.humanName .. " - Currently Disabled")
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
				local activeCount = (activeTeams.count >= 1 and activeTeams.count) or 1
				local teamODEnergySum = 0
				local summedBaseMetalAfterPrivate = summedBaseMetal
				
				-- Extra base share from mex production
				for i = 1, allyTeamData.teams do  -- calculate active team OD sum
					local teamID = allyTeamData.team[i]
					if activeTeams[teamID] then
						teamODEnergySum = teamODEnergySum + (teamODEnergy[teamID] or 0)
						--Spring.Echo(teamID .. " energy " ..  (teamODEnergy[teamID] or "nil"))
					end
					
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
											local _,_,em,eu = spGetUnitResources(unitID)
											local inc = (em or 0) - (eu or 0)
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
				
				
				-- Add resources finally
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					if activeTeams[teamID] then
						local te = teamEnergy[teamID]
						
						-- old system
						-- local odShare
						-- local ratio = summedOverdrive / activeCount
						--if (teamODEnergySum > 0 and teamODEnergy[teamID]) then 
						--	odShare = OD_OWNER_SHARE * summedOverdrive * teamODEnergy[teamID] / teamODEnergySum +  (1-OD_OWNER_SHARE) * ratio
						--end		
						local odShare = (summedOverdriveMetalAfterPayback / activeCount + (teamPacybackOD[teamID] or 0)) or 0
						local baseShare = (summedBaseMetalAfterPrivate / activeCount + (privateBaseMetal[teamID] or 0)) or 0
						
						sendTeamInformationToAwards(teamID, baseShare, odShare, te.totalChange)
						
						spAddTeamResource(teamID, "m", odShare + baseShare)
						--Spring.Echo(teamID .. " got odShare " .. odShare)
						SetTeamEconomyRulesParams(teamID, activeCount, energyWasted, ODenergy, summedMetalProduction, summedBaseMetal, summedOverdrive, baseShare, odShare, te.totalChange, allyTeamEnergyIncome) 
					end
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
	metalMake = metalMake or 0
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
		
		spSetUnitRulesParam(unitID, "mex_income", metalMake, alliedTrueTable)
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
	
	_G.pylon = pylon
	_G.lowPowerUnits = lowPowerUnits
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if (mexDefs[unitDefID]) then
			local inc = spGetUnitRulesParam(unitID, "mexIncome")
			AddMex(unitID, false, inc)
		end
		if (pylonDefs[unitDefID]) then
			AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
		end
		--if (energyDefs[unitDefID]) then
		--	AddEnergy(unitID, unitDefID, unitTeam)
		--end
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
		SetTeamEconomyRulesParams(teamList[i], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	end
	
	
	-- "oremex" modoption, instead of modyfing overdrive code integrity and decreasing readability, this will do
	-- check unit_oremex.lua for oremex code.
	if (OreMexModOption == 1) then
		spAddTeamResource = function(a,b,c) 
			if b~="m" then Spring.AddTeamResource(a,b,c) end  --disable metal distribution issued by *this* gadget.
		end
		setOreIncome = function(unitID, oreAmount)
			 GG.oreIncome[unitID] = oreAmount -- this spawn the rocks. It don't need to reset to empty value, because this is set to NIL when unitID is destroyed in unit_oremex.lua anyway
		end
		enableEnergyPayback = false -- because metal/rocks is reclaimable by anyone, so payback can't work. Also resource distribution is handled within oremex (currently communism). -- or does oremex need a communism modoption?
		enableMexPayback = false
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
		--Note: pylon was added in UnitFinished() when resurrected.
		notDestroyed[unitID] = true
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if (pylonDefs[unitDefID] and notDestroyed[unitID]) then
		AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
	end
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
		
		if (pylonDefs[unitDefID] and notDestroyed[unitID]) then
			local _,_,_,_,build = spGetUnitHealth(unitID)
			if (build == 1) then
				AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
				--Spring.Echo(spGetUnitAllyTeam(unitID) .. "  " .. newAllyTeam)
			end
		end
		--if (energyDefs[unitDefID]) then
		--	AddEnergy(unitID, unitDefID, unitTeam)
		--	RemoveEnergy(unitID, unitDefID, unitTeam)
		--end
	else
		if (mexDefs[unitDefID]) then 
			TransferMexRefund(unitID, teamID)
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeamID)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (mexDefs[unitDefID] and mexByID[unitID]) then 
			RemoveMex(unitID)
		end
		
		if (pylonDefs[unitDefID] and notDestroyed[unitID]) then
			RemovePylon(unitID)
		end
		
		if paybackDefs[unitDefID] and enableEnergyPayback then
			RemoveEnergyToPayback(unitID, unitDefID)
		end
		--if (energyDefs[unitDefID]) then
		--	AddEnergy(unitID, unitDefID, unitTeam)
		--	RemoveEnergy(unitID, unitDefID, unitTeam)
		--end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (mexDefs[unitDefID] and mexByID[unitID]) then  
		RemoveMex(unitID)
	end
	if (pylonDefs[unitDefID]) then
		notDestroyed[unitID] = nil
		RemovePylon(unitID)
	end
	if paybackDefs[unitDefID] and enableEnergyPayback then
		RemoveEnergyToPayback(unitID, unitDefID)
	end
	--if (energyDefs[unitDefID]) then
	--	RemoveEnergy(unitID, unitDefID, unitTeam)
	--end
end

-------------------------------------------------------------------------------------
