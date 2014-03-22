--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "1.0.4" -- this now has it's own changelog

function widget:GetInfo()
  return {
    name      = "Ore pAI (auto ore reclaim/assist)",
    desc      = "pAI module for units to automaticly seek ore (to reclaim) and repair/assist allies. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = 4,
    enabled   = true,	-- now it comes with design!
    handler   = true,	-- geh
  }
end

--TODO AI assistant should be vastly improved, including eco building and connecting grid as well as bulk command sending to minimise traffic

-- changelog
-- 22 march 2014 - 1.0.4. Widget is now AI micro assistant. It also has it's own changelog from now on.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spValidUnitID		= Spring.ValidUnitID
local spGetUnitDefID	  	= Spring.GetUnitDefID
local spFindUnitCmdDesc		= Spring.FindUnitCmdDesc
local spEditUnitCmdDesc		= Spring.EditUnitCmdDesc
local spGetMyTeamID         	= Spring.GetMyTeamID
local spGetTeamResources    	= Spring.GetTeamResources
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetUnitPosition 	= Spring.GetUnitPosition
local spIsUnitAllied		= Spring.IsUnitAllied
local spGiveOrderToUnit   	= Spring.GiveOrderToUnit
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spGetFeaturesInRectangle	= Spring.GetFeaturesInRectangle
local spGetFeatureDefID		= Spring.GetFeatureDefID
local spGetUnitHealth		= Spring.GetUnitHealth
local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetGameFrame		= Spring.GetGameFrame
local spGiveOrderArrayToUnitArray	= Spring.GiveOrderArrayToUnitArray

local glDepthTest	= gl.DepthTest
local glColor		= gl.Color
local glRotate		= gl.Rotate
local glTranslate	= gl.Translate
local glPopMatrix	= gl.PopMatrix
local glPushMatrix	= gl.PushMatrix
local glAlphaTest	= gl.AlphaTest
local glTexture		= gl.Texture
local glTexRect		= gl.TexRect
local GL_GREATER	= GL.GREATER
local glUnitMultMatrix	= gl.UnitMultMatrix

local modOptions = Spring.GetModOptions()

local iconsize	 = 32
local iconhsize	= iconsize * 0.5

local ExtractorInView = {}
local Rotation = 0

local mexDefs = {
	[UnitDefNames["cormex"].id] = true,
}

local CMD_AUTOECO = 35301

local OnDefaultDefs = {
	[UnitDefNames["armnanotc"].id] = true,
}
local EcoDefs = {
	[UnitDefNames["armnanotc"].id] = true,
}
-- more setup
for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	if (ud.isBuilder and not(ud.isFactory)) or (ud.customParams.commtype) then
		EcoDefs[i] = true
	end
end

local pAIjob = {} -- unit can be either assister, or miner, it's decided every half minute, ratio is 4:6, miner will never get assist order, assister will never get repair order.
local pAIcontrolled = {}
local ecoUnit = {}
local pAIwait = {}
local IgnoreWait = {}
local NextOrderTick = {}
local pAIretreat = {}
local pAIretreatIgnore = {}

local myTeamID
local getMovetype = Spring.Utilities.getMovetype

local CMD_OPT_SHIFT = CMD.OPT_SHIFT 
local CMD_RECLAIM = CMD.RECLAIM
local CMD_PATROL = CMD.PATROL
local CMD_REPAIR = CMD.REPAIR
local CMD_FIGHT = CMD.FIGHT
local CMD_GUARD = CMD.GUARD
local CMD_MOVE = CMD.MOVE
local CMD_INSERT = CMD.INSERT

local random = math.random
local floor = math.floor

local ORDER_FRAME_LIMIT = 150	-- framelimit is increased should more units be controlled...
local ORDER_FRAME_LIMIT_MIN = 150
local MAX_TRANVEL_RANGE = 2000
local MAX_CARETAKER_RANGE = 500

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- "Interface" (silly hazard icon over extractors should they be able to damage units)

function widget:Update(s)
	Rotation=Rotation+1
	if (Rotation > 360) then
		Rotation = 0
	end
end

function widget:DrawWorld()
	if not Spring.IsGUIHidden() then
		glDepthTest(true)
		glAlphaTest(GL_GREATER, 0)
		for unitID,_ in pairs(ExtractorInView) do
			local unitDefID = spGetUnitDefID(unitID)
			if (unitDefID) then
				glPushMatrix()
				glTexture('LuaUI/Images/hazard.png')
				glUnitMultMatrix(unitID)
				glTranslate(0, UnitDefs[unitDefID].height + 4, 0)
				glRotate(Rotation,0,1,0)
				glColor(1,1,1,1)
				glTexRect(-iconhsize, 0, iconhsize, iconsize)
				glPopMatrix()
			end
		end
		-- done
		glAlphaTest(false)
		glColor(1,1,1,1)
		glTexture(false)
		glDepthTest(false)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Eco AI, basically any unit decides for itself what to do, for now

local function disSQ(x1,y1,x2,y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

local function IgnoreGaia(unitID)
	local ud = UnitDefs[spGetUnitDefID(unitID)]
	if ud and not(ud.canAttack) then
		return true
	end
	return false
end

local function FindAnyOreInRange(x,z,range)
	local features = spGetFeaturesInRectangle(x-range,z-range,x+range,z+range)
	for i=1,#features do
		local featureID = features[i]
		local featureDefID = spGetFeatureDefID(featureID)
		if (FeatureDefs[featureDefID].name=="ore") then
			return featureID
		end
	end
	return nil
end

local function pAIgetsafelocation(myUnit,x,y,z,teamID,far)
	local units = spGetUnitsInCylinder(x,z,MAX_TRANVEL_RANGE)
	-- nearest unit that can fire... go there!
	local unit
	local best_dist
	if (far) then
		for i=1,#units do
			local unitID = units[i]
			if (spIsUnitAllied(unitID)) then
				local ud = UnitDefs[spGetUnitDefID(unitID)]
				if (ud) and (ud.canAttack) and not(ud.isFactory) and not(pAIretreatIgnore[myUnit][unitID]) then
					local tx,ty,tz = spGetUnitPosition(unitID)
					local dist = disSQ(x,z,tx,tz)
					if ((best_dist == nil) or (best_dist > dist)) and (dist > 90000) then
						best_dist = dist
						unit = unitID
					end
				end
			end
		end
		if (unit) then
			pAIretreatIgnore[myUnit][unit] = true
		end
	else
		for i=1,#units do
			local unitID = units[i]
			if (spIsUnitAllied(unitID)) then
				local ud = UnitDefs[spGetUnitDefID(unitID)]
				if (ud) and (ud.canAttack) and not(ud.isFactory) then
					local tx,ty,tz = spGetUnitPosition(unitID)
					local dist = disSQ(x,z,tx,tz)
					if (best_dist == nil) or (best_dist > dist) then
						best_dist = dist
						unit = unitID
					end
				end
			end
		end
	end
	if (unit) then
		return spGetUnitPosition(unit)
	else
		return nil
	end
end

local function FindAnythingNearToRepair(myUnit,x,z,range)
	local units = spGetUnitsInCylinder(x,z,range)
	local unit
	local best_dist
	for i=1,#units do
		local unitID = units[i]
		if (spIsUnitAllied(unitID)) and (myUnit ~= unitID) then
			local hp,maxHp,_,_,build = spGetUnitHealth(unitID)
			if (hp < maxHp) or (build ~= 1) then
				local cx,_,cz = spGetUnitPosition(unitID)
				local dist = disSQ(x,z,cx,cz)
				if (best_dist == nil) or (best_dist > dist) then
					unit = unitID
					best_dist = dist
				end
			end
		end
	end
	if (unit) then
		return unit
	end
	return nil
end

function widget:UnitIdle(unitID, unitDefID, teamID)
	if (pAIcontrolled[unitID]) and (pAIwait[unitID]) then
		 pAIwait[unitID] = false
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if (pAIcontrolled[unitID]) and not(pAIwait[unitID]) then
		pAIretreat[unitID] = spGetGameFrame()+ORDER_FRAME_LIMIT
	end
end

local function pAIthink(goodMetal,f)
	for unitID,_ in pairs(pAIcontrolled) do
		if (spGetUnitTeam(unitID) == myTeamID) and not(pAIwait[unitID]) then
			local ud = UnitDefs[spGetUnitDefID(unitID)]
			if not(ud.isFactory) then
				local x,y,z = spGetUnitPosition(unitID)
				local queue = spGetCommandQueue(unitID, 1)
				IgnoreWait[unitID] = true
				if (getMovetype(ud) ~= false) then
					if (NextOrderTick[unitID] < f) then
						local units = spGetUnitsInCylinder(x,z,300)
						local enemy_near = false
						for i=1,#units do
							local targetID = units[i]
							if not(spIsUnitAllied(targetID)) and not(IgnoreGaia(targetID)) then
							      enemy_near = true
							      break
							end
						end
						if (enemy_near) or (pAIretreat[unitID] > 0) then
							local hp,maxHp = spGetUnitHealth(unitID)
							if not(ud.canAttack) or (hp < maxHp*0.33) then
								if (hp >= 400) then
									local tx,ty,tz,allyID = pAIgetsafelocation(unitID,x,y,z,myTeamID,false)
									if (tx) then
										  --spGiveOrderToUnit(unitID, CMD_MOVE, {tx,ty,tz},{})
										  spGiveOrderToUnit(unitID, CMD_REPAIR, {allyID},{}) -- why run, lets help allies!
										  spGiveOrderToUnit(unitID, CMD_FIGHT, {x+random(-200,200),0,z+random(-200,200)},CMD_OPT_SHIFT)
									else
										  spGiveOrderToUnit(unitID, CMD_FIGHT, {x+random(-200,200),0,z+random(-200,200)},{})
									end
								else
									local tx,ty,tz,allyID = pAIgetsafelocation(unitID,x,y,z,myTeamID,true)
									if (tx) then
										  spGiveOrderToUnit(unitID, CMD_MOVE, {tx,ty,tz},{})
									end
								end
							else
								spGiveOrderToUnit(unitID, CMD_FIGHT, {x+random(-200,200),0,z+random(-200,200)},{})
							end
						else
							if (pAIjob[unitID] == 0) then
								if not(goodMetal) and ((#queue == 0) or (queue[1].id ~= CMD_RECLAIM)) then -- RECLAIM LEL
									local oreID = FindAnyOreInRange(x,z,MAX_TRANVEL_RANGE)
									if (oreID) then
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {oreID},{})
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									else
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},{})
										local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_TRANVEL_RANGE)
										if (repairNearestID) then
											spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},CMD_OPT_SHIFT)
										end
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT) -- NO ORE QQ
									end
								elseif (#queue == 0) or (queue[1].id ~= CMD_REPAIR) then -- ASSIST LEL
									local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_TRANVEL_RANGE)
									if (repairNearestID) then
										spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},{})
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									else
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},{})
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									end
								end
							else
								if (pAIjob[unitID] == 1) and ((#queue == 0) or (queue[1].id ~= CMD_RECLAIM)) then -- RECLAIM LEL
									local oreID = FindAnyOreInRange(x,z,MAX_TRANVEL_RANGE)
									if (oreID) then
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {oreID},{})
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									else
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},{})
										local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_TRANVEL_RANGE)
										if (repairNearestID) then
											spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},CMD_OPT_SHIFT)
										end
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT) -- NO ORE QQ
									end
								elseif (pAIjob[unitID] == 2) and ((#queue == 0) or (queue[1].id ~= CMD_REPAIR)) then -- ASSIST LEL
									local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_TRANVEL_RANGE)
									  if (repairNearestID) then
										spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},{})
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									else
										spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_TRANVEL_RANGE},{})
										spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_TRANVEL_RANGE},CMD_OPT_SHIFT)
									end
								end
							end
						end
						NextOrderTick[unitID] = f+ORDER_FRAME_LIMIT
					end
				elseif (NextOrderTick[unitID] < f) then
					if (pAIjob[unitID] == 0) then
						if not(goodMetal) and ((#queue == 0) or (queue[1].id ~= CMD_RECLAIM)) then -- RECLAIM LEL
							local oreID = FindAnyOreInRange(x,z,MAX_CARETAKER_RANGE)
							if (oreID) then
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {oreID},{})
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							else
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},{})
								local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_CARETAKER_RANGE)
								if (repairNearestID) then
									spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},CMD_OPT_SHIFT)
								end
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT) -- NO ORE QQ
							end
						elseif (#queue == 0) or (queue[1].id ~= CMD_REPAIR) then -- ASSIST LEL
							local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_CARETAKER_RANGE)
							if (repairNearestID) then
								spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},{})
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							else
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},{})
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							end
						end
					else
						if (pAIjob[unitID] == 1) and ((#queue == 0) or (queue[1].id ~= CMD_RECLAIM)) then -- RECLAIM LEL
							local oreID = FindAnyOreInRange(x,z,MAX_CARETAKER_RANGE)
							if (oreID) then
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {oreID},{})
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							else
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},{})
								local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_CARETAKER_RANGE)
								if (repairNearestID) then
									spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},CMD_OPT_SHIFT)
								end
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT) -- NO ORE QQ
							end
						elseif (pAIjob[unitID] == 2) and ((#queue == 0) or (queue[1].id ~= CMD_REPAIR)) then -- ASSIST LEL
							local repairNearestID = FindAnythingNearToRepair(unitID,x,z,MAX_CARETAKER_RANGE)
							if (repairNearestID) then
								spGiveOrderToUnit(unitID, CMD_REPAIR, {repairNearestID},{})
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							else
								spGiveOrderToUnit(unitID, CMD_REPAIR, {x,y,z,MAX_CARETAKER_RANGE},{})
								spGiveOrderToUnit(unitID, CMD_RECLAIM, {x,y,z,MAX_CARETAKER_RANGE},CMD_OPT_SHIFT)
							end
						end
					end
					NextOrderTick[unitID] = f+ORDER_FRAME_LIMIT
				end
				IgnoreWait[unitID] = false
				if (pAIretreat[unitID] < f) then
					pAIretreat[unitID] = 0
					pAIretreatIgnore[unitID] = {}
				end
			end
		end
	end
end

function widget:TeamChanged(teamID)
	if (spGetSpectatingState()) then
		widgetHandler:RemoveCallIn("GameFrame")
	end
	myTeamID = spGetMyTeamID()
end
  
function widget:GameFrame(n)
	if ((n%1800)==1) then
		if (#pAIcontrolled > 0) then
			local new_limit = 150
			local controlled = #pAIcontrolled
			while (controlled >= 50) do
				controlled = controlled - 50
				new_limit = new_limit + 150
			end
			if (new_limit > ORDER_FRAME_LIMIT_MIN) then
				ORDER_FRAME_LIMIT = new_limit
			end
		end
	end
	if ((n%900)==0) then
		if (#pAIcontrolled > 0) then
			local mCur, mMax, _, mInc = spGetTeamResources(myTeamID, "metal")
			if (mCur*1.3 >= mMax) then
				local controlled = 0
				local noJob = {}
				local miner = {}
				local assist = {}
				for unitID,_ in pairs(pAIcontrolled) do
					local unitDefID = spGetUnitDefID(unitID)
					if (pAIjob[unitID] == 0) and not(OnDefaultDefs[unitDefID]) then -- caretaker should do anything always
						noJob[unitID] = true
						controlled = controlled + 1
					elseif (pAIjob[unitID] == 1) then
						miner[unitID] = true
						controlled = controlled + 1
					elseif (pAIjob[unitID] == 2) then
						assist[unitID] = true
						controlled = controlled + 1
					end
				end
				local want_miner = floor(controlled/10*6)
				if (want_miner == 0) then
					  want_miner = 1
				end
				if (#miner < want_miner) then
				      for unitID,_ in pairs(assist) do
					    miner[unitID] = true
					    pAIjob[unitID] = 1
					    assist[unitID] = nil
					    if (#miner >= want_miner) then
						  break
					    end
				      end
				      for unitID,_ in pairs(noJob) do
					    miner[unitID] = true
					    pAIjob[unitID] = 1
					    noJob[unitID] = nil
					    if (#miner >= want_miner) then
						  break
					    end
				      end
				end
				for unitID,_ in pairs(noJob) do
					assist[unitID] = true
					pAIjob[unitID] = 2
					noJob[unitID] = nil
				end
			else
				for unitID,_ in pairs(pAIcontrolled) do
					pAIjob[unitID] = 0 -- no job! do anything!
				end
			end
		end
	end
	if ((n%30)==1) then
		local mCur, mMax, _, mInc = spGetTeamResources(myTeamID, "metal")
		local goodMetal = false
		if ((mMax - mCur) < mInc) or ((mCur*0.9) > mMax) then goodMetal = true end
		pAIthink(goodMetal,n)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

function widget:AllowCommand_GetWantedCommand()	
	return {[CMD_AUTOECO] = true}
end

function widget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function widget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_AUTOECO) then
		return true  -- command was not used
	end
	ToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_AUTOECO then
		local foundValidUnit = false
		local newEcoOrder = nil
		local selectedUnits = spGetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			local unitDefID = spGetUnitDefID(unitID)
			if EcoDefs[unitDefID] or UnitDefs[unitDefID].isFactory then
				if not foundValidUnit then
					foundValidUnit = true
					if pAIcontrolled[unitID] then
						newEcoOrder = false
					else
						newEcoOrder = true
					end
				end
				if (newEcoOrder) then
					pAIcontrolled[unitID] = true
					NextOrderTick[unitID] = -100
					pAIretreat[unitID] = 0
					pAIjob[unitID] = 0
					pAIretreatIgnore[unitID] = {}
					pAIwait[unitID] = false
				elseif (pAIcontrolled[unitID]) then
					pAIcontrolled[unitID] = nil
				end
			end
		end
		return true
	else
		local selectedUnits = spGetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			if pAIcontrolled[unitID] and not(IgnoreWait[unitID]) then
				pAIwait[unitID] = true
			end
		end
	end
end

function widget:CommandsChanged()
	local selectedUnits = spGetSelectedUnits()
	local foundGood = false
	local customCommands = widgetHandler.customCommands
	for i=1,#selectedUnits do
		local unitID = selectedUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		if not foundGood and (EcoDefs[unitDefID] or UnitDefs[unitDefID].isFactory) then
			foundGood = true
			local ecoOrder = pAIcontrolled[unitID] and 1 or 0
			table.insert(customCommands,
			{
				id      = CMD_AUTOECO,
				type    = CMDTYPE.ICON_MODE,
				name    = 'Auto Eco',
				action  = 'autoeco',
				tooltip	= 'Automaticly hunt down ore.',
				params 	= {ecoOrder, 'Autoeco Off','Autoeco On'}
			})
			end
		
		if foundGood then
			return
		end
	end 
end

function widget:UnitFinished(unitID, unitDefID)
	if spValidUnitID(unitID) and unitDefID and (mexDefs[unitDefID]) then
		ExtractorInView[unitID] = true
	end
end

function widget:UnitEnteredLos(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if (mexDefs[unitDefID]) then
		ExtractorInView[unitID] = true
	end	
end

function widget:UnitLeftLos(unitID)
	if (ExtractorInView[unitID]) then
		ExtractorInView[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if not EcoDefs[unitDefID] then
		return
	end
	
	ecoUnit[unitID] = true	
	if OnDefaultDefs[unitDefID] or pAIcontrolled[builderID] then
		pAIcontrolled[unitID] = true
		NextOrderTick[unitID] = -100
		pAIjob[unitID] = 0
		pAIretreat[unitID] = 0
		pAIretreatIgnore[unitID] = {}
		if (OnDefaultDefs[unitDefID]) then
			pAIwait[unitID] = false
		else
			pAIwait[unitID] = true
		end
	end
end


function widget:UnitDestroyed(unitID)
	if (ExtractorInView[unitID]) then
		ExtractorInView[unitID] = nil
	end
	
	if ecoUnit[unitID] then
		if (pAIcontrolled[unitID]) then
			pAIcontrolled[unitID] = nil
		end
		ecoUnit[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	local oremex = (tonumber(modOptions.oremex) == 1)
	local oredmg = (tonumber(modOptions.oremex_harm))
	
	if (oremex == false) then
		widgetHandler:RemoveWidget()
		return
	end
	
	if ((modOptions.oremex_harm ~= nil) and (oredmg == 0)) then
		widgetHandler:RemoveCallIn("DrawWorld")
		widgetHandler:RemoveCallIn("Update")
	end
	
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		if spValidUnitID(unitID) and unitDefID and (mexDefs[unitDefID]) then
			ExtractorInView[unitID] = true
		end
		if EcoDefs[unitDefID] then
			ecoUnit[unitID] = true			
			if OnDefaultDefs[unitDefID] then
				pAIcontrolled[unitID] = true
				NextOrderTick[unitID] = -100
				pAIjob[unitID] = 0
				pAIretreat[unitID] = 0
				pAIretreatIgnore[unitID] = {}
				pAIwait[unitID] = false
			end
		end
	end
	
	myTeamID = spGetMyTeamID()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------