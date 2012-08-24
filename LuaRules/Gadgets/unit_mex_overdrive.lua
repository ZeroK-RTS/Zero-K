-- $Id: unit_mex_overdrive.lua 4550 2009-05-05 18:07:29Z licho $
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
local linkdefs = {}

include("LuaRules/Configs/constants.lua")
include("LuaRules/Configs/mex_overdrive.lua")
local odSharingModOptions


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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

Spring.SetGameRulesParam("lowpower",1)

local MEX_DIAMETER = Game.extractorRadius*2

local PAYBACK_FACTOR = 1.5

local paybackDefs = { -- cost is how much to pay back
	[UnitDefNames["armwin"].id] = {cost = UnitDefNames["armwin"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["armsolar"].id] = {cost = UnitDefNames["armsolar"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["armfus"].id] = {cost = UnitDefNames["armfus"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["cafus"].id] = {cost = UnitDefNames["cafus"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["geo"].id] = {cost = UnitDefNames["geo"].metalCost*PAYBACK_FACTOR},
	[UnitDefNames["amgeo"].id] = {cost = UnitDefNames["amgeo"].metalCost*PAYBACK_FACTOR},
}

local function PaybackFactorFunction(repayRatio)
	-- Must map [0,1) to (0,1]
	-- Must not have any sequences on the domain that converge to 0 in the codomain.
	local repay =  2 - repayRatio*1.8
	if repay > 0.8 then
		return 0.8
	else
		return repay
	end
end

--local PYLON_ENERGY_RANGESQ = 160000
--local PYLON_LINK_RANGESQ = 40000
--local PYLON_MEX_RANGESQ = 10000
--local PYLON_MEX_LIMIT = 100

--local CMD_MEXE = 30666

local spammedError = false

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

local spGetTeamResources  = Spring.GetTeamResources
local spAddTeamResource   = Spring.AddTeamResource
local spUseTeamResource   = Spring.UseTeamResource
local spGetTeamInfo       = Spring.GetTeamInfo

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local takenMexId = {} -- mex ids that are taken by disabled pylons
local notDestroyed = {}

local mexes = {}   -- mexes[teamID][gridID][unitID] == mexMetal
local mexByID = {}
local mexesToAdd = {}

local lowPowerUnits = {inner = {count = 0, units = {}}}

local pylon = {} -- pylon[allyTeamID][unitID] = {gridID,mexes,mex[unitID],x,z,overdrive, nearPlant[unitID],nearPylon[unitID], color}

local allyTeamInfo = {} 

do
  local allyTeamList = Spring.GetAllyTeamList()
  for i=1,#allyTeamList do
	local allyTeamID = allyTeamList[i]
	pylon[allyTeamID] = {}
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
-- local functions

local function energyToExtraM(energy)  
	return -1+sqrt(1+(energy*0.25))
end


local function HSLtoRGB(ch,cs,cl)
 
if cs == 0 then
  cr = cl
  cg = cl
  cb = cl
else
  if cl < 0.5 then temp2 = cl * (cl + cs)
  else temp2 = (cl + cs) - (cl * cs)
  end
 
  temp1 = 2 * cl - temp2
  tempr = ch + 1 / 3
 
  if tempr > 1 then tempr = tempr - 1 end
  tempg = ch
  tempb = ch - 1 / 3
  if tempb < 0 then tempb = tempb + 1 end
 
  if tempr < 1 / 6 then cr = temp1 + (temp2 - temp1) * 6 * tempr
  elseif tempr < 0.5 then cr = temp2
  elseif tempr < 2 / 3 then cr = temp1 + (temp2 - temp1) * ((2 / 3) - tempr) * 6
  else cr = temp1
  end
 
  if tempg < 1 / 6 then cg = temp1 + (temp2 - temp1) * 6 * tempg
  elseif tempg < 0.5 then cg = temp2
  elseif tempg < 2 / 3 then cg = temp1 + (temp2 - temp1) * ((2 / 3) - tempg) * 6
  else cg = temp1
  end
 
  if tempb < 1 / 6 then cb = temp1 + (temp2 - temp1) * 6 * tempb
  elseif tempb < 0.5 then cb = temp2
  elseif tempb < 2 / 3 then cb = temp1 + (temp2 - temp1) * ((2 / 3) - tempb) * 6
  else cb = temp1
  end
 
end
return {cr,cg,cb, 0.2}
end --HSLtoRGB


local function GetGridColor(conversion, isExcess) 
 	local n = conversion      
	  -- mex has no esource/esource has no mex
		if n==0 then
                return {1, .25, 1, 0.2}
 
        else
                 if n < 3.5 then 
                 h = 5760/(3.5+2)^2 
                 else
                 h=5760/(n+2)^2
                 end
			return HSLtoRGB(h/255,1,0.5)
        end
        
--[[
--	average/good - will be green
	local good = 3
	--max/inefficient - will be red
	local bad = 15
		 -- mex has no esource/esource has no mex
	if n == 0 then
		return {1, 0.25, 1, 0.25}
	else
                -- red, green, blue
                r, g, b = 0, 0, 0
                
                if n <= good then
                        b = (1 - n/good)^.5
                        g = (n/good)^.5
                elseif n <= bad then
                        -- difference of bad and good
                        local z = bad-good
                        -- n - good, since we are inside "good-bad" now
                        -- n must not be bigger than z
                        nRemain = min(n-good, z)
                        
                        g = 1 - nRemain/z
                        r = (nRemain/z)^.3
                else
                        r = bad/n
                end
        end
	return {r, g, b, 0.2}]]--
end 

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- PYLONS

local function AddPylonToGrid(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]

	local newGridID = 0
	local attachedGrids = 0
	local attachedGrid = {}
	local attachedGridID = {}
	
	--check for nearby pylons
	local ownRange = pylon[allyTeamID][unitID].linkRange
	for pid, pylonData in pairs(pylon[allyTeamID]) do
		if pid ~= unitID and (pylonData.x-pX)^2 + (pylonData.z-pZ)^2 <= (pylonData.linkRange+ownRange)^2  and pylonData.gridID ~= 0 and pylonData.active then
			pylon[allyTeamID][unitID].nearPylon[pid] = true
			if not attachedGridID[pylonData.gridID] then
				attachedGrids = attachedGrids + 1
				
				attachedGrid[attachedGrids] = pylonData.gridID
				attachedGridID[pylonData.gridID] = true
			end
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
				for mid,_ in pairs(pylonData.mex) do
					mexes[allyTeamID][newGridID][mid] = mexes[allyTeamID][oldGridID][mid]
					mexByID[mid].gridID = newGridID
					mexes[allyTeamID][oldGridID][mid] = nil
				end
				ai.grid[newGridID].pylon[pid] = true
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
	
	-- add econ to new grid
	-- mexes
	for mid,_ in pairs(pylon[allyTeamID][unitID].mex) do
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

local function AddPylon(unitID, unitDefID, unitOverdrive, range)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]

	pylon[allyTeamID][unitID] = {
		gridID = 0,
		--mexes = 0,
		mex = {},
		nearPylon = {},
		linkRange = range,
		mexRange = 10,
		--nearEnergy = {},
		x = pX,
		z = pZ,
		neededLink = pylonDefs[unitDefID].neededLink,
		overdrive = unitOverdrive, 
		active = true,
	}
	
	-- check for mexes
	if unitOverdrive then 
		for mid, orgMetal in pairs(mexes[allyTeamID][0]) do
			local mX,_,mZ = spGetUnitPosition(mid)
			if (mid == unitID) then -- mex as pylon
			--if (pX-mX)^2 + (pZ-mZ)^2 <= range^2 and not takenMexId[mid] then
			
				--pylon[allyTeamID][unitID].mexes = pylon[allyTeamID][unitID].mexes + 1
				pylon[allyTeamID][unitID].mex[mid] = true
				--takenMexId[mid] = true
				
				--if pylon[allyTeamID][unitID].mexes >= PYLON_MEX_LIMIT then
				--	break
				--end
			end
		end
	end
	
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
	
	AddPylonToGrid(unitID)
end

local function DestoryGrid(allyTeamID,oldGridID)
	local ai = allyTeamInfo[allyTeamID]
	
	for pid,_ in pairs(ai.grid[oldGridID].pylon) do
		pylon[allyTeamID][pid].gridID = 0
		pylon[allyTeamID][pid].nearPylon = {}
		
		for mid,_ in pairs(pylon[allyTeamID][pid].mex) do
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
	
	local pX,_,pZ = spGetUnitPosition(unitID)
	
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
	
	AddPylonToGrid(unitID)
end

local function DeactivatePylon(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	local oldGridID = pylon[allyTeamID][unitID].gridID
	
	local pylonList = ai.grid[oldGridID].pylon
	local energyList = pylon[allyTeamID][unitID].nearEnergy
	
	DestoryGrid(allyTeamID,oldGridID)
	
	pylon[allyTeamID][unitID].active = false
	
	for pid,_ in pairs(pylonList) do
		if (pid ~= unitID) then
			AddPylonToGrid(pid)
		end
	end
	
	--pylon[allyTeamID][unitID].nearEnergy = {}
	-- energy
	--[[
	for eid,_ in pairs(energyList) do
		ai.plant[eid] = 0
		local eX,_,eZ = spGetUnitPosition(eid)
		-- check for nearby pylons
		for pid, pylonData in pairs(pylon[allyTeamID]) do
			if (pylonData.x-eX)^2 + (pylonData.z-eZ)^2 < PYLON_ENERGY_RANGESQ and pylonData.active then
				ai.plant[eid] = 1
				ai.grid[pylonData.gridID].plant[eid] = true
				pylon[allyTeamID][pid].nearEnergy[eid] = true
				break
			end
		end
		
	end
	--]]
end

local function RemovePylon(unitID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if not pylon[allyTeamID][unitID] then
		--Spring.Echo("RemovePylon not pylon[allyTeamID][unitID] " .. unitID)
		return
	end
	
	local pX,_,pZ = spGetUnitPosition(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	local oldGridID = pylon[allyTeamID][unitID].gridID
	local activeState = pylon[allyTeamID][unitID].active
	
	local mexList = pylon[allyTeamID][unitID].mex
	
	if activeState then
		local pylonList = ai.grid[oldGridID].pylon	
		local energyList = pylon[allyTeamID][unitID].nearEnergy
	
		DestoryGrid(allyTeamID,oldGridID)
		
		pylon[allyTeamID][unitID] = nil
		for pid,_ in pairs(pylonList) do
			if (pid ~= unitID) then
				AddPylonToGrid(pid)
			end
		end
		
		-- energy
		--[[
		for eid,_ in pairs(energyList) do
			ai.plant[eid] = 0
			local eX,_,eZ = spGetUnitPosition(eid)
			-- check for nearby pylons
			for pid, pylonData in pairs(pylon[allyTeamID]) do
				if (pylonData.x-eX)^2 + (pylonData.z-eZ)^2 < PYLON_ENERGY_RANGESQ  and pylonData.active then
					ai.plant[eid] = 1
					ai.grid[pylonData.gridID].plant[eid] = true
					pylon[allyTeamID][pid].nearEnergy[eid] = true
					break
				end
			end
		end
		--]]
	else
		pylon[allyTeamID][unitID] = nil
	end
	
	-- mexes
	for mid,_ in pairs(mexList) do
		local orgMetal = mexes[allyTeamID][0][mid]
		mexes[allyTeamID][0][mid] = nil
		mexByID[mid] = nil
		local mexGridID = 0
		takenMexId[mid] = false
		
		local mX, _, mZ = spGetUnitPosition(mid)
						
		for pid, pylonData in pairs(pylon[allyTeamID]) do
			if pid == mid then
			--if pylonData.overdrive and pylonData.mexes < PYLON_MEX_LIMIT and (pylonData.x-mX)^2 + (pylonData.z-mZ)^2 <= pylonData.mexRange^2 then
				--pylonData.mexes = pylonData.mexes+1
				pylonData.mex[mid] = true
				mexGridID = pylonData.gridID
				break
			end
		end
		
		mexes[allyTeamID][mexGridID][mid] = orgMetal
		mexByID[mid].gridID = mexGridID
		if mexGridID ~= 0 then
			local ai = allyTeamInfo[allyTeamID]
			ai.mexCount = ai.mexCount + 1
			ai.mexMetal = ai.mexMetal + orgMetal
			ai.mexSquaredSum = ai.mexSquaredSum + (orgMetal * orgMetal)
			ai.grid[mexGridID].mexMetal = ai.grid[mexGridID].mexMetal + orgMetal
			ai.grid[mexGridID].mexSquaredSum = ai.grid[mexGridID].mexSquaredSum + (orgMetal * orgMetal)
		end
	end
	
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- METAL DISTRIBUTION Payback InvestmentReturn, return OD cost of the energy structure

local teamPayback = {} -- teamPayback[teamID] = {count = 0, toRemove = {}, data = {[1] = {unitID = unitID, cost = costOfUnit, repaid = howMuchHasBeenRepaid}}}
local unitPaybackTeamID = {} -- indexed by unitID, tells unit which team gets it's payback.

local function AddEnergyToPayback(unitID, unitDefID, unitTeam)
	local def = paybackDefs[unitDefID]

	unitPaybackTeamID[unitID] = unitTeam
	teamPayback[unitTeam] = teamPayback[unitTeam] or {count = 0, toRemove = {}, data = {}}
	
	local teamData = teamPayback[unitTeam]
	teamData.count = teamData.count + 1
	teamData.data[teamData.count] = {
		unitID = unitID,
		cost = def.cost,
		repaid = 0,
	}
end

local function RemoveEnergyToPayback(unitID, unitDefID)
	local unitTeam = unitPaybackTeamID[unitID]
	if unitTeam then -- many energy pieces will not have a payback when destroyed
		local teamData = teamPayback[unitTeam]
		teamData.toRemove[unitID] = true
	end
end

local function InvestmentReturn (summedOverdrive,allyTeamData,activeTeams,teamEnergy, allyTeamEnergyIncome, activeCount)
	-- Payback from energy production
	local teamPacybackOD = {}
	local summedOverdriveMetalAfterPayback = summedOverdrive
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
							if inc ~= 0 then
								local repayRatio = data[j].repaid/data[j].cost
								if repayRatio < 1 then
									local repayMetal = inc/allyTeamEnergyIncome * summedOverdrive * PaybackFactorFunction(repayRatio)
									data[j].repaid = data[j].repaid + repayMetal
									summedOverdriveMetalAfterPayback = summedOverdriveMetalAfterPayback - repayMetal
									teamPacybackOD[teamID] = teamPacybackOD[teamID] + repayMetal
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
	local teamPacybackOD_2 = {}
	for i = 1, allyTeamData.teams do 
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			teamPacybackOD_2[teamID] = summedOverdriveMetalAfterPayback / activeCount + (teamPacybackOD[teamID] or 0)
		end
	end
	return teamPacybackOD_2
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- METAL DISTRIBUTION Delta-OD, grow & shrink based on extra E feed into OD & decay after 3 minute

local secondLapsed = {}
local previous_summedOverdrive = {}
local history_summedOverdrive = {}
local previous_teamODEnergy = {}
local history_teamODEnergy = {}
local history_index = 0
local function DeltaODWithDecayScheme(allyTeamID, allyTeamData, activeTeams, activeCount, teamODEnergy, summedOverdrive, summedBaseMetalAfterPrivate, privateBaseMetal)
	
	local timeToUpdate = 180 -- constant to customize OD distribution. ie: compare current OD with-respect-to "timeToUpdate" second ago. Greater value means greater return. 
	--//Store history of relevant data:
	history_index_new = history_index + 1
	if history_index_new > timeToUpdate then 
		history_index_new = 1 
	end
	history_summedOverdrive[history_index_new] = history_summedOverdrive[history_index_new] or {}
	history_summedOverdrive[history_index_new][allyTeamID] = summedOverdrive
	for i = 1, allyTeamData.teams do --iterate & update E history over all player including for inactive player.
		local teamID = allyTeamData.team[i]
		history_teamODEnergy[history_index_new] = history_teamODEnergy[history_index_new] or {}
		history_teamODEnergy[history_index_new][teamID] = (teamODEnergy[teamID] or 0) --update history
	end
	--//Retrieve relevant data from history:
	local history_index_old = history_index_new - (timeToUpdate - 1)
	if history_index_old < 1 then 
		history_index_old = history_index_old + timeToUpdate 
	end
	history_summedOverdrive[history_index_old] = history_summedOverdrive[history_index_old] or {}
	previous_summedOverdrive[allyTeamID] = history_summedOverdrive[history_index_old][allyTeamID] or 0
	for i = 1, allyTeamData.teams do
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			history_teamODEnergy[history_index_old] = history_teamODEnergy[history_index_old] or {}
			previous_teamODEnergy[teamID] = history_teamODEnergy[history_index_old][teamID] or 0 --retrieve old value
		end
	end
	--//Calculate total E difference & individual E contribution:
	local teamODEnergyDiff = {} --Energy changes for each team
	local totalEDiff = 0 --the total Energy changes with respect to reference point
	for i = 1, allyTeamData.teams do  --get total E difference and get individual E difference.
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			teamODEnergyDiff[teamID] =  (teamODEnergy[teamID] or 0) - previous_teamODEnergy[teamID] --the difference in currentOD energy with respect to reference point for each team.
			totalEDiff = totalEDiff + teamODEnergyDiff[teamID] --totalEDiff (total Energy difference)
		end
	end
	--//Calculate normalizing denominator/factor that limit negative OD:
	local metalDiff = summedOverdrive - previous_summedOverdrive[allyTeamID] -- the difference between current OD-metal vs reference OD-metal
	local teamODEnergyPercent = {}
	local normFactor = 1
	for i = 1, allyTeamData.teams do -- [Anti-bug], flag any big negative OD share which absolute-valued greater than mex-metal-share. This is to prevent negative income for people who looses E.  
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			teamODEnergyPercent[teamID] = teamODEnergyDiff[teamID]/totalEDiff
			local proposedODshare = (teamODEnergyPercent[teamID]/normFactor)*metalDiff --equation (1)
			local proposedMexShare = summedBaseMetalAfterPrivate / activeCount + (privateBaseMetal[teamID] or 0) --equation copied from other part of unit_mex_overdrive.lua
			if proposedODshare < 0 and proposedMexShare < math.abs(proposedODshare) then --if proposed delta-ODshare consume more than the available mex-income then: scale down delta-OD for all.
				normFactor = math.abs(teamODEnergyPercent[teamID]/(proposedMexShare/metalDiff)) --from equation (1), where "proposedODshare" is replaced with "proposedMexShare" and solve for new "normFactor"
			end
		end
	end
	--//Calculate delta-ODshare for each team:
	local newODshare = {}
	for i = 1, allyTeamData.teams do --multiply ODEnergyShare with OD increase/decrease
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			newODshare[teamID] = (teamODEnergyPercent[teamID]/normFactor)*metalDiff --the amount of metal deserved for each contributed increase or decrease in team's E
			if(newODshare[teamID] ~= newODshare[teamID]) then --> if nan check, true ,(nan = 0/0). Happens when "teamODEnergyPercent[teamID] == 0/0", "We rely on the property that NaN is the only value that doesn't equal itself" -- DavidManura  -Ref: http://lua-users.org/wiki/InfAndNanComparisons
				newODshare[teamID] = 0
			end
		end
	end
	--//Calculate total-ODshare for each team:
	local basicODShare = previous_summedOverdrive[allyTeamID]/activeCount -- OD-metal-shares that is set as reference point, set to equal sharing.
	local teamPacybackOD = {}
	for i = 1, allyTeamData.teams do --gave away basic OD share + delta-OD distribution (if available)
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			teamPacybackOD[teamID] = basicODShare + (newODshare[teamID] or 0) --add new OD-metal to the reference OD-metal share
		end
	end
	return teamPacybackOD
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- METAL DISTRIBUTION 50 percent reserved for contributor who feed E into OD

local function FiftyPercent(allyTeamData,activeTeams,summedOverdrive,activeCount,teamODEnergySum,teamODEnergy)
	local teamPacybackOD = {}
	for i = 1, allyTeamData.teams do 
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			local equalSplit = summedOverdrive / activeCount
			local odShare = 0
			if (teamODEnergySum > 0 and teamODEnergy[teamID]) then --if there's Overdrive and player is one of the contributor then:
				odShare = OD_OWNER_SHARE * summedOverdrive *(teamODEnergy[teamID]/ teamODEnergySum) +  (1-OD_OWNER_SHARE) * equalSplit --OD split exclusive for contributor + OD split for the rest of the alliance
			end
			teamPacybackOD[teamID] = odShare
		end
	end
	return teamPacybackOD
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- METAL DISTRIBUTION all split equally

local function CommunalTrust (allyTeamData,activeTeams,summedOverdrive,activeCount)
	local teamPacybackOD = {}
	for i = 1, allyTeamData.teams do 
		local teamID = allyTeamData.team[i]
		if activeTeams[teamID] then
			teamPacybackOD[teamID] = summedOverdrive / activeCount
		end
	end
	return teamPacybackOD
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
					local stunned_or_inbuld = spGetUnitIsStunned(unitID)
					if stunned_or_inbuld then
						orgMetal = 0
					end
					local mexE = 0
					if (allyMetalSquared > 0) then -- divide energy in ratio given by squared metal from mex
						mexE = allyE*(orgMetal * orgMetal)/ allyMetalSquared 
						energyWasted = energyWasted-mexE
						gridEnergySpent[i] = gridEnergySpent[i] + mexE
						-- if a grid is being too overdriven it has become maxed.
						-- the grid's mexSqauredSum is used for best distribution
						if gridEnergySpent[i] > maxGridCapacity[i] then
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
							for unitID, orgMetal in pairs(allyTeamMexes[i]) do
								local stunned_or_inbuld = spGetUnitIsStunned(unitID)
								if stunned_or_inbuld then
									orgMetal = 0
								end
								local mexE = gridE*(orgMetal * orgMetal)/ gridMetalSquared 
								local metalMult = energyToExtraM(mexE)
								spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5)
								local thisMexM = orgMetal + orgMetal * metalMult
								spCallCOBScript(unitID, "SetSpeed", 0, thisMexM * 500) 
 
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
									else
										if not spammedError then
											Spring.Log(gadget:GetInfo().name, LOG.ERROR, "unitDefID missing for maxxed metal extractor")
											spammedError = true
										end
									end
								end
							end
							break
						end
					end 
					
					local metalMult = energyToExtraM(mexE)
					spSetUnitRulesParam(unitID, "overdrive", 1+mexE/5)
					local thisMexM = orgMetal + orgMetal * metalMult
					spCallCOBScript(unitID, "SetSpeed", 0, thisMexM * 500) 
					
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
						else
							if not spammedError then
								Spring.Log(gadget:GetInfo().name, LOG.ERROR, "unitDefID missing for metal extractor")
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
		privateBaseMetal[teamID] = (privateBaseMetal[teamID] or 0) + value*mexByID[unitID].refundTime*MEX_REFUND_SHARE/MEX_REFUND_TIME
		mexByID[unitID].refundTime = mexByID[unitID].refundTime - 1
		if mexByID[unitID].refundTime <= 0 then
			mexByID[unitID].refundTeamID = nil
			mexByID[unitID].refundTime = nil
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

	if (n%32 == 1) then
		lowPowerUnits.inner = {count = 0, units = {}}
		
		for allyTeamID, allyTeamData in pairs(allyTeamInfo) do 
			
			--// Check if pylons changed their active status (emp, reverse-build, ..)
			for unitID, pylonData in pairs(pylon[allyTeamID]) do
				if spValidUnitID(unitID) then
					local stunned_or_inbuld = spGetUnitIsStunned(unitID)
					local states = spGetUnitStates(unitID)
					local currentlyActive = (not stunned_or_inbuld) and states and states.active
					if (currentlyActive) and (not pylonData.active) then
						ReactivatePylon(unitID)
					elseif (not currentlyActive) and (pylonData.active) then
						DeactivatePylon(unitID)
					end
				end
			end
			
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
						local stunned_or_inbuild = spGetUnitIsStunned(unitID)
						if (not stunned_or_inbuild) then
							local _,_,em,eu = spGetUnitResources(unitID)
							maxGridCapacity[i] = maxGridCapacity[i] + (em or 0) - (eu or 0)
						end
					end
				end
			end
			
			--// check if pylons disable due to low grid power (eg weapons)
			for unitID, pylonData in pairs(pylon[allyTeamID]) do
				if pylonData.neededLink then
					if pylonData.gridID == 0 or pylonData.neededLink > maxGridCapacity[pylonData.gridID] then
						spSetUnitRulesParam(unitID,"lowpower",1, {inlos = true})
						lowPowerUnits.inner.count = lowPowerUnits.inner.count + 1
						lowPowerUnits.inner.units[lowPowerUnits.inner.count] = unitID
					else
						spSetUnitRulesParam(unitID,"lowpower",0, {inlos = true})
					end
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
				local stunned_or_inbuld = spGetUnitIsStunned(unitID)
				if stunned_or_inbuld then
					orgMetal = 0
				end
				summedBaseMetal = summedBaseMetal + orgMetal
                
				spSetUnitRulesParam(unitID, "overdrive", 1)
				spCallCOBScript(unitID, "SetSpeed", 0, orgMetal * 500) 
				
				if mexByID[unitID].refundTeamID then
					local teamID = mexByID[unitID].refundTeamID
					privateBaseMetal[teamID] = (privateBaseMetal[teamID] or 0) + orgMetal*mexByID[unitID].refundTime*MEX_REFUND_SHARE/MEX_REFUND_TIME
					mexByID[unitID].refundTime = mexByID[unitID].refundTime - 1
					if mexByID[unitID].refundTime <= 0 then
						mexByID[unitID].refundTeamID = nil
						mexByID[unitID].refundTime = nil
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
			for unitID, pylonData in pairs(pylon[allyTeamID]) do
				local grid = pylonData.gridID
				local conversion = 0
				if (grid ~= 0 and gridMetalGain[grid]>0) then conversion = gridEnergySpent[grid]/gridMetalGain[grid] end 
				
				pylonData.color = GetGridColor(conversion, false)
				
				if not pylonData.overdrive then
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
				
				local teamPacybackOD = {}
				
				if odSharingModOptions == "investmentreturn" then 
					teamPacybackOD = InvestmentReturn (summedOverdrive,allyTeamData,activeTeams,teamEnergy, allyTeamEnergyIncome, activeCount)
				elseif odSharingModOptions == "deltaoverdrive" then
					teamPacybackOD = DeltaODWithDecayScheme(allyTeamID, allyTeamData, activeTeams, activeCount, teamODEnergy, summedOverdrive, summedBaseMetalAfterPrivate, privateBaseMetal)
				elseif odSharingModOptions == "fiftypercent" then
					teamPacybackOD = FiftyPercent(allyTeamData,activeTeams,summedOverdrive,activeCount,teamODEnergySum,teamODEnergy)
				elseif odSharingModOptions == "communism" then
					teamPacybackOD = CommunalTrust (allyTeamData,activeTeams,summedOverdrive,activeCount)
				end
				
				-- Add resources finally
				for i = 1, allyTeamData.teams do 
					local teamID = allyTeamData.team[i]
					if activeTeams[teamID] then
						local te = teamEnergy[teamID]
						
						local odShare = teamPacybackOD[teamID]
						local baseShare = summedBaseMetalAfterPrivate / activeCount + (privateBaseMetal[teamID] or 0)
						
						sendTeamInformationToAwards(teamID, baseShare, odShare, te.totalChange)
						
						spAddTeamResource(teamID, "m", odShare + baseShare)
						--Spring.Echo(teamID .. " got odShare " .. odShare)
						SendToUnsynced("MexEnergyEvent", teamID, activeCount, energyWasted, ODenergy,summedMetalProduction, summedBaseMetal, summedOverdrive, baseShare, odShare, te.totalChange, allyTeamEnergyIncome, allyTeamID) 
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

local function AddMex(unitID, teamID, metalMake)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if (allyTeamID) then
		mexByID[unitID] = {gridID = 0, allyTeamID = allyTeamID}
		
		if teamID then
			mexByID[unitID].refundTeamID = teamID
			mexByID[unitID].refundTime = MEX_REFUND_TIME
		end
		
		spCallCOBScript(unitID, "SetSpeed", 0, metalMake * 500) 
		local mexGridID = 0
		local mX, _, mZ = spGetUnitPosition(unitID)
		for pid, pylonData in pairs(pylon[allyTeamID]) do
			if unitID == pid then -- self OD mexes
			--if pylonData.overdrive and pylonData.mexes < PYLON_MEX_LIMIT and (pylonData.x-mX)^2 + (pylonData.z-mZ)^2 <= pylonData.mexRange^2  then
				--pylonData.mexes = pylonData.mexes+1
				pylonData.mex[unitID] = true
				mexGridID = pylonData.gridID
				break
			end
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
		
		for pid, pylonData in pairs(pylon[mex.allyTeamID]) do
			if (pylonData.mex[unitID] ~= nil) then
				--pylonData.mexes = pylonData.mexes - 1
				pylonData.mex[unitID] = nil
			end
		end
		mexes[mex.allyTeamID][mex.gridID][unitID] = nil
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
-- ENERGY
--[[
local function AddEnergy(unitID, unitDefID, unitTeam)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	ai.plant[unitID] = 0
	
	-- check for nearby pylons
	local eX,_,eZ = spGetUnitPosition(unitID)
	for pid, pylonData in pairs(pylon[allyTeamID]) do
		if (pylonData.x-eX)^2 + (pylonData.z-eZ)^2 < PYLON_ENERGY_RANGESQ and pylonData.active then
			ai.plant[unitID] = 1
			ai.grid[pylonData.gridID].plant[unitID] = true
			pylon[allyTeamID][pid].nearEnergy[unitID] = true
			break
		end
	end
end

local function RemoveEnergy(unitID, unitDefID, unitTeam)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	ai.plant[unitID] = nil
	
	-- check for nearby pylons
	for pid, pylonData in pairs(pylon[allyTeamID]) do
		if (pylonData.nearEnergy[unitID] ~= nil) then
			pylonData.nearEnergy[unitID] = nil
			ai.grid[pylonData.gridID].plant[unitID] = nil
		end
	end
end
--]]

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
	odSharingModOptions =(Spring.GetModOptions()).overdrivesharingscheme or "fiftypercent" --get game modifier (ModOptions.lua)
	Spring.Echo("Using Overdrive Sharing ModOptions: " .. odSharingModOptions)
	
	_G.pylon = pylon
	_G.lowPowerUnits = lowPowerUnits
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if (mexDefs[unitDefID]) then
			local inc = spGetUnitRulesParam(unitID, "mexIncome")
			if inc then
				AddMex(unitID, false, inc)
			end
		end
		if (pylonDefs[unitDefID]) then
			AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
		end
		--if (energyDefs[unitDefID]) then
		--	AddEnergy(unitID, unitDefID, unitTeam)
		--end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (mexDefs[unitDefID]) then
		local inc = spGetUnitRulesParam(unitID, "mexIncome")
		if inc then
			AddMex(unitID, unitTeam, inc)
		end
	end
	if pylonDefs[unitDefID] then
		notDestroyed[unitID] = true
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if (pylonDefs[unitDefID] and notDestroyed[unitID]) then
		AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
	end
	if paybackDefs[unitDefID] and (odSharingModOptions == "investmentreturn") then
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
		
		if paybackDefs[unitDefID] then
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
	if paybackDefs[unitDefID] then
		RemoveEnergyToPayback(unitID, unitDefID)
	end
	--if (energyDefs[unitDefID]) then
	--	RemoveEnergy(unitID, unitDefID, unitTeam)
	--end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------

local spValidUnitID      = Spring.ValidUnitID
local isUnitInView       = Spring.IsUnitInView
local getUnitTeam        = Spring.GetUnitTeam
local getUnitLosState    = Spring.GetUnitLosState
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spGetUnitPosition  = Spring.GetUnitPosition

--local spGetLocalTeamID   = Spring.GetLocalTeamID
local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
local spGetMyAllyTeamID  = Spring.GetMyAllyTeamID
local spGetTeamList      = Spring.GetTeamList
local spGetTeamUnits     = Spring.GetTeamUnits
local areTeamsAllied     = Spring.AreTeamsAllied
local spGetSpectatingState = Spring.GetSpectatingState
local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState

local glVertex        = gl.Vertex
local glPolygonOffset = gl.PolygonOffset
local glDepthTest     = gl.DepthTest
local glCallList      = gl.CallList
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glCreateList    = gl.CreateList
local glPushMatrix    = gl.PushMatrix
local glPopMatrix     = gl.PopMatrix
local glTranslate     = gl.Translate
local glScale         = gl.Scale

local GL_QUADS        = GL.QUADS
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN

local Util_DrawGroundCircle = gl.Utilities.DrawGroundCircle

local floor = math.floor

local circlePolys = 0 -- list for circles

function WrapToLuaUI(_,teamID, allies, energyWasted, energyForOverdrive, totalIncome, baseMetal, overdriveMetal, myBase, myOD, EnergyChange, allyTeamEnergyIncome, allyTeamID)
  if (allyTeamID ~= spGetLocalAllyTeamID()) then return end
  if (Script.LuaUI('MexEnergyEvent')) then
    Script.LuaUI.MexEnergyEvent(teamID, allies, energyWasted, energyForOverdrive, totalIncome, baseMetal, overdriveMetal, myBase, myOD, EnergyChange, allyTeamEnergyIncome, allyTeamID)
  end
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction('MexEnergyEvent',WrapToLuaUI)
	
	local circleDivs = 32

	circlePolys = glCreateList(function()
		glBeginEnd(GL_TRIANGLE_FAN, function()
		local radstep = (2.0 * math.pi) / circleDivs
			for i = 1, circleDivs do
				local a = (i * radstep)
				glVertex(math.sin(a), 0, math.cos(a))
			end
		end)
	end)

end


local function DrawArray(ar, unitID)  -- renders lines from unitID to array memebers
	if (not ar) then return end
	if (not spValidUnitID(unitID)) then return end 
	
	--local uvisible = isUnitInView(unitID)
	local ux,uy,uz = spGetUnitPosition(unitID)
	
	for id,_ in spairs(ar) do		
		if (spValidUnitID(id)) then 
			glVertex(ux,uy,uz)
			--if (uvisible or isUnitInView(id)) then
				glVertex(spGetUnitPosition(id))
			--end 
		end 
	end
end 

--[[
local powerTexture = 'Luaui/Images/visible_energy.png'

local function DrawPylonEnergyLines()
	myAllyID = spGetMyAllyTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview

  	local pylon = SYNCED.pylon

	
	if (spec) then 
		for _,pylonGroup in spairs(pylon) do 
			for unitID, pylonData in spairs(pylonGroup) do 
				DrawArray(pylonData.nearEnergy, unitID)
			end
		end 
	else 
		for unitID, pylonData in spairs(pylon[myAllyID]) do 
			DrawArray(pylonData.nearEnergy, unitID)
		end
	end 
end 
--]]
local function DrawPylonMexLines()
	myAllyID = spGetMyAllyTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview

  	local pylon = SYNCED.pylon

	if (spec) then 
		for _,pylonGroup in spairs(pylon) do 
			for unitID, pylonData in spairs(pylonGroup) do 
				DrawArray(pylonData.mex, unitID)
			end
		end 
	else 
		for unitID, pylonData in spairs(pylon[myAllyID]) do 
			DrawArray(pylonData.mex, unitID)
		end
	end
end 

local function DrawPylonLinkLines()
	myAllyID = spGetMyAllyTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview

  	local pylon = SYNCED.pylon

	if (spec) then 
		for _,pylonGroup in spairs(pylon) do 
			for unitID, pylonData in spairs(pylonGroup) do 
				DrawArray(pylonData.nearPylon, unitID)
			end
		end 
	else 
		for unitID, pylonData in spairs(pylon[myAllyID]) do 
			DrawArray(pylonData.nearPylon, unitID)
		end
	end
end 

local disabledColor = { 0.6,0.7,0.5,0.2}

local colors = {
	{0.9,0.9,0.2,0.2},
	{0.9,0.2,0.2,0.2},
	{0.2,0.9,0.2,0.2},
	{0.2,0.2,0.9,0.2},
	{0.2,0.9,0.9,0.2},
	{0.9,0.2,0.9,0.2},
}

local function HighlightPylons(selectedUnitDefID)
	local myAlly = spGetMyAllyTeamID()
	local pylon = SYNCED.pylon

	--gl.PushAttrib(GL.COLOR_BUFFER_BIT)
	--gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.ZERO)
	for id, data in spairs(pylon[myAlly]) do 
		local radius = pylonDefs[spGetUnitDefID(id)].range
		if (radius) then 
			local color
			if (not data.gridID) or data.gridID == 0 or data.color == nil then
				color = disabledColor
			else 
				color = data.color
			end 
			glColor(color[1],color[2], color[3], color[4])

			local x,y,z = spGetUnitBasePosition(id)
			Util_DrawGroundCircle(x,z, radius)
		end 
	end 
	
	
	if selectedUnitDefID then 
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if coords then 
			local radius = pylonDefs[selectedUnitDefID].range
			if (radius == 0) then
			else
				local x = floor((coords[1])/16)*16 +8
				local z = floor((coords[3])/16)*16 +8
				glColor(disabledColor)
--				coords[1] = floor((coords[1]+8)/16)*16
				--coords[3] = floor((coords[3]+8)/16)*16
				Util_DrawGroundCircle(x,z, radius)

				--[[glPushMatrix()
				glTranslate(unpack(coords))
				glScale(radius,1,radius)
				glCallList(circlePolys)
				glPopMatrix()]]--
			end
		end 
	end 
	
	--glPolygonOffset(false)

	--glDepthTest(true)
--[[
	if SYNCED.pylon and snext(SYNCED.pylon) then
		gl.PushAttrib(GL.LINE_BITS)
		
		glDepthTest(true)
		glColor(0.8,0.8,0.2,math.random()*0.1+0.3)
		gl.LineWidth(1)
		glBeginEnd(GL.LINES, DrawPylonEnergyLines)
		
		gl.PopAttrib() 
	end
--]]
	--gl.PopAttrib()
end 


function gadget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end
	--[[if SYNCED.pylon and snext(SYNCED.pylon) then
		gl.PushAttrib(GL.LINE_BITS)
		
		glColor(0.5,0.4,1,math.random()*0.1+0.5)
		gl.LineWidth(3)
		glBeginEnd(GL.LINES, DrawPylonMexLines)
		
		glColor(0.9,0.8,0.2,math.random()*0.1+0.5)
		gl.LineWidth(3)
		glBeginEnd(GL.LINES, DrawPylonLinkLines)
			
		glDepthTest(false)
		glColor(1,1,1,1)
			
		gl.PopAttrib() 
	end]]--

	local _, cmd_id = spGetActiveCommand()  -- show pylons if pylon is about to be placed
	if (cmd_id) then 
		if pylonDefs[-cmd_id] then 
			HighlightPylons(-cmd_id)
			return
		--elseif energyDefs[-cmd_id] or mexDefs[-cmd_id] then
		--	HighlightPylons(nil)
		--	return
		end 
	return end
	
	
	local selUnits = spGetSelectedUnits()  -- or show it if its selected 
	if not selUnits then return end 
  
	for i=1,#selUnits do 
		local ud = spGetUnitDefID(selUnits[i])
		if (pylonDefs[ud]) then 
			HighlightPylons(nil)
		return 
		end 
	end 
end

--[[ moved to widget
local function DrawUnitFunc(yshift)
	glTranslate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local lowPowerUnits = SYNCED.lowPowerUnits.inner
	
	if lowPowerUnits.count > 0 then
		local spec, fullview = spGetSpectatingState()
		local myAllyID = spGetMyAllyTeamID()

		spec = spec or fullview
		glColor(1,1,1,1)
		gl.Texture(powerTexture )
		for i = 1, lowPowerUnits.count do
			local los = Spring.GetUnitLosState(lowPowerUnits.units[i], myAllyID, false)
			if spValidUnitID(lowPowerUnits.units[i]) and spGetUnitDefID(lowPowerUnits.units[i]) and ((los and los.los) or spec) then
				gl.DrawFuncAtUnit(lowPowerUnits.units[i], false, DrawUnitFunc,  UnitDefs[spGetUnitDefID(lowPowerUnits.units[i])].height+30)
			end
		end
		gl.Texture("")
	end
	
end
--]]


-------------------------------------------------------------------------------------

end