-- $Id: unit_satellites.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_satellites.lua
--  brief:   Indicates and lets you select high-altitude units from the ground
--  author:  CarRepairer
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Satellites",
    desc      = "v0.32 Indicates and lets you select high-altitude units from the ground",
    author    = "CarRepairer",
    date      = "2008-06-18",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local satellites = {}
local selectme = false
local hiliteme = false
local selectedSatellites = {}

local GetUnitPosition	= Spring.GetUnitPosition
local GetGameFrame	= Spring.GetGameFrame
local GetTeamColor	= Spring.GetTeamColor 
local SelectUnitArray	= Spring.SelectUnitArray
local GetSelectedUnits	= Spring.GetSelectedUnits
local GetGroundHeight	= Spring.GetGroundHeight
local GetUnitDefID	= Spring.GetUnitDefID
local GetUnitTeam	= Spring.GetUnitTeam
local WorldToScreenCoords = Spring.WorldToScreenCoords
local GetMouseState	= Spring.GetMouseState
local GetPlayerInfo	= Spring.GetPlayerInfo
local TraceScreenRay	= Spring.TraceScreenRay
local GetTeamInfo	= Spring.GetTeamInfo

local glDepthTest        = gl.DepthTest
local glDrawGroundCircle = gl.DrawGroundCircle
local glLineWidth        = gl.LineWidth
local glColor            = gl.Color
local glVertex		 = gl.Vertex
local glBeginEnd	 = gl.BeginEnd
local GL_LINE_LOOP	 = GL.LINE_LOOP



local font		= "LuaUI/Fonts/FreeSansBold_16"
local fhDraw		= fontHandler.Draw


fontHandler.UseFont(font)


local abs = math.abs
local cos = math.cos
local sin = math.sin
local twoPI = (2.0 * math.pi)
local deg2rad = math.pi/180

local offsetSize = 10

local triCartCoords = {}
local triPolCoords = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawShape = function(x,z, triangleIndex)

	for i = triangleIndex,triangleIndex+2 do
		local px = x+triCartCoords[i][1]
		local pz = z+triCartCoords[i][2]
		local py = GetGroundHeight(px, pz) + 2

		glVertex(px, py, pz)
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitFromFactory(unitID, unitDefID, teamID, _, _, _)
	local unitDef = UnitDefs[unitDefID]
	local unitName
	if unitDefID then
		unitName = unitDef.name 
	end

	if (unitName == 'owl') then

		local	team = GetUnitTeam(unitID)
		local _, player = GetTeamInfo(team)
		local playerName = GetPlayerInfo(player) or 'noname'

		local fullName = unitDef.humanName 

		satellites[unitID] = {
			teamColor = {GetTeamColor(teamID)},
			playerName = playerName,
			fullName = fullName,
		}
		

	end
end
function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (UnitDefs[unitDefID] and UnitDefs[unitDefID].name == 'owl') then
		satellites[unitID] = nil
	end
end


function widget:UnitEnteredLos(unitID, unitDefID, unitTeam)
	-- These aren't correct
	unitDefID = GetUnitDefID(unitID)
	unitTeam = GetUnitTeam(unitID)

	widget:UnitFromFactory(unitID, unitDefID, unitTeam)
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	-- These aren't correct
	unitDefID = GetUnitDefID(unitID)
	unitTeam = GetUnitTeam(unitID)

	widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end




function widget:Initialize()
	triPolCoords = {
		{deg2rad * 0, 10},
		{deg2rad * 20, 30},
		{deg2rad * -20, 30},

		{deg2rad * 180, 10},
		{deg2rad * 200, 30},
		{deg2rad * 160, 30},	
	}

	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		widget:UnitFromFactory(unitID, GetUnitDefID(unitID), GetUnitTeam(unitID), _, _, _)
	end

end


function widget:DrawScreen() 

	for unitID, attrib in pairs(satellites) do
		local x,_,z = GetUnitPosition(unitID)
		if hiliteme == unitID and (x and z) then
			local y = GetGroundHeight(x, z) + 2
			local sx,sy,_ = WorldToScreenCoords(x,y,z)

			local text = attrib.fullName ..' ('.. attrib.playerName ..')'

			glColor(attrib.teamColor[1], attrib.teamColor[2], attrib.teamColor[3], attrib.teamColor[4])
			fontHandler.UseFont(font)
			fontHandler.DrawCentered(text, sx,sy)
		end
	end
	glColor(0,0,0,0)
end

function widget:DrawWorld()
	local gameFrame = GetGameFrame()
	local rot = twoPI * (gameFrame % 40) / 40
	--local pulse = abs((gameFrame % 100) - 50) / 50

	for i, polCoord in ipairs(triPolCoords) do
		local x = cos(triPolCoords[i][1]+rot)*triPolCoords[i][2]
		local z = sin(triPolCoords[i][1]+rot)*triPolCoords[i][2]
		triCartCoords[i] = { x,z }
	end
	
	glDepthTest(true)
	glLineWidth(2)

	local mx, my, b1, b2, b3 = GetMouseState()

	for unitID, attrib in pairs(satellites) do
		local x,_,z = GetUnitPosition(unitID)
		if (x and z) then
			--local y = GetGroundHeight(x, z) + 2

			if hiliteme == unitID then
				glLineWidth(3)
				glColor(1, 1, 1, 1)
				glDrawGroundCircle(x,0,z, 30, 32)
				glLineWidth(1)
			end

			--Selection circle
			if selectedSatellites[unitID] then
				glColor(0, 1, 0, 1)
				glDrawGroundCircle(x,0,z, 30, 32)
			end
			
			--Outline triangles
			glLineWidth(4)
			glColor(0, 0, 0, 1)	

			glBeginEnd(GL_LINE_LOOP, DrawShape, x,z ,1 )
			glBeginEnd(GL_LINE_LOOP, DrawShape, x,z ,4 )

			--Teamcolor triangles
			glLineWidth(2)
			glColor(attrib.teamColor[1], attrib.teamColor[2], attrib.teamColor[3], attrib.teamColor[4])
			glBeginEnd(GL_LINE_LOOP, DrawShape, x,z ,1 )
			glBeginEnd(GL_LINE_LOOP, DrawShape, x,z ,4 )
		end
	end
				
	glColor(0,0,0,0)
	glDepthTest(false)
	
	if gameFrame % 4 < 0.1 then

		local selectedUnits = GetSelectedUnits()
		selectedSatellites = {}

		for _, unitID in ipairs(selectedUnits) do
			selectedSatellites[unitID] = true
		end
		
		hiliteme = false
		for unitID, _ in pairs(satellites) do
			local ux,_,uz = GetUnitPosition(unitID)
			local _,pos = TraceScreenRay(mx,my,true)
			if ( pos and ux and
				abs(pos[1] - ux) < 50
				and abs(pos[3] - uz) < 50
			) then
				hiliteme = unitID
			end
		end

	end

end

function widget:MouseRelease(mx, my, button)
	return false
end

function widget:MousePress(mx, my, button)
	local _,pos = TraceScreenRay(mx,my,true)

	for unitID, _ in pairs(satellites) do
		local ux,_,uz = GetUnitPosition(unitID)
		if ( pos and ux and
			abs(pos[1] - ux) < 50
			and abs(pos[3] - uz) < 50
		) then
			selectme = unitID
			SelectUnitArray( {unitID} )
			return true
		end
	end
	return false
end
