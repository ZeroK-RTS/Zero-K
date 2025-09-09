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

include("keysym.lua")

-- There is nothing stopping you replacing the below with "games/zk.sdd/LuaRules/Configs/StartBoxes/"
local SAVE_DIR = "MapTools/StartBoxes/"

local _, GadgetStartboxUtilities = VFS.Include ("LuaRules/Gadgets/Include/startbox_utilities.lua")

local MAP_FILE        = (Game.mapName or "") .. ".lua"
local MAP_WIDTH, MAP_HEIGHT = Game.mapSizeX, Game.mapSizeZ
local LEEWAY = 20

local polygon = { }
local final_polygons = { }
local polygonPreview = false
local currentTransforms = false


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

options_path = 'Settings/Toolbox/Startbox Editor'
options_order = {'help', 'enable_mouse', 'undo_vertex', 'finish_poly', 'delete_last_poly', 'select_transform', 'write_raw', 'write_transform', 'barbarian_output'}
options = {
	enable_mouse = {
		name = "Use Mouse",
		type = "bool",
		value = false,
		advanced = true,
	},
	
	help = {
		name = 'Startbox Editor',
		type = 'text',
		value = [[Enable "Use Mouse" to start.
 - Left click to place a vertex.
 - Right click to place a vertex and then finish the polgyon.
 - Hold Ctrl for orthagonal lines.
 - Set hotkeys for the functions below.
]],
		path = scrollPath,
	},
	
	undo_vertex = {
		type = 'button',
		name = "Undo Vertex",
		desc = "Remove the mosr recently placed vertex.",
		advanced = true,
		OnChange = function ()
			polygon[#polygon] = nil
		end,
	},
	finish_poly = {
		type = 'button',
		name = "Finish Polygon",
		desc = "Finish drawing the current polygon.",
		advanced = true,
		OnChange = function ()
			final_polygons[#final_polygons+1] = polygon
			polygon = {}
		end,
	},
	delete_last_poly = {
		type = 'button',
		name = "Delete Last Polygon",
		desc = "Delete the most recently finished polygon.",
		advanced = true,
		OnChange = function ()
			final_polygons[#final_polygons] = nil
		end,
	},
	
	select_transform = {
		name = "Set Transform",
		type = 'radioButton',
		value = 'none',
		advanced = true,
		items={
			{key='none',     name='None'},
			{key='half_rot', name='Half Rotation'},
			{key='hor_mir',  name='Mirror Horizontal'},
			{key='vert_mir', name='Mirror Vertical'},
			{key='main_mir', name='Mirror Main Diagonal'},
			{key='off_mir',  name='Mirror Off Diagonal'},
			{key='four_rot', name='Four Way Rotation'},
		},
		OnChange = function(self)
			if self.value == 'none'     then
				currentTransforms = false
			elseif self.value == 'half_rot' then
				currentTransforms = {HalfRotate}
			elseif self.value == 'hor_mir'  then
				currentTransforms = {HorFlip}
			elseif self.value == 'vert_mir' then
				currentTransforms = {VertFlip}
			elseif self.value == 'main_mir' then
				currentTransforms = {MainDiagFlip}
			elseif self.value == 'off_mir'  then
				currentTransforms = {OffDiagFlip}
			elseif self.value == 'four_rot' then
			currentTransforms = {
				HalfRotate,
				QuarterRotate,
				function (pos) return QuarterRotate(HalfRotate(pos)) end,
			}
			end
		end,
	},
	
	write_raw = {
		type = 'button',
		name = "Save Startboxes Raw",
		desc = "Save startboxes, splitting boxes between teams.",
		advanced = true,
		OnChange = function ()
			Spring.Echo("Save startboxes, splitting boxes between teams. First half for one team, second half for the other.")
			SaveStartboxes()
		end,
	},
	write_transform = {
		type = 'button',
		name = "Save Startboxes Transform",
		desc = "Save startboxes, with transform.",
		advanced = true,
		OnChange = function ()
			Spring.Echo("Save startboxes, with transform")
			if currentTransforms then
				SaveStartboxesTransform()
			else
				Spring.Echo("Set a transform first")
			end
		end,
	},
	barbarian_output = {
		type = 'button',
		name = "Echo Startboxes",
		desc = "Print startboxes to the infolog like a savage.",
		advanced = true,
		OnChange = function ()
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
		end,
	},
}

function widget:MousePress(mx, my, button)
	if not options.enable_mouse.value then
		return
	end
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
	if not options.enable_mouse.value then
		return
	end
	widgetHandler:RemoveCallIn("MapDrawCmd")
	return true
end

function widget:MouseMove(mx, my)
	if not options.enable_mouse.value then
		return
	end
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
	if not options.enable_mouse.value then
		return
	end
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
