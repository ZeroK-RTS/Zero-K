function gadget:GetInfo()
	return {
		name = "Unit Dodge",
		desc = "calculates obsticle dodge vector for units",
		author = "petturtle",
		date = "2021",
		layer = 0,
		enabled = true
	}
end

local DEBUG = false

if gadgetHandler:IsSyncedCode() then

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local Config = VFS.Include("LuaRules/Configs/projectile_dodge_defs.lua")
local ProjectileTargets = VFS.Include("LuaRules/Utilities/projectile_targets.lua") 

local CACHE_TIME = 15
local DODGE_HEIGHT = 50
local QUERY_RADIUS = 300
local SAFETY_RADIUS = 30
local RAY_DISTANCE = 80
local MAX_DISTANCE = 80000

local abs = math.abs
local max = math.max
local min = math.min
local cos = math.cos
local sin = math.sin
local acos = math.acos
local sqrt = math.sqrt

local vector = Spring.Utilities.Vector

local spIsPosInLos = Spring.IsPosInLos
local spValidUnitID = Spring.ValidUnitID
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitStates = Spring.GetUnitStates
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitDirection = Spring.GetUnitDirection
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileGravity = Spring.GetProjectileGravity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local markerX = 0
local markerZ = 0

local function PlaceMarker(x, z, msg)
    Spring.MarkerErasePosition(markerX, 0, markerZ)
    markerX = x
    markerZ = z
    Spring.MarkerAddPoint(markerX, 0, markerZ, msg)
end

local idleDodgeCmdDesc = {
	id      = CMD_IDLE_DODGE,
	type    = CMDTYPE.ICON_MODE,
	name    = "Idle Dodge.",
	action  = 'idledodge',
	tooltip	= '.',
	params 	= {0, "Always", "Not on Hold Pos", "Never"}
}

local moveDodgeCmdDesc = {
	id      = CMD_MOVE_DODGE,
	type    = CMDTYPE.ICON_MODE,
	name    = "Move Dodge.",
	action  = 'movedodge',
	tooltip	= '.',
	params 	= {0, "Always", "Not on Hold Pos", "Never"}
}

-- obsticle
-- [1] = target
-- [2] = target y
-- [3] = projID
-- [4] = projDefID

local hitCache = {}
local idleStates = {}
local moveStates = {}

local function GetHitData(obsticle)
    local currFrame = spGetGameFrame()
    local hitData = hitCache[obsticle[3]]
    if hitData and (hitData.expiredFrame == nil or hitData.expiredFrame > currFrame) then
        return hitData
    end

    local config = Config[obsticle[4]]
    local line, eta = ProjectileTargets(config, obsticle[3], obsticle[1], obsticle[2], obsticle[2] + DODGE_HEIGHT)
    hitData = {
        eta = currFrame + eta,
        line = line,
        radius = config.aoe,
    }

    if config.dynamic then
        hitData.expiredFrame = currFrame + CACHE_TIME
    end

    hitCache[obsticle[3]] = hitData
    return hitData
end

local function GetNearestPointToLine(point, a, b)
	local line = vector.Subtract(b, a)
	if line[1] ~= 0 or line[2] ~= 0 then
		local t = ((point[1]-a[1])*line[1] + (point[2] - a[2])*line[2]) / (line[1]*line[1] + line[2]*line[2])
		if t < 0 then
			return vector.Clone(a)
		elseif t > 1 then
			return vector.Clone(b)
		else
			return vector.Add(a, vector.Mult(t, line))
		end
	end
	return vector.Clone(a)
end

local function QueryHitData(unitID, uRadius, updateRate)
    local query = {}
    local currFrame = spGetGameFrame()
    local allyTeam = spGetUnitAllyTeam(unitID)
    local uPosX, _, uPosZ = spGetUnitPosition(unitID)
    local obsticles = GG.MapObsticles(uPosX, uPosZ, QUERY_RADIUS, {"projectiles"})
    for i = 1, #obsticles do
        local obsticle = obsticles[i]
        local pPos, pPosY = vector.New3(spGetProjectilePosition(obsticle[3]))
    	if spIsPosInLos(pPos[1], pPosY, pPos[2], allyTeam) then
            local hitData = GetHitData(obsticle)
            local hitTime = hitData.eta - currFrame
            if hitTime > 0 then
                local uPos = {uPosX, uPosZ}
                local unitDefID = spGetUnitDefID(unitID)
                local line = hitData.line
                local near = GetNearestPointToLine(uPos, line[1], line[3])
                local speed = UnitDefs[unitDefID].speed
                local distance = vector.Distance(uPos, near) + hitData.radius + uRadius + SAFETY_RADIUS
                local dodgeTime = distance / speed * updateRate
                if dodgeTime > hitTime then
                    hitData.near = near
                    query[#query+1] = hitData
                end
            end
        end
    end
    return query
end

local function BoidDodge(query, uPos, uDir, uRadius)
    local dodge, dodgeMag = {0, 0}, 0
    for i = 1, #query do
        local hitData = query[i]
        local line = hitData.line
        local hitPoint = hitData.near
        if uPos[1] == hitPoint[1] and uPos[2] == hitPoint[2] then
            local lineDir = vector.Subtract(line[3], line[1])
            dodge = vector.Add(dodge, {-lineDir[2], lineDir[1]})
            dodgeMag = max(dodgeMag, hitData.radius + uRadius + SAFETY_RADIUS + SAFETY_RADIUS)
        else
            local dodgeRadius = vector.Distance(uPos, hitPoint)
            if dodgeRadius < hitData.radius + uRadius + SAFETY_RADIUS then
                local hitNormal = vector.Norm(1,  vector.Subtract(uPos, hitPoint))
                dodge = vector.Add(dodge, hitNormal)
                dodgeMag = max(dodgeMag, hitData.radius + uRadius + SAFETY_RADIUS + SAFETY_RADIUS - dodgeRadius)
            end
        end
    end
    dodge = vector.Norm(dodgeMag, dodge)
    return dodge, dodgeMag
end

local function RayDodge(query, uPos, uDir, rDir, uRadius)
    local closestPoint, closestRadius, closestDir, closestDistance = nil, 0, 0, 999999
    for i = 1, #query do
        local hitData = query[i]
        local line = hitData.line
        local lineDir = vector.Subtract(line[3], line[1])
        local intersection = vector.Intersection(uPos, rDir, line[1], lineDir)
        if intersection then
            local unitToInter = vector.Subtract(intersection, uPos)
            if vector.Dot(rDir, unitToInter) >= 0 then
                local cNear = GetNearestPointToLine(intersection, line[1], line[3])
                local cDistance = vector.Distance(cNear, intersection)
                if cDistance < hitData.radius + uRadius + SAFETY_RADIUS then
                    local cNearToUnit = vector.Subtract(uPos, cNear)
                    local angle = vector.AngleTo(cNearToUnit, lineDir)
                    local dodgePointDistance = hitData.radius / sin(abs(angle)) + SAFETY_RADIUS
                    local dodgePoint = vector.Add(cNear, vector.Norm(dodgePointDistance, cNearToUnit))
                    local distance = vector.Distance(dodgePoint, uPos)
                    if distance < closestDistance then
                        closestDir = lineDir
                        closestPoint = dodgePoint
                        closestRadius = hitData.radius
                        closestDistance = distance
                    end
                end
            end
        end
    end

    if closestPoint then
        if vector.Dot(uDir, closestDir) < 0 then
            closestDir = {-closestDir[1], -closestDir[2]}
        end
        local dodgeRadius = uRadius + closestRadius + SAFETY_RADIUS + SAFETY_RADIUS
        local target = vector.Add(closestPoint, vector.Norm(dodgeRadius, closestDir))
        local origTarget = vector.Add(uPos, rDir)
        if vector.Distance(uPos, target) < vector.Distance(uPos, origTarget) then
            local toTarget = vector.Norm(RAY_DISTANCE, vector.Subtract(target, uPos))
            return uPos[1] + toTarget[1], uPos[2] + toTarget[2], RAY_DISTANCE
        end
    end

    local length = sqrt(rDir[1]*rDir[1] + rDir[2]*rDir[2])
    local move = vector.Norm(length, rDir)
    return uPos[1] + move[1], uPos[2] + move[2], 0
end

local function IdleDodge(unitID, updateRate)
    if not spValidUnitID(unitID) or spGetUnitIsDead(unitID) then
        return 0, 0, 0
    end

    local uPos = vector.New3(spGetUnitPosition(unitID))
    if not idleStates[unitID] then
        return uPos[1], uPos[2], 0
    end

    local idleDodge = idleStates[unitID][1]
    local moveState = spGetUnitStates(unitID).movestate
    if (idleDodge == 1 and moveState == 0) or idleDodge == 2 then
        return uPos[1], uPos[2], 0
    end

    

    local uRadius = spGetUnitRadius(unitID)
    local query = QueryHitData(unitID, uRadius, updateRate)
    -- Spring.MarkerAddPoint(uPos[1], 0, uPos[2], "" .. #query)
    local uDir = vector.New3(spGetUnitDirection(unitID))
    local dodge, dodgeMag = BoidDodge(query, uPos, uDir, uRadius)
    return uPos[1] + dodge[1], uPos[2] + dodge[2], dodgeMag
end

local function MoveDodge(unitID, move_x, move_z, updateRate)
    if not spValidUnitID(unitID) or spGetUnitIsDead(unitID) then
        return move_x, move_z, 0
    end

    if not moveStates[unitID] then
        return move_x, move_z, 0
    end

    local moveDodge = moveStates[unitID][1]
    local moveState = spGetUnitStates(unitID).movestate
    if not force and ((moveDodge == 1 and moveState == 0) or moveDodge == 2) then
        return move_x, move_z, 0
    end

    local uPos = vector.New3(spGetUnitPosition(unitID))
    local uRadius = spGetUnitRadius(unitID)
    local query = QueryHitData(unitID, uRadius, updateRate)
    local uDir = vector.New3(spGetUnitDirection(unitID))
    local dodge, dodgeMag = BoidDodge(query, uPos, uDir, uRadius)

    if dodgeMag <= 0 and move_x then
        local rDir = vector.Subtract({move_x, move_z}, uPos)
        return RayDodge(query, uPos, uDir, rDir, uRadius)
    end

    return uPos[1] + dodge[1], uPos[2] + dodge[2], dodgeMag
end

local external = {
    Idle = IdleDodge,
    Move = MoveDodge,
}

local function CmdToggle(unitID, unitDefID, cmdID, cmdParams)
    local cmdDescID, cmdDesc
    if cmdID == CMD_IDLE_DODGE then
        cmdDesc = idleDodgeCmdDesc
        cmdDescID = spFindUnitCmdDesc(unitID, CMD_IDLE_DODGE)
        idleStates[unitID] = cmdDesc.params
    else
        cmdDesc = moveDodgeCmdDesc
        cmdDescID = spFindUnitCmdDesc(unitID, CMD_MOVE_DODGE)
        moveStates[unitID] = cmdDesc.params
    end

    if (cmdDescID) then
        cmdDesc.params[1] = cmdParams[1]
        spEditUnitCmdDesc(unitID, cmdDescID, {params = cmdDesc.params})
    end
    return false
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
    spInsertUnitCmdDesc(unitID, idleDodgeCmdDesc)
    spInsertUnitCmdDesc(unitID, moveDodgeCmdDesc)
    CmdToggle(unitID, unitDefID, CMD_IDLE_DODGE, {1})
    CmdToggle(unitID, unitDefID, CMD_MOVE_DODGE, {1})
end

function gadget:UnitDestroyed(unitID)
    idleStates[unitID] = nil
    moveStates[unitID] = nil
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_IDLE_DODGE and cmdID ~= CMD_MOVE_DODGE) then
		return true
	end
    return CmdToggle(unitID, unitDefID, cmdID, cmdParams)
end

function gadget:ProjectileDestroyed(projID)
	if hitCache[projID] then
		hitCache[projID] = nil
	end
end

function gadget:Initialize()
    GG.UnitDodge = external
    _G.hitCache = hitCache
end

elseif DEBUG then -- ----- Unsynced -----

local SYNCED = SYNCED
local PI = math.pi
local TWO_PI = math.pi * 2
local INCREMENT = PI/ 6

local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local glColor = gl.Color
local glVertex =  gl.Vertex
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local glLineWidth = gl.LineWidth
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local GL_LINE_LOOP = GL.LINE_LOOP

local function DrawHitZone(x1, y1, z1, x2, y2, z2, aoe)
    local dirX, dirZ = x1 - x2, z1 - z2
    local angle = atan2(x2*dirZ - z2*dirX, x2*dirX + z2*dirZ) - PI/4
    for theta = angle, PI + angle, INCREMENT do
        glVertex({x1 + aoe * cos(theta), y1 + 5, z1 + aoe * sin(theta)})
    end
    for theta = PI + angle, TWO_PI + angle, INCREMENT do
        glVertex({x2 + aoe * cos(theta), y2 + 5, z2 + aoe * sin(theta)})
    end
end

function gadget:DrawWorld()
    if SYNCED.hitCache then
        glDepthTest(true)
        glColor({0,1,0,0.25})
        glLineWidth(2)
        for _, hitdata in pairs(SYNCED.hitCache) do
            local line = hitdata.line
            local radius = hitdata.radius
            glPushMatrix()
            glBeginEnd(GL_LINE_LOOP, DrawHitZone, line[1][1], line[2], line[1][2], line[3][1], line[4], line[3][2], radius)
            glPopMatrix()  
        end
        glLineWidth(1)
        glColor({1,1,1,1})
        glDepthTest(false)
    end
end

end
