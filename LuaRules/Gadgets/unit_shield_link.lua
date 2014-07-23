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
local version = 1.231

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

---CONFIG---
local linkLimit = { --set maximum link desired, empty means "no limit"
	[UnitDefNames["shieldfelon"].id] = 5,
	[UnitDefNames["core_spectre"].id] = 5, --aspis
	[UnitDefNames["corjamt"].id] = 5, --aegis
}
local linkSequence = { --set any unit to link first, first unit get more link but limited by linkLimit (if set)
	[1] = UnitDefNames["shieldfelon"].id,
	[2] = UnitDefNames["core_spectre"].id, --aspis
	[3] = UnitDefNames["corjamt"].id, --aegis
}
------------

local NO_LINK = {nil}

local shieldTeams = {}

local shieldConnections = {}
local unitRulesParamsSetting = {allied=true,} --Fixme: what is the losAccess setting that obey spec's limited LOS mode?

local updateLink = {nil}

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
		local allyTeam = spGetUnitAllyTeam(unitID)
		if not (shieldTeams[allyTeam] and shieldTeams[allyTeam][unitID]) then -- not need to redo table if already have table (UnitFinished() will call this function 2nd time)
			shieldTeams[allyTeam] = shieldTeams[allyTeam] or {}
			local shieldUnit = {
				shieldPower  = shieldWep.shieldPower,
				shieldRadius = shieldWep.shieldRadius,
				shieldRegen  = shieldWep.shieldPowerRegen,
				unitDefID    = unitDefID,
				linkLimit    = linkLimit[unitDefID],
				link         = NO_LINK,  --real table is created in each UpdateAllLinks() call
				neighbor     = {},
				numNeighbors = 0,
			}
			shieldTeams[allyTeam][unitID] = shieldUnit
		end
		updateLink[allyTeam] = updateLink[allyTeam] or {}
		updateLink[allyTeam][unitID] = true
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local allyTeam = spGetUnitAllyTeam(unitID)
	if ud.shieldWeaponDef and shieldTeams[allyTeam] then
		local shieldUnit = shieldTeams[allyTeam][unitID]
		shieldTeams[allyTeam][unitID] = nil
		if shieldUnit then
			shieldUnit.link[unitID] = nil
			if shieldUnit.numNeighbors ~= 0 then --shield unit was connected to other shield
				QueueLinkToUpdateAndResetVFX(allyTeam,shieldUnit.link)
			end
			shieldUnit.link = NO_LINK  --help GC by removing pointer to old table
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	local ud = UnitDefs[unitDefID]
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam)
	if ud.shieldWeaponDef then
		local shieldUnit
		local allyTeam = spGetUnitAllyTeam(unitID)
		if shieldTeams[oldAllyTeam] and shieldTeams[oldAllyTeam][unitID] then
			shieldUnit = shieldTeams[oldAllyTeam][unitID]
			shieldUnit.link[unitID] = nil
			shieldTeams[oldAllyTeam][unitID] = nil
			if shieldUnit.numNeighbors ~= 0 then --shield unit was connected to other shield
				QueueLinkToUpdateAndResetVFX(oldAllyTeam,shieldUnit.link)
			end
			ClearShieldVFX(unitID,oldAllyTeam)
			updateLink[allyTeam] = updateLink[allyTeam] or {}
			updateLink[allyTeam][unitID] = true
			shieldUnit.link = NO_LINK --help GC by removing pointer to old table
		end
			
		shieldTeams[allyTeam] = shieldTeams[allyTeam] or {}
		shieldTeams[allyTeam][unitID] = shieldUnit --Note: wont be problem when NIL when nanoframe is captured because is always filled with new value when unit finish 
	end
end

function ClearAllShieldVFX(allyTeam)
	if shieldConnections[allyTeam] then
		for unitID,_ in pairs(shieldConnections[allyTeam]) do
			spSetUnitRulesParam(unitID,"shield_link",-1,unitRulesParamsSetting)
		end
		shieldConnections[allyTeam] = {}
	end
end

function ClearShieldVFX(unitID,allyTeam)
	if shieldConnections[allyTeam] then
		spSetUnitRulesParam(unitID,"shield_link",-1,unitRulesParamsSetting)
		shieldConnections[allyTeam][unitID] = nil
	end
end

function AddShieldVFX(unitID,allyTeam,conUnitID)
	shieldConnections[allyTeam] = shieldConnections[allyTeam] or {}
	if not shieldConnections[allyTeam][unitID] then
		spSetUnitRulesParam(unitID,"shield_link",conUnitID,unitRulesParamsSetting)
		shieldConnections[allyTeam][unitID] = conUnitID
	else 
		spSetUnitRulesParam(conUnitID,"shield_link",unitID,unitRulesParamsSetting)
		shieldConnections[allyTeam][conUnitID] = unitID
	end
end

function QueueLinkToUpdateAndResetVFX(allyTeam,link,unitID)
	if (link == NO_LINK) then
		updateLink[allyTeam] = updateLink[allyTeam] or {}
		updateLink[allyTeam][unitID] = true
	else
		updateLink[allyTeam] = updateLink[allyTeam] or {}
		for id2,_ in pairs(link) do
			ClearShieldVFX(id2,allyTeam)
			updateLink[allyTeam][id2] = true
		end
	end
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

local function AdjustLinks(allyTeam, unitList, isPreLinkingPhase, targetDefID,isPartialLinkingState, targetUnitIDs)
		for ud1,shieldUnit1 in pairs(unitList) do
			repeat --Is clever hax for making "break" behave like "continue"
				if isPreLinkingPhase then
					if shieldUnit1.unitDefID ~= targetDefID then break end --skip unprioritized units and other unitDefs
					shieldUnit1.prelinked = true
				else --not prelinking phase
					if shieldUnit1.prelinked then break end --skip prioritized units
				end
				if  isPartialLinkingState then
					if not (targetUnitIDs[ud1]) then break end --skip already linked units
				end

				if not shieldUnit1.linkable then break end -- continue to next unit

				for ud2,shieldUnit2 in pairs(unitList) do --iterate over all shield unit, find anyone that's in range.
					if ((not shieldUnit1.linkLimit) or shieldUnit1.linkLimit > shieldUnit1.numNeighbors)
                        and shieldUnit1.link ~= shieldUnit2.link and shieldUnit2.linkable then --if new link isn't existing link, and if this unit is linkable, then: 

						local xDiff = shieldUnit1.x - shieldUnit2.x
						local zDiff = shieldUnit1.z - shieldUnit2.z
						local yDiff = shieldUnit1.y - shieldUnit2.y
						local sumRadius = shieldUnit1.shieldRadius + shieldUnit2.shieldRadius

						if xDiff <= sumRadius and zDiff <= sumRadius and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < sumRadius*sumRadius then --if this unit is in range of old unit:
							AddShieldVFX(ud1,allyTeam,ud2)
		
							shieldUnit1.numNeighbors = shieldUnit1.numNeighbors + 1
							shieldUnit2.numNeighbors = shieldUnit2.numNeighbors + 1
							shieldUnit1.neighbor[shieldUnit1.numNeighbors] = ud2
							shieldUnit2.neighbor[shieldUnit2.numNeighbors] = ud1
								
							for unitID,shieldUnit3 in pairs(shieldUnit2.link) do
								shieldUnit1.link[unitID] = shieldUnit3 --copy content from new link to existing link
								shieldUnit3.link = shieldUnit1.link --assign existing link to new unit
							end
						end
					end
				end -- for ud2
			until true --exit repeat
		end	-- for ud1
end

local function UpdateAllLinks(allyTeam,unitList,isPartialLinkingState, unitsToPartialLink)
	for unitID,shieldUnit in pairs(unitList) do
		if not isPartialLinkingState or unitsToPartialLink[unitID] then --reset link data for targeted UnitID or all units (this will force re-creation of links)
			local x,y,z = spGetUnitPosition(unitID)
			local valid = x and y and z
			shieldUnit.linkable = valid and IsEnabled(unitID)
			shieldUnit.online = shieldUnit.linkable
			shieldUnit.enabled  = shieldUnit.linkable

			if (shieldUnit.linkable) then
				shieldUnit.x = x
				shieldUnit.y = y
				shieldUnit.z = z
				shieldUnit.link = { [unitID] = shieldUnit }
			else
				shieldUnit.link = NO_LINK
			end

			shieldUnit.numNeighbors = 0
			shieldUnit.prelinked = false
		end
	end

	if not isPartialLinkingState then
		ClearAllShieldVFX() -- Reset all when we want to recreate all link
	end

	for i=1, #linkSequence do --unit that is to be linked first (to have most link)
		local unitDefID = linkSequence[i]
		AdjustLinks(allyTeam, unitList, true , unitDefID,isPartialLinkingState,unitsToPartialLink) 
	end
	AdjustLinks(allyTeam, unitList, false,nil,isPartialLinkingState,unitsToPartialLink)
end

local function UpdateEnabledState()
	for allyTeam,unitList in pairs(shieldTeams) do
		for unitID,shieldUnit in pairs(unitList) do
			shieldUnit.enabled = IsEnabled(unitID)
			shieldUnit.online = shieldUnit.linkable and shieldUnit.enabled --if linked, update 'online' state (for charge distribution)
		end
	end
end

local RECHARGE_KOEF = 0.01
local shieldChargeList = {nil}
local listCount = 0
function gadget:GameFrame(n)
	if n%30 == 18 then  --update every 30 frames at the 18th frame
		--note: only update link when unit moves reduce total consumption by 53% when unit idle.
		for allyTeam,unitList in pairs(shieldTeams) do
			for unitID,shieldUnit in pairs(unitList) do
				if updateLink[allyTeam] and updateLink[allyTeam][unitID] then --already queued to update
					--skip/do-nothing
				elseif shieldUnit.linkable ~= shieldUnit.enabled then --if unit was linked/unlinked but now stunned/unstunned (state changes)
					QueueLinkToUpdateAndResetVFX(allyTeam,shieldUnit.link,unitID)
				elseif shieldUnit.linkable then
					local x,y,z = shieldUnit.x,shieldUnit.y,shieldUnit.z
					if x and y and z then
						local ux,uy,uz = Spring.GetUnitPosition(unitID)
						if ux-x > 10 or x-ux > 10 or uy-y > 10 or y-uy > 10 or  uz-z > 10 or z-uz > 10 then --if unit change position
							QueueLinkToUpdateAndResetVFX(allyTeam,shieldUnit.link)
						end
					else
						Spring.Echo("Warning: shieldUnitPosition for " .. unitID .. " is NIL") --should not happen, all ShieldUnit should've been subjected to linking check at least once
						updateLink[allyTeam] = true --re-create all link
						break; --nothing else to do, escape loop
					end
				end
			end
		end
		for allyTeam,unitToPartialLink in pairs(updateLink) do 
			UpdateAllLinks(allyTeam,shieldTeams[allyTeam],type(unitToPartialLink)=='table',unitToPartialLink) --adjust/create link
			updateLink[allyTeam] = nil
			listCount = -1 --trigger "shieldChargeList[]" to update too
		end
		
	elseif n%5 == 3 then
		UpdateEnabledState() --do stun checks at a bit faster rate for charge distribution algorithm (below)
	end
	
	-- Distribution Method A: distribute shield charge to nearest neighbor
	if n%30 == 18 and listCount == -1 then  -- translate pairs to ordered table
		listCount = 0
		for allyTeam,unitList in pairs(shieldTeams) do
			for unitID,shieldUnit in pairs(unitList) do
				if shieldUnit.link ~= NO_LINK then
					listCount = listCount + 1
					shieldChargeList[listCount] = {unitID,shieldUnit} --Note: "shieldUnit" is a pointer
				end
			end
		end
	end
	--Distribute charge to nearest neighbor
	local unitID2,charger_On,charger_charge,charger_capacity --note: prevent repeated localization reduce consumption by 2%.
	local unitID3,chargee_On,chargee_charge,chargee_capacity,chargee_regen
	local chargeFlow, shieldUnit2,shieldUnit3
	for i=1, listCount do --looping without pairs reduce consumption by 7%.
		unitID2 = shieldChargeList[i][1]
		shieldUnit2 = shieldChargeList[i][2]
		charger_On,charger_charge = spGetUnitShieldState(unitID2, -1) --probably return NIL if unit is dead
		if (charger_On and shieldUnit2.online) then
			charger_capacity = shieldUnit2.shieldPower
			for i=1, shieldUnit2.numNeighbors do
				unitID3 = shieldUnit2.neighbor[i]
				shieldUnit3 = shieldUnit2.link[unitID3]
				if shieldUnit3~= nil then --shield dead? (NOTE! neighbor list is not updated when unit die, its only updated in AdjustLinks(), however "shieldUnit.link[unitID]" is emptied upon death)
					chargee_On,chargee_charge = spGetUnitShieldState(unitID3, -1)
					if chargee_On and shieldUnit3.online and (charger_charge>chargee_charge) then 
						chargee_capacity = shieldUnit3.shieldPower
						chargee_regen = shieldUnit3.shieldRegen
						--charge flow is: based on the absolute difference in charge content,
						--charge flow must:
						--1)not be more than receiver's capacity, 
						--2)not be more than donator's available charge,
						--3)leave spaces for receiver to regen,
						--charge flow is capable: to reverse flow (IS DISABLED!) when receiver have regen and is full,
						chargeFlow = math.min(RECHARGE_KOEF*(charger_charge-chargee_charge),charger_charge, chargee_capacity-chargee_regen-chargee_charge) --minimize positive flow
						chargeFlow = math.max(0, chargeFlow, charger_charge - charger_capacity) --minimize negative flow (DISABLED by setting max 0 flow, prevent cheap reservoir from charging expensive reservoir using overflow)
						charger_charge = charger_charge - chargeFlow --deduct charge
						spSetUnitShieldState(unitID3, -1, chargee_charge + chargeFlow)--add charge to receiver
					end
				end
			end
			spSetUnitShieldState(unitID2, -1, charger_charge)--deduct charge
		end 
	end
	-- Distribution Method A - END
	
	--[[-- Distribution Method B: distribute to all linked shield based on total average
	for allyTeam,unitList in pairs(shieldTeams) do
		local processedLinks = { [NO_LINK] = true } --DO NOT USE PAIRS ON THIS
		for unitID,shieldUnit in pairs(unitList) do
			repeat --doesn't do loop but make "break" behave like "continue"
				if not processedLinks[shieldUnit.link] then --check if this linked group have been processed before
					processedLinks[shieldUnit.link] = true --mark this linked groupd as processed
		
					local totalCharge =	0
					local linkUnits = 0
					local udata = {}	-- unit data,	charge and chargeMax
					for unitID2,shieldUnit2 in pairs(shieldUnit.link) do
						local shieldOn,shieldCharge = spGetUnitShieldState(unitID2, -1)
						if (shieldOn) then 
							udata[unitID2] = {
								charge = shieldCharge,
								chargeMax = shieldUnit2.shieldPower
							}
							totalCharge = totalCharge + shieldCharge
							linkUnits = linkUnits + 1
						end 
					end
					local avg = totalCharge / linkUnits	-- calculate average charge of netwrok 
					local overflow = 0
					local slack = 0 

					for uid,d in pairs(udata) do	-- equalize all sheilds to average by 1% of their difference from average 
						local newCharge = d.charge + (avg - d.charge) * RECHARGE_KOEF
						if (newCharge > d.chargeMax) then 
							overflow = overflow + newCharge - d.chargeMax
							newCharge = d.chargeMax
						else 
							slack = slack + d.chargeMax - newCharge
						end 
						d.charge = newCharge
						spSetUnitShieldState(uid, -1, newCharge)
					end
		
					if overflow > 0 and slack > 0 then	-- if there was overflow (above max charge) and	there is still some unused space for charge, transfer it there 
						for uid,d in pairs(udata) do
							if (d.charge < d.chargeMax) then 
								local newCharge = d.charge + overflow * (d.chargeMax - d.charge) / slack 
								spSetUnitShieldState(uid, -1, newCharge)
							end 
						end
					end 
				end
			until true --exit repeat
		end
	end
	--]]-- Distribution Method B - END
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

local function DrawFunc2()
	local unitID
	local connectedToUnitID
	local x1, y1, z1, x2, y2, z2
	for i=1, #shieldUnits do
		unitID =shieldUnits[i]
		connectedToUnitID = tonumber(spGetUnitRulesParam(unitID, "shield_link") or -1)
		if (connectedToUnitID and (connectedToUnitID >= 0) and (spIsUnitInView(unitID) or spIsUnitInView(connectedToUnitID)) and (spValidUnitID(unitID) and spValidUnitID(connectedToUnitID))) then
			x1, y1, z1 = spGetUnitViewPosition(unitID, true)
			x2, y2, z2 = spGetUnitViewPosition(connectedToUnitID, true)
			glVertex(x1, y1, z1)
			glVertex(x2, y2, z2)
		end
	end
end

function gadget:DrawWorld()
	if shieldCount > 1 then
		glPushAttrib(GL_LINE_BITS)

		glDepthTest(true)
		glColor(1,0,1,math.random()*0.3+0.2)
		glLineWidth(1)
		glBeginEnd(GL_LINES, DrawFunc2)

		glDepthTest(false)
		glColor(1,1,1,1)

		glPopAttrib()
	end
end

--[[
local function DrawFunc()
	myAllyID = spGetMyAllyTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview
	
	local shieldConnections = SYNCED.shieldConnections
	for allyID, connections in spairs(shieldConnections) do

		-- for _,cons in sipairs(connections) do  -- ordered array contains u1,u2,u1,u2,... 
		for u1,u2 in spairs(connections) do  --unordered array contains u1 u2,u1 u2,... pairs 
			local l1
			local l2
		
			if (spec or allyID == myAllyID) then
				l1 = spIsUnitInView(u1)
				l2 = spIsUnitInView(u2)
			end

			if ((l1 or l2) and (spValidUnitID(u1) and spValidUnitID(u2))) then
				local x1, y1, z1 = spGetUnitViewPosition(u1, true)
				local x2, y2, z2 = spGetUnitViewPosition(u2, true)
				glVertex(x1, y1, z1)
				glVertex(x2, y2, z2)
			end
		end
	end
end


function gadget:DrawWorld()
	if SYNCED.shieldConnections and snext(SYNCED.shieldConnections) then
		glPushAttrib(GL_LINE_BITS)
	
		glDepthTest(true)
		glColor(1,0,1,math.random()*0.3+0.2)
		glLineWidth(1)
		glBeginEnd(GL_LINES, DrawFunc2)
	
		glDepthTest(false)
		glColor(1,1,1,1)
	
		glPopAttrib()
	end
end
--]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

