function widget:GetInfo() return {
	name      = "Start Boxes",
	desc      = "Shows start-boxes during placement",
	author    = "trepan, jK, Rafal, Sprung",
	date      = "2007-2015",
	license   = "GNU GPL, v2 or later",
	layer     = 1002,
	enabled   = true,
} end

local startboxString = Spring.GetModOptions().startboxes
if not startboxString then return end -- missions and such

local startboxConfig = loadstring(startboxString)()
for id, box in pairs(startboxConfig) do
	box[1] = box[1]*Game.mapSizeX
	box[2] = box[2]*Game.mapSizeZ
	box[3] = box[3]*Game.mapSizeX
	box[4] = box[4]*Game.mapSizeZ
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local xformList = 0
local coneList = 0

local allyStartBox    = nil
local enemyStartBoxes = {}

local allyStartBoxColor  = { 0, 1, 0, 0.3 }  -- green
local enemyStartBoxColor = { 1, 0, 0, 0.3 }  -- red

local startTimer = Spring.GetTimer()

function widget:Initialize()
	-- only show at the beginning
	if ((Spring.GetGameFrame() > 1) or (Game.startPosType ~= 2)) then
		widgetHandler:RemoveWidget(self)
		return
	end

	-- flip and scale (using x & y for gl.Rect())
	xformList = gl.CreateList(function()
		gl.LoadIdentity()
		gl.Translate(0, 1, 0)
		gl.Scale(1 / Game.mapSizeX, -1 / Game.mapSizeZ, 1)
	end)

	-- cone list for world start positions
	coneList = gl.CreateList(function()
		local h = 100
		local r = 25
		local divs = 32
		gl.BeginEnd(GL.TRIANGLE_FAN, function()
			gl.Vertex( 0, h,  0)
			for i = 0, divs do
				local a = i * ((math.pi * 2) / divs)
				local cosval = math.cos(a)
				local sinval = math.sin(a)
				gl.Vertex(r * sinval, 0, r * cosval)
			end
		end)
	end)

	local myBoxID = Spring.GetTeamRulesParam(Spring.GetMyTeamID(), "start_box_id")
	if myBoxID then
		allyStartBox = startboxConfig[myBoxID]
	end

	for id, box in pairs(startboxConfig) do
		if (id ~= myBoxID) then
			table.insert(enemyStartBoxes, box)
		end
	end
end

function widget:Shutdown()
	gl.DeleteList(xformList)
	gl.DeleteList(coneList)
end

function widget:GameStart()
	widgetHandler:RemoveWidget(self)
end

local function ValidStartpos (x, y, z)
	return x and (x ~= 0) and (y ~= 0) and (z ~= 0)
end

function widget:DrawWorld()

	gl.Fog(false)

	if (allyStartBox) then
		gl.Color (allyStartBoxColor)
		gl.Utilities.DrawGroundRectangle (allyStartBox)
	end

	gl.Color(enemyStartBoxColor)
	for _,startBox in ipairs(enemyStartBoxes) do
		gl.Utilities.DrawGroundRectangle(startBox)
	end

	for _, teamID in ipairs(Spring.GetTeamList()) do
		local x, y, z = Spring.GetTeamStartPosition(teamID)
		if ValidStartpos(x,y,z) then
			local r, g, b = Spring.GetTeamColor(teamID)
			local alpha = 0.5 + math.abs(((Spring.DiffTimers(Spring.GetTimer(), startTimer) * 3) % 1) - 0.5)

			gl.PushMatrix()
				gl.Translate(x, y, z)
				gl.Lighting(false)
				gl.Color(r, g, b, alpha)
				gl.CallList(coneList)
			gl.PopMatrix()
		end
	end

	gl.Fog(true)
end

function widget:DrawScreenEffects()
	gl.Fog(false)
	gl.BeginText()

	for _, teamID in ipairs(Spring.GetTeamList()) do
		local name = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(teamID)))
		local x, y, z = Spring.GetTeamStartPosition(teamID)
		if name and ValidStartpos(x, y, z) then
			local sx, sy, sz = Spring.WorldToScreenCoords(x, y + 120, z)
			if (sz < 1) then
				local r, g, b = Spring.GetTeamColor(teamID)
				gl.Text( '\255' ..
					string.char(math.floor(r * 255)) ..
					string.char(math.floor(g * 255)) ..
					string.char(math.floor(b * 255)) ..
					name, sx, sy, 18, 'cs'
				)
			end
		end
	end

	gl.EndText()
	gl.Fog(true)
end

local dotSize = math.max(Game.mapSizeX, Game.mapSizeZ) * 0.01
function widget:DrawInMiniMap(sx, sz)

	gl.PushMatrix()
	gl.CallList(xformList)
	gl.LineWidth(1.49)

	for i = 1, #enemyStartBoxes do
		local x1, z1, x2, z2 = unpack(enemyStartBoxes[i])
		gl.Color(enemyStartBoxColor)
		gl.Rect(x1, z1, x2, z2)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
		gl.Rect(x1, z1, x2, z2)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	end

	if (allyStartBox) then
		local x1, z1, x2, z2 = unpack(allyStartBox)
		gl.Color(allyStartBoxColor)
		gl.Rect(x1, z1, x2, z2)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
		gl.Rect(x1, z1, x2, z2)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	end

	gl.LineWidth(3)
	gl.Rotate (270,1,0,0)

	for _, teamID in ipairs(Spring.GetTeamList()) do
		local x, y, z = Spring.GetTeamStartPosition(teamID)
		if ValidStartpos(x, y, z) then
			local r, g, b = Spring.GetTeamColor(teamID)
			local i = 2 * math.abs(((Spring.DiffTimers(Spring.GetTimer(), startTimer) * 3) % 1) - 0.5)
			gl.Color(i, i, i)
			gl.DrawGroundCircle(x, 0, z, dotSize * 1.2, 16)
			gl.Color(r, g, b)
			gl.DrawGroundCircle(x, 0, z, dotSize, 16)
		end
	end

	gl.LineWidth(1.0)
	gl.PopMatrix()
end
