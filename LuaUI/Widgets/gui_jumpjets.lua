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

local reverseCompatibility = (Game.version:find('91.0') == 1) or (Game.version:find('94') and not Game.version:find('94.1.1'))

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

local allyTeamID = Spring.GetMyAllyTeamID()

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
	if reverseCompatibility then
		return spTestBuildOrder(unitDefID, x, y, z, 1)
	else
		return spTestMoveOrder(unitDefID, x, y, z, 0, 0, 0, true, true, true)		
	end
end

local function GetJumpViabilityLevel(unitDefID, x, y, z)
	if spTestMoveOrderX(unitDefID, x, y, z) then
		return V_PASS
	else
		local height = spGetGroundHeight(x, z)
		if (not UnitDefs[unitDefID]) or height < -UnitDefs[unitDefID].maxWaterDepth then
			-- Water too deep for the unit to walk on
			return false
		end
		
		local normal = select(2, spGetGroundNormal(x, z))
		if normal < 0.6 then
			 -- Ground is too steep for bots to walk on.
			return false
		end
		
		-- Ground is fine, must contain a blocking structure or
		-- be out of LOS. Spring.TestMoveOrder returns false in 
		-- widgets for all out of LOS locations.
		
		if spIsPosInLos(x, y, z, allyTeamID) then
			return V_STRUCTURE
		else
			return V_FOG
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
  [CMD_SET_WANTED_MAX_SPEED] = true,
}

local curve = {CMD_MOVE, CMD_JUMP, CMD_FIGHT}
local line = {CMD_ATTACK}

curve = ListToSet(curve)
line  = ListToSet(line)

local lastJump = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetDist3(a, b)
  return ((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2)^0.5
end


local function GetDist2(a, b)
  return ((a[1] - b[1])^2 + (a[3] - b[3])^2)^0.5
end

local function DrawLoop(start, vector, color, progress, step, height)
  glColor(color[1], color[2], color[3], color[4])
  for i=progress, 1, step do
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


local function DrawArc(unitID, start, finish, color, jumpFrame, range, isEstimate, quality)

  -- todo: display lists
  
  quality = quality or 1
  
  local step
  local progress
  local vector       = {}
  
  local unitDefID    = spGetUnitDefID(unitID)
  local height       = jumpDefs[unitDefID].height
  
  for i=1, 3 do
    vector[i]        = finish[i] - start[i]
  end
  
  if (range) then
	local col = isEstimate and orange or yellow
    glColor(col[1], col[2], col[3], col[4])
    glDrawGroundCircle(start[1], start[2], start[3], range, 100*quality)
  end
  
  if (jumpFrame) then
    local vertex     = {}
    
    vertex[1]        = start[1] + vector[1]*0.5
    vertex[2]        = start[2] + vector[2]*0.5 + (1-(2*0.5-1)^2)*height
    vertex[3]        = start[3] + vector[3]*0.5
    
    local lineDist   = GetDist3(start, finish)
    local flightDist = GetDist2(start, vertex) + GetDist3(vertex, finish)
    
    local speed      = jumpDefs[unitDefID].speed * lineDist/flightDist
    step             = speed/lineDist
    
    local frame      = spGetGameFrame()
    
    progress         = (frame - jumpFrame) * step
    
  else
    progress         = 0
    step             = 0.01/quality
  end
  
  glLineStipple('')
  glBeginEnd(GL_LINE_STRIP, DrawLoop, start, vector, color, progress, step, height)
  glLineStipple(false)
  
end


local function Line(a, b, color)
  glColor(color[1], color[2], color[3], color[4])
  glVertex(a[1], a[2], a[3])
  glVertex(b[1], b[2], b[3])
end


local function DrawLine(a, b, color)
  glLineStipple('')
  glBeginEnd(GL_LINE_STRIP, Line, a, b, color)
  glLineStipple(false)
end
 
-- unused
--[[
local function DrawQueue(unitID)
  local queue = spGetCommandQueue(unitID)
  if (not queue or not jumpDefs[spGetUnitDefID(unitID)]) then
    return
  end
  for i=1, #queue do
    if (queue[i].id == CMD_JUMP) then
      if (i == 1 and lastJump[unitID]) then
        local ls = lastJump[unitID]
        DrawArc(unitID, ls.pos, queue[i].params, green, ls.frame)
      else
        local j = 1
        while (queue[i-j] and ignore[queue[i-j].id] and j > 0) do
          j = j + 1
        end
        if (curve[queue[i-j].id]) then
          DrawArc(unitID, queue[i-j].params, queue[i].params, green)
        elseif (line[queue[i-j].id] and #queue[i].params == 3) then
          DrawLine(queue[i-j].params, queue[i].params, yellow)
        end
      end
    end
  end
end
--]]

local function GetArcColor(viability, inRange)
	if viability then
		return inRange and viabilityColours[viability][1] or viabilityColours[viability][2]
	end
	return red
end

local function DrawMouseArc(unitID, shift, groundPos, quality)
	local unitDefID = spGetUnitDefID(unitID)
	if (not groundPos or not jumpDefs[unitDefID]) then
		return
	end

	local passIf
	if reverseCompatibility then
		local queue = spGetCommandQueue(unitID, 1)
		passIf = (not queue or #queue == 0 or not shift)
	else
		local queueCount = spGetCommandQueue(unitID, 0)
		passIf = (not queueCount or queueCount == 0 or not shift)
	end

	local viability = GetJumpViabilityLevel(unitDefID, groundPos[1], groundPos[2], groundPos[3])
	
	local range = jumpDefs[unitDefID].range
	if passIf then
		local _,_,_,ux,uy,uz = spGetUnitPosition(unitID,true)
		local unitPos = {ux,uy,uz}
		local dist = GetDist2(unitPos, groundPos)
		local color = GetArcColor(viability, range > dist)
		DrawArc(unitID, unitPos, groundPos, color, nil, range, false, quality)
	elseif (shift) then
		local queue = spGetCommandQueue(unitID, -1)
		local i = #queue
		while queue[i] and (ignore[queue[i].id] and i > 0) do
			i = i - 1
		end
		if (curve[queue[i].id]) or (queue[i].id < 0) or (#queue[i].params == 3) or (#queue[i].params == 4) then
			local isEstimate = not curve[queue[i].id]
			local dist  = GetDist2(queue[i].params, groundPos)
			local color = GetArcColor(viability, range > dist)
			DrawArc(unitID, queue[i].params, groundPos, color, nil, range, isEstimate, quality)
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
	local queue = spGetCommandQueue(unitID, 1)
    if queue and (#queue == 0 or not shift) then
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
    local cmd = spGetCommandQueue(unitID, 2)[2] 
    if (cmd and cmd.id == CMD_JUMP) then
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


--[[
function widget:Initialize()
  -- check for custom key bind, bind jump if does not exist
  local hotkeys = Spring.GetActionHotKeys("jump")
  if #hotkeys == 0 then
	Spring.SendCommands("unbind any+j mouse2")  
	Spring.SendCommands("bind any+j jump")
  end
end 
]]--

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