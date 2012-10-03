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
    author    = "quantum, msafwan(impulse jump)",
    date      = "May 30 2008, Oct 3 2012",
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
local spGetGroundHeight        = Spring.GetGroundHeight

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local pairs = pairs


local glVertex = glVertex
local green    = {0.5,   1, 0.5,   1}
local yellow   = {  1,   1, 0.5,   1}
local orange   = {	1, 0.5,   0,   1}
local pink     = {  1, 0.5, 0.5,   1}
local red      = {  1,   0,   0,   1}
local isImpulseJump = (Spring.GetModOptions().impulsejump  == "1") --ImpulseJump arc & ground circle

local jumpDefNames  = VFS.Include"LuaRules/Configs/jump_defs.lua"

local function ListToSet(t)
  local new = {}
  for i=1,#t do
    new[ t[i] ] = true
  end 
  return new
end


local jumpDefs = {}
for name, data in pairs(jumpDefNames) do
  jumpDefs[UnitDefNames[name].id] = data
end

local ignore = {
  [CMD_SET_WANTED_MAX_SPEED] = true,
}

local curve = {CMD_MOVE, CMD_JUMP, CMD_FIGHT}
local line = {CMD_ATTACK}

curve = ListToSet(curve)
line  = ListToSet(line)

local lastJump = {}

local function GetDist3(a, b)
  return ((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2)^0.5
end


local function GetDist2(a, b)
  return ((a[1] - b[1])^2 + (a[3] - b[3])^2)^0.5
end


local function DrawLoop(start, vector, progress, step, height)
	for i=progress, 1, step do
		local x = start[1] + vector[1]*i
		local y = start[2] + vector[2]*i + (1-(2*i-1)^2)*height
		local z = start[3] + vector[3]*i

		glVertex(x, y, z)
	end
end

local function DrawArc(unitID, start, finish, color, jumpFrame, range, isEstimate, unitDefID, numUnits_IJ, updateNow_IJ)

	-- todo: display lists
	local step
	local progress
	local vector       = {}
	local unitDefID    = spGetUnitDefID(unitID)
	local height       = jumpDefs[unitDefID].height

	for i=1, 3 do
		vector[i]        = finish[i] - start[i]
	end
  
	if (range) then --draw range on the ground
		local col = isEstimate and orange or yellow
		glColor(col[1], col[2], col[3], col[4])
		if isImpulseJump and jumpDefs[unitDefID].limitHeight then --when range need to be limited by height
			DrawImpulseJumpGroundCircle (unitID,height,start,range,finish, numUnits_IJ, updateNow_IJ) --a function that map the terrain & cache the vertex & draw the range.
		else --draw range at all height
			glDrawGroundCircle(start[1], start[2], start[3], range, 100)
		end
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
    step             = 0.01
  end
  
  glLineStipple('')
  glColor(color[1], color[2], color[3], color[4])
  if isImpulseJump then
	glBeginEnd(GL_LINE_STRIP, DrawImpulseJumpArc, start,vector, (jumpDefs[unitDefID].limitHeight and height) or height + vector[2])
  else
    glBeginEnd(GL_LINE_STRIP, DrawLoop, start, vector, progress, step, height)
  end
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
 
--[[
-- unused
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


local function  DrawMouseArc(unitID, shift, groundPos, numUnits_IJ, updateNow_IJ)
  local unitDefID = spGetUnitDefID(unitID)
  if (not groundPos or not jumpDefs[unitDefID]) then
    return
  end
  local queue = spGetCommandQueue(unitID)
  local range = jumpDefs[unitDefID].range
  if (not queue or #queue == 0 or not shift) then
    local unitPos = {spGetUnitPosition(unitID)}
    local dist = GetDist2(unitPos, groundPos)
	local color
	if isImpulseJump and jumpDefs[unitDefID].limitHeight then
		local maxheight = jumpDefs[unitDefID].height + unitPos[2]
		color = ((range > dist and maxheight > groundPos[2]) and green) or pink --a customized situation where impulse jump is made to have limited height
	else
		color = (range > dist and green) or pink
	end
    DrawArc(unitID, unitPos, groundPos, color, nil, range, nil, unitDefID, numUnits_IJ, updateNow_IJ)
  elseif (shift) then
    local i = #queue
    while (ignore[queue[i].id] and i > 0) do
      i = i - 1
    end
    if (curve[queue[i].id]) or (queue[i].id < 0) or (#queue[i].params == 3) or (#queue[i].params == 4) then
	  local isEstimate = not curve[queue[i].id]
      local dist  = GetDist2(queue[i].params, groundPos)
	  local cGood = isEstimate and yellow or green
	  local cBad = isEstimate and orange or pink
      local color = range > dist and cGood or cBad
      if isImpulseJump and jumpDefs[unitDefID].limitHeight then
	    local maxheight = jumpDefs[unitDefID].height + queue[i].params[2]
        color = (range > dist and maxheight > groundPos[2]) and cGood or cBad
      else
        color = range > dist and cGood or cBad
      end
      DrawArc(unitID, queue[i].params, groundPos, color, nil, range, isEstimate, unitDefID, numUnits_IJ, updateNow_IJ)
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
    if (#spGetCommandQueue(unitID, 1) == 0 or not shift) then
      lastJump[unitID] = {
        pos   = {spGetUnitPosition(unitID)},
        frame = spGetGameFrame(),
      }
    end
  end
end


function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
  if jumpDefs[unitDefID] then
    local cmd = spGetCommandQueue(unitID, 2)[2] 
    if (cmd and cmd.id == CMD_JUMP) then
        lastJump[unitID] = {
          pos = {spGetUnitPosition(unitID)}, 
          frame = spGetGameFrame(),
        }
    end
  end
end

local vertexCache1 ={} --used only by "DrawImpulseJumpGroundCircle()" to cache vertex
local positionCompare = {} --used to cache vertex, same as "vertexCache1" ^

function widget:UnitDestroyed(unitID)
  lastJump[unitID] = nil
  positionCompare[unitID] = nil --used by impulse jump only
  vertexCache1[unitID] = nil --same ^^
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

local numSelectedUnits_IJ = 0 --used by impulse jump drawing for a customized GUI experience
local updateNow_IJ = true -- used by impulse jump to limit its drawing frequency. To reduce CPU usage

function widget:DrawWorld()
  local _, activeCommand = spGetActiveCommand()
  if (activeCommand == CMD_JUMP) then
    local mouseX, mouseY   = spGetMouseState()
    local category, arg    = spTraceScreenRay(mouseX, mouseY)
    local _, _, _, shift   = spGetModKeyState()
    local units = spGetSelectedUnits()
	numSelectedUnits_IJ = #units
    for i=1,#units do
      DrawMouseArc(units[i], shift, category == 'ground' and arg, numSelectedUnits_IJ, updateNow_IJ)
    end
	updateNow_IJ = false --stop updating the impulse jump's ground circle until to do so.
  end
end

--------------------------------------------------------------------------------
--Impulse Jump specialized draw function----------------------------------------------
local timeElapsed =0

function widget:Update(dt) --used in impulse jump only
	timeElapsed = timeElapsed + dt
	if timeElapsed >= 0.06 then -- period of update is 0.06sec because 1/15sec is the minimum for perceiving motion picture. ref: http://en.wikipedia.org/wiki/Frame_rate  
		updateNow_IJ = true
		timeElapsed = 0
	end
end

--//this function draw the impulse jump range by calling "_TerrainScan()" function and caches the vertex whenever unit is not moving.
function DrawImpulseJumpGroundCircle (unitID,height,start,range,finish, numUnits_IJ, updateNow_IJ)
	local centerCirle = {start[1], start[2], start[3]}
	if (numUnits_IJ == 1) and GetDist2(finish, start) > range*2 then --range circle will follow the player's mouse when he select only 1 unit so that he can test the terrain.
		centerCirle = {finish[1], finish[2], finish[3]}
	end
	positionCompare[unitID] = positionCompare[unitID] or {-1,-1,-1}
	vertexCache1[unitID] = vertexCache1[unitID] or {} --use old vertex cache for this unit or initialize empty one
	local vertexes = {}
	local samePos =(positionCompare[unitID][1]==centerCirle[1] and positionCompare[unitID][2]==centerCirle[2] and positionCompare[unitID][3]==centerCirle[3])
	if samePos or (not updateNow_IJ) then
		for i=1, #vertexCache1[unitID], 1 do --if same position then copy vertex from vertex cache
			if vertexCache1[unitID][i].segment == nil then
				break ----break when reach the end, else it will continue to copy old vertexes too..
			end
			vertexes[i] = {vertexCache1[unitID][i][1], vertexCache1[unitID][i][2], vertexCache1[unitID][i][3], segment = vertexCache1[unitID][i].segment}
		end
	else --if unit is moving then calculate new vertex
		local far 
		local circleDivs = 30
		local lineDivs = 30
		local startSegment = 0
		local maxHeight = height + spGetGroundHeight(centerCirle[1],centerCirle[3])
		--vertexes = RecursiveTerrainScan(startSegment, circleDivs, circleDivs, range, start,maxHeight, 0) --default: circleDivs = 70
		vertexes = VolumeTerrainScan(startSegment, circleDivs, range, centerCirle, maxHeight, lineDivs) --default: circleDivs = 30 
		circleDivs, startSegment, maxHeight = nil, nil, nil
		
		for i=1, #vertexes do --cache vertex
			vertexCache1[unitID][i] = {vertexes[i][1], vertexes[i][2], vertexes[i][3], segment = vertexes[i].segment}
			vertexCache1[unitID][i+1] = { nil, nil, nil, segment=nil}
		end
		positionCompare[unitID] = {centerCirle[1], centerCirle[2] ,centerCirle[3]}
	end
	-- [[ GL.LINE_LOOP or GL_LINE_STRIP?
	glBeginEnd(GL_LINE_STRIP, function() --draw
								for i = 1, #vertexes do
									if vertexes[i][1] and vertexes[i][2] and vertexes[i][3] then --nil check because "RecursiveTerrainScan" still return some nil, can't fix for now.
										glVertex(vertexes[i][1], vertexes[i][2], vertexes[i][3])
									end
								end
							end)--]]
end

--//this function draw the impulse jump arc using the same equation as used in "unit_jumpjet.lua" gadget.
local cache1 = {}
function DrawImpulseJumpArc(start,vector, height)

	local art_Grav = 1 -- Game.gravity/30/30 --get any game gravity.
	local art_yVel = (cache1[height]) or (4*(-art_Grav/2)*(-height))^0.5 --determinant is set to 0. See unit_jumpjets.lua for more info.
	--local art_flightTimeApex = -art_yVel/(2*(-art_Grav/2)) --get the single root for parabola (quadratic) equation 
	local distance = 			GetDist2({0,0,0}, vector)
	--local art_xzVel_est =		distance/(art_flightTimeApex*2)
	local targetHeight = 		math.min(height-1, vector[2]) --choose either the ceiling height or the target height
	local art_flightTimeFull =	(-art_yVel - (art_yVel^2 - 4*(-art_Grav/2)*(-vector[2]))^0.5)/(2*(-art_Grav/2)) --equation for finding root for parabola
	local art_xzVel = 			distance/art_flightTimeFull --distance = horizontalSpeed*flightTime rearranged
	local art_directionxz = 	math.atan2(vector[3]/distance, vector[1]/distance) --get direction in angle (radian)
	local art_xVel = 			math.cos(art_directionxz)*art_xzVel --convert horizontal speed into x and z component
	local art_zVel = 			math.sin(art_directionxz)*art_xzVel
	
	for i=0, art_flightTimeFull, 1 do	--draw each point in the parabola at 1 frame step.
		local x = start[1] + art_xVel*i
		local y = start[2] + art_yVel*i -art_Grav*i*i/2
		local z = start[3] + art_zVel*i
		glVertex(x, y, z)
	end
	
	cache1[height] = art_yVel
	art_Grav, art_yVel, art_flightTimeApex, distance, targetHeight = nil, nil, nil, nil, nil
	art_flightTimeFull, art_xzVel, art_directionxz, art_xVel, art_zVel = nil, nil, nil, nil, nil
end

--//This function map the terrain volumetrically from the center of the circle. This mapping will be used as vertex at point where groundHeight exceed maxHeight. This use max amount of CPU but produce a complete result.  
function VolumeTerrainScan(startSeg, circleDivs1, range1, startPos, maxHeight, lineDivs1)
	local vertexAndAngle = {}
	for seg=startSeg, circleDivs1, 1 do --check the volume of the circle clockwise. Resolution of circle is "circleDivs1"
		local lastX
		local lastZ
		local lastGroundHeight
		local angle = 2.0 * math.pi * (seg / circleDivs1)
		local cosv = math.cos(angle)
		local sinv = math.sin(angle)
		for rng= 0, range1, range1/lineDivs1 do --check groundheight along a line. Resolution of line is "lineDivs1"
			local x = cosv*rng + startPos[1]
			local z = sinv*rng + startPos[3]
			local groundHeight = spGetGroundHeight(x,z)
			if groundHeight < maxHeight then
				lastX = x
				lastZ = z
				lastGroundHeight = groundHeight
			else
				break
			end
		end
		vertexAndAngle[seg+1] = {lastX, lastGroundHeight, lastZ, segment = seg} --remember the point as vertex
	end
	return vertexAndAngle
end

--[[
--//This function draw a circle and then will recursively (in successively smaller circle) map any terrain that cause a gap in the circle. This mapping will then be used as vertex (The gap happens when terrain exceed the maxHeight where the circle intersect). Not used because result is not complete
function RecursiveTerrainScan(startSeg, endSeg, circleDivs1, range1, startPos, maxHeight, currentDepth)
	currentDepth = currentDepth + 1
	if currentDepth > 100 then 
		return {{}} --if it is going too deep then then it just doesn't make sense, so return.
	end 
	
	local vertexAndAngle = {}
	local wasEmpty = false
	for i = startSeg, endSeg,1 do --create vertex of circle. Copied from "minimap_event.lua" by trepan/Dave Rodgers, thanks.
		local angle = 2.0 * math.pi * (i / circleDivs1)
		local cosv = math.cos(angle)*range1 + startPos[1]
		local sinv = math.sin(angle)*range1 + startPos[3]
		local groundHeight = spGetGroundHeight(cosv,sinv)
		if groundHeight < maxHeight then --only vertex within max height is included
			vertexAndAngle[#vertexAndAngle+1] = {cosv, groundHeight, sinv, segment = i}
			wasEmpty = false
		elseif (not wasEmpty) then --include empty vertex once to indicate empty space
			vertexAndAngle[#vertexAndAngle+1] = {nil, nil, nil, segment = i} --indicate that this vertex is over the max height and need to be revised
			wasEmpty = true
		end
	end
	
	local inBtwnEmptyVrtx = {}
	for i=1, #vertexAndAngle, 1 do --fill in the empty vertexes
		if vertexAndAngle[i][1] == nil then --if vertexAndAngle[i] is empty, then it mean it need to be filled with real values
			local nextSegment = (i<#vertexAndAngle and vertexAndAngle[i+1].segment) or endSeg --select the i+1 segment or use end's segment
			inBtwnEmptyVrtx[1] = nil --we make sure the first content is empty so that the table lenght is resetted to 0 whenever we re-use this table.
			inBtwnEmptyVrtx = RecursiveTerrainScan(vertexAndAngle[i].segment, nextSegment, circleDivs1, range1-10, startPos,maxHeight, currentDepth)
			if inBtwnEmptyVrtx[1][1] then
				vertexAndAngle[i]={inBtwnEmptyVrtx[1][1],inBtwnEmptyVrtx[1][2],inBtwnEmptyVrtx[1][3], segment= inBtwnEmptyVrtx[1].segment} -- replace vertexAndAngle[i] that contain nil
				local indexToBeSandwiched = i+1
				for j=2, #inBtwnEmptyVrtx, 1 do
					table.insert(vertexAndAngle, indexToBeSandwiched, inBtwnEmptyVrtx[j])
					indexToBeSandwiched = indexToBeSandwiched + 1
				end
			else --an extremely rare case where we don't even get a result after millions of recursive depth
				table.remove(vertexAndAngle, i) -- delete vertexAndAngle[i] that contain nil
			end
		end
	end
	
	return vertexAndAngle --we return result to upper recursive level
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------