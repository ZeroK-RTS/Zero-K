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
local version = 1.20

-- CHANGELOG
--	2009-5-24: CarRepairer: Added graphic lines to show links of shields (also shows links of enemies' visible shields, can remove if desired).
--	2009-5-30: CarRepairer: Lups graphic lines, fix for 0.79.1 compatibility.
--	2009-9-15: Licho: added simple fast graph lines

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitIsStunned	= Spring.GetUnitIsStunned
local spGetUnitIsActive		= Spring.GetUnitIsActive
local spGetUnitShieldState	= Spring.GetUnitShieldState
local spSetUnitShieldState	= Spring.SetUnitShieldState
local spGetTeamInfo			= Spring.GetTeamInfo


if gadgetHandler:IsSyncedCode() then
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

shieldConnections = {}
_G.shieldConnections = shieldConnections

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
		updateLink[allyTeam] = 2
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
			shieldUnit.link = NO_LINK  --help GC by removing pointer to old table
			if shieldUnit.numNeighbors ~= 0 then --shield unit was connected to other shield
				updateLink[allyTeam] = 2
			end
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	local ud = UnitDefs[unitDefID]
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam)
	if ud.shieldWeaponDef then
		local shieldUnit
		if shieldTeams[oldAllyTeam] and shieldTeams[oldAllyTeam][unitID] then
			shieldUnit = shieldTeams[oldAllyTeam][unitID]
			shieldTeams[oldAllyTeam][unitID] = nil
			shieldUnit.link[unitID] = nil
			shieldUnit.link = NO_LINK
		end
			
		local allyTeam = spGetUnitAllyTeam(unitID)
		shieldTeams[allyTeam] = shieldTeams[allyTeam] or {}
		shieldTeams[allyTeam][unitID] = shieldUnit --Note: wont be problem when NIL because is always filled with new value when unit finish (ie: when unit captured before finish) 
	end
end

-- check if working unit so it can be used for shield link
local function isEnabled(unitID)
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
        local sc = shieldConnections[allyTeam]
		local cnt = #sc + 1

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
								
							sc[cnt]   = ud1
                            sc[cnt+1] = ud2
							cnt = cnt + 2
		
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
		if not isPartialLinkingState or unitsToPartialLink[unitID] then
			local x,y,z = spGetUnitPosition(unitID)
			local valid = x and y and z
			shieldUnit.linkable = valid and isEnabled(unitID)
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

	if not isPartialLinkingState then --we are to append link (to only few units that are deemed safe) so no need to re-check/create all link 
		shieldConnections[allyTeam] = {}
	end

	for i=1, #linkSequence do --unit that is to be linked first (to have most link)
		local unitDefID = linkSequence[i]
		AdjustLinks(allyTeam, unitList, true , unitDefID,isPartialLinkingState,unitsToPartialLink) 
	end
	AdjustLinks(allyTeam, unitList, false,isPartialLinkingState,unitsToPartialLink)
end

local function UpdateEnabledState()
	for allyTeam,unitList in pairs(shieldTeams) do
		for unitID,shieldUnit in pairs(unitList) do
			shieldUnit.enabled = isEnabled(unitID)
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
		local unitToPartialLink = {} --some unit that are safe to link without re-create/check all link
		for allyTeam,unitList in pairs(shieldTeams) do
			if not updateLink[allyTeam] then --skip positional & stun checks if re-linking is already ordered
				for unitID,shieldUnit in pairs(unitList) do
					if shieldUnit.linkable ~= shieldUnit.enabled then --check if unit was linked/unlinked but now stunned/unstunned
						if shieldUnit.numNeighbors == 0 then --lonely shield units
							updateLink[allyTeam] = 1
							unitToPartialLink[unitID] = true
						else
							updateLink[allyTeam] = 2
							break; --escape, nothing else to check
						end
					elseif shieldUnit.linkable then
						local x,y,z = shieldUnit.x,shieldUnit.y,shieldUnit.z
						if x and y and z then
							local ux,uy,uz = Spring.GetUnitPosition(unitID)
							if ux-x > 10 or x-ux > 10 or uy-y > 10 or y-uy > 10 or  uz-z > 10 or z-uz > 10 then --check if any unit change position
								if shieldUnit.numNeighbors == 0 then --lonely shield units
									updateLink[allyTeam] = 1
									unitToPartialLink[unitID] = true
								else
									updateLink[allyTeam] = 2
									break; --escape, nothing else to check
								end
							end
						else
							Spring.Echo("Warning: shieldUnitPosition for " .. unitID .. " is NIL") --should not happen, all ShieldUnit should've been subjected to linking check at least once
							updateLink[allyTeam] = 2
							break;
						end
					end
				end
			end
		end
		for allyTeam,type in pairs(updateLink) do 
			UpdateAllLinks(allyTeam,shieldTeams[allyTeam],(type==1),unitToPartialLink) --adjust/create link
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
		charger_On,charger_charge = spGetUnitShieldState(unitID2, -1)
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:Initialize()
end


local function DrawFunc()
	myAllyID = spGetMyAllyTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview
	
	local shieldConnections = SYNCED.shieldConnections
	for allyID, connections in spairs(shieldConnections) do
		local u1, u2

		for _,con in sipairs(connections) do  --array contains u1,u2,u1,u2,... 
			if (not u1) then
				u1 = con
			else
				u2 = con
			
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

				u1 = nil
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

