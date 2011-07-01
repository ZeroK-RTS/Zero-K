function widget:GetInfo()
  return {
    name      = "Restricted Zones",
    desc      = "Place restricted zones - ceasefired units walking into them will break your ceasefire.",
    author    = "CarRepairer",
    date      = "2011-06-30",
    license   = "GNU GPL, v2 or later",
    layer     = 2000,
    enabled   = true -- loaded by default?
  }
end


local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

if tobool(Spring.GetModOptions().noceasefire) or Spring.FixedAllies() then
  return
end

local echo 				= Spring.Echo

if not WG.rzones then
	WG.rzones = {
		rZonePlaceMode = false
	}
end

--[[
local rZonePlaceMode	= false

options = {
	rzplacemode = {
		type = 'button',
		name='rz placement',
		OnChange = function()
			echo 'test'
			rZonePlaceMode= not rZonePlaceMode;
		end,
	},
}
--]]

local spGetTeamList		= Spring.GetTeamList
local spGetAllyTeamList	= Spring.GetAllyTeamList
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID
local spTraceScreenRay		= Spring.TraceScreenRay


local spGetGameFrame 		= Spring.GetGameFrame
local SendLuaRulesMsg 		= Spring.SendLuaRulesMsg
local spGetSpectatingState 	= Spring.GetSpectatingState
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID

local glPushMatrix			= gl.PushMatrix
local glPopMatrix			= gl.PopMatrix
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local glTranslate			= gl.Translate
local glColor				= gl.Color
local glBeginEnd			= gl.BeginEnd
local glVertex				= gl.Vertex
local GL_QUADS     			= GL.QUADS
local glDrawGroundCircle	= gl.DrawGroundCircle
local glLineWidth			= gl.LineWidth
local glDepthTest			= gl.DepthTest

local blink 			= true
local cycle				= 1
local shortcycle		= 1

local rZones			= {}
local rZoneCount		= 0
local spec				= true
local rzRadius			= 250

local myAllyID 		= spGetLocalAllyTeamID()
local myTeamID 		= spGetLocalTeamID()
local myPlayerID	= Spring.GetLocalPlayerID()
--local myCeasefires 	= {}


local function FindClosestRZone(sx, _, sz)
	local closestDistSqr = math.huge
	local cx, cy, cz  --  closest coordinates
	for rZoneID, pos in pairs(rZones) do
		local hx, hy, hz = pos[1], pos[2], pos[3]
		if hx then 
			local dSquared = (hx - sx)^2 + (hz - sz)^2
			if (dSquared < closestDistSqr) then
				closestDistSqr = dSquared
				cx = hx; cy = hy; cz = hz
				cRZoneID = rZoneID
			end
		end
	end
	if (not cx) then return -1, -1, -1, -1 end
	return cx, cy, cz, closestDistSqr, cRZoneID
end

local function addRZone(x, y, z)
	rZoneCount = rZoneCount + 1
	rZones[#rZones+1] = {x, y, z}
end

local function removeRZone(rZoneID)
	if rZones[rZoneID] then
		rZoneCount = rZoneCount - 1
	end
	rZones[rZoneID] = nil
end

function inRZones(cAlliance)
	local teamList = spGetTeamList(cAlliance)
	for _,teamID in ipairs(teamList) do
		for rZoneID, pos in pairs(rZones) do
			local units = spGetUnitsInCylinder(pos[1], pos[3], rzRadius, teamID)
			if units and units[1] then
				return true
			end
		end
	end
	return false
end

-----------------------------------------------------------------------------
function widget:MousePress(x,y,button)

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local mods = {alt=alt, ctrl=ctrl, meta=meta, shift=shift}

  if (button==1) then
		if WG.rzones.rZonePlaceMode then
			local _,pos = spTraceScreenRay(x,y,true)
			if pos then
				local wx,wy,wz = pos[1], pos[2], pos[3]
				local _, _, _, dSquared, closestRZoneID = FindClosestRZone(wx,wy,wz)
				if dSquared ~= -1 and dSquared < rzRadius*rzRadius then
					removeRZone(closestRZoneID)
				else
					addRZone(wx,wy,wz)
				end
				return true
			end
		end
	end
	return false
end

function widget:DrawWorld()
	if WG.rzones.rZonePlaceMode then
		glDepthTest(true)
		for _,pos in pairs(rZones) do
			glLineWidth(4)
			if blink then 
				glColor(1,0,0,1)
			else
				glColor(0,0,0,1)
			end
			glDrawGroundCircle(pos[1],0,pos[3], rzRadius, 32)
			glLineWidth(2)
			if blink then 
				glColor(0,0,0,1)
			else
				glColor(1,0,0,1)
			end
			
			glDrawGroundCircle(pos[1],0,pos[3], rzRadius, 32)
		end
		glDepthTest(false)
		glLineWidth(1)
	end
end


function widget:Initialize()

end

function widget:Shutdown()
end

function widget:Update()
	
	
	shortcycle = cycle % 32 + 1
	cycle = cycle % (32*5) + 1
	
	if shortcycle == 1 then
		blink = not blink
	end

	
	spec = spGetSpectatingState()
	
	if cycle == 1 then
		myAllyID = spGetLocalAllyTeamID()
		myTeamID = spGetLocalTeamID()
		
		if not spec then
			--for cAlliance, _ in pairs(myCeasefires) do
			local alliances = spGetAllyTeamList()
			for _, alliance in ipairs(alliances) do
				if Spring.GetGameRulesParam('cf_' .. myAllyID .. '_' .. alliance) == 1 then
					if inRZones(alliance) then
						SendLuaRulesMsg('ceasefire:n'..alliance)
					end
				end
			end
		end
		
	end

end

--[[
function widget:PlayerChanged(playerID)
  if myPlayerID == playerID then
  end
end
--]]
