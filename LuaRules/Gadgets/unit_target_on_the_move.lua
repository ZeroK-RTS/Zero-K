
function gadget:GetInfo()
  return {
	name 	= "Target on the move",
	desc	= "Adds a command to set unit target without using the normal command queue",
	author	= "Google Frog",
	date	= "September 25 2011",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then --SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spSetUnitTarget       = Spring.SetUnitTarget
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitLosState 	= Spring.GetUnitLosState
local spGiveOrderToUnit     = Spring.GiveOrderToUnit

local getMovetype = Spring.Utilities.getMovetype

local CMD_WAIT = CMD.WAIT

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

for i=1, #UnitDefs do
	local ud = UnitDefs[i]
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

local deadUnitID = 0 

--------------------------------------------------------------------------------
-- Commands

include("LuaRules/Configs/customcmds.h.lua")

local unitSetTargetCmdDesc = {
	id      = CMD_UNIT_SET_TARGET,
	type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
	name    = 'Set Target',
	action  = 'settarget',
    cursor  = 'Attack',
	tooltip	= 'Sets target for unit, not removed by move commands',
	hidden = true,
}

local unitSetTargetCircleCmdDesc = {
	id      = CMD_UNIT_SET_TARGET_CIRCLE,
	type    = CMDTYPE.ICON_UNIT_OR_AREA,
	name    = 'Set Target Circle',
	action  = 'settargetcircle',
    cursor  = 'Attack',
	tooltip	= 'Sets target for unit, not removed by move commands, circle version',
	hidden = false,
}

local unitCancelTargetCmdDesc = {
	id      = CMD_UNIT_CANCEL_TARGET,
	type    = CMDTYPE.ICON,
	name    = 'Cancel Target',
	action  = 'canceltarget',
	tooltip	= 'Removes target for unit',
	hidden = false,
}

--------------------------------------------------------------------------------
-- Gadget Interaction

function GG.GetUnitTarget(unitID)
	return unitById[unitID] and unit.data[unitById[unitID]] and unit.data[unitById[unitID]].targetID
end

--------------------------------------------------------------------------------
-- Target Handling

local function unitInRange(unitID, targetID, range)
    local dis = Spring.GetUnitSeparation(unitID, targetID) -- 2d range
    return dis and range and dis < range
end

local function locationInRange(unitID, x, y, z, range)
    local ux, uy, uz = spGetUnitPosition(unitID)
    return range and ((ux - x)^2 + (uz - z)^2) < range^2
end

local function setTarget(data)
    if spValidUnitID(data.id) then
        if not data.targetID then
            if locationInRange(data.id, data.x, data.y, data.z, data.range) then
                spSetUnitTarget(data.id, data.x, data.y, data.z)
            end
        elseif spValidUnitID(data.targetID) and spGetUnitAllyTeam(data.targetID) ~= data.allyTeam then
            if (not Spring.GetUnitIsCloaked(data.targetID)) and unitInRange(data.id, data.targetID, data.range) then
                spSetUnitTarget(data.id, data.targetID)
            end
        else
            return false
        end
    end
    return true
end

local function removeUnseenTarget(data)
	if data.targetID and not data.alwaysSeen and spValidUnitID(data.targetID) then
		local los = spGetUnitLosState(data.targetID, data.allyTeam, false)
		if not (los and (los.los or los.radar)) then
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
        spSetUnitTarget(unitID,deadUnitID)
        if setTarget(data) then
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
		spSetUnitTarget(unitID,deadUnitID)
	end
	if unitDefID and validUnits[unitDefID] and unitById[unitID] then
		if waitWaitUnits[unitDefID] then
			spSetUnitTarget(unitID,deadUnitID)
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
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

    _G.unit = unit
    _G.drawPlayerAlways = drawPlayerAlways
    
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
            range = UnitDefs[unitDefID].maxWeaponRange,
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
			range = UnitDefs[unitDefID].maxWeaponRange,
			alwaysSeen = tud and (tud.isBuilding == true or tud.maxAcc == 0),
		})
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_UNIT_CANCEL_TARGET] = true, [CMD_UNIT_SET_TARGET] = true, [CMD_UNIT_SET_TARGET_CIRCLE] = true}
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
					bot = cmdParams[6]
					top = cmdParams[3]
				end
				
				local units = CallAsTeam(team,
					function ()
					return Spring.GetUnitsInRectangle(left,top,right,bot) end)
				
				setTargetClosestFromList(unitID, unitDefID, team, units)
				
			elseif #cmdParams == 3 or (#cmdParams == 4 and cmdParams[4] == 0) then
                addUnit(unitID, {
                    id = unitID, 
                    x = cmdParams[1], 
                    y = CallAsTeam(teamID, function () return spGetGroundHeight(cmdParams[1],cmdParams[3]) end), 
                    z = cmdParams[3], 
                    allyTeam = spGetUnitAllyTeam(unitID), 
                    range = UnitDefs[unitDefID].maxWeaponRange
                })
			
			elseif #cmdParams == 4 then
			
				local team = Spring.GetUnitTeam(unitID)
				
				if not team then
					return false
				end
				
				local units = CallAsTeam(team,
					function ()
					return Spring.GetUnitsInCylinder(cmdParams[1],cmdParams[3],cmdParams[4]) end)
					
				setTargetClosestFromList(unitID, unitDefID, team, units)
				
            elseif #cmdParams == 1 then
                local targetUnitDef = spGetUnitDefID(cmdParams[1])
				local tud = targetUnitDef and UnitDefs[targetUnitDef]
				addUnit(unitID, {
                    id = unitID, 
                    targetID = cmdParams[1], 
                    allyTeam = spGetUnitAllyTeam(unitID), 
                    range = UnitDefs[unitDefID].maxWeaponRange,
					alwaysSeen = tud and (tud.isBuilding == true or tud.maxAcc == 0),
                })
            end
        end
        return false  -- command was used
    elseif cmdID == CMD_UNIT_CANCEL_TARGET then
		if validUnits[unitDefID] then
			removeUnit(unitID)
		end
        return false  -- command was used
    end
	return true  -- command was not used
end

--------------------------------------------------------------------------------
-- Target update

function gadget:GameFrame(n)
	if n%16 == 15 then -- timing synced with slow update to reduce attack jittering
        -- 15 causes attack command to override target command
        -- 0 causes target command to take precedence
        
        local toRemove = {count = 0, data = {}}
        for i = 1, unit.count do
            if not setTarget(unit.data[i]) then
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

--------------------------------------------------------------------------------
-- Drawing toggle goes through synced for no good reason

function gadget:RecvLuaMsg(msg, playerID)
    if msg == "target_move_selectionlow" then
        drawPlayerAlways[playerID] = 5 --"Hide commands except if you select unit(s)"
	elseif msg == "target_move_all" then
        drawPlayerAlways[playerID] = 4 --"Always display commands for all units at all time."
    elseif msg == "target_move_selection" then
        drawPlayerAlways[playerID] = 3 --"Always display commands for selected units only, but if you press SHIFT it display commands for all units."
	elseif msg == "target_move_shift" then
        drawPlayerAlways[playerID] = 2 --"Hide commands of all units, but if you press SHIFT it display them again."
    elseif msg == "target_move_minimal" then
        drawPlayerAlways[playerID] = 1 --"Hide commands except if you select unit(s) and pressing SHIFT."
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glVertex 		= gl.Vertex
local glPushAttrib  = gl.PushAttrib
local glLineStipple = gl.LineStipple
local glDepthTest   = gl.DepthTest
local glLineWidth   = gl.LineWidth
local glColor       = gl.Color
local glBeginEnd    = gl.BeginEnd
local glPopAttrib   = gl.PopAttrib
local glCreateList  = gl.CreateList
local glCallList    = gl.CallList
local glDeleteList  = gl.DeleteList
local GL_LINES      = GL.LINES

local spIsUnitInView 		= Spring.IsUnitInView
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitLosState 	= Spring.GetUnitLosState
local spValidUnitID 		= Spring.ValidUnitID
local spGetMyAllyTeamID 	= Spring.GetMyAllyTeamID 	
local spGetMyTeamID         = Spring.GetMyTeamID
local spIsUnitSelected      = Spring.IsUnitSelected
local spGetModKeyState      = Spring.GetModKeyState
local spIsGUIHidden         = Spring.IsGUIHidden
local spGetGameFrame        = Spring.GetGameFrame
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount

local myAllyTeam = spGetMyAllyTeamID()
local myTeam = spGetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()
local defaultState = 1

local function unitDraw(u1, u2)
	glVertex(spGetUnitPosition(u1))
	glVertex(CallAsTeam(myTeam, function () return spGetUnitPosition(u2) end))
end

local function unitDrawVisible(u1, u2)
	glVertex(spGetUnitPosition(u1))
	glVertex(spGetUnitPosition(u2))
end

local function terrainDraw(u, x, y, z)
    glVertex(spGetUnitPosition(u))
	glVertex(x,y,z)
end

local function CommandVisibleState(unitID,mode, shift)
	local drawThis =(mode==4) or
					(mode==2 and shift) or 
					(mode==3 and (spIsUnitSelected(unitID) or shift)) or
					(mode==1 and (spIsUnitSelected(unitID) and shift)) or
					(mode==5 and spIsUnitSelected(unitID))
	return drawThis
end

local function drawCommands(unit, mode,shift)
    for i = 1, unit.count do
        local u = unit.data[i]
        if select(1, spGetSpectatingState()) then
            if CommandVisibleState(u.id, mode, shift) and spValidUnitID(u.id) then
                if not u.targetID then
                    terrainDraw(u.id, u.x, u.y, u.z)
                elseif spValidUnitID(u.targetID) then
                    unitDrawVisible(u.id, u.targetID)
                end
            end
        elseif u.allyTeam == myAllyTeam and CommandVisibleState(u.id, mode, shift) and spValidUnitID(u.id) then
            if not u.targetID then
                terrainDraw(u.id, u.x, u.y, u.z)
            elseif spValidUnitID(u.targetID) then
                local los = spGetUnitLosState(u.targetID, myAllyTeam, false)
                if los and (los.los or los.radar) then
                    unitDraw(u.id, u.targetID)
                end
            end
        end
    end
end

local drawList = 0
local drawAnything = false

function gadget:DrawWorld()
    if drawAnything then
        glPushAttrib(GL.LINE_BITS)
        glLineStipple(true)
        glDepthTest(false)
        glLineWidth(1.4)
        glColor(1, 0.75, 0, 1)
        glCallList(drawList)
        glColor(1,1,1,1)
        glLineStipple(false)
        glPopAttrib()
    end
end

local function gameFrame()
    if spIsGUIHidden() then 
        drawAnything = false
		return 
    end
    local unit = SYNCED.unit
    if unit then
		local alt,ctrl,meta,shift = spGetModKeyState()
        local mode = SYNCED.drawPlayerAlways[myPlayerID] or defaultState
		
        if (mode==4) or 
		(mode==2 and shift) or 
		(mode==3 and (spGetSelectedUnitsCount()>0 or shift)) or
		(mode==1 and (spGetSelectedUnitsCount()>0 and shift)) or 
		(mode==5 and spGetSelectedUnitsCount()>0)
		then
            
            drawAnything = false
            for i = 1, unit.count do
                local u = unit.data[i]
                if (u.allyTeam == myAllyTeam or select(1, spGetSpectatingState())) and CommandVisibleState(u.id,mode, shift) and spValidUnitID(u.id) then
                    drawAnything = true
                    break
                end
            end
            
            if drawAnything then
                glDeleteList(drawList)
                drawList = glCreateList(function () glBeginEnd(GL_LINES, drawCommands, unit, mode,shift) end)
                return
            end
        end
    end
    
    drawAnything = false
end

local lastFrame = 0
function gadget:Update()
    local f = spGetGameFrame()
    if lastFrame < f then
        lastFrame = f
        gameFrame()
    end
end

end