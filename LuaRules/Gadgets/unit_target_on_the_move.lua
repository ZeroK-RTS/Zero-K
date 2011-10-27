
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

--------------------------------------------------------------------------------
-- Globals

local unitById = {} -- unitById[unitID] = position of unitID in unit
local unit = {count = 0, data = {}} -- data holds all unitID data

local drawPlayerAlways = {}

--------------------------------------------------------------------------------
-- Commands

include("LuaRules/Configs/customcmds.h.lua")

local unitSetTargetCmdDesc = {
	id      = CMD_UNIT_SET_TARGET,
	type    = CMDTYPE.ICON_UNIT_OR_MAP,
	name    = 'Set Target',
	action  = 'settarget',
    cursor  = 'Attack',
	tooltip	= 'Sets target for unit, not removed by move commands',
	hidden = true,
}

local unitCancelTargetCmdDesc = {
	id      = CMD_UNIT_CANCEL_TARGET,
	type    = CMDTYPE.ICON,
	name    = 'Cancel Target',
	action  = 'canceltarget',
	tooltip	= 'Removes target for unit',
	hidden = true,
}

--------------------------------------------------------------------------------
-- Target setting

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
            if unitInRange(data.id, data.targetID, data.range) then
                spSetUnitTarget(data.id, data.targetID)
            end
        else
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Unit adding/removal

local function validUnit(unitDefID)
    return UnitDefs[unitDefID] and UnitDefs[unitDefID].canAttack and UnitDefs[unitDefID].canMove
end

local function addUnit(unitID, data)
    if spValidUnitID(unitID) then
        spSetUnitTarget(unitID, 0)
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
    if spValidUnitID(unitID) then
        spSetUnitTarget(unitID, 0)
    end
    
    if unitById[unitID] then
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
	-- add those with weapons
	if validUnit(unitDefID) then -- units that cannot move do not need the target command
		spInsertUnitCmdDesc(unitID, unitSetTargetCmdDesc)
        spInsertUnitCmdDesc(unitID, unitCancelTargetCmdDesc)
	end
	
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
    if unitById[facID] and validUnit(unitDefID) then
        local data = unit.data[unitById[facID]]
        addUnit(unitID, {
            id = unitID, 
            targetID = data.targetID, 
            x = data.x, y = data.y, z = data.z,
            allyTeam = spGetUnitAllyTeam(unitID), 
            range = UnitDefs[unitDefID].maxWeaponRange
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

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
    
    if cmdID == CMD_UNIT_SET_TARGET  then
        if UnitDefs[unitDefID] and not UnitDefs[unitDefID].canFly and UnitDefs[unitDefID].maxWeaponRange and UnitDefs[unitDefID].maxWeaponRange > 0 then
            if #cmdParams == 3 then
                addUnit(unitID, {
                    id = unitID, 
                    x = cmdParams[1], 
                    y = CallAsTeam(teamID, function () return spGetGroundHeight(cmdParams[1],cmdParams[3]) end), 
                    z = cmdParams[3], 
                    allyTeam = spGetUnitAllyTeam(unitID), 
                    range = UnitDefs[unitDefID].maxWeaponRange
                })
            elseif #cmdParams == 1 then
                addUnit(unitID, {
                    id = unitID, 
                    targetID = cmdParams[1], 
                    allyTeam = spGetUnitAllyTeam(unitID), 
                    range = UnitDefs[unitDefID].maxWeaponRange
                })
            end
        end
        return false  -- command was used
    elseif cmdID == CMD_UNIT_CANCEL_TARGET then
        removeUnit(unitID)
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
        
        toRemove = {count = 0, data = {}}
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
end

--------------------------------------------------------------------------------
-- Drawing toggle goes through synced for no good reason

function gadget:RecvLuaMsg(msg, playerID)
    if msg == "target_on_the_move_draw_always" then
        drawPlayerAlways[playerID] = true
    elseif msg == "target_on_the_move_draw_normal" then
        drawPlayerAlways[playerID] = false
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

local myAllyTeam = spGetMyAllyTeamID()
local myTeam = spGetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()

local function unitDraw(u1, u2)
	glVertex(spGetUnitPosition(u1))
	glVertex(CallAsTeam(myTeam, function () return spGetUnitPosition(u2) end))
end

local function terrainDraw(u, x, y, z)
    glVertex(spGetUnitPosition(u))
	glVertex(x,y,z)
end

local function drawCommands(unit, always)
    for i = 1, unit.count do
        local u = unit.data[i]
        if u.allyTeam == myAllyTeam and (always or spIsUnitSelected(u.id)) and spValidUnitID(u.id) then
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
        glLineStipple(1, 2047)
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
        return 
    end
    
    if SYNCED.unit then
		local alt,ctrl,meta,shift = spGetModKeyState()
        local always = shift or SYNCED.drawPlayerAlways[myPlayerID]
        local unit = SYNCED.unit
        
        drawAnything = false
        for i = 1, unit.count do
            local u = unit.data[i]
            if u.allyTeam == myAllyTeam and (always or spIsUnitSelected(u.id)) and spValidUnitID(u.id) then
                drawAnything = true
                break
            end
        end
        
        if drawAnything then
            glDeleteList(drawList)
            drawList = glCreateList(function () glBeginEnd(GL_LINES, drawCommands, unit, always) end)
            return
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