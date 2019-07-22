-- $Id: gui_jumpjets.lua 4207 2009-03-29 01:08:09Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Jumpjet GUI",
		desc      = "Draws jump arc.",
		author    = "quantum",
		date      = "May 30, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = 10000,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMD_ATTACK               = CMD.ATTACK
local CMD_FIGHT                = CMD.FIGHT
local CMD_MOVE                 = CMD.MOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED
local GL_LINE_STRIP            = GL.LINE_STRIP
local glBeginEnd               = gl.BeginEnd
local glColor                  = gl.Color
local glDrawGroundCircle       = gl.DrawGroundCircle
local glLineStipple            = gl.LineStipple
local glVertex                 = gl.Vertex
local spGetActiveCommand       = Spring.GetActiveCommand
local spGetCommandQueue        = Spring.GetCommandQueue
local spGetGameFrame           = Spring.GetGameFrame
local spGetModKeyState         = Spring.GetModKeyState
local spGetMouseState          = Spring.GetMouseState
local spGetSelectedUnits       = Spring.GetSelectedUnits
local spGetUnitDefID           = Spring.GetUnitDefID
local spGetUnitPosition        = Spring.GetUnitPosition
local spTraceScreenRay         = Spring.TraceScreenRay
local spTestMoveOrder          = Spring.TestMoveOrder
local spTestBuildOrder         = Spring.TestBuildOrder
local spGetGroundHeight        = Spring.GetGroundHeight
local spGetGroundNormal        = Spring.GetGroundNormal
local spIsPosInLos             = Spring.IsPosInLos

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local pairs = pairs


local glVertex = glVertex
local green      = {0.5,   1, 0.5,   1}
local greenred   = {  0.8, 0.5, 0.5,   1}
local yellow     = {  1,   1, 0.5,   1}
local orange     = { 0.9, 0.5,   0,   1}
local red        = {  1,   0,   0,   1}

-- Types of passibility.
local V_PASS = 0
local V_STRUCTURE = 1
local V_FOG = 2

-- First in range, then out of range
local viabilityColours = {
	[V_PASS] = {green, greenred},
	[V_STRUCTURE] = {yellow, orange},
	[V_FOG] = {greenred, greenred},
}

local jumpDefs  = VFS.Include"LuaRules/Configs/jump_defs.lua"

local function spTestMoveOrderX(unitDefID, x, y, z)
	return spTestMoveOrder(unitDefID, x, y, z, 0, 0, 0, true, true, true)
end

local function CheckTerrainBlock(bx, by, bz, finish, height)
	local vx, vy, vz = finish[1] - bx, finish[2] - by, finish[3] - bz
	local wallStep = 0.015
	
	-- check if there is no wall in between
	local x,z = bx, bz
	--Spring.Echo("Widget", x, by, z, "vec", vx, vy, vz, "step", wallStep)
	for i = 0, 1, wallStep do
		x = x + vx*wallStep
		z = z + vz*wallStep
		if ((spGetGroundHeight(x,z) - 30) > (by + vy*i + (1 - (2*i - 1)^2)*height)) then
			return i
		end
	end
	return false
end

local function GetJumpViabilityLevel(unitDefID, bx, by, bz, finish, height)
	local x, y, z = finish[1], finish[2], finish[3]

	if spTestMoveOrderX(unitDefID, x, y, z) then
		local blockStep = CheckTerrainBlock(bx, by, bz, finish, height)
		return V_PASS, blockStep
	else
		local normal = select(2, spGetGroundNormal(x, z))
		if normal < 0.6 then
			 -- Ground is too steep for bots to walk on.
			return false
		end
		
		local blockStep = CheckTerrainBlock(bx, by, bz, finish, height)
		
		local height = spGetGroundHeight(x, z)
		if (not UnitDefs[unitDefID]) or height < -UnitDefs[unitDefID].maxWaterDepth then
			-- Water too deep for the unit to walk on
			return V_STRUCTURE, blockStep
		end
		
		-- Ground is fine, must contain a blocking structure or
		-- be out of LOS. Spring.TestMoveOrder returns false in 
		-- widgets for all out of LOS locations.
		
		if spIsPosInLos(x, y, z) then
			return V_STRUCTURE, blockStep
		else
			return V_FOG, blockStep
		end
	end
end

local function ListToSet(t)
	local new = {}
	for i=1,#t do
		new[ t[i] ] = true
	end 
	return new
end

local ignore = {
	[CMD_SET_WANTED_MAX_SPEED or 70] = true,
}

local curve = ListToSet({CMD_MOVE, CMD_RAW_MOVE, CMD_JUMP, CMD_FIGHT})
local line = ListToSet({CMD_ATTACK})

local lastJump = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetDist3(a, b)
	return ((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2)^0.5
end

local function GetDist2(a, b)
	return ((a[1] - b[1])^2 + (a[3] - b[3])^2)^0.5
end

local function DrawLoop(start, vector, color, progress, step, height, secondColorStep, secondColor)
	glColor(color[1], color[2], color[3], color[4])
	for i = progress, 1, step do
		if secondColorStep and secondColorStep < i then
			glColor(secondColor[1], secondColor[2], secondColor[3], secondColor[4])
			secondColorStep = false
		end
		local x = start[1] + vector[1]*i
		local y = start[2] + vector[2]*i + (1-(2*i-1)^2)*height
		local z = start[3] + vector[3]*i

		glVertex(x, y, z)
	end

	local x = start[1] + vector[1]
	local y = start[2] + vector[2]
	local z = start[3] + vector[3]

	glVertex(x, y, z)
end

local function DrawLineSeaLine(point, color)
	glVertex(point[1], point[2], point[3])
	glVertex(point[1], 0, point[3])
end

local function GetArcColor(viability, inRange)
	if viability then
		return inRange and viabilityColours[viability][1] or viabilityColours[viability][2]
	end
	return red
end

local function DrawArc(unitID, unitDefID, start, bx, by, bz, finish, inRange, range, isEstimate, quality)
	-- todo: display lists
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	local height       = jumpDefs[unitDefID].height
	
	local by = math.max(by, spGetGroundHeight(bx, bz))
	local viability, blockStep = GetJumpViabilityLevel(unitDefID, bx, by, bz, finish, height)
	local color = GetArcColor(viability, inRange)

	quality = quality or 1
	
	local vector       = {}
	for i = 1, 3 do
		vector[i]        = finish[i] - start[i]
	end

	if (range) then
		local col = isEstimate and orange or yellow
		glColor(col[1], col[2], col[3], col[4])
		glDrawGroundCircle(start[1], start[2], start[3], range, 100*quality)
	end

	local progress         = 0
	local step             = 0.01/quality

	glLineStipple('')
	glBeginEnd(GL_LINE_STRIP, DrawLoop, start, vector, color, progress, step, height, blockStep, red)
	glLineStipple(false)
	
	if finish[2] < 0 then
		glLineStipple(1, 255)
		glBeginEnd(GL_LINE_STRIP, DrawLineSeaLine, finish, color)
		glLineStipple(false)
	end
end

local function DrawMouseArc(unitID, shift, groundPos, quality)
	local unitDefID = spGetUnitDefID(unitID)
	if (not groundPos or not jumpDefs[unitDefID]) then
		return
	end
	groundPos[2] = Spring.GetGroundHeight(groundPos[1], groundPos[3])
	local queueCount = spGetCommandQueue(unitID, 0)
	local passIf = (not queueCount or queueCount == 0 or not shift)
	
	local range = jumpDefs[unitDefID].range
	if passIf then
		local bx,by,bz,ux,uy,uz = spGetUnitPosition(unitID,true)
		local unitPos = {ux,uy,uz}
		local dist = GetDist2(unitPos, groundPos)
		DrawArc(unitID, unitDefID, unitPos, bx, by, bz, groundPos, range > dist, range, false, quality)
	elseif (shift) then
		local queue = spGetCommandQueue(unitID, -1)
		local i = #queue
		while queue[i] and (ignore[queue[i].id] and i > 0) do
			i = i - 1
		end
		if (curve[queue[i].id]) or (queue[i].id < 0) or (#queue[i].params == 3) or (#queue[i].params == 4) then
			local isEstimate = not curve[queue[i].id]
			local dist  = GetDist2(queue[i].params, groundPos)
			DrawArc(unitID, unitDefID, queue[i].params, queue[i].params[1], queue[i].params[2], queue[i].params[3], groundPos, range > dist, range, isEstimate, quality)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(id, params, options)
	if (id ~= CMD_JUMP) then
		return
	end
	local units = spGetSelectedUnits()
	for i=1,#units do
		unitID = units[i]
		local _, _, _, shift   = spGetModKeyState()
		local queue = spGetCommandQueue(unitID, 0)
		if queue and (queue == 0 or not shift) then
			local _,_,_,ux,uy,uz = spGetUnitPosition(unitID,true)
			lastJump[unitID] = {
				pos   = {ux,uy,uz},
				frame = spGetGameFrame(),
			}
		end
	end
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if jumpDefs[unitDefID] then
		local cmdID = Spring.GetUnitCurrentCommand(unitID, 2)
		if cmdID == CMD_JUMP then
			local _,_,_,ux,uy,uz = spGetUnitPosition(unitID,true)
			lastJump[unitID] = {
				pos = {ux,uy,uz},
				frame = spGetGameFrame(),
			}
		end
	end
end

function widget:UnitDestroyed(unitID)
	lastJump[unitID] = nil
end

function widget:DrawWorld()
	local _, activeCommand = spGetActiveCommand()
	if (activeCommand == CMD_JUMP) then
		local mouseX, mouseY   = spGetMouseState()
		local category, arg    = spTraceScreenRay(mouseX, mouseY, true)
		local _, _, _, shift   = spGetModKeyState()
		local units = spGetSelectedUnits()
		local quality = 1
		if #units > 50 then
			quality = 0.5
		end
		for i=1,#units do
			DrawMouseArc(units[i], shift, category == 'ground' and arg, quality)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
