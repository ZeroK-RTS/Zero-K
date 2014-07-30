function gadget:GetInfo()
	return {
		name 	= "Shield Link",
		desc	= "Nearby shields on the same ally team share charge to and from each other. Working Version",
		author	= "lurker",
		date	= "2009",
		license	= "Public domain",
		layer	= 0,
		enabled	= true	--	loaded by default?
	}
end
local version = 1.232

-- CHANGELOG
--	2009-5-24: CarRepairer: Added graphic lines to show links of shields (also shows links of enemies' visible shields, can remove if desired).
--	2009-5-30: CarRepairer: Lups graphic lines, fix for 0.79.1 compatibility.
--	2009-9-15: Licho: added simple fast graph lines

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


if gadgetHandler:IsSyncedCode() then

local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitIsStunned	= Spring.GetUnitIsStunned
local spGetUnitIsActive		= Spring.GetUnitIsActive
local spGetUnitShieldState	= Spring.GetUnitShieldState
local spSetUnitShieldState	= Spring.SetUnitShieldState
local spSetUnitRulesParam  = Spring.SetUnitRulesParam

------------
local shieldTeams = {}

local unitRulesParamsSetting = {inlos = true} -- Let enemies see links. It is information availible to them anyway

local updateLink = {}
local updateAllyTeamLinks = {}

-- Double table is required to choose a random element from the list
local function AddThingToIterable(id, things, thingByID)
	thingByID.count = thingByID.count + 1
	thingByID.data[thingByID.count] = id
	things[id] = thingByID.count
end

local function RemoveThingFromIterable(id, things, thingByID)
	if things[id] then
		things[thingByID.data[thingByID.count]] = things[id]
		thingByID.data[things[id]] = thingByID.data[thingByID.count]
		thingByID.data[thingByID.count] = nil
		things[id] = nil
		thingByID.count = thingByID.count - 1
		return true
	end
	return false
end

function gadget:Initialize()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID)

	-- only count finished buildings
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild ~= nil and inbuild then
		return
	end

	local ud = UnitDefs[unitDefID]
	if ud.shieldWeaponDef then
		local shieldWep = WeaponDefs[ud.shieldWeaponDef]
		--local x,y,z = spGetUnitPosition(unitID)
		local allyTeamID = spGetUnitAllyTeam(unitID)
		if not (shieldTeams[allyTeamID] and shieldTeams[allyTeamID][unitID]) then -- not need to redo table if already have table (UnitFinished() will call this function 2nd time)
			shieldTeams[allyTeamID] = shieldTeams[allyTeamID] or {}
			local shieldUnit = {
				shieldMaxCharge  = shieldWep.shieldPower,
				shieldRadius = shieldWep.shieldRadius,
				shieldRegen  = shieldWep.shieldPowerRegen,
				unitDefID    = unitDefID,
				neighbors    = {},
				neighborList = {data = {}, count = 0},
				allyTeamID   = allyTeamID,
				enabled      = false,
				oldEnabled   = false,
				oldFastEnabled = false,
			}
			shieldTeams[allyTeamID][unitID] = shieldUnit
		end
		QueueLinkUpdate(allyTeamID,unitID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if ud.shieldWeaponDef and shieldTeams[allyTeamID] then
		local unitData = shieldTeams[allyTeamID][unitID]
		if unitData then
			RemoveUnitFromNeighbors(allyTeamID, unitID, unitData.neighborList)
		end
		shieldTeams[allyTeamID][unitID] = nil
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	local ud = UnitDefs[unitDefID]
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam)
	if ud.shieldWeaponDef then
		local unitData
		local allyTeamID = spGetUnitAllyTeam(unitID)
		if shieldTeams[oldAllyTeam] and shieldTeams[oldAllyTeam][unitID] then
			unitData = shieldTeams[oldAllyTeam][unitID]
			shieldTeams[oldAllyTeam][unitID] = nil
			RemoveUnitFromNeighbors(oldAllyTeam, unitID, unitData.neighborList)
			QueueLinkUpdate(allyTeamID,unitID)
			unitData.neighbors = {}
			unitData.neighborList = {data = {}, count = 0}
		end
			
		shieldTeams[allyTeamID] = shieldTeams[allyTeamID] or {}
		shieldTeams[allyTeamID][unitID] = unitData --Note: wont be problem when NIL when nanoframe is captured because is always filled with new value when unit finish 
	end
end

function RemoveUnitFromNeighbors(allyTeamID, unitID, neighborList)
	local otherID
	local thisShieldTeam = shieldTeams[allyTeamID]
	for i = 1, neighborList.count do
		otherID = neighborList.data[i]
		if thisShieldTeam[otherID] then
			RemoveThingFromIterable(unitID, thisShieldTeam[otherID].neighbors, thisShieldTeam[otherID].neighborList)
		end
	end
end

function QueueLinkUpdate(allyTeamID,unitID)
	updateLink[allyTeamID] = updateLink[allyTeamID] or {}
	updateLink[allyTeamID][unitID] = true
end

-- check if working unit so it can be used for shield link
local function IsEnabled(unitID)
	local stunned_or_inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) then
		return false
	end
	local active = spGetUnitIsActive(unitID)
	if active ~= nil then
		return active
	else
		return true
	end
end

local function ShieldsAreTouching(shield1, shield2)
	local xDiff = shield1.x - shield2.x
	local zDiff = shield1.z - shield2.z
	local yDiff = shield1.y - shield2.y
	local sumRadius = shield1.shieldRadius + shield2.shieldRadius
	return xDiff <= sumRadius and zDiff <= sumRadius and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < sumRadius*sumRadius 
end

local function AdjustLinks(allyTeamID, shieldList, unitUpdateList)
	local unitData
	for unitID,_ in pairs(unitUpdateList) do
		unitData = shieldList[unitID]
		if unitData.enabled then
			for otherID, otherData in pairs(shieldList) do --iterate over all shield unit, find anyone that's in range.
				if not (otherData.neighbors[unitID] or unitData.neighbors[otherID]) and 
							otherData.enabled and ShieldsAreTouching(unitData, otherData) then
					AddThingToIterable(otherID, unitData.neighbors, unitData.neighborList)
					AddThingToIterable(unitID, otherData.neighbors, otherData.neighborList)
				end
			end -- for otherID
		end
	end	-- for unitID
end

local function UpdateAllLinks(allyTeamID, shieldList, unitUpdateList)
	local unitData
	for unitID,_ in pairs(unitUpdateList) do
		unitData = shieldTeams[allyTeamID][unitID]
		if unitData then
			local x,y,z = spGetUnitPosition(unitID)
			local valid = x and y and z
			unitData.enabled = valid and IsEnabled(unitID)
			
			if (unitData.enabled) then
				unitData.x = x
				unitData.y = y
				unitData.z = z
				
				--local otherID, otherData
				--local i = 1
				--while i <= unitData.neighborList.count do
				--	otherID = unitData.neighborList.data[i]
				--	if shieldTeams[allyTeamID][otherID] then
				--		otherData = shieldTeams[allyTeamID][otherID]
				--		if not (otherData.enabled and ShieldsAreTouching(unitData, otherData)) then
				--			RemoveThingFromIterable(unitID, otherData.neighbors, otherData.neighborList)
				--			if RemoveThingFromIterable(otherID, unitData.neighbors, unitData.neighborList) then
				--				i = i - 1
				--			end
				--		end
				--	end
				--	i = i + 1
				--end
			else
				--RemoveUnitFromNeighbors(allyTeamID, unitID, unitData.neighborList)
				--unitData.neighbors = {}
				--unitData.neighborList = {data = {}, count = 0}
			end
		end
	end
	
	AdjustLinks(allyTeamID, shieldList,unitUpdateList)
end

local function UpdateEnabledState()
	for allyTeamID,unitList in pairs(shieldTeams) do
		for unitID,shieldUnit in pairs(unitList) do
			shieldUnit.enabled = IsEnabled(unitID)
			if shieldUnit.enabled ~= shieldUnit.oldFastEnabled then
				if shieldUnit.oldFastEnabled then
					spSetUnitRulesParam(unitID,"shield_link",-1,unitRulesParamsSetting)
				end
				shieldUnit.oldFastEnabled = shieldUnit.enabled
			end
		end
	end
end

local RECHARGE_KOEF = 0.01
local function DoChargeTransfer(lowID, lowData, lowCharge, highID, highData, highCharge)
	--charge flow is: based on the absolute difference in charge content,
	--charge flow must:
	--1)not be more than receiver's capacity, 
	--2)not be more than donator's available charge,
	--3)leave spaces for receiver to regen,
	--charge flow is capable: to reverse flow (IS DISABLED!) when receiver have regen and is full,
	local chargeFlow = math.min(RECHARGE_KOEF*(highCharge - lowCharge),highCharge, lowData.shieldMaxCharge - lowData.shieldRegen - lowCharge) --minimize positive flow
	if chargeFlow > 0 then -- Disallow negative flow
		spSetUnitShieldState(highID, -1, highCharge - chargeFlow)
		spSetUnitShieldState(lowID, -1, lowCharge + chargeFlow)
		return true
	end
	return false
end


local shieldUnitList = {}
local listCount = 0
function gadget:GameFrame(n)
	if n%30 == 18 then  --update every 30 frames at the 18th frame
		--note: only update link when unit moves reduce total consumption by 53% when unit idle.
		for allyTeamID,unitList in pairs(shieldTeams) do
			for unitID, unitData in pairs(unitList) do
				if unitData.enabled ~= unitData.oldEnabled then --if unit was linked/unlinked but now stunned/unstunned (state changes)
					if unitData.oldEnabled then
						--RemoveUnitFromNeighbors(allyTeamID, unitID, unitData.neighborList)
					else
						QueueLinkUpdate(allyTeamID,unitID)
					end
					unitData.oldEnabled = unitData.enabled
				elseif unitData.enabled then
					local x,y,z = unitData.x, unitData.y, unitData.z
					if x and y and z then
						local ux,uy,uz = Spring.GetUnitPosition(unitID)
						if ux-x > 10 or x-ux > 10 or uy-y > 10 or y-uy > 10 or  uz-z > 10 or z-uz > 10 then --if unit change position
							QueueLinkUpdate(allyTeamID, unitID)
						end
					else
						Spring.Echo("Warning: shieldUnitPosition for " .. unitID .. " is NIL") --should not happen, all ShieldUnit should've been subjected to linking check at least once
						updateAllyTeamLinks[allyTeamID] = true --re-create all link
						break; --nothing else to do, escape loop
					end
				end
			end
		end
		for allyTeamID,_ in pairs(updateAllyTeamLinks) do
			UpdateAllLinks(allyTeamID,shieldTeams[allyTeamID],shieldTeams[allyTeamID])
			updateAllyTeamLinks[allyTeamID] = nil
			listCount = -1
		end
		for allyTeamID,unitToLink in pairs(updateLink) do
			UpdateAllLinks(allyTeamID,shieldTeams[allyTeamID],unitToLink) --adjust/create link
			updateLink[allyTeamID] = nil
			listCount = -1 --trigger "shieldUnitList[]" to update too
		end
		
	elseif n%5 == 3 then
		UpdateEnabledState() --do stun checks at a bit faster rate for charge distribution algorithm (below)
	end
	
	-- Charge Distribution
	-- Translate to ordered table every second. The units are iterated over every frame.
	if n%30 == 18 and listCount == -1 then
		listCount = 0
		for allyTeamID,unitList in pairs(shieldTeams) do
			for unitID,shieldUnit in pairs(unitList) do
				if shieldUnit.enabled and shieldUnit.neighborList.count > 0 then
					listCount = listCount + 1
					shieldUnitList[listCount] = {
						unitID = unitID,
						data = shieldUnit, --Note: "shieldUnit" is a pointer
					} 
					
					--for otherID,_ in pairs(shieldUnit.neighbors) do
					----for i = 1, shieldUnit.numNeighbors do
					----	local otherID = shieldUnit.neighborList[i]
					--	local otherShield = shieldTeams[shieldUnit.allyTeamID][otherID]
					--	if otherShield then
					--		Spring.MarkerAddLine(shieldUnit.x,0,shieldUnit.z,otherShield.x,0,otherShield.z)
					--	end
					--end
				end
			end
		end
	end
	
	--Distribute charge to random nearby neighbor
	if n%2 == 0 then
		local unitID, unitData, unitCharge, allyTeamID --note: prevent repeated localization reduce consumption by 2%.
		local otherID, otherData, otherCharge
		local on, randomUnit, drawLink, attempt
		for i=1, listCount do --looping without pairs reduce consumption by 7%.
			unitID = shieldUnitList[i].unitID
			unitData = shieldUnitList[i].data
			on, unitCharge = spGetUnitShieldState(unitID, -1)
			drawLink = false
			attempt = 1
			while attempt and attempt < 3 do
				if on and unitCharge and unitData.enabled and unitData.neighborList.count >= 1 then
					allyTeamID = unitData.allyTeamID
					unitFlow = 0
					randomUnit = math.random(1,unitData.neighborList.count)
					otherID = unitData.neighborList.data[randomUnit]
					if otherID then
						otherData = shieldTeams[allyTeamID][otherID]
						if otherData then
							on, otherCharge = spGetUnitShieldState(otherID, -1)
							if on and otherCharge and otherData.enabled and ShieldsAreTouching(unitData, otherData) then
								if (unitCharge > otherCharge) then
									drawLink = DoChargeTransfer(otherID, otherData, otherCharge, unitID, unitData, unitCharge)
								else
									drawLink = DoChargeTransfer(unitID, unitData, unitCharge, otherID, otherData, otherCharge)
								end
								if drawLink then
									spSetUnitRulesParam(unitID,"shield_link",otherID,unitRulesParamsSetting)
								end
								attempt = false
							else
								RemoveThingFromIterable(unitID, otherData.neighbors, otherData.neighborList)
								RemoveThingFromIterable(otherID, unitData.neighbors, unitData.neighborList)
								attempt = attempt + 1
							end
						else
							RemoveThingFromIterable(otherID, unitData.neighbors, unitData.neighborList)
							attempt = attempt + 1
						end
					else
						attempt = attempt + 1
					end
				else
					attempt = false
				end
			end 
			if not drawLink then
				spSetUnitRulesParam(unitID,"shield_link",-1,unitRulesParamsSetting)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UNSYNCED
else
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glVertex = gl.Vertex
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glPushAttrib = gl.PushAttrib
local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local glPopAttrib = gl.PopAttrib

local GL_LINE_BITS = GL.LINE_BITS
local GL_LINES     = GL.LINES

local spGetMyAllyTeamID    = Spring.GetMyAllyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spIsUnitInView       = Spring.IsUnitInView
local spValidUnitID        = Spring.ValidUnitID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitLosState    = Spring.GetUnitLosState

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local shieldUnits = {}
local shieldCount = 0

function gadget:Initialize()
	local spGetUnitDefID = Spring.GetUnitDefID
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if UnitDefs[unitDefID].shieldWeaponDef then
		shieldCount = shieldCount + 1
		shieldUnits[shieldCount] = unitID
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if UnitDefs[unitDefID].shieldWeaponDef then
		for i=1, #shieldUnits do
			if shieldUnits[i] == unitID then
				table.remove(shieldUnits,i)
				shieldCount = shieldCount - 1
				break;
			end
		end
	end
end

local function DrawFunc()
	local unitID
	local connectedToUnitID
	local x1, y1, z1, x2, y2, z2
	local spec, fullview = spGetSpectatingState()
	local myTeam = spGetMyAllyTeamID()
	for i=1, #shieldUnits do
		unitID = shieldUnits[i]
		connectedToUnitID = tonumber(spGetUnitRulesParam(unitID, "shield_link") or -1)
		if connectedToUnitID and connectedToUnitID >= 0 and (spValidUnitID(unitID) and spValidUnitID(connectedToUnitID)) then
			local los1 = spGetUnitLosState(unitID, myTeam, false)
			local los2 = spGetUnitLosState(connectedToUnitID, myTeam, false)
			if (fullview or (los1 and los1.los) or (los2 and los2.los)) and 
					(spIsUnitInView(unitID) or spIsUnitInView(connectedToUnitID)) then
				x1, y1, z1 = spGetUnitViewPosition(unitID, true)
				x2, y2, z2 = spGetUnitViewPosition(connectedToUnitID, true)
				glVertex(x1, y1, z1)
				glVertex(x2, y2, z2)
			end
		end
	end
end

function gadget:DrawWorld()
	if shieldCount > 1 then
		glPushAttrib(GL_LINE_BITS)
    
		glDepthTest(true)
		glColor(1,0,1,math.random()*0.2+0.2)
		glLineWidth(1.1)
		glBeginEnd(GL_LINES, DrawFunc)
    
		glDepthTest(false)
		glColor(1,1,1,1)
    
		glPopAttrib()
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

