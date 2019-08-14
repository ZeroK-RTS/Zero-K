function gadget:GetInfo()
	return {
		name    = "Shield Link",
		desc    = "Nearby shields on the same ally team share charge to and from each other. Working Version",
		author  = "lurker",
		date    = "2009",
		license = "Public domain",
		layer   = 0,
		enabled = true -- loaded by default?
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

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitIsStunned    = Spring.GetUnitIsStunned
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spGetUnitShieldState  = Spring.GetUnitShieldState
local spSetUnitShieldState  = Spring.SetUnitShieldState
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spGetUnitRulesParam   = Spring.GetUnitRulesParam

------------
local RECHARGE_KOEF = 0.01
local CHARGE_DRAW_THRESHOLD = 0.1

------------
local allyTeamShields = {}
local allyTeamShieldList = {}

local unitRulesParamsSetting = {inlos = true} -- Let enemies see links. It is information availible to them anyway

local updateLink = {}
local updateAllyTeamLinks = {}

-- Double table with index in things
local function AddDataThingToIterable(id, data, things, thingByID)
	if id and data then
		thingByID.count = thingByID.count + 1
		thingByID[thingByID.count] = id
		things[id] = data
		things[id].index = thingByID.count
	end
end

local function RemoveDataThingFromIterable(id, things, thingByID)
	if things[id] then
		things[thingByID[thingByID.count]].index = things[id].index
		thingByID[things[id].index] = thingByID[thingByID.count]
		thingByID[thingByID.count] = nil
		things[id] = nil
		thingByID.count = thingByID.count - 1
		return true
	end
	return false
end

-- Double table is required to choose a random element from the list
local function AddThingToIterable(id, things, thingByID)
	thingByID.count = thingByID.count + 1
	thingByID[thingByID.count] = id
	things[id] = thingByID.count
end

local function RemoveThingFromIterable(id, things, thingByID)
	if things[id] then
		things[thingByID[thingByID.count]] = things[id]
		thingByID[things[id]] = thingByID[thingByID.count]
		thingByID[thingByID.count] = nil
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
	
	local shieldWeaponDefID
	local shieldNum = -1
	if ud.customParams.dynamic_comm then
		if GG.Upgrades_UnitShieldDef then
			shieldWeaponDefID, shieldNum = GG.Upgrades_UnitShieldDef(unitID)
		end
	else
		shieldWeaponDefID = ud.shieldWeaponDef
	end
	
	if shieldWeaponDefID then
		local shieldWep = WeaponDefs[shieldWeaponDefID]
		if not shieldWep.customParams.unlinked then
			--local x,y,z = spGetUnitPosition(unitID)
			local allyTeamID = spGetUnitAllyTeam(unitID)
			if not (allyTeamShields[allyTeamID] and allyTeamShields[allyTeamID][unitID]) then -- not need to redo table if already have table (UnitFinished() will call this function 2nd time)
				allyTeamShields[allyTeamID] = allyTeamShields[allyTeamID] or {}
				allyTeamShieldList[allyTeamID] = allyTeamShieldList[allyTeamID] or {count = 0}
				
				local shieldRegen = shieldWep.shieldPowerRegen
				if shieldRegen == 0 and shieldWep.customParams and shieldWep.customParams.shield_rate then
					shieldRegen = tonumber(shieldWep.customParams.shield_rate)
				end
				
				local shieldUnit = {
					shieldMaxCharge  = shieldWep.shieldPower,
					shieldNum    = shieldNum,
					shieldRadius = shieldWep.shieldRadius,
					shieldRegen  = shieldRegen,
					shieldRank   = ((shieldWep.shieldRadius > 400) and 3) or ((shieldWep.shieldRadius > 200) and 2) or 1,
					unitDefID    = unitDefID,
					neighbors    = {},
					neighborList = {count = 0},
					allyTeamID   = allyTeamID,
					enabled      = false,
					oldEnabled   = false,
					oldFastEnabled = false,
				}
				AddDataThingToIterable(unitID, shieldUnit, allyTeamShields[allyTeamID], allyTeamShieldList[allyTeamID])
			end
			QueueLinkUpdate(allyTeamID,unitID)
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if allyTeamShields[allyTeamID] and allyTeamShields[allyTeamID][unitID] then
		local unitData = allyTeamShields[allyTeamID][unitID]
		if unitData then
			RemoveUnitFromNeighbors(allyTeamID, unitID, unitData.neighborList)
		end
		RemoveDataThingFromIterable(unitID, allyTeamShields[allyTeamID], allyTeamShieldList[allyTeamID])
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	local ud = UnitDefs[unitDefID]
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam, false)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if allyTeamID and allyTeamShields[oldAllyTeam] and allyTeamShields[oldAllyTeam][unitID] then
		local unitData
		if allyTeamShields[oldAllyTeam] and allyTeamShields[oldAllyTeam][unitID] then
			unitData = allyTeamShields[oldAllyTeam][unitID]
			
			RemoveDataThingFromIterable(unitID, allyTeamShields[oldAllyTeam], allyTeamShieldList[oldAllyTeam])
			RemoveUnitFromNeighbors(oldAllyTeam, unitID, unitData.neighborList)
			unitData.neighbors = {}
			unitData.neighborList = {count = 0}
			unitData.allyTeamID = allyTeamID
		end
		allyTeamShields[allyTeamID] = allyTeamShields[allyTeamID] or {}
		allyTeamShieldList[allyTeamID] = allyTeamShieldList[allyTeamID] or {count = 0}
		
		--Note: wont be problem when NIL when nanoframe is captured because is always filled with new value when unit finish
		AddDataThingToIterable(unitID, unitData, allyTeamShields[allyTeamID], allyTeamShieldList[allyTeamID])
		QueueLinkUpdate(allyTeamID,unitID)
	end
end

function RemoveUnitFromNeighbors(allyTeamID, unitID, neighborList)
	local otherID
	local thisShieldTeam = allyTeamShields[allyTeamID]
	for i = 1, neighborList.count do
		otherID = neighborList[i]
		if thisShieldTeam[otherID] then
			RemoveThingFromIterable(unitID, thisShieldTeam[otherID].neighbors, thisShieldTeam[otherID].neighborList)
		end
	end
end

function QueueLinkUpdate(allyTeamID,unitID)
	updateLink[allyTeamID] = updateLink[allyTeamID] or {}
	updateLink[allyTeamID][unitID] = true
end

-- Check if working unit so it can be used for shield link
local function IsEnabled(unitID)
	local enabled = spGetUnitShieldState(unitID)
	if not enabled then
		return false
	end
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild then
		return false
	end
	local att_enabled = (spGetUnitRulesParam(unitID, "att_abilityDisabled") ~= 1)
	return att_enabled
end

local function ShieldsAreTouching(shield1, shield2)
	local xDiff = shield1.x - shield2.x
	local zDiff = shield1.z - shield2.z
	local yDiff = shield1.y - shield2.y
	local sumRadius = shield1.shieldRadius + shield2.shieldRadius
	return xDiff <= sumRadius and zDiff <= sumRadius and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < sumRadius*sumRadius
end

local function AdjustLinks(allyTeamID, shieldUnits, shieldList, unitUpdateList)
	local unitData
	for unitID,_ in pairs(unitUpdateList) do
		unitData = shieldUnits[unitID]
		if unitData and unitData.enabled then
			local otherID, otherData
			for i = 1, shieldList.count do --iterate over all shield unit, find anyone that's in range.
				otherID = shieldList[i]
				if unitID ~= otherID then
					otherData = shieldUnits[otherID]
					if not (otherData.neighbors[unitID] or unitData.neighbors[otherID]) and
							otherData.enabled and ShieldsAreTouching(unitData, otherData) then
						if unitData.shieldRank == otherData.shieldRank then
							AddThingToIterable(otherID, unitData.neighbors, unitData.neighborList)
							AddThingToIterable(unitID, otherData.neighbors, otherData.neighborList)
						elseif unitData.shieldRank < otherData.shieldRank then
							-- The higher ranked shield does not initiate transfer with lower shields.
							AddThingToIterable(otherID, unitData.neighbors, unitData.neighborList)
						else
							AddThingToIterable(unitID, otherData.neighbors, otherData.neighborList)
						end
					end
				end
			end -- for otherID
		end
	end	-- for unitID
end

local function UpdateAllLinks(allyTeamID, shieldUnits, shieldList, unitUpdateList)
	local unitData
	for unitID,_ in pairs(unitUpdateList) do
		unitData = allyTeamShields[allyTeamID][unitID]
		if unitData then
			local x,y,z = spGetUnitPosition(unitID)
			local valid = x and y and z
			unitData.enabled = valid and IsEnabled(unitID)
			
			if (unitData.enabled) then
				unitData.x = x
				unitData.y = y
				unitData.z = z
			end
		end
	end
	
	AdjustLinks(allyTeamID, shieldUnits, shieldList, unitUpdateList)
end

local function UpdateEnabledState()
	for allyTeamID,unitList in pairs(allyTeamShields) do
		for unitID,shieldUnit in pairs(unitList) do
			shieldUnit.enabled = IsEnabled(unitID)
			if shieldUnit.enabled ~= shieldUnit.oldFastEnabled then
				if shieldUnit.oldFastEnabled then
					spSetUnitRulesParam(unitID,"shield_link_unit",-1,unitRulesParamsSetting)
				end
				shieldUnit.oldFastEnabled = shieldUnit.enabled
			end
		end
	end
end

local function DoChargeTransfer(lowID, lowData, lowCharge, highID, highData, highCharge)
	--charge flow is: based on the absolute difference in charge content,
	--charge flow must:
	--1)not be more than receiver's capacity,
	--2)not be more than donator's available charge,
	--3)leave spaces for receiver to regen,
	--charge flow is capable: to reverse flow (IS DISABLED!) when receiver have regen and is full,
	local chargeFlow = math.min(RECHARGE_KOEF*(highCharge - lowCharge),highCharge, lowData.shieldMaxCharge - lowData.shieldRegen - lowCharge) --minimize positive flow
	if chargeFlow > 0 then -- Disallow negative flow
		chargeFlow = chargeFlow * (spGetUnitRulesParam(highID, "totalReloadSpeedChange") or 1)
		spSetUnitShieldState(highID, highData.shieldNum, highCharge - chargeFlow)
		spSetUnitShieldState(lowID, lowData.shieldNum, lowCharge + chargeFlow)
		return chargeFlow
	end
	return 0
end

function gadget:GameFrame(n)
	if n%30 == 18 then  --update every 30 frames at the 18th frame
		--note: only update link when unit moves reduce total consumption by 53% when unit idle.
		for allyTeamID,unitList in pairs(allyTeamShieldList) do
			local unitID, unitData
			for i = 1, unitList.count do
				unitID = unitList[i]
				unitData = allyTeamShields[allyTeamID][unitID]
				if unitData.enabled ~= unitData.oldEnabled then --if unit was linked/unlinked but now stunned/unstunned (state changes)
					if not unitData.oldEnabled then
						QueueLinkUpdate(allyTeamID,unitID)
					end
					unitData.oldEnabled = unitData.enabled
				elseif unitData.enabled then
					local x,y,z = unitData.x, unitData.y, unitData.z
					if x and y and z then
						local ux,uy,uz = spGetUnitPosition(unitID)
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
			UpdateAllLinks(allyTeamID,allyTeamShields[allyTeamID],allyTeamShieldList[allyTeamID],allyTeamShields[allyTeamID])
			updateAllyTeamLinks[allyTeamID] = nil
		end
		for allyTeamID,unitToLink in pairs(updateLink) do
			UpdateAllLinks(allyTeamID,allyTeamShields[allyTeamID],allyTeamShieldList[allyTeamID],unitToLink) --adjust/create link
			updateLink[allyTeamID] = nil
		end
		
	elseif n%5 == 3 then
		UpdateEnabledState() --do stun checks at a bit faster rate for charge distribution algorithm (below)
	end
	
	-- Charge Distribution
	--Distribute charge to random nearby neighbor
	local drawChange = (n%10 == 0)
	if n%2 == 0 then
		for allyTeamID,unitList in pairs(allyTeamShieldList) do
			local shieldUnits = allyTeamShields[allyTeamID]
			local unitID, unitData, unitCharge
			local otherID, otherData, otherCharge
			local on, chargeFlow, attempt
			local randomUnitIndex, randomNumberRange
			for i = 1, unitList.count do
				unitID = unitList[i]
				unitData = shieldUnits[unitID]
				on, unitCharge = spGetUnitShieldState(unitID, unitData.shieldNum)
				chargeFlow = 0
				attempt = 1
				while attempt and attempt < 3 do
					if on and unitCharge and unitData.enabled and unitData.neighborList.count >= 1 then
						allyTeamID = unitData.allyTeamID
						unitFlow = 0
						-- The +1 is here intentionally to give units a chance to not link (because
						-- otherID will be nil). This penalises the flow rate of units with few
						-- neighbors.
						randomNumberRange = unitData.neighborList.count + 1
						randomUnitIndex = math.random(1, randomNumberRange)
						otherID = unitData.neighborList[randomUnitIndex]
						if otherID then
							otherData = allyTeamShields[allyTeamID][otherID]
							if otherData then
								on, otherCharge = spGetUnitShieldState(otherID, otherData.shieldNum)
								if on and otherCharge and otherData.enabled and ShieldsAreTouching(unitData, otherData) then
									if (unitCharge > otherCharge) then
										chargeFlow = DoChargeTransfer(otherID, otherData, otherCharge, unitID, unitData, unitCharge)
									else
										chargeFlow = DoChargeTransfer(unitID, unitData, unitCharge, otherID, otherData, otherCharge)
									end
									if chargeFlow >= CHARGE_DRAW_THRESHOLD and drawChange then
										spSetUnitRulesParam(unitID,"shield_link_unit",otherID,unitRulesParamsSetting)
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
						elseif randomUnitIndex == randomNumberRange then
							-- If I hit the end of the range I picked myself as a partner.
							attempt = false
						else
							attempt = attempt + 1
						end
					else
						attempt = false
					end
				end
				if chargeFlow < CHARGE_DRAW_THRESHOLD and drawChange then
					spSetUnitRulesParam(unitID,"shield_link_unit",-1,unitRulesParamsSetting)
				end
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

local abs = math.abs

local spGetMyAllyTeamID    = Spring.GetMyAllyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spIsUnitInView       = Spring.IsUnitInView
local spValidUnitID        = Spring.ValidUnitID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitLosState    = Spring.GetUnitLosState
local spGetGameFrame       = Spring.GetGameFrame

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local shieldUnits = {}
local shieldCount = 0

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

function gadget:Initialize()
	local spGetUnitDefID = Spring.GetUnitDefID
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
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
		connectedToUnitID = tonumber(spGetUnitRulesParam(unitID, "shield_link_unit") or -1)
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

local function DrawWorldFunc()
	if shieldCount > 1 then
		local frame = spGetGameFrame()
		local alpha = 0.5-0.1*abs((frame%10) - 5)
		
		glPushAttrib(GL_LINE_BITS)
    
		glDepthTest(true)
		glColor(1,0,1,alpha)
		glLineWidth(alpha+0.6)
		glBeginEnd(GL_LINES, DrawFunc)
    
		glDepthTest(false)
		glColor(1,1,1,1)
    
		glPopAttrib()
	end
end

function gadget:DrawWorld()
	DrawWorldFunc()
end
function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
