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
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mexDefs = {}
--local energyDefs = {}
local pylonDefs = {}
local linkdefs = {}

local DEFAULT_PYLON_RANGE = 200 -- mex range, link = range*2
local MEX_OWNER_SHARE = 0.05 -- 5% to owner

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (udef.extractsMetal > 0) then
		mexDefs[i] = true
	end
	if (tonumber(udef.customParams.pylonrange) or 0 > 0) then
		pylonDefs[i] = {
			range = tonumber(udef.customParams.pylonrange) or DEFAULT_PYLON_RANGE,
			extractor = (udef.extractsMetal > 0),
			neededLink = tonumber(udef.customParams.neededlink) or false,
			keeptooltip = udef.customParams.keeptooltip or false,
		}
	end
		
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

Spring.SetGameRulesParam("lowpower",1)

local HIDDEN_STORAGE = 10000 -- hidden storage: it will spend all energy above (storage - hidden_storage)

local MEX_DIAMETER = Game.extractorRadius*2

--local PYLON_ENERGY_RANGESQ = 160000
--local PYLON_LINK_RANGESQ = 40000
--local PYLON_MEX_RANGESQ = 10000
--local PYLON_MEX_LIMIT = 100

--local CMD_MEXE = 30666

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local GetUnitIsActive = Spring.GetUnitIsActive
local spValidUnitID = Spring.ValidUnitID

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local takenMexId = {} -- mex ids that are taken by disabled pylons

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
-- local functions

local function energyToExtraM(energy)  
	return -1+math.sqrt(1+(energy*0.25))
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
                        nRemain = math.min(n-good, z)
                        
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local pX,_,pZ = Spring.GetUnitPosition(unitID)
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local pX,_,pZ = Spring.GetUnitPosition(unitID)
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
			local mX,_,mZ = Spring.GetUnitPosition(mid)
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
			local eX,_,eZ = Spring.GetUnitPosition(eid)
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	
	local pX,_,pZ = Spring.GetUnitPosition(unitID)
	
	pylon[allyTeamID][unitID].active = true

	-- check for energy
	--[[
	for eid, state in pairs(ai.plant) do
		if state == 0 then
			local eX,_,eZ = Spring.GetUnitPosition(eid)
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
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
		local eX,_,eZ = Spring.GetUnitPosition(eid)
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)

	if not pylon[allyTeamID][unitID] then
		return
	end
	
	local pX,_,pZ = Spring.GetUnitPosition(unitID)
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
			local eX,_,eZ = Spring.GetUnitPosition(eid)
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
		
		local mX, _, mZ = Spring.GetUnitPosition(mid)
						
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

local function AddNewMexes(n)
	if (n%32 ~= 2) then -- in sync 1 frame after slow update
		return
	end
	for unitID,_ in pairs(mexesToAdd) do -- check units to add 
		local stunned_or_inbuld = Spring.GetUnitIsStunned(unitID)
		local currentlyActive = not stunned_or_inbuld
		if currentlyActive then
			mexesToAdd[unitID] = mexesToAdd[unitID] - 1
			if mexesToAdd[unitID] <= 0 then --unit should be operating to max we can determine metal and add 
				mexesToAdd[unitID] = nil
				local allyTeamID = Spring.GetUnitAllyTeam(unitID)
				if (allyTeamID) then
					local mm, mu = Spring.GetUnitResources(unitID)
					local metalMake = (mm or 0) - (mu or 0)
					metalMake = metalMake / MEX_OWNER_SHARE
					mexByID[unitID] = {gridID = 0, allyTeamID = allyTeamID}
					
					Spring.CallCOBScript(unitID, "SetSpeed", 0, metalMake * 500) 
					local mexGridID = 0
					local mX, _, mZ = Spring.GetUnitPosition(unitID)
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
		end
	end
end

local function OptimizeOverDrive(allyTeamID,allyTeamData,allyE,maxGridCapacity)
	local summedMetalProduction = 0
	local maxedMetalProduction = 0
		
	local summedBaseMetal = 0
	local maxedBaseMetal = 0
    
    local summedOverdrive = 0
	local maxedOverdrive = 0
    
	local allyMetal = allyTeamData.mexMetal
	local allyMetalSquared = allyTeamData.mexSquaredSum
	
	local energyWasted = allyE
	
	local gridEnergySpent = {}
	local gridMetalGain = {}

	local reCalc = true
	local maxedGrid = {}
	while reCalc do	-- calculate overdrive for as long as a new grid is not maxed
		reCalc = false
		for i = 1, allyTeamData.grids do -- loop through grids
			if not (maxedGrid[i] or allyTeamData.nilGrid[i]) then -- do not check maxed grids
				gridEnergySpent[i] = 0
				gridMetalGain[i] = 0
				for unitID, orgMetal in pairs(mexes[allyTeamID][i]) do -- loop mexes
					local stunned_or_inbuld = Spring.GetUnitIsStunned(unitID)
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
							summedOverdriveMetal = 0
                            
							maxedGrid[i] = true
							reCalc = true
							allyE = allyE - gridE
							energyWasted = allyE
							for unitID, orgMetal in pairs(mexes[allyTeamID][i]) do
								local stunned_or_inbuld = Spring.GetUnitIsStunned(unitID)
								if stunned_or_inbuld then
									orgMetal = 0
								end
								local mexE = gridE*(orgMetal * orgMetal)/ gridMetalSquared 
								local metalMult = energyToExtraM(mexE)
								Spring.SetUnitRulesParam(unitID, "overdrive", 1+mexE/5)
								local thisMexM = orgMetal * (1-MEX_OWNER_SHARE) + orgMetal * metalMult
								Spring.CallCOBScript(unitID, "SetSpeed", 0, thisMexM * 500) 
                                
								maxedMetalProduction = maxedMetalProduction + thisMexM
								maxedBaseMetal = maxedBaseMetal + orgMetal
                                maxedOverdrive = summedOverdrive + orgMetal * metalMult
                                
								allyMetalSquared = allyMetalSquared - orgMetal * orgMetal
								gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
								
								local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
								if not pylonDefs[Spring.GetUnitDefID(unitID)].keeptooltip then
									if unitDef then
										Spring.SetUnitTooltip(unitID,"Makes: " .. math.round(orgMetal,2) .. " + Overdrive: +" .. math.round(metalMult*100,0) .. "%  \nEnergy: -" .. math.round(mexE,2))
									else
										Spring.Echo("unitDefID missing for maxxed metal extractor")
									end
								end
							end
							break
						end
					end 
					
					local metalMult = energyToExtraM(mexE)
					Spring.SetUnitRulesParam(unitID, "overdrive", 1+mexE/5)
					local thisMexM = orgMetal * (1-MEX_OWNER_SHARE) + orgMetal * metalMult
					Spring.CallCOBScript(unitID, "SetSpeed", 0, thisMexM * 500) 
                    
					summedMetalProduction = summedMetalProduction + thisMexM
					summedBaseMetal = summedBaseMetal + orgMetal
                    summedOverdrive = summedOverdrive + orgMetal * metalMult
                    
					gridMetalGain[i] = gridMetalGain[i] + orgMetal * metalMult
					local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
					if not pylonDefs[Spring.GetUnitDefID(unitID)].keeptooltip then
						if unitDef then
							if (metalMult < 1.5) then
								Spring.SetUnitTooltip(unitID,"Makes: " .. math.round(orgMetal,2) .. " + Overdrive: +" .. math.round(metalMult*100,0) .. "%  Energy: -" .. math.round(mexE,2))
							else
								Spring.SetUnitTooltip(unitID,"Makes: " .. math.round(orgMetal,2) .. " + Overdrive: +" .. math.round(metalMult*100,0) .. "%  Energy: -" .. math.round(mexE,2) .. " \nConnect more energy sources to produce additional metal")
							end
						else
							Spring.Echo("unitDefID missing for metal extractor")
						end
					end
				end
				
				if reCalc then
					break
				end		
			end
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
		gridMetalGain;
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
	AddNewMexes(n)

	if (n%32 == 1) then
	
		lowPowerUnits.inner = {count = 0, units = {}}
		
		for allyTeamID, allyTeamData in pairs(allyTeamInfo) do 
			
			--// check if pylons changed their active status (emp, reverse-build, ..)
			for unitID, pylonData in pairs(pylon[allyTeamID]) do
				if spValidUnitID(unitID) then
					local stunned_or_inbuld = Spring.GetUnitIsStunned(unitID)
					local states = Spring.GetUnitStates(unitID)
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
			local teamIncome = 0

			-- calcullate total income - tax 95% of energy income 
			local sumInc = 0
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
				teamEnergy[teamID] = {totalChange = 0, num = teamID}
				local te = teamEnergy[teamID]
				te.eCur, te.eMax, te.ePull, te.eInc, te.eExp, _, te.eSent, te.eRec = Spring.GetTeamResources(teamID, "energy")
				local incTakeNE = (lastTeamNe[teamID] and lastTeamNe[teamID] > 0 and te.eInc -lastTeamNe[teamID]) or te.eInc
                teamIncome = teamIncome + incTakeNE
				if (te.eCur ~= nil) then 
					te.eTax = incTakeNE * math.max(0, math.min(1, (te.eCur - te.eInc) / (te.eMax - HIDDEN_STORAGE))) -- don't take more than you make!
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
			-- distribute taxes evenly - apply "change" on individual teams 
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
			
			-- calculate overdrive energy excess 
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
						local fillRatio = math.max(0, (te.eCur - te.eInc) / (te.eMax - HIDDEN_STORAGE))
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
						local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID)
						if (not stunned_or_inbuild) then
							local _,_,em,eu = Spring.GetUnitResources(unitID)
							maxGridCapacity[i] = maxGridCapacity[i] + (em or 0) - (eu or 0)
						end
					end
				end
			end
			
			--// check if pylons disable due to low grid power (eg weapons)
			for unitID, pylonData in pairs(pylon[allyTeamID]) do
				if pylonData.neededLink then
					if pylonData.gridID == 0 or pylonData.neededLink > maxGridCapacity[pylonData.gridID] then
						Spring.SetUnitRulesParam(unitID,"lowpower",1, {inlos = true})
						lowPowerUnits.inner.count = lowPowerUnits.inner.count + 1
						lowPowerUnits.inner.units[lowPowerUnits.inner.count] = unitID
					else
						Spring.SetUnitRulesParam(unitID,"lowpower",0, {inlos = true})
					end
				end
			end

			--// Use the free Grid-Energy for Overdrive
			local energyWasted, summedMetalProduction, summedBaseMetal, summedOverdrive, gridEnergySpent, gridMetalGain = OptimizeOverDrive(allyTeamID,allyTeamData,allyE,maxGridCapacity)
			
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
					--Spring.AddTeamResource(teamID, "e", energyWasted*( eMax - HIDDEN_STORAGE - eCur)/totalFreeStorage)
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
					--Spring.AddTeamResource(teamID, "e", ( eMax - HIDDEN_STORAGE - eCur))
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
					Spring.AddTeamResource(teamID, "e", te.totalChange)
				elseif te.totalChange < 0 then
					Spring.UseTeamResource(teamID, "e", -te.totalChange)
				end
			end 
			
			--// Income For non-Gridded mexes
			for unitID, orgMetal in pairs(mexes[allyTeamID][0]) do
				local stunned_or_inbuld = Spring.GetUnitIsStunned(unitID)
				if stunned_or_inbuld then
					orgMetal = 0
				end
				summedBaseMetal =summedBaseMetal + orgMetal
                
				Spring.SetUnitRulesParam(unitID, "overdrive", 1)
				Spring.CallCOBScript(unitID, "SetSpeed", 0, orgMetal * 500) 

				local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
				summedMetalProduction = summedMetalProduction + orgMetal
				local pylonDef = pylonDefs[Spring.GetUnitDefID(unitID)]
				if pylonDef and not pylonDef.keeptooltip then
					if unitDef then
						Spring.SetUnitTooltip(unitID,"Metal Extractor - Makes: " .. math.round(orgMetal,2) .. " Not connected to Grid")
					else
						Spring.Echo("unitDefID missing for ungridded mex")
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
					local unitDefID = Spring.GetUnitDefID(unitID)
					local unitDef = unitDefID and UnitDefs[unitDefID]
					if not unitDef then
						Spring.Echo("unitDefID missing for pylon")
					else
						if not pylonDefs[unitDefID].keeptooltip then
							if grid ~= 0 then
								Spring.SetUnitTooltip(unitID,"GRID: "  .. math.round(gridEnergySpent[grid],2) .. "/" .. math.round(maxGridCapacity[grid],2) .. "E => " .. math.round(gridMetalGain[grid],2).."M")
							else
								Spring.SetUnitTooltip(unitID,unitDef.humanName .. " - Currently Disabled")
							end
						end
					end
				end
			end
			--// Share Overdrive Metal
			for i = 1, allyTeamData.teams do 
				local teamID = allyTeamData.team[i]
                local te = teamEnergy[teamID]
				Spring.AddTeamResource(teamID, "m", summedMetalProduction / allyTeamData.teams)
				SendToUnsynced("MexEnergyEvent", teamID, allyTeamData.teams, energyWasted, ODenergy,summedMetalProduction, summedBaseMetal, summedOverdrive, te.totalChange, teamIncome) 
			end 
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- MEXES

local function SetupMex(unitID, unitDefID, unitTeam)
	Spring.SetUnitResourcing(unitID, 'cmm', 0)
	Spring.SetUnitResourcing(unitID, 'cue', 0)
	mexesToAdd[unitID] = 3 -- 3 seconds left for the income to stabilize
end

local function RemoveMex(unitID)
	Spring.SetUnitResourcing(unitID, 'cmm', 0)
	Spring.SetUnitResourcing(unitID, 'cue', 0)
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
		local x,_,z = Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,0,z,"inconsistent mex entry 124125_1")
	end
	
	for allyTeam, _ in pairs(mexes) do
		for i = 0, allyTeamInfo[allyTeam].grids do
			if (mexes[allyTeam][i][unitID] ~= nil) then
				local x,_,z = Spring.GetUnitPosition(unitID)
				Spring.MarkerAddPoint(x,0,z,"inconsistent mex entry 124125_0")
			end
		end
	end

end

local function RemoveMexesAroundUnit(unitID)
	local x,_,z = Spring.GetUnitPosition(unitID)
	local units = Spring.GetUnitsInCylinder(x,z,MEX_DIAMETER)
	
	for i = 1, #units do
		if mexByID[units[i]] and units[i] ~= unitID then
			RemoveMex(units[i])
			mexesToAdd[units[i]] = 3
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- ENERGY
--[[
local function AddEnergy(unitID, unitDefID, unitTeam)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local ai = allyTeamInfo[allyTeamID]
	ai.plant[unitID] = 0
	
	-- check for nearby pylons
	local eX,_,eZ = Spring.GetUnitPosition(unitID)
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
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
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
	
	_G.pylon = pylon
	_G.lowPowerUnits = lowPowerUnits
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if (mexDefs[unitDefID]) then
			SetupMex(unitID,unitDefID, Spring.GetUnitTeam(unitID))
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
		SetupMex(unitID, unitDefID, teamID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if (pylonDefs[unitDefID]) then
		AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
	end
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID)
	local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (mexDefs[unitDefID]) then 
			SetupMex(unitID, unitDefID, teamID)
		end
		
		if (pylonDefs[unitDefID]) then
			local _,_,_,_,build  = Spring.GetUnitHealth(unitID)
			if (build == 1) then
				AddPylon(unitID, unitDefID, pylonDefs[unitDefID].extractor, pylonDefs[unitDefID].range)
				--Spring.Echo(Spring.GetUnitAllyTeam(unitID) .. "  " .. newAllyTeam)
			end
		end
		--if (energyDefs[unitDefID]) then
		--	AddEnergy(unitID, unitDefID, unitTeam)
		--	RemoveEnergy(unitID, unitDefID, unitTeam)
		--end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID)
	local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (mexDefs[unitDefID] and mexByID[unitID]) then 
			RemoveMex(unitID)
		end
		
		if (pylonDefs[unitDefID]) then
			RemovePylon(unitID)
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
		RemoveMexesAroundUnit(unitID)
	end
	if (pylonDefs[unitDefID]) then
		RemovePylon(unitID)
	end
	--if (energyDefs[unitDefID]) then
	--	RemoveEnergy(unitID, unitDefID, unitTeam)
	--end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------

local glVertex = gl.Vertex
local isUnitInView = Spring.IsUnitInView
local areTeamsAllied = Spring.AreTeamsAllied
local getUnitTeam = Spring.GetUnitTeam
local getUnitLosState = Spring.GetUnitLosState
local spValidUnitID = Spring.ValidUnitID

local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetUnitBasePosition = Spring.GetUnitBasePosition
local glPolygonOffset = gl.PolygonOffset
local glDepthTest     = gl.DepthTest
local glCallList = gl.CallList
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glCreateList      = gl.CreateList
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local spGetActiveCommand = Spring.GetActiveCommand
local glScale = gl.Scale
local spTraceScreenRay = Spring.TraceScreenRay
local spGetMouseState = Spring.GetMouseState
local GL_QUADS = GL.QUADS
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetTeamList = Spring.GetTeamList
local spGetTeamUnits = Spring.GetTeamUnits

local powerTexture = 'Luaui/Images/energy.png'

local floor = math.floor

local circlePolys = 0 -- list for circles

function WrapToLuaUI(_,teamID, allies, energyWasted, energyForOverdrive, totalIncome, baseMetal, overdriveMetal, EnergyChange, teamIncome)
  if (teamID ~= Spring.GetLocalTeamID()) then return end
  if (Script.LuaUI('MexEnergyEvent')) then
    Script.LuaUI.MexEnergyEvent(teamID, allies, energyWasted, energyForOverdrive, totalIncome, baseMetal, overdriveMetal, EnergyChange, teamIncome)
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
	local ux,uy,uz = Spring.GetUnitPosition(unitID)
	
	for id,_ in spairs(ar) do		
		if (spValidUnitID(id)) then 
			glVertex(ux,uy,uz)
			--if (uvisible or isUnitInView(id)) then
				glVertex(Spring.GetUnitPosition(id))
			--end 
		end 
	end
end 

--[[
local function DrawPylonEnergyLines()
	myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
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
	myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
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
	myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
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
			gl.Utilities.DrawGroundCircle(x,z, radius)
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
				gl.Utilities.DrawGroundCircle(x,z, radius)

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
		
		gl.DepthTest(true)
		gl.Color(0.8,0.8,0.2,math.random()*0.1+0.3)
		gl.LineWidth(1)
		gl.BeginEnd(GL.LINES, DrawPylonEnergyLines)
		
		gl.PopAttrib() 
	end
--]]
	--gl.PopAttrib()
end 


function gadget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end
	--[[if SYNCED.pylon and snext(SYNCED.pylon) then
		gl.PushAttrib(GL.LINE_BITS)
		
		gl.Color(0.5,0.4,1,math.random()*0.1+0.5)
		gl.LineWidth(3)
		gl.BeginEnd(GL.LINES, DrawPylonMexLines)
		
		gl.Color(0.9,0.8,0.2,math.random()*0.1+0.5)
		gl.LineWidth(3)
		gl.BeginEnd(GL.LINES, DrawPylonLinkLines)
			
		gl.DepthTest(false)
		gl.Color(1,1,1,1)
			
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

local function DrawUnitFunc(yshift)
	gl.Translate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local lowPowerUnits = SYNCED.lowPowerUnits.inner
	
	if lowPowerUnits.count > 0 then
		local spec, fullview = Spring.GetSpectatingState()
		local myAllyID = Spring.GetMyAllyTeamID()

		spec = spec or fullview
		gl.Color(1,1,1,1)
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

-------------------------------------------------------------------------------------

end
