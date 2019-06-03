--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
	name    = "Target on the move",
	desc    = "Adds a command to set unit target without using the normal command queue",
	author  = "Google Frog",
	date    = "September 25 2011",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
  }
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
include("LuaRules/Configs/customcmds.h.lua")

if not gadgetHandler:IsSyncedCode() then
	function gadget:Initialize()
		Spring.SetCustomCommandDrawData(CMD_UNIT_SET_TARGET, "SetTarget", {1.0, 0.75, 0.0, 0.7}, true)
		Spring.SetCustomCommandDrawData(CMD_UNIT_SET_TARGET_CIRCLE, "SetTarget", {1.0, 0.75, 0.0, 0.7}, true)
		Spring.AssignMouseCursor("SetTarget", "cursortarget", true, false)
	end
	
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spSetUnitTarget       = Spring.SetUnitTarget
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitLosState     = Spring.GetUnitLosState
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spSetUnitRulesParam   = Spring.SetUnitRulesParam

local getMovetype = Spring.Utilities.getMovetype

local CMD_WAIT = CMD.WAIT
local CMD_FIRE_STATE = CMD.FIRE_STATE

-- Constans
local TARGET_NONE   = 0
local TARGET_GROUND = 1
local TARGET_UNIT   = 2
--------------------------------------------------------------------------------
-- Config

-- Unseen targets will be removed after at least UNSEEN_TIMEOUT*USEEN_UPDATE_FREQUENCY frames 
-- and at most (UNSEEN_TIMEOUT+1)*USEEN_UPDATE_FREQUENCY frames/
local USEEN_UPDATE_FREQUENCY = 45
local UNSEEN_TIMEOUT = 2

--------------------------------------------------------------------------------
-- Globals

local validUnits = {}
local waitWaitUnits = {}
local weaponCounts = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	weaponCounts[i] = (ud.weapons and #ud.weapons)
	if ((not (ud.canFly and (ud.isBomber or ud.isBomberAirUnit))) and 
			ud.canAttack and ud.canMove and ud.maxWeaponRange and ud.maxWeaponRange > 0) or ud.isFactory then
		if getMovetype(ud) == 0 then
			waitWaitUnits[i] = true
		end
		validUnits[i] = true
	end
end

local unitById = {} -- unitById[unitID] = position of unitID in unit
local unit = {count = 0, data = {}} -- data holds all unitID data

local drawPlayerAlways = {}

--------------------------------------------------------------------------------
-- Commands

local allyTargetUnits = {
	[UnitDefNames["jumpsumo"].id] = true,
	[UnitDefNames["amphlaunch"].id] = true,
}

local unitSetTargetCmdDesc = {
	id      = CMD_UNIT_SET_TARGET,
	type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
	name    = 'Set Target',
	action  = 'settarget',
	cursor  = 'SetTarget',
	tooltip = 'Set Target: Set a priority target that is indepdent of the units command queue.',
	hidden = true,
}

local unitSetTargetCircleCmdDesc = {
	id      = CMD_UNIT_SET_TARGET_CIRCLE,
	type    = CMDTYPE.ICON_UNIT_OR_AREA,
	name    = 'Set Target Circle',
	action  = 'settargetcircle',
	cursor  = 'SetTarget',
	tooltip = 'Set Target: Set a priority target that is indepdent of the units command queue.',
	hidden = false,
}

local unitCancelTargetCmdDesc = {
	id      = CMD_UNIT_CANCEL_TARGET,
	type    = CMDTYPE.ICON,
	name    = 'Cancel Target',
	action  = 'canceltarget',
	tooltip = 'Cancel Target: Cancel the units priority target.',
	hidden = false,
}

--------------------------------------------------------------------------------
-- Target Handling

local function unitInRange(unitID, unitDefID, targetID)
	return true
	--local dis = Spring.GetUnitSeparation(unitID, targetID) -- 2d range
	--local _, _, _, ux, uy, uz = spGetUnitPosition(unitID, true)
	--local _, _, _, tx, ty, tz = spGetUnitPosition(targetID, true)
	--local range = Spring.Utilities.GetUpperEffectiveWeaponRange(unitDefID, uy - ty) + 50
	--return dis and range and dis < range
end

local function locationInRange(unitID, unitDefID, x, y, z)
	return true
	--local _, _, _, ux, uy, uz = spGetUnitPosition(unitID, true)
	--local range = Spring.Utilities.GetUpperEffectiveWeaponRange(unitDefID, uy - y) + 50
	--return range and ((ux - x)^2 + (uz - z)^2) < range^2
end

local function clearTarget(unitID)
	spSetUnitTarget(unitID, nil) -- The second argument is needed.
	spSetUnitRulesParam(unitID,"target_type",TARGET_NONE)
end

local function IsValidTargetBasedOnAllyTeam(targetID, myAllyTeamID)
	if Spring.GetUnitNeutral(targetID) then
		return Spring.GetUnitRulesParam(targetID, "avoidAttackingNeutral") ~= 1
	end
	return spGetUnitAllyTeam(targetID) ~= myAllyTeamID
end

local function setTarget(data, sendToWidget)
	if spValidUnitID(data.id) then
		if not data.targetID then
			if locationInRange(data.id, data.unitDefID, data.x, data.y, data.z) then
				spSetUnitTarget(data.id, data.x, data.y, data.z)
				GG.UnitSetGroundTarget(data.id)
			end
			if sendToWidget then
				spSetUnitRulesParam(data.id,"target_type",TARGET_GROUND)
				spSetUnitRulesParam(data.id,"target_x",data.x)
				spSetUnitRulesParam(data.id,"target_y",data.y)
				spSetUnitRulesParam(data.id,"target_z",data.z)
			end
		elseif spValidUnitID(data.targetID) and (data.allyAllowed or IsValidTargetBasedOnAllyTeam(data.targetID, data.allyTeam)) then
			if (not Spring.GetUnitIsCloaked(data.targetID)) and unitInRange(data.id, data.unitDefID, data.targetID) and (data.id ~= data.targetID) then
				spSetUnitTarget(data.id, data.targetID, false, true)
			end
			if sendToWidget then
				spSetUnitRulesParam(data.id,"target_type",TARGET_UNIT)
				spSetUnitRulesParam(data.id,"target_id",data.targetID)
			end
		else
			return false
		end
	end
	return true
end

local function removeUnseenTarget(data)
	if data.targetID and not data.alwaysSeen and spValidUnitID(data.targetID) then
		local los = spGetUnitLosState(data.targetID, data.allyTeam, true)
		if not los or (los % 4 == 0) then
			if data.unseenTargetTimer == UNSEEN_TIMEOUT then
				return true
			elseif not data.unseenTargetTimer then
				data.unseenTargetTimer = 1
			else
				data.unseenTargetTimer = data.unseenTargetTimer + 1
			end
		elseif data.unseenTargetTimer then
			data.unseenTargetTimer = nil
		end
	end
end

--------------------------------------------------------------------------------
-- Unit adding/removal

local function addUnit(unitID, data)
	if spValidUnitID(unitID) then
		-- clear current traget
		clearTarget(unitID)
		if setTarget(data, true) then
			if unitById[unitID] then
				unit.data[unitById[unitID]] = data
			else
				unit.count = unit.count + 1
				unit.data[unit.count] = data
				unitById[unitID] = unit.count
			end
		end
	end
end

local function removeUnit(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	if not (unitDefID and waitWaitUnits[unitDefID]) then
		clearTarget(unitID)
	end
	if unitDefID and validUnits[unitDefID] and unitById[unitID] then
		if waitWaitUnits[unitDefID] then
			clearTarget(unitID)
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
		end
		if unitById[unitID] ~= unit.count then
			unit.data[unitById[unitID]] = unit.data[unit.count]
			unitById[unit.data[unit.count].id] = unitById[unitID]
		end
		unit.data[unit.count] = nil
		unit.count = unit.count - 1
		unitById[unitID] = nil
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_SET_TARGET)
	gadgetHandler:RegisterCMDID(CMD_UNIT_CANCEL_TARGET)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
	if validUnits[unitDefID] then
		spInsertUnitCmdDesc(unitID, unitSetTargetCmdDesc)
		spInsertUnitCmdDesc(unitID, unitSetTargetCircleCmdDesc)
		spInsertUnitCmdDesc(unitID, unitCancelTargetCmdDesc)
	end
	
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	if unitById[facID] and validUnits[unitDefID] then
		local data = unit.data[unitById[facID]]
		addUnit(unitID, {
			id = unitID, 
			targetID = data.targetID, 
			x = data.x, y = data.y, z = data.z,
			allyTeam = spGetUnitAllyTeam(unitID), 
			unitDefID = unitDefID,
			alwaysSeen = data.alwaysSeen,
		})
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	removeUnit(unitID)
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	removeUnit(unitID)
end

--------------------------------------------------------------------------------
-- Command Tracking

local function disSQ(x1,y1,x2,y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

local function setTargetClosestFromList(unitID, unitDefID, team, choiceUnits)

	local ux, uy, uz = Spring.GetUnitPosition(unitID)
				
	local bestDis = false
	local bestUnit = false

	if ux and choiceUnits then
		for i = 1, #choiceUnits do
			local tTeam = Spring.GetUnitTeam(choiceUnits[i])
			if tTeam and (not Spring.AreTeamsAllied(team,tTeam)) then
				local tx,ty,tz = Spring.GetUnitPosition(choiceUnits[i])
				if tx then
					local newDis = disSQ(ux,uz,tx,tz)
					if (not bestDis) or bestDis > newDis then
						bestDis = newDis
						bestUnit = choiceUnits[i]
					end
				end
			end
		end
	end
	
	if bestUnit then
		local targetUnitDef = spGetUnitDefID(bestUnit)
		local tud = targetUnitDef and UnitDefs[targetUnitDef]
		addUnit(unitID, {
			id = unitID, 
			targetID = bestUnit, 
			allyTeam = spGetUnitAllyTeam(unitID), 
			unitDefID = unitDefID,
			alwaysSeen = tud and tud.isImmobile,
		})
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_FIRE_STATE] = true, [CMD_UNIT_CANCEL_TARGET] = true, [CMD_UNIT_SET_TARGET] = true, [CMD_UNIT_SET_TARGET_CIRCLE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
	if cmdID == CMD_UNIT_SET_TARGET or cmdID == CMD_UNIT_SET_TARGET_CIRCLE then
		if validUnits[unitDefID] then
			if #cmdParams == 6 then
				local team = Spring.GetUnitTeam(unitID)
				
				if not team then
					return false
				end
				
				local top, bot, left, right
				if cmdParams[1] < cmdParams[4] then
					left = cmdParams[1]
					right = cmdParams[4]
				else
					left = cmdParams[4]
					right = cmdParams[1]
				end
				
				if cmdParams[3] < cmdParams[6] then
					top = cmdParams[3]
					bot = cmdParams[6]
				else
					top = cmdParams[6]
					bot = cmdParams[3]
				end
				
				local units = CallAsTeam(team,
					function ()
						return Spring.GetUnitsInRectangle(left,top,right,bot)
					end
				)
				
				setTargetClosestFromList(unitID, unitDefID, team, units)
				
			elseif #cmdParams == 3 or (#cmdParams == 4 and cmdParams[4] == 0) then
				addUnit(unitID, {
					id = unitID, 
					x = cmdParams[1], 
					y = CallAsTeam(teamID, function () return spGetGroundHeight(cmdParams[1],cmdParams[3]) end), 
					z = cmdParams[3], 
					allyTeam = spGetUnitAllyTeam(unitID), 
					unitDefID = unitDefID,
				})
			
			elseif #cmdParams == 4 then
			
				local team = Spring.GetUnitTeam(unitID)
				
				if not team then
					return false
				end
				
				local units = CallAsTeam(team,
					function ()
						return Spring.GetUnitsInCylinder(cmdParams[1],cmdParams[3],cmdParams[4])
					end
				)
				
				setTargetClosestFromList(unitID, unitDefID, team, units)
				
			elseif #cmdParams == 1 then
				local targetUnitDef = spGetUnitDefID(cmdParams[1])
				local tud = targetUnitDef and UnitDefs[targetUnitDef]
				addUnit(unitID, {
					id = unitID, 
					targetID = cmdParams[1], 
					allyTeam = spGetUnitAllyTeam(unitID), 
					allyAllowed = allyTargetUnits[unitDefID],
					unitDefID = unitDefID,
					alwaysSeen = tud and tud.isImmobile,
				})
			end
		end
		return false  -- command was used
	elseif cmdID == CMD_UNIT_CANCEL_TARGET then
		if validUnits[unitDefID] then
			removeUnit(unitID)
		end
		return false  -- command was used
	elseif cmdID == CMD_FIRE_STATE and weaponCounts[unitDefID] then
		-- Cancel target when firestate is not fire at will
		if cmdParams and (cmdParams[1] or 0) < 2 then
			for i = 1, weaponCounts[unitDefID] do
				Spring.UnitWeaponHoldFire(unitID, i)
			end
		end
	end
	return true  -- command was not used
end

--------------------------------------------------------------------------------
-- Gadget Interaction

function GG.GetUnitTarget(unitID)
	return unitById[unitID] and unit.data[unitById[unitID]] and unit.data[unitById[unitID]].targetID
end

function GG.GetUnitTargetGround(unitID)
	if unitById[unitID] and unit.data[unitById[unitID]] then
		return not unit.data[unitById[unitID]].targetID
	end
	return false
end

function GG.SetUnitTarget(unitID, targetID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not (unitDefID and validUnits[unitDefID]) then
		return
	end
	local targetUnitDef = spGetUnitDefID(targetID)
	local tud = targetUnitDef and UnitDefs[targetUnitDef]
	
	if tud then
		addUnit(unitID, {
			id = unitID, 
			targetID = targetID, 
			allyTeam = spGetUnitAllyTeam(unitID), 
			allyAllowed = allyTargetUnits[unitDefID],
			unitDefID = unitDefID,
			alwaysSeen = tud.isImmobile,
		})
	end
end

--------------------------------------------------------------------------------
-- Target update

function gadget:GameFrame(n)
	if n%16 == 15 then -- timing synced with slow update to reduce attack jittering
		-- 15 causes attack command to override target command
		-- 0 causes target command to take precedence

		local toRemove = {count = 0, data = {}}
		for i = 1, unit.count do
			if not setTarget(unit.data[i], false) then
				toRemove.count = toRemove.count + 1
				toRemove.data[toRemove.count] = unit.data[i].id
			end
		end

		for i = 1, toRemove.count do
			removeUnit(toRemove.data[i])
		end
	end

	if n%USEEN_UPDATE_FREQUENCY == 0 then
		local toRemove = {count = 0, data = {}}
		for i = 1, unit.count do
			if removeUnseenTarget(unit.data[i]) then
				toRemove.count = toRemove.count + 1
				toRemove.data[toRemove.count] = unit.data[i].id
			end
		end
		for i = 1, toRemove.count do
			removeUnit(toRemove.data[i])
		end
	end
	
end
