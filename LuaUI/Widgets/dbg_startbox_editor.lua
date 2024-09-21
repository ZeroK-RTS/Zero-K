function widget:GetInfo() return {
	name    = "Startbox Editor",
	desc    = "Map development tool for drawing startboxes. Consult the ZK mediawiki at Startbox_API for usage and tips",
	author  = "git blame",
	date    = "git log",
	license = "PD",
	layer   = math.huge,
	enabled = false,
} end

--[[ tl;dr
LMB to draw (either clicks or drag)
RMB to accept a polygon
D to remove last polygon
S to echo current polygons as a startbox

use S once per allyteam
copy it from infolog to the config
dont forget to change TEAM to an actual number
]]

-- There is nothing stopping you replacing the below with "games/zk.sdd/LuaRules/Configs/StartBoxes/"
local SAVE_DIR = "MapTools/StartBoxes/"

local _, GadgetStartboxUtilities = VFS.Include ("LuaRules/Gadgets/Include/startbox_utilities.lua")

local MAP_FILE        = (Game.mapName or "") .. ".lua"
local MAP_WIDTH, MAP_HEIGHT = Game.mapSizeX, Game.mapSizeZ
local LEEWAY = 20

local polygon = { }
local final_polygons = { }
local polygonPreview = false

function widget:MousePress(mx, my, button)
	if (button ~= 1 and button ~= 3) then
		return
	end
	widgetHandler:UpdateCallIn("MapDrawCmd")
	
	local pos = select(2, Spring.TraceScreenRay(mx, my, true, true))
	if not pos then
		return true
	end
	
	if pos[1] < LEEWAY then
		pos[1] = 0
	end
	if pos[3] < LEEWAY then
		pos[3] = 0
	end
	if pos[1] > MAP_WIDTH - LEEWAY then
		pos[1] = MAP_WIDTH
	end
	if pos[3] > MAP_HEIGHT - LEEWAY then
		pos[3] = MAP_HEIGHT
	end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if ctrl and #polygon > 0 then
		eastWest = math.abs(polygon[#polygon][1] - pos[1])
		northSouth = math.abs(polygon[#polygon][3] - pos[3])
		if eastWest > northSouth then
			pos[3] = polygon[#polygon][3]
		else
			pos[1] = polygon[#polygon][1]
		end
	end
	
	if (#polygon == 0) then
		polygon[#polygon+1] = pos
	else
		local dx = math.abs(pos[1] - polygon[#polygon][1])
		local dz = math.abs(pos[3] - polygon[#polygon][3])
		if (dx > 10 or dz > 10) then
			polygon[#polygon+1] = pos
		end
	end

	if (button ~= 1) then
		final_polygons[#final_polygons+1] = polygon
		polygon = {}
	end
	return true
end

function widget:MouseRelease(mx, my, button)
	widgetHandler:RemoveCallIn("MapDrawCmd")
	return true
end

function widget:MouseMove(mx, my)
	local pos = select(2, Spring.TraceScreenRay(mx, my, true))
	if not pos then
		return
	end

	if (#polygon == 0) then
		polygon[1] = pos
	else
		local dx = math.abs(pos[1] - polygon[#polygon][1])
		local dz = math.abs(pos[3] - polygon[#polygon][3])
		if (dx > 10 or dz > 10) then
			polygon[#polygon+1] = pos
		end
	end
	return true
end

include("keysym.lua")

local function HorFlip(pos)
	return {MAP_WIDTH - pos[1], pos[2]}
end

local function VertFlip(pos)
	return {pos[1], MAP_HEIGHT - pos[2]}
end

local function MainDiagFlip(pos)
	return {pos[2], pos[1]}
end

local function OffDiagFlip(pos)
	return {MAP_HEIGHT - pos[2], MAP_WIDTH - pos[1]}
end

local function QuarterRotate(pos)
	return {
		(1 - pos[2]/MAP_HEIGHT) * MAP_WIDTH,
		pos[1] * MAP_HEIGHT / MAP_WIDTH,
	}
end

local function HalfRotate(pos)
	return {
		MAP_WIDTH - pos[1],
		MAP_HEIGHT - pos[2],
	}
end

local function MakeTeamBoxes(startIndex, endIndex, Transform)
	local boxes = {}
	local startpoints = {}
	for i = startIndex, endIndex do
		local box = {}
		local left, right, top, bot = false, false, false, false
		for j = 1, #final_polygons[i] do
			local pos = final_polygons[i][j]
			local boxPos = {pos[1], pos[3]}
			if Transform then
				boxPos = Transform(boxPos)
			end
			box[#box + 1] = boxPos
			if not left or left < boxPos[1] then
				left = boxPos[1]
			end
			if not right or right > boxPos[1] then
				right = boxPos[1]
			end
			if not top or top < boxPos[2] then
				top = boxPos[2]
			end
			if not bot or bot > boxPos[2] then
				bot = boxPos[2]
			end
		end
		boxes[#boxes + 1] = box
		startpoints[#startpoints + 1] = {(left + right) / 2, (top + bot) / 2}
		Spring.Echo("Box " .. i)
	end
	if #startpoints == 0 then
		Spring.Echo("Too few polygons")
		return false
	end
	
	local nameLong, nameShort = GadgetStartboxUtilities.GetStartboxName(startpoints[1][1]/MAP_WIDTH, startpoints[1][2]/MAP_HEIGHT)
	Spring.Echo("Name: " .. nameLong .. ", " .. nameShort)
	local writeTable = {
		nameLong = nameLong,
		nameShort = nameShort,
		startpoints = startpoints,
		boxes = boxes,
	}
	return writeTable
end

local function SaveStartboxes()
	local writeTable = {
		MakeTeamBoxes(1, math.floor(#final_polygons / 2)),
		MakeTeamBoxes(math.floor(#final_polygons / 2) + 1, #final_polygons),
	}
	WG.SaveTable(writeTable, SAVE_DIR, MAP_FILE, nil, {concise = true, prefixReturn = true, endOfFile = true})
	Spring.Echo("Startboxes saved to " .. SAVE_DIR .. MAP_FILE)
end

local function SaveStartboxesTransform()
	local writeTable = {
		MakeTeamBoxes(1, #final_polygons),
	}
	for i = 1, #currentTransforms do
		writeTable[#writeTable + 1] = MakeTeamBoxes(1, #final_polygons, currentTransforms[i])
	end
	WG.SaveTable(writeTable, SAVE_DIR, MAP_FILE, nil, {concise = true, prefixReturn = true, endOfFile = true})
	Spring.Echo("Startboxes saved to " .. SAVE_DIR .. MAP_FILE)
end

function widget:KeyPress(key)
	if (key == KEYSYMS.B) then
		local str = "\t\n\t\tboxes = {\n" -- not as separate echoes because timestamp keeps getting in the way
		for j = 1, #final_polygons do
			str = str .. "\t\t\t{\n"
			local polygon = final_polygons[j]
			for i = 1, #polygon do
				local pos = polygon[i]
				str = str .. "\t\t\t\t{" .. math.floor(pos[1]) .. ", " .. math.floor(pos[3]) .. "},\n"
			end
			str = str .. "\t\t\t},\n"
		end
		str = str .. "\t\t},\n"
		Spring.Echo(str)
		return true
	end
	if (key == KEYSYMS.A) then
		Spring.Echo("Save startboxes, splitting boxes between teams")
		SaveStartboxes()
		return true
	end
	if (key == KEYSYMS.S) then
		Spring.Echo("Save startboxes, with transform")
		if currentTransforms then
			SaveStartboxesTransform()
		else
			Spring.Echo("Set a transform with R, T, Y or G first")
		end
		return true
	end
	if (key == KEYSYMS.R) then
		Spring.Echo("Set half rotation transform")
		currentTransforms = {HalfRotate}
		return true
	end
	if (key == KEYSYMS.T) then
		Spring.Echo("Set horizontal mirror transform")
		currentTransforms = {HorFlip}
		return true
	end
	if (key == KEYSYMS.Y) then
		Spring.Echo("Set vertical mirror transform")
		currentTransforms = {VertFlip}
		return true
	end
	if (key == KEYSYMS.F) then
		Spring.Echo("Set 4-way rotational transform")
		currentTransforms = {
			HalfRotate,
			QuarterRotate,
			function (pos) return QuarterRotate(HalfRotate(pos)) end,
		}
		return true
	end
	if (key == KEYSYMS.I) then
		Spring.Echo("Set main diagonal mirror")
		currentTransforms = {MainDiagFlip}
		return true
	end
	if (key == KEYSYMS.O) then
		Spring.Echo("Set off diagonal mirror")
		currentTransforms = {OffDiagFlip}
		return true
	end
	if (key == KEYSYMS.D) and (#final_polygons > 0) then
		final_polygons[#final_polygons] = nil
		return true
	end
	if (key == KEYSYMS.N) and polygon and #polygon >= 3 then
		final_polygons[#final_polygons+1] = polygon
		polygon = {}
		return true
	end
	if (key == KEYSYMS.U) and polygon and #polygon > 0 then
		polygon[#polygon] = nil
		return true
	end
end

local function DrawLine(Transform)
	for i = 1, #polygon do
		local x = polygon[i][1]
		local z = polygon[i][3]
		local y = Spring.GetGroundHeight(x, z)
		if Transform then
			pos = Transform({x, z})
			x, z = pos[1], pos[2]
		end
		gl.Vertex(x,y,z)
	end

	local mx,my = Spring.GetMouseState()
	local pos = select(2, Spring.TraceScreenRay(mx, my, true))
	if pos then
		if Transform then
			pos = Transform({pos[1], pos[3]})
			pos[3] = pos[2]
			pos[2] = Spring.GetGroundHeight(pos[1], pos[3])
		end
		gl.Vertex(pos[1],pos[2],pos[3])
	end
end

local function DrawFinalLine(fpi, Transform)
	local poly = final_polygons[fpi]
	for i = 1, #poly do
		local x = poly[i][1]
		local z = poly[i][3]
		if Transform then
			pos = Transform({x, z})
			x, z = pos[1], pos[2]
		end
		local y = Spring.GetGroundHeight(x, z)
		gl.Vertex(x,y,z)
	end
	
	local pos = poly[1]
	if Transform then
		pos = Transform({pos[1], pos[3]})
		pos[3] = pos[2]
		pos[2] = Spring.GetGroundHeight(pos[1], pos[3])
	end
	gl.Vertex(pos[1], pos[2], pos[3])
end

function widget:DrawWorld()
	if (#final_polygons == 0 and #polygon == 0) then
		return
	end
	gl.LineWidth(3.0)
	gl.Color(0, 1, 0, 0.5)
	for i = 1, #final_polygons do
		gl.BeginEnd(GL.LINE_STRIP, DrawFinalLine, i)
	end
	gl.Color(0, 1, 0, 1)
	gl.BeginEnd(GL.LINE_STRIP, DrawLine)
	gl.LineWidth(1.0)
	gl.Color(1, 1, 1, 1)
	
	if currentTransforms then
		for p = 1, #currentTransforms do
			gl.LineWidth(3.0)
			gl.Color(0, 0.5, 0.5, 0.5)
			for i = 1, #final_polygons do
				gl.BeginEnd(GL.LINE_STRIP, DrawFinalLine, i, currentTransforms[p])
			end
			gl.Color(0, 0.5, 0.5, 1)
			gl.BeginEnd(GL.LINE_STRIP, DrawLine, currentTransforms[p])
			gl.LineWidth(1.0)
			gl.Color(1, 1, 1, 1)
		end
	end
end

function widget:Initialize()
	widgetHandler:RemoveCallIn("MapDrawCmd")
end
