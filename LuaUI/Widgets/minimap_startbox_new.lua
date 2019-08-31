function widget:GetInfo() return {
	name      = "Start Boxes",
	desc      = "Shows start-boxes during placement",
	author    = "trepan, jK, Rafal, Sprung",
	date      = "2007-2015",
	license   = "GNU GPL, v2 or later",
	layer     = 1002,
	enabled   = true,
} end

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local GetRawBoxes, GetParsedBoxes = VFS.Include("LuaUI/Headers/startbox_utilities.lua")
local startboxConfig = GetParsedBoxes()

local rawBoxes = GetRawBoxes()
for boxID, boxx in pairs(rawBoxes) do
	local box = boxx.boxes
	for i = 1, #box do
		local polygon = box[i]
		local orientation = 0
		local prevX = polygon[#polygon][1]
		local prevZ = polygon[#polygon][2]
		for j = 1, #polygon do
			local x = polygon[j][1]
			local z = polygon[j][2]
			orientation = orientation + ((x - prevX)*(z + prevZ))
			prevX = x
			prevZ = z
		end
		if orientation > 0 then
			polygon.orientation = true
		else
			polygon.orientation = false
		end
	end
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local xformList = 0
local coneList = 0
local boxList = 0
local boxMinimapList = 0
local alliedBoxList = 0
local enemyBoxList = 0

local recommendedStartpoints
local myTeammates = Spring.GetTeamList(Spring.GetMyAllyTeamID())
local allyStartBox    = nil
local enemyStartBoxes = {}
local allyStartBoxRaw    = nil
local enemyStartBoxesRaw = {}

local allyStartBoxColor  = { 0, 1, 0, 0.3 }  -- green
local enemyStartBoxColor = { 1, 0, 0, 0.3 }  -- red
local recommendedStartposRadius = 256

local startTimer = Spring.GetTimer()

local function drawOwnBox ()
	if not allyStartBox then return end
	gl.BeginEnd(GL.TRIANGLES, function()
		for i = 1, #allyStartBox do
			local x1, z1, x2, z2, x3, z3 = unpack(allyStartBox[i])
			gl.Vertex(x1, -1, z1)
			gl.Vertex(x3, -1, z3)
			gl.Vertex(x2, -1, z2)
			gl.Vertex(x1,  1, z1)
			gl.Vertex(x2,  1, z2)
			gl.Vertex(x3,  1, z3)
		end
	end)
	for j = 1, #allyStartBoxRaw do
		local polygon = allyStartBoxRaw[j]
		gl.BeginEnd(GL.QUAD_STRIP, function()
			if polygon.orientation then
				for i = 1, #polygon do
					local x = polygon[i][1]
					local z = polygon[i][2]
					gl.Vertex(x, 1, z)
					gl.Vertex(x, -1, z)
				end
				gl.Vertex(polygon[1][1],  1, polygon[1][2])
				gl.Vertex(polygon[1][1], -1, polygon[1][2])
			else
				gl.Vertex(polygon[1][1],  1, polygon[1][2])
				gl.Vertex(polygon[1][1], -1, polygon[1][2])
				for i = #polygon, 1, -1 do
					local x = polygon[i][1]
					local z = polygon[i][2]
					gl.Vertex(x, 1, z)
					gl.Vertex(x, -1, z)
				end
			end
		end)
	end
end

local function drawEnemyBoxes ()
	gl.BeginEnd(GL.TRIANGLES, function()
		for j = 1, #enemyStartBoxes do
			local box = enemyStartBoxes[j]
			for i = 1, #box do
				local x1, z1, x2, z2, x3, z3 = unpack(box[i])
				gl.Vertex(x1, -1, z1)
				gl.Vertex(x3, -1, z3)
				gl.Vertex(x2, -1, z2)
				gl.Vertex(x1,  1, z1)
				gl.Vertex(x2,  1, z2)
				gl.Vertex(x3,  1, z3)
			end
		end
	end)
	for k = 1, #enemyStartBoxesRaw do
		local box = enemyStartBoxesRaw[k]
		for j = 1, #box do
			local polygon = box[j]
			gl.BeginEnd(GL.QUAD_STRIP, function()
				if polygon.orientation then
					for i = 1, #polygon do
						local x = polygon[i][1]
						local z = polygon[i][2]
						gl.Vertex(x, 1, z)
						gl.Vertex(x, -1, z)
					end
					gl.Vertex(polygon[1][1],  1, polygon[1][2])
					gl.Vertex(polygon[1][1], -1, polygon[1][2])
				else
					gl.Vertex(polygon[1][1],  1, polygon[1][2])
					gl.Vertex(polygon[1][1], -1, polygon[1][2])
					for i = #polygon, 1, -1 do
						local x = polygon[i][1]
						local z = polygon[i][2]
						gl.Vertex(x, 1, z)
						gl.Vertex(x, -1, z)
					end
				end
			end)
		end
	end
end

local function drawBoxes()
	local minY, maxY = Spring.GetGroundExtremes()
	local avgY = (maxY+minY)/2
	local sumY = (maxY-minY) + 100 -- with some leeway

	gl.PushMatrix()
	gl.Translate(0, avgY, 0)
	gl.Scale(1, sumY, 1)
	gl.DepthMask(false)
	gl.StencilTest(true)
	gl.Culling(false)
	gl.DepthTest(true)
	gl.ColorMask(false, false, false, false)
	gl.StencilOp(GL.KEEP, GL.INCR, GL.KEEP)
	gl.StencilMask(0x11)
	gl.StencilFunc(GL.ALWAYS, 0, 0)

	gl.CallList(alliedBoxList)
	gl.CallList(enemyBoxList)

	gl.Culling(GL.FRONT)
	gl.DepthTest(false)
	gl.ColorMask(true, true, true, true)
	gl.StencilOp(GL.ZERO, GL.ZERO, GL.ZERO)
	gl.StencilMask(0x11)
	gl.StencilFunc(GL.NOTEQUAL, 0, 0+1)

	gl.Color(allyStartBoxColor)
	gl.CallList(alliedBoxList)
	gl.Color(enemyStartBoxColor)
	gl.CallList(enemyBoxList)

	gl.StencilTest(false)
	gl.Culling(false)
	gl.PopMatrix()
end

local function drawBoxesMinimap()
	if (allyStartBox) then
		gl.Color (allyStartBoxColor)
		for i = 1, #allyStartBox do
			local x1, z1, x2, z2, x3, z3 = unpack(allyStartBox[i])
			gl.Shape (GL.TRIANGLES, {
				{ v = {x1, z1, 0} },
				{ v = {x2, z2, 0} },
				{ v = {x3, z3, 0} },
			})
		end
	end

	gl.Color(enemyStartBoxColor)
	for i = 1, #enemyStartBoxes do
		local box = enemyStartBoxes[i]
		for j = 1, #box do
			local x1, z1, x2, z2, x3, z3 = unpack(box[j])
			gl.Shape (GL.TRIANGLES, {
				{ v = {x1, z1, 0} },
				{ v = {x2, z2, 0} },
				{ v = {x3, z3, 0} },
			})
		end
	end
end

function widget:Initialize()
	-- only show at the beginning
	if (Spring.GetGameFrame() > 1) or (Game.startPosType ~= 2) or (Spring.GetModOptions().fixedstartpos == "1") then
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
	if myBoxID and startboxConfig[myBoxID] then
		allyStartBox = startboxConfig[myBoxID].boxes
		allyStartBoxRaw = rawBoxes[myBoxID].boxes
		recommendedStartpoints = startboxConfig[myBoxID].startpoints
	end

	local shuffleMode = Spring.GetGameRulesParam("shuffleMode")
	if (shuffleMode ~= "allshuffle") then -- only draw occupied boxes
		local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
		local allyTeamList = Spring.GetAllyTeamList()
		local actualAllyTeamList = {}
		for i = 1, #allyTeamList do
			local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
			if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
				actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
			end
		end

		for i = 1, #actualAllyTeamList do
			local id = actualAllyTeamList[i]
			if ((id ~= myBoxID) and startboxConfig[id] and startboxConfig[id].boxes) then
				table.insert(enemyStartBoxes, startboxConfig[id].boxes)
				table.insert(enemyStartBoxesRaw, rawBoxes[id].boxes)
			end
		end
	else -- occupied boxes unknown; draw all
		for id, box in pairs(startboxConfig) do
			if (id ~= myBoxID and box.boxes) then
				table.insert(enemyStartBoxes, box.boxes)
				table.insert(enemyStartBoxesRaw, rawBoxes[id].boxes)
			end
		end
	end

	alliedBoxList = gl.CreateList(drawOwnBox)
	enemyBoxList = gl.CreateList(drawEnemyBoxes)
	boxList = gl.CreateList(drawBoxes)
	boxMinimapList = gl.CreateList(drawBoxesMinimap)
end

function widget:Update()
	if Spring.GetGameRulesParam("totalSaveGameFrame") then
		Spring.SendCommands("forcestart")
		widgetHandler:RemoveWidget()
	end
end

function widget:Shutdown()
	gl.DeleteList(xformList)
	gl.DeleteList(coneList)
	gl.DeleteList(boxList)
	gl.DeleteList(boxMinimapList)
	gl.DeleteList(alliedBoxList)
	gl.DeleteList(enemyBoxList)
end

function widget:GameStart()
	widgetHandler:RemoveWidget(self)
end

local function ValidStartpos (x, y, z)
	return x and (x ~= 0) and (y ~= 0) and (z ~= 0)
end

function widget:DrawWorld()

	gl.Fog(false)

	gl.CallList(boxList)

	if (allyStartBox and recommendedStartpoints) then
		gl.Color (allyStartBoxColor)
		gl.LineWidth(3)
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINES)
		for i = 1, #recommendedStartpoints do
			local x = recommendedStartpoints[i][1]
			local z = recommendedStartpoints[i][2]
			local empty = true
			for j = 1, #myTeammates do
				local tx, _, tz = Spring.GetTeamStartPosition(myTeammates[j])
				if ((tx-x)^2 + (tz-z)^2 < recommendedStartposRadius^2) then
					empty = false
				end
			end
			if empty then gl.DrawGroundCircle(x, 0, z, recommendedStartposRadius, 19) end
		end
		gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
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

local function GetTeamName(teamID)
	local _, leaderID, _, isAiTeam = Spring.GetTeamInfo(teamID, false)
	if isAiTeam then
		local aiName = select(2, Spring.GetAIInfo(teamID))
		if aiName then
			return aiName
		end
	end

	if not leaderID then
		return
	end
	local playerName = Spring.GetPlayerInfo(leaderID, false)
	if not playerName then
		return
	end
	if isAiTeam then
		return "AI (" .. playerName .. ")"
	end
	return playerName
end

function widget:DrawScreenEffects()
	gl.Fog(false)
	gl.BeginText()

	for _, teamID in ipairs(Spring.GetTeamList()) do
		local name = GetTeamName(teamID)
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

local boxes_loaded_minimap = false
function widget:DrawInMiniMap(minimapX, minimapY)

	gl.PushMatrix()
	gl.CallList(xformList)
	gl.LineWidth(1.49)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)

	gl.CallList(boxMinimapList)

	gl.Color(1,1,1,1)
	gl.LineWidth(1.0)
	gl.PopMatrix()

	local dotSize = math.max(minimapX, minimapY) * 0.3
	gl.PushMatrix()
	gl.LineWidth(3)
	gl.Translate(0, minimapY, 0)
	gl.Scale(minimapX/mapX, -minimapY/mapZ, 1)
	
	for _, teamID in ipairs(Spring.GetTeamList()) do
		local x, y, z = Spring.GetTeamStartPosition(teamID)
		if ValidStartpos(x, y, z) then
			local r, g, b = Spring.GetTeamColor(teamID)
			local i = 2 * math.abs(((Spring.DiffTimers(Spring.GetTimer(), startTimer) * 3) % 1) - 0.5)
			gl.Color(i, i, i)
			gl.Utilities.DrawCircle(x, z, dotSize * 1.2)
			gl.Color(r, g, b)
			gl.Utilities.DrawCircle(x, z, dotSize)
		end
	end
	gl.PopMatrix()
end
