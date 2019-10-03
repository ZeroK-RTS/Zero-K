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
		author    = "Licho, Google Frog (pylon conversion), ashdnazg (quadField)",
		date      = "16.5.2008 (OD date)",
		license   = "GNU GPL, v2 or later",
		layer     = -4,   -- OD grid circles must be drawn before lava drawing gadget some maps have (which has layer = -3)
		enabled   = true  --  loaded by default?
	}
end

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
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam

local spGetTeamResources  = Spring.GetTeamResources
local spAddTeamResource   = Spring.AddTeamResource
local spUseTeamResource   = Spring.UseTeamResource
local spGetTeamInfo       = Spring.GetTeamInfo

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mexDefs = {}
--local energyDefs = {}
local pylonDefs = {}
local generatorDefs = {}
local isReturnOfInvestment = (Spring.GetModOptions().overdrivesharingscheme ~= "0")

local enableEnergyPayback = isReturnOfInvestment
local enableMexPayback = isReturnOfInvestment

include("LuaRules/Configs/constants.lua")

--[[ Set to be twice the largest link range except Pylon, so a regular linking building can be in 4 quads at most.
     Pylons can belong to more quads but they are comparatively rare and would inflate this value too much.
     A potential optimisation here would be to measure if limiting this value to Solar radius would help even further
     since Solar/Wind/Mex make up the majority of linkables. ]]
local QUADFIELD_SQUARE_SIZE = 300

for i = 1, #UnitDefs do
	local udef = UnitDefs[i]
	if (udef.customParams.ismex) then
		mexDefs[i] = true
	end
	local pylonRange = tonumber(udef.customParams.pylonrange) or 0
	if pylonRange > 0 then
		pylonDefs[i] = {
			range = pylonRange,
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
			sharedEnergyGenerator = udef.customParams.shared_energy_gen and true
		}
	end
end

local alliedTrueTable = {allied = true}
local inlosTrueTable = {inlos = true}

local sentErrorWarning = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


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

local MIN_STORAGE = 0.5
local PAYBACK_FACTOR = 0.5
local MEX_REFUND_SHARE = 0.5 -- refund starts at 50% of base income and linearly goes to 0% over time

local paybackDefs = { -- cost is how much to pay back
	[UnitDefNames["energywind"].id] = {cost = UnitDefNames["energywind"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["energysolar"].id] = {cost = UnitDefNames["energysolar"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["energyfusion"].id] = {cost = UnitDefNames["energyfusion"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["energysingu"].id] = {cost = UnitDefNames["energysingu"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["energygeo"].id] = {cost = UnitDefNames["energygeo"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["energyheavygeo"].id] = {cost = UnitDefNames["energyheavygeo"].metalCost*PAYBACK_FACTOR},
}

local spammedError = false
local debugGridMode = false
local debugAllyTeam = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local mexes = {}   -- mexes[teamID][gridID][unitID] == mexMetal
local mexByID = {} -- mexByID[unitID] = {gridID, allyTeamID, refundTeamID, refundTime, refundTotal, refundSoFar}

local pylon = {} -- pylon[allyTeamID][unitID] = {gridID,mexes,mex[unitID],x,z,overdrive, attachedPylons = {[1] = size, [2] =  unitID, ...}}
local pylonList = {} -- pylon[allyTeamID] = {data = {[1] = unitID, [2] = unitID, ...}, count = number}

local generator = {} -- generator[allyTeamID][teamID][unitID] = {generatorListID, metalIncome, energyIncome}
local generatorList = {} -- generator[allyTeamID][teamID] = {data  = {[1] = unitID, [2] = unitID, ...}, count = number}
local resourceGenoratingUnit = {}

local pylonGridQueue = false -- pylonGridQueue[unitID] = true

local unitPaybackTeamID = {} -- indexed by unitID, tells unit which team gets it's payback.
local teamPayback = {} -- teamPayback[teamID] = {count = 0, toRemove = {}, data = {[1] = {unitID = unitID, cost = costOfUnit, repaid = howMuchHasBeenRepaid}}}

local allyTeamInfo = {}

local quadFields = {} -- quadFields[allyTeamID] = quadField object (see Utilities/quadField.lua)

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
		quadFields[allyTeamID] = Spring.Utilities.QuadField(QUADFIELD_SQUARE_SIZE)

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
			innateMetal = Spring.GetGameRulesParam("OD_allyteam_metal_innate_" .. allyTeamID) or 0,
			innateEnergy = Spring.GetGameRulesParam("OD_allyteam_energy_innate_" .. allyTeamID) or 0,
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
			teamID, resourceShares, -- TeamID of the team as well as number of active allies.

			summedBaseMetal, -- AllyTeam base metal extrator income
			summedOverdrive, -- AllyTeam overdrive income
			allyTeamMiscMetalIncome, -- AllyTeam constructor income

			allyTeamEnergyIncome, -- AllyTeam total energy generator income
			allyTeamEnergyMisc, -- Team share innate and constructor energyIncome
			overdriveEnergySpending, -- AllyTeam energy spent on overdrive
			energyWasted, -- AllyTeam energy excess

			baseShare, -- Team share of base metal extractor income
			odShare, -- Team share of overdrive income
			miscShare, -- Team share of constructor metal income

			energyIncome, -- Total energy generator income
			energyMisc, -- Team share innate and constructor energyIncome
			overdriveEnergyNet, -- Amount of energy spent or recieved due to overdrive and income
			overdriveEnergyChange) -- real change in energy due to overdrive

	if previousData[teamID] then
		local pd = previousData[teamID]
		spSetTeamRulesParam(teamID, "OD_allies",               pd.resourceShares, privateTable)

		spSetTeamRulesParam(teamID, "OD_team_metalBase",       pd.summedBaseMetal, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_metalOverdrive",  pd.summedOverdrive, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_metalMisc",       pd.allyTeamMiscMetalIncome, privateTable)

		spSetTeamRulesParam(teamID, "OD_team_energyIncome",    pd.allyTeamEnergyIncome, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_energyMisc",      pd.allyTeamEnergyMisc, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_energyOverdrive", pd.overdriveEnergySpending, privateTable)
		spSetTeamRulesParam(teamID, "OD_team_energyWaste",     pd.energyWasted, privateTable)

		spSetTeamRulesParam(teamID, "OD_metalBase",       pd.baseShare, privateTable)
		spSetTeamRulesParam(teamID, "OD_metalOverdrive",  pd.odShare, privateTable)
		spSetTeamRulesParam(teamID, "OD_metalMisc",       pd.miscShare, privateTable)

		spSetTeamRulesParam(teamID, "OD_energyIncome",    pd.energyIncome, privateTable)
		spSetTeamRulesParam(teamID, "OD_energyMisc",      pd.energyMisc, privateTable)
		spSetTeamRulesParam(teamID, "OD_energyOverdrive", pd.overdriveEnergyNet, privateTable)
		spSetTeamRulesParam(teamID, "OD_energyChange",    pd.overdriveEnergyChange, privateTable)

		spSetTeamRulesParam(teamID, "OD_RoI_metalDue",    teamPayback[teamID].metalDueOD, privateTable)
		spSetTeamRulesParam(teamID, "OD_base_metalDue",   teamPayback[teamID].metalDueBase, privateTable)
	else
		previousData[teamID] = {}
	end

	local pd = previousData[teamID]

	pd.resourceShares = resourceShares

	pd.summedBaseMetal = summedBaseMetal
	pd.summedOverdrive = summedOverdrive
	pd.allyTeamMiscMetalIncome = allyTeamMiscMetalIncome

	pd.allyTeamEnergyIncome = allyTeamEnergyIncome
	pd.allyTeamEnergyMisc = allyTeamEnergyMisc
	pd.overdriveEnergySpending = overdriveEnergySpending
	pd.energyWasted = energyWasted

	pd.baseShare = baseShare
	pd.odShare = odShare
	pd.miscShare = miscShare

	pd.energyIncome = energyIncome
	pd.energyMisc = energyMisc
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

	if debugGridMode then
		Spring.Echo("AddPylonToGrid " .. unitID)
	end

	local newGridID = 0
	local attachedGrids = 0
	local attachedGrid = {}
	local attachedGridID = {}

	--check for nearby pylons
	local ownRange = pylon[allyTeamID][unitID].linkRange

	local attachedPylons = pylon[allyTeamID][unitID].attachedPylons

	for i = 2, attachedPylons[1] do
		local pid = attachedPylons[i]
		local pylonData = pylon[allyTeamID][pid]
		if pylonData then
			if pid ~= unitID and pylonData.gridID ~= 0 and pylonData.active then
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
	if debugGridMode then
		Spring.Echo("QueueAddPylonToGrid " .. unitID)
	end
	if not pylonGridQueue then
		pylonGridQueue = {}
	end
	pylonGridQueue[unitID] = true
end

local function RemovePylonsFromGridQueue(unitID)
	if debugGridMode then
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
	quadFields[allyTeamID]:Insert(unitID, pX, pZ, range)
	local intersections = quadFields[allyTeamID]:GetIntersections(unitID)

	pylon[allyTeamID][unitID] = {
		gridID = 0,
		--mexes = 0,
		mex = (mexByID[unitID] and true) or false,
		attachedPylons = intersections,
		linkRange = range,
		mexRange = 10,
		--nearEnergy = {},
		x = pX,
		z = pZ,
		neededLink = pylonDefs[unitDefID].neededLink,
		active = true,
		color = 0,
	}

	for i = 2, intersections[1] do
		local pid = intersections[i]
		local pylonData = pylon[allyTeamID][pid]
		if pylonData then
			local attachedPylons = pylonData.attachedPylons
			attachedPylons[1] = attachedPylons[1] + 1
			attachedPylons[attachedPylons[1]] = unitID
		elseif not spammedError then
			Spring.Echo("Pylon problem detected in AddPylonToGrid.")
		end
	end

	local list = pylonList[allyTeamID]
	list.count = list.count + 1
	list.data[list.count] = unitID

	pylon[allyTeamID][unitID].listID = list.count

	if debugGridMode then
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

	if debugGridMode then
		Spring.Echo("DestroyGrid " .. oldGridID)
	end

	for pid,_ in pairs(ai.grid[oldGridID].pylon) do
		pylon[allyTeamID][pid].gridID = 0

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

	if debugGridMode then
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

	if debugGridMode then
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

	if debugGridMode then
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

	local intersections = pylon[allyTeamID][unitID].attachedPylons

	for i = 2, intersections[1] do
		local pid = intersections[i]
		local pylonData = pylon[allyTeamID][pid]
		if pylonData then
			local attachedPylons = pylonData.attachedPylons
			for j = 2, attachedPylons[1] do
				if attachedPylons[j] == unitID then
					attachedPylons[j] = attachedPylons[attachedPylons[1]]
					attachedPylons[1] = attachedPylons[1] - 1 -- no need to delete since we keep size
					break
				end
			end
		elseif not spammedError then
			Spring.Echo("Pylon problem detected in AddPylonToGrid.")
		end
	end
	quadFields[allyTeamID]:Remove(unitID)


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
			ai.mexCount = ai.mexCount + 1
			ai.mexMetal = ai.mexMetal + orgMetal
			ai.mexSquaredSum = ai.mexSquaredSum + (orgMetal * orgMetal)
			ai.grid[mexGridID].mexMetal = ai.grid[mexGridID].mexMetal + orgMetal
			ai.grid[mexGridID].mexSquaredSum = ai.grid[mexGridID].mexSquaredSum + (orgMetal * orgMetal)
		end
	end

	if debugGridMode then
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
								local this_stunned_or_inbuld = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1)
								if this_stunned_or_inbuld then
									orgMetal = 0
								end
								local thisIncomeFactor = spGetUnitRulesParam(unitID,"resourceGenerationFactor")
								if thisIncomeFactor then
									orgMetal = orgMetal*thisIncomeFactor
								end
								local thisMexE = gridE*(orgMetal * orgMetal)/ gridMetalSquared
								local metalMult = energyToExtraM(thisMexE)
								local thisMexM = orgMetal + orgMetal * metalMult

								spSetUnitRulesParam(unitID, "overdrive", 1+thisMexE/5, inlosTrueTable)
								spSetUnitRulesParam(unitID, "overdrive_energyDrain", thisMexE, inlosTrueTable)
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

local lastTeamOverdriveNetLoss = {}

function gadget:GameFrame(n)
	
	if not (GG.Lagmonitor and GG.Lagmonitor.GetResourceShares) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Lag monitor doesn't work so Overdrive is STUFFED")
	end
	local allyTeamResourceShares, teamResourceShare = GG.Lagmonitor.GetResourceShares()
	
	if (n % TEAM_SLOWUPDATE_RATE == 1) then
		for allyTeamID, allyTeamData in pairs(allyTeamInfo) do
			local debugMode = debugAllyTeam and debugAllyTeam[allyTeamID]
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
						local activeState = Spring.Utilities.GetUnitActiveState(unitID)
						local currentlyActive = (not stunned_or_inbuld) and (activeState or pylonData.neededLink)
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
			
			--// Calculate personal and shared energy income, and shared constructor metal income.
			-- Income is only from energy structures and constructors. Reclaim is always personal and unhandled by OD.
			local resourceShares = allyTeamResourceShares[allyTeamID]
			local splitByShare = true
			if (not resourceShares) or resourceShares < 1 then
				splitByShare = false
				resourceShares = allyTeamData.teams
			end
			
			local allyTeamMiscMetalIncome = allyTeamData.innateMetal
			local allyTeamSharedEnergyIncome = allyTeamData.innateEnergy
			local teamEnergy = {}
			
			for j = 1, allyTeamData.teams do
				local teamID = allyTeamData.team[j]
				-- Calculate total energy and misc. metal income from units and structures
				local genList = generatorList[allyTeamID][teamID]
				local gen = generator[allyTeamID][teamID]
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
							local currentlyActive = not stunned_or_inbuld
							local metal, energy = 0, 0
							if currentlyActive then
								local incomeFactor = spGetUnitRulesParam(unitID,"resourceGenerationFactor") or 1
								metal  = data.metalIncome*incomeFactor
								energy = data.energyIncome*incomeFactor

								allyTeamMiscMetalIncome = allyTeamMiscMetalIncome + metal
								if data.sharedEnergyGenerator then
									allyTeamSharedEnergyIncome = allyTeamSharedEnergyIncome + energy
								else
									sumEnergy = sumEnergy + energy
								end
							end
							spSetUnitRulesParam(unitID, "current_metalIncome", metal, inlosTrueTable)
							spSetUnitRulesParam(unitID, "current_energyIncome", energy, inlosTrueTable)
						end
					end
				end
				
				teamEnergy[teamID] = {inc = sumEnergy}
			end
			
			if debugMode then
				Spring.Echo("=============== Overdrive Debug " .. allyTeamID .. " ===============")
				Spring.Echo("resourceShares", resourceShares, "teams", allyTeamData.teams, "metal", allyTeamMiscMetalIncome, "energy", allyTeamSharedEnergyIncome)
				Spring.Echo("splitByShare", splitByShare, "innate metal", allyTeamData.innateMetal, "innate energy", allyTeamData.innateEnergy)
			end
			
			--// Calculate total energy and other metal income from structures and units
			-- Does not include reclaim

			local allyTeamEnergyIncome = 0
			local allyTeamExpense = 0
			local allyTeamEnergySpare = 0
			local allyTeamPositiveSpare = 0
			local allyTeamNegativeSpare = 0
			local allyTeamEnergyCurrent = 0
			local allyTeamEnergyMax = 0
			local allyTeamEnergyMaxCurMax = 0
			local holdBackEnergyFromOverdrive = 0

			local energyProducerOrUserCount = 0
			local sumInc = 0
			for i = 1, allyTeamData.teams do
				local teamID = allyTeamData.team[i]
				-- Collect energy information and contribute to ally team data.
				local te = teamEnergy[teamID]
				
				local share = (splitByShare and teamResourceShare[teamID]) or 1
				te.inc = te.inc + share*allyTeamSharedEnergyIncome/resourceShares

				te.cur, te.max, te.pull, _, te.exp, _, te.sent, te.rec = spGetTeamResources(teamID, "energy")
				te.exp = math.max(0, te.exp - (lastTeamOverdriveNetLoss[teamID] or 0))

				te.max = math.max(MIN_STORAGE, te.max - HIDDEN_STORAGE) -- Caretakers spend in chunks of 0.33

				allyTeamEnergyIncome = allyTeamEnergyIncome + te.inc
				allyTeamEnergyCurrent = allyTeamEnergyCurrent + te.cur
				allyTeamEnergyMax = allyTeamEnergyMax + te.max
				allyTeamExpense = allyTeamExpense + te.exp

				te.spare = te.inc - te.exp
				if te.max == MIN_STORAGE and te.spare < MIN_STORAGE then
					te.spare = 0
				end

				allyTeamEnergySpare = allyTeamEnergySpare + te.spare
				allyTeamPositiveSpare = allyTeamPositiveSpare + max(0, te.spare)
				allyTeamNegativeSpare = allyTeamNegativeSpare + max(0, -te.spare)
				
				if debugMode then
					Spring.Echo("--- Team Economy ---", teamID, "has share", teamResourceShare[teamID])
					Spring.Echo("inc", te.inc, "exp", te.exp, "spare", te.spare, "pull", te.pull)
					Spring.Echo("last spend", lastTeamOverdriveNetLoss[teamID], "cur", te.cur, "max", te.max)
				end
				
				if te.inc > 0 or te.exp > 0 then
					-- Include expense in case someone has no economy at all (not even cons) and wants to run cloak.
					te.energyProducerOrUser = true
					energyProducerOrUserCount = energyProducerOrUserCount + 1
				end
			end
			
			if energyProducerOrUserCount == 0 then
				for i = 1, allyTeamData.teams do
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					te.energyProducerOrUser = true
				end
				energyProducerOrUserCount = allyTeamData.teams
				if energyProducerOrUserCount == 0 then
					energyProducerOrUserCount = 1
				end
			end
			
			-- Allocate extra energy storage to teams with less energy income than the spare energy of their team.
			-- This better allows teams to spend at the capacity supported by their team.
			local averageSpare = allyTeamEnergySpare/energyProducerOrUserCount
			if debugMode then
				Spring.Echo("=========== Spare Energy ===========", allyTeamID)
				Spring.Echo("averageSpare", averageSpare)
			end
			for i = 1, allyTeamData.teams do
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]
				if te.energyProducerOrUser then
					te.extraFreeStorage = math.max(0, averageSpare - te.inc)
					
					-- This prevents full overdrive until everyone has full energy storage.
					allyTeamEnergyMaxCurMax = allyTeamEnergyMaxCurMax + math.max(te.max + te.extraFreeStorage, te.cur)
					
					-- Save from energy from being sent to overdrive if we are stalling and have below average energy income.
					local holdBack = math.max(0, te.extraFreeStorage - te.cur)
					holdBackEnergyFromOverdrive = holdBackEnergyFromOverdrive + holdBack
					if debugMode then
						Spring.Echo(teamID, "extraFreeStorage", te.extraFreeStorage, "spare", te.spare, "held back", holdBack)
					end
				else
					te.extraFreeStorage = 0
					if debugMode then
						Spring.Echo(teamID, "Not participating")
					end
				end
			end
			
			-- This is how much energy will be spent on overdrive. It remains to determine how much
			-- is spent by each player.
			local energyForOverdrive = max(0, allyTeamEnergySpare)*((allyTeamEnergyMaxCurMax > 0 and max(0, min(1, allyTeamEnergyCurrent/allyTeamEnergyMaxCurMax))) or 1)
			energyForOverdrive = math.max(0, energyForOverdrive - holdBackEnergyFromOverdrive)
			
			if debugMode then
				Spring.Echo("=========== AllyTeam Economy ===========", allyTeamID)
				Spring.Echo("inc", allyTeamEnergyIncome, "exp", allyTeamExpense, "spare", allyTeamEnergySpare)
				Spring.Echo("+spare", allyTeamPositiveSpare, "-spare", allyTeamNegativeSpare, "cur", allyTeamEnergyCurrent, "max", allyTeamEnergyMax)
				Spring.Echo("energyForOverdrive", energyForOverdrive, "heldBack", holdBackEnergyFromOverdrive)
				Spring.Echo("maxCurMax", allyTeamEnergyMaxCurMax, "averageSpare", averageSpare)
			end
			
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
			for i = 1, list.count do
				local unitID = list.data[i]
				local pylonData = pylon[allyTeamID][unitID]
				if pylonData then
					if pylonData.neededLink then
						if pylonData.gridID == 0 or pylonData.neededLink > maxGridCapacity[pylonData.gridID] then
							spSetUnitRulesParam(unitID,"lowpower",1, inlosTrueTable)
							GG.ScriptNotifyUnpowered(unitID, true)
						else
							spSetUnitRulesParam(unitID,"lowpower",0, inlosTrueTable)
							GG.ScriptNotifyUnpowered(unitID, false)
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
				
				-- Allow a refund up to the to the average spare energy contributed to the system. This allows
				-- people with zero storage to build.
				te.freeStorage = te.max + te.exp - te.cur + te.extraFreeStorage
				if te.energyProducerOrUser then
					te.freeStorage = te.freeStorage + allyTeamEnergySpare/energyProducerOrUserCount
				end
				if te.freeStorage > 0 then
					if te.energyProducerOrUser then
						totalFreeStorage = totalFreeStorage + te.freeStorage
						if debugMode then
							Spring.Echo(teamID, "Free", te.freeStorage)
						end
					end
				else
					-- Even sides that do not produce or consume may have excess energy.
					energyToRefund = energyToRefund - te.freeStorage
					te.overdriveEnergyNet = te.overdriveEnergyNet + te.freeStorage
					te.freeStorage = 0
					if debugMode then
						Spring.Echo(teamID, "Overflow", -te.freeStorage)
					end
				end
			end
			
			if debugMode then
				Spring.Echo("AllyTeam totalFreeStorage", totalFreeStorage, "energyToRefund", energyToRefund)
			end

			if totalFreeStorage > energyToRefund then
				for i = 1, allyTeamData.teams do
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					if te.energyProducerOrUser then
						te.overdriveEnergyNet = te.overdriveEnergyNet + energyToRefund*te.freeStorage/totalFreeStorage
					end
				end
				energyWasted = 0
			else
				for i = 1, allyTeamData.teams do
					local teamID = allyTeamData.team[i]
					local te = teamEnergy[teamID]
					if te.energyProducerOrUser then
						te.overdriveEnergyNet = te.overdriveEnergyNet + te.freeStorage
					end
				end
				energyWasted = energyToRefund - totalFreeStorage
			end
			
			if debugMode then
				Spring.Echo("AllyTeam energyWasted", energyWasted)
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
						if not unitDefID then
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

			-- Extra base share from mex production
			local summedBaseMetalAfterPrivate = summedBaseMetal
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
			local teamPaybackOD = {}
			if enableEnergyPayback then
				for i = 1, allyTeamData.teams do
					local teamID = allyTeamData.team[i]
					if teamResourceShare[teamID] then -- Isn't this always 1 or 0?
					-- well it can technically be 2+ when comsharing (but shouldn't act as a multiplier because the debt should transfer)
						local te = teamEnergy[teamID]
						teamPaybackOD[teamID] = 0

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
												teamPaybackOD[teamID] = teamPaybackOD[teamID] + repayMetal
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
			
			--// Share Overdrive Metal and Energy
			-- Make changes to team resources
			local shareToSend = {}
			local metalStorageToSet = {}
			local totalToShare = 0
			local freeSpace = {}
			local totalFreeSpace = 0
			local totalMetalIncome = {}
			for i = 1, allyTeamData.teams do
				local teamID = allyTeamData.team[i]
				local te = teamEnergy[teamID]

				--// Energy
				-- Inactive teams still interact normally with energy for a few reasons:
				-- * Energy shared to them would disappear otherwise.
				-- * If they have reclaim (somehow) then they could build up storage without sharing.
				local energyChange = te.overdriveEnergyNet + te.inc
				if energyChange > 0 then
					spAddTeamResource(teamID, "e", energyChange)
					lastTeamOverdriveNetLoss[teamID] = 0
				elseif te.overdriveEnergyNet + te.inc < 0 then
					spUseTeamResource(teamID, "e", -energyChange)
					lastTeamOverdriveNetLoss[teamID] = -energyChange
				else
					lastTeamOverdriveNetLoss[teamID] = 0
				end
				
				if debugMode then
					Spring.Echo("Team energy income", teamID, "change", energyChange, "inc", te.inc, "net", te.overdriveEnergyNet)
				end
				
				-- Metal
				local odShare = 0
				local baseShare = 0
				local miscShare = 0
				local energyMisc = 0

				local share = (splitByShare and teamResourceShare[teamID]) or 1
				if share > 0 then
					odShare = ((share * summedOverdriveMetalAfterPayback / resourceShares) + (teamPaybackOD[teamID] or 0)) or 0
					baseShare = ((share * summedBaseMetalAfterPrivate / resourceShares) + (privateBaseMetal[teamID] or 0)) or 0
					miscShare = share * allyTeamMiscMetalIncome / resourceShares
					energyMisc = share * allyTeamSharedEnergyIncome / resourceShares
				end

				sendTeamInformationToAwards(teamID, baseShare, odShare, te.overdriveEnergyNet)

				local mCurr, mStor = spGetTeamResources(teamID, "metal")
				mStor = math.max(MIN_STORAGE, mStor - HIDDEN_STORAGE) -- Caretakers spend in chunks of 0.33
				
				if mCurr > mStor then
					shareToSend[i] = mCurr - mStor
					metalStorageToSet[i] = mStor
					totalToShare = totalToShare + shareToSend[i]
				end
				
				local metalIncome = odShare + baseShare + miscShare
				if mCurr + metalIncome < mStor then
					freeSpace[i] = mStor - (mCurr + metalIncome)
					totalFreeSpace = totalFreeSpace + freeSpace[i]
				end
				
				totalMetalIncome[i] = metalIncome
				--Spring.Echo(teamID .. " got odShare " .. odShare)
				SetTeamEconomyRulesParams(
					teamID, resourceShares, -- TeamID of the team as well as number of active allies.

					summedBaseMetal, -- AllyTeam base metal extrator income
					summedOverdrive, -- AllyTeam overdrive income
					allyTeamMiscMetalIncome, -- AllyTeam constructor income

					allyTeamEnergyIncome, -- AllyTeam total energy income (everything)
					allyTeamSharedEnergyIncome,
					overdriveEnergySpending, -- AllyTeam energy spent on overdrive
					energyWasted, -- AllyTeam energy excess

					baseShare, -- Team share of base metal extractor income
					odShare, -- Team share of overdrive income
					miscShare, -- Team share of constructor metal income

					te.inc, -- Non-reclaim energy income for the team
					energyMisc, -- Team share of innate and constructor income
					te.overdriveEnergyNet, -- Amount of energy spent or recieved due to overdrive and income
					te.overdriveEnergyNet + te.inc -- real change in energy due to overdrive
				)
			end
			
			if totalToShare ~= 0 then
				local excessFactor = 1 - math.min(1, totalFreeSpace/totalToShare)
				local shareFactorPerSpace = (1 - excessFactor)/totalFreeSpace
				for i = 1, allyTeamData.teams do
					if shareToSend[i] then
						local sendID = allyTeamData.team[i]
							
						for j = 1, allyTeamData.teams do
							if freeSpace[j] then
								local recieveID = allyTeamData.team[j]
								Spring.ShareTeamResource(sendID, recieveID, "metal", shareToSend[i] * freeSpace[j] * shareFactorPerSpace)
							end
						end
						if excessFactor ~= 0 and GG.EndgameGraphs then
							GG.EndgameGraphs.AddTeamMetalExcess(sendID, shareToSend[i] * excessFactor)
						end
					end
				end
			end
			
			for i = 1, allyTeamData.teams do
				local teamID = allyTeamData.team[i]
				if metalStorageToSet[i] then
					Spring.SetTeamResource(teamID, "metal", metalStorageToSet[i])
				end
				spAddTeamResource(teamID, "m", totalMetalIncome[i])
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
				isWind = defData.isWind,
				sharedEnergyGenerator = defData.sharedEnergyGenerator,
			}
		else
			generator[allyTeamID][teamID][unitID] = {
				metalIncome = spGetUnitRulesParam(unitID, "wanted_metalIncome") or defData.metalIncome,
				energyIncome = spGetUnitRulesParam(unitID, "wanted_energyIncome") or defData.energyIncome,
				sharedEnergyGenerator = defData.sharedEnergyGenerator,
			}
		end
	else
		generator[allyTeamID][teamID][unitID] = {
			metalIncome = spGetUnitRulesParam(unitID, "wanted_metalIncome") or 0,
			energyIncome = spGetUnitRulesParam(unitID, "wanted_energyIncome") or 0,
			sharedEnergyGenerator = unitDefID and UnitDefs[unitDefID].customParams.shared_energy_gen and true,
		}
	end

	local list = generatorList[allyTeamID][teamID]
	list.count = list.count + 1
	list.data[list.count] = unitID

	generator[allyTeamID][teamID][unitID].listID = list.count
	resourceGenoratingUnit[unitID] = true
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
		debugGridMode = not debugGridMode
		if debugGridMode then
			local allyTeamList = Spring.GetAllyTeamList()
			for i=1,#allyTeamList do
				local allyTeamID = allyTeamList[i]
				local list = pylonList[allyTeamID]
				for j = 1, list.count do
					local unitID = list.data[j]
					UnitEcho(unitID, j .. ", " .. unitID)
				end
			end
		end
	end
end

local function OverdriveDebugEconomyToggle(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local allyTeamID = tonumber(words[1])
	Spring.Echo("Debug priority for allyTeam " .. (allyTeamID or "nil"))
	if allyTeamID then
		if not debugAllyTeam then
			debugAllyTeam = {}
		end
		if debugAllyTeam[allyTeamID] then
			debugAllyTeam[allyTeamID] = nil
			if #debugAllyTeam == 0 then
				debugAllyTeam = {}
			end
			Spring.Echo("Disabled")
		else
			debugAllyTeam[allyTeamID] = true
			Spring.Echo("Enabled")
		end
	end
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- External functions

local externalFunctions = {}

function externalFunctions.AddUnitResourceGeneration(unitID, metal, energy, sharedEnergyGenerator, override)
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

	local metalIncome = math.max(0, ((override and 0) or genData.metalIncome) + (metal * (Spring.GetModOptions().metalmult or 1)))
	local energyIncome = math.max(0, ((override and 0) or genData.energyIncome) + (energy * (Spring.GetModOptions().energymult or 1)))

	genData.metalIncome = metalIncome
	genData.energyIncome = energyIncome
	genData.sharedEnergyGenerator = sharedEnergyGenerator

	spSetUnitRulesParam(unitID, "wanted_metalIncome", metalIncome, inlosTrueTable)
	spSetUnitRulesParam(unitID, "wanted_energyIncome", energyIncome, inlosTrueTable)
end

function externalFunctions.AddInnateIncome(allyTeamID, metal, energy)
	if not (allyTeamID and allyTeamInfo[allyTeamID]) then
		return
	end
	allyTeamInfo[allyTeamID].innateMetal = (allyTeamInfo[allyTeamID].innateMetal or 0) + metal
	allyTeamInfo[allyTeamID].innateEnergy = (allyTeamInfo[allyTeamID].innateEnergy or 0) + energy
	Spring.SetGameRulesParam("OD_allyteam_metal_innate_" .. allyTeamID, allyTeamInfo[allyTeamID].innateMetal)
	Spring.SetGameRulesParam("OD_allyteam_energy_innate_" .. allyTeamID, allyTeamInfo[allyTeamID].innateEnergy)
end

function externalFunctions.RedirectTeamIncome(giveTeamID, recieveTeamID)

end

function externalFunctions.RemoveTeamIncomeRedirect(teamID)

end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()

	GG.Overdrive = externalFunctions

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

	gadgetHandler:AddChatAction("debuggrid", OverdriveDebugToggle, "Toggles grid debug mode for overdrive.")
	gadgetHandler:AddChatAction("debugecon", OverdriveDebugEconomyToggle, "Toggles economy debug mode for overdrive.")
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
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID, false)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeamID, false)

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
		if mexDefs[unitDefID] and mexByID[unitID] then
			TransferMexRefund(unitID, teamID)
		end
	end

	if (generatorDefs[unitDefID]) or spGetUnitRulesParam(unitID, "wanted_energyIncome") then
		AddResourceGenerator(unitID, unitDefID, teamID, newAllyTeamID)
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID, false)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeamID, false)

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
