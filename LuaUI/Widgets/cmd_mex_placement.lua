
function widget:GetInfo()
	return {
		name      = "Mex Placement Handler",
		desc      = "Places mexes in the correct position",
		author    = "Google Frog with some from Niobium and Evil4Zerggin.",
		version   = "v1",
		date      = "22 April, 2012", --2 April 2013
		license   = "GNU GPL, v2 or later",
		layer     = 1001, -- Under Chili
		enabled   = true,
		alwaysStart = true,
		handler   = true
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local _, _, GetAllyTeamOctant = VFS.Include("LuaUI/Headers/startbox_utilities.lua")
local GetMiniMapFlipped = Spring.Utilities.IsMinimapFlipped
include("keysym.lua")

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetTeamUnits        = Spring.GetTeamUnits
local spGetMyTeamID         = Spring.GetMyTeamID
local spTestBuildOrder      = Spring.TestBuildOrder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGiveOrder           = Spring.GiveOrder
local spGetGroundInfo       = Spring.GetGroundInfo
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetMapDrawMode      = Spring.GetMapDrawMode
local spGetGameFrame        = Spring.GetGameFrame
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetAllUnits         = Spring.GetAllUnits
local spGetPositionLosState = Spring.GetPositionLosState

local glLineWidth        = gl.LineWidth
local glColor            = gl.Color
local glRect             = gl.Rect
local glText             = gl.Text
local glGetTextWidth     = gl.GetTextWidth
local glPolygonMode      = gl.PolygonMode
local glDrawGroundCircle = gl.DrawGroundCircle
local glUnitShape        = gl.UnitShape
local glDepthTest        = gl.DepthTest
local glLighting         = gl.Lighting
local glScale            = gl.Scale
local glBillboard        = gl.Billboard
local glAlphaTest        = gl.AlphaTest
local glTexture          = gl.Texture
local glTexRect          = gl.TexRect
local glVertex           = gl.Vertex
local glBeginEnd         = gl.BeginEnd
local glLoadIdentity     = gl.LoadIdentity
local glRotate           = gl.Rotate
local glPopMatrix        = gl.PopMatrix
local glPushMatrix       = gl.PushMatrix
local glTranslate        = gl.Translate
local glCallList         = gl.CallList
local glCreateList       = gl.CreateList
local glDrawCircle

local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL           = GL.FILL
local GL_GREATER         = GL.GREATER

local abs   = math.abs
local floor = math.floor
local max   = math.max
local min   = math.min
local strFind = string.find
local strFormat = string.format

local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local sqrt = math.sqrt
local tasort = table.sort
local taremove = table.remove

local myAllyTeam = spGetMyAllyTeamID()

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local METAL_MAP_SQUARE_SIZE = Game.metalMapSquareSize
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local MEX_WALL_SIZE = 8 * 6
local MEX_HOLE_SIZE = 3 * 6

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

WG.mouseoverMexIncome = 0

local spotByID = {}
local spotData = {}
local spotHeights = {}

local wantDrawListUpdate = false

local wasSpectating = spGetSpectatingState()
local metalSpotsNil = true

local metalmult = tonumber(Spring.GetModOptions().metalmult) or 1
local metalmultInv = metalmult > 0 and (1/metalmult) or 1

local myPlayerID = Spring.GetMyPlayerID()
local myOctant = 1
local pregame = true

local placedMexSinceShiftPressed = false

------------------------------------------------------------
-- Config
------------------------------------------------------------

local TEXT_SIZE = 16
local TEXT_CORRECT_Y = 1.25

local PRESS_DRAG_THRESHOLD_SQR = 25^2
local MINIMAP_DRAW_SIZE = math.max(mapX,mapZ) * 0.0145

options_path = 'Settings/Interface/Map/Metal Spots'
options_order = { 'drawicons', 'size', 'rounding', 'catlabel', 'area_point_command', 'catlabel_terra', 'wall_low', 'wall_high', 'burry_shallow', 'burry_deep'}
options = {
	drawicons = {
		name = 'Show Income as Icon',
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = "Enabled: income is shown pictorially.\nDisabled: income is shown as a number.",
		OnChange = function() updateMexDrawList() end
	},
	size = {
		name = "Income Display Size",
		desc = "How large should the font or icon be?",
		type = "number",
		value = 40,
		min = 10,
		max = 150,
		step = 5,
		update_on_the_fly = true,
		advanced = true,
		OnChange = function() updateMexDrawList() end
	},
	rounding = {
		name = "Display decimal digits",
		desc = "How precise should the number be?\nNo effect on icons.",
		type = "number",
		value = 1,
		min = 1,
		max = 4,
		update_on_the_fly = true,
		advanced = true,
		tooltip_format = "%.0f", -- show 1 instead of 1.0 (confusion)
		OnChange = function() updateMexDrawList() end
	},
	catlabel = {
		name = 'Area Mex',
		type = 'label',
		path = 'Settings/Interface/Building Placement',
	},
	area_point_command = {
		name = 'Point click queues mex',
		type = 'bool',
		value = true,
		desc = "Clicking on the map with Area Mex or Area Terra Mex snaps to the nearest spot, like placing a mex.",
		path = 'Settings/Interface/Building Placement',
	},
	catlabel_terra = {
		name = 'Area Terra Mex (Alt+W by default)',
		type = 'label',
		path = 'Settings/Interface/Building Placement',
	},
	wall_low = {
		name = "Low Wall height",
		desc = "How high should a default terraformed wall be?",
		type = "number",
		value = 40,
		min = 2,
		max = 120,
		step = 1,
		path = 'Settings/Interface/Building Placement',
	},
	wall_high = {
		name = "High Wall height",
		desc = "How high should a tall terraformed wall (hold Ctrl) be?",
		type = "number",
		value = 75,
		min = 2,
		max = 120,
		step = 1,
		path = 'Settings/Interface/Building Placement',
	},
	burry_shallow = {
		name = "Shallow burry depth",
		desc = "How deep should a burried mex (hold Alt) be?",
		type = "number",
		value = 55,
		min = 2,
		max = 120,
		step = 1,
		path = 'Settings/Interface/Building Placement',
	},
	burry_deep = {
		name = "Deep burry depth",
		desc = "How deep should a deeper burried mex (hold Alt+Ctrl) be?",
		type = "number",
		value = 90,
		min = 2,
		max = 120,
		step = 1,
		path = 'Settings/Interface/Building Placement',
	},
}

local centerX
local centerZ
local extraction = 0

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Mexes and builders

local mexDefIDs = {}
for i = 1, #UnitDefs do
	if UnitDefs[i].customParams.metal_extractor_mult then
		mexDefIDs[i] = true
	end
end

local primaryMexDefID = UnitDefNames["staticmex"].id -- FIXME: let mods specify a different one?

local lltDefID = UnitDefNames["turretlaser"].id
local solarDefID = UnitDefNames["energysolar"].id
local windDefID = UnitDefNames["energywind"].id

local mexUnitDef = UnitDefs[primaryMexDefID]
local mexDefInfo = {
	extraction = 0.001,
	oddX = mexUnitDef.xsize % 4 == 2,
	oddZ = mexUnitDef.zsize % 4 == 2,
}

local mexBuilder = {}

local mexBuilderDefs = {}
for udid, ud in ipairs(UnitDefs) do
	for i, option in ipairs(ud.buildOptions) do
		if mexDefIDs[option] then
			mexBuilderDefs[udid] = option -- FIXME: modded builders can build many mexes, make this a set?
		end
	end
end

local addons = { -- coordinates of solars for the Ctrl Alt modifier key, indexed by allyTeam start position
                 -- The first two solars are in front, this is partially to make use of solar tankiness,
                 -- but also because cons typically approach from the back so would otherwise be standing
                 -- on the buildspot and have to waste time moving away
	{ -- North East East
		{-64, -16 },
		{-16,  64 },
		{ 64,  16 },
		{ 16, -64 },
	},
	{ -- North North East
		{ 16,  64 },
		{-64,  16 },
		{-16, -64 },
		{ 64, -16 },
	},
	{ -- North North West
		{-16,  64 },
		{ 64,  16 },
		{ 16, -64 },
		{-64, -16 },
	},
	{ -- Nort West West
		{ 64, -16 },
		{ 16,  64 },
		{-64,  16 },
		{-16, -64 },
	},
	{ -- South West West
		{ 64,  16 },
		{ 16, -64 },
		{-64, -16 },
		{-16,  64 },
	},
	{ -- South South West
		{-16, -64 },
		{ 64, -16 },
		{ 16,  64 },
		{-64,  16 },
	},
	{ -- South South East
		{ 16, -64 },
		{-64, -16 },
		{-16,  64 },
		{ 64,  16 },
	},
	{ -- South East East
		{-64,  16 },
		{-16, -64 },
		{ 64, -16 },
		{ 16,  64 },
	},
}

------------------------------------------------------------
-- Functions
------------------------------------------------------------

local function GetClosestMetalSpot(x, z) --is used by single mex placement, not used by areamex
	local bestSpot
	local bestDist = math.huge
	local bestIndex
	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local dx, dz = x - spot.x, z - spot.z
		local dist = dx*dx + dz*dz
		if dist < bestDist then
			bestSpot = spot
			bestDist = dist
			bestIndex = i
		end
	end
	return bestSpot, sqrt(bestDist), bestIndex
end

local function Distance(x1,z1,x2,z2)
	local dis = (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
	return dis
end

local function IsSpotBuildable(index)
	if not index then
		return true
	end
	local spot = spotData[index]
	if not spot then
		return true
	end

	local unitID = spot.unitID
	if unitID and spGetUnitAllyTeam(unitID) == spGetMyAllyTeamID() then
		local build = select(5, spGetUnitHealth(unitID))
		if build and build < 1 then
			return true
		end
	end
	return false
end

local function IntegrateMetal(x, z, forceUpdate)
	local newCenterX, newCenterZ

	if (mexDefInfo.oddX) then
		newCenterX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterX = floor( x / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end

	if (mexDefInfo.oddZ) then
		newCenterZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterZ = floor( z / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end

	if (centerX == newCenterX and centerZ == newCenterZ and not forceUpdate) then
		return
	end

	centerX = newCenterX
	centerZ = newCenterZ

	local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)

	local mult = mexDefInfo.extraction
	local result = 0

	for i = startX, endX do
		for j = startZ, endZ do
			local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
			local dx, dz = cx - centerX, cz - centerZ
			local dist = sqrt(dx * dx + dz * dz)

			if (dist < MEX_RADIUS) then
				local _, metal = spGetGroundInfo(cx, cz)
				result = result + metal
			end
		end
	end

	extraction = result * mult
end

------------------------------------------------------------
-- Command Handling
------------------------------------------------------------

local function MakeOptions()
	local a, c, m, s = Spring.GetModKeyState()
	local coded = (a and CMD.OPT_ALT or 0) +
	              (c and CMD.OPT_CTRL or 0) +
	              (m and CMD.OPT_META or 0) +
	              (s and CMD.OPT_SHIFT or 0)
	
	return {
		alt   = a and true or false,
		ctrl  = c and true or false,
		meta  = m and true or false,
		shift = s and true or false,
		coded = coded,
		internal = false,
		right = false,
	}
end

local function PlaceSingleMex(bx, bz, facing, options)
	local facing = Spring.GetBuildFacing() or 0
	local options = MakeOptions()

	local closestSpot = GetClosestMetalSpot(bx, bz)
	if closestSpot then
		local units = spGetUnitsInRectangle(closestSpot.x-1, closestSpot.z-1, closestSpot.x+1, closestSpot.z+1)
		local foundUnit = false
		local foundEnemy = false
		for i = 1, #units do
			local unitID = units[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			if mexDefIDs[unitDefID] then
				if spGetUnitAllyTeam(unitID) == spGetMyAllyTeamID() then
					foundUnit = unitID
				else
					foundEnemy = true
				end
				break
			end
		end

		if foundEnemy then
			return true, true
		elseif foundUnit then
			local build = select(5, spGetUnitHealth(foundUnit))
			if build ~= 1 then
				if options.meta then
					WG.CommandInsert(CMD.REPAIR, {foundUnit}, options)
				else
					spGiveOrder(CMD.REPAIR, {foundUnit}, options)
				end
				WG.noises.PlayResponse(false, CMD.REPAIR)
				return true, options.shift
			end
			return true, true
		else
			local mexDefID = primaryMexDefID
			local _, cmdID = spGetActiveCommand()
			if cmdID and mexDefIDs[-cmdID] then
				mexDefID = -cmdID
			end

			-- check if some other widget wants to handle the command before sending it to units.
			local commandHeight = math.max(0, Spring.GetGroundHeight(closestSpot.x, closestSpot.z))
			if Spring.TestBuildOrder(mexDefID, closestSpot.x, commandHeight, closestSpot.z, facing) == 0 then
				return true, true
			end
			local params = {closestSpot.x, commandHeight, closestSpot.z, facing}
			local GBC_processed = WG.GlobalBuildCommand and WG.GlobalBuildCommand.CommandNotifyMex(-mexDefID, params, options, false)
			if not GBC_processed then
				if pregame then
					WG.InitialQueueHandleCommand(-mexDefID, params, options)
				elseif options.meta then
					WG.CommandInsert(-mexDefID, params, options)
				else
					spGiveOrder(-mexDefID, params, options)
				end
				WG.noises.PlayResponse(false, -mexDefID)
			end
			return true, options.shift
		end
	end
	return false, options.shift
end

local function MakeMexTerraform(units, pointX, pointZ, height, holeMode)
	if not (units and units[1]) then
		return false
	end

	local pointY = Spring.GetGroundHeight(pointX, pointZ)
	if pointY < -25 or (height < 0 and pointY < 0) then
		return false
	end
	pointY = math.max(pointY, 0)
	
	-- Setup parameters for terraform command
	local team = Spring.GetUnitTeam(units[1]) or Spring.GetMyTeamID()
	local commandTag = WG.Terraform_GetNextTag()
	
	local params = {}
	params[1] = 1            -- terraform type = level
	params[2] = team
	params[3] = pointX
	params[4] = pointZ
	params[5] = commandTag
	params[6] = 1               -- Loop parameter
	params[7] = math.max(pointY + height, 0) -- Height parameter of terraform
	params[8] = 5               -- Five points in the terraform
	params[9] = #units          -- Number of constructors with the command
	params[10] = (height > 0 and 1) or 2 -- Raise-only or lower only depending on direction.
	
	-- Rectangle of terraform
	local rectangleSize = (holeMode and MEX_HOLE_SIZE) or MEX_WALL_SIZE
	params[11]  = pointX + rectangleSize
	params[12] = pointZ + rectangleSize
	params[13] = pointX + rectangleSize
	params[14] = pointZ - rectangleSize
	params[15] = pointX - rectangleSize
	params[16] = pointZ - rectangleSize
	params[17] = pointX - rectangleSize
	params[18] = pointZ + rectangleSize
	params[19] = pointX + rectangleSize
	params[20] = pointZ + rectangleSize
	
	-- Set constructors
	local i = 21
	for j = 1, 1 do
		params[i] = units[i]
		i = i + 1
	end
	
	Spring.GiveOrderToUnit(units[1], CMD_TERRAFORM_INTERNAL, params, 0)
	
	return {CMD_LEVEL, {pointX, pointY, pointZ, commandTag}}
end

local function HandleAreaMex(cmdID, cx, cy, cz, cr, cmdOpts)
	local xmin = cx-cr
	local xmax = cx+cr
	local zmin = cz-cr
	local zmax = cz+cr

	local commands = {}
	local orderedCommands = {}
	local dis = {}

	local ux = 0
	local uz = 0
	local us = 0

	local aveX = 0
	local aveZ = 0

	local mexDefID = primaryMexDefID
	local units = spGetSelectedUnits()
	for i = 1, #units do
		local unitID = units[i]
		local buildableMexDefID = mexBuilder[unitID]
		if buildableMexDefID then
			mexDefID = buildableMexDefID
			local x,_,z = spGetUnitPosition(unitID)
			ux = ux+x
			uz = uz+z
			us = us+1
		end
	end

	if pregame then
		if WG.InitialQueueGetTail and WG.InitialQueueGetTail() then
			aveX, aveZ = WG.InitialQueueGetTail()
		else
			aveX = Game.mapSizeX / 2
			aveZ = Game.mapSizeZ / 2
		end
	elseif (us == 0) then
		return
	else
		aveX = ux/us
		aveZ = uz/us
	end
	
	local terraMode = (cmdID == CMD_AREA_TERRA_MEX)
	local energyToMake = 0
	local burryMode = false
	local wallHeight = options.wall_low.value
	if cmdOpts.ctrl then
		if cmdOpts.alt then
			energyToMake = 4
			burryMode = true
			wallHeight = options.burry_deep.value
		else
			energyToMake = 1
			wallHeight = options.wall_high.value
		end
	elseif cmdOpts.alt then
		energyToMake = 2
		burryMode = true
		wallHeight = options.burry_shallow.value
	end
	local makeMexEnergy = (not terraMode) and (energyToMake > 0)

	for i = 1, #WG.metalSpots do
		local mex = WG.metalSpots[i]
		--if (mex.x > xmin) and (mex.x < xmax) and (mex.z > zmin) and (mex.z < zmax) then -- square area, should be faster
		if (Distance(cx, cz, mex.x, mex.z) < cr*cr) and (makeMexEnergy or (terraMode and not burryMode) or IsSpotBuildable(i)) then -- circle area, slower
			commands[#commands+1] = {x = mex.x, z = mex.z, d = Distance(aveX,aveZ,mex.x,mex.z)}
		end
	end

	local noCommands = #commands
	while noCommands > 0 do
		tasort(commands, function(a,b) return a.d < b.d end)
		orderedCommands[#orderedCommands+1] = commands[1]
		aveX = commands[1].x
		aveZ = commands[1].z
		taremove(commands, 1)
		for k, com in pairs(commands) do
			com.d = Distance(aveX,aveZ,com.x,com.z)
		end
		noCommands = noCommands-1
	end

	local shift = cmdOpts.shift

	do --issue ordered order to unit(s)
		local commandArrayToIssue={}
		local unitArrayToReceive ={}
		for i = 1, #units do --prepare unit list
			local unitID = units[i]
			if mexBuilder[unitID] then
				unitArrayToReceive[#unitArrayToReceive+1] = unitID
			end
		end
		
		-- If ctrl or alt is held and the first metal spot is blocked by a mex, then the mex command is blocked
		-- and the remaining commands are issused with shift. This causes the area mex command to act as if shift
		-- where hold even when it is not. I do not know why this issue is absent when no modkey are held.
		if makeMexEnergy and not (cmdOpts.shift or cmdOpts.meta) then
			commandArrayToIssue[#commandArrayToIssue+1] = {CMD.STOP, {} }
		end
		
		--prepare command list
		for i, command in ipairs(orderedCommands) do
			local x = command.x
			local z = command.z
			local y = math.max(0, Spring.GetGroundHeight(x, z))

			-- check if some other widget wants to handle the command before sending it to units.
			if not WG.GlobalBuildCommand or not WG.GlobalBuildCommand.CommandNotifyMex(-mexDefID, {x, y, z, 0}, cmdOpts, true) then
				if terraMode and burryMode then
					local params = MakeMexTerraform(units, x, z, -wallHeight, true)
					if params then
						commandArrayToIssue[#commandArrayToIssue + 1] = params
					end
				end
				commandArrayToIssue[#commandArrayToIssue + 1] = {-mexDefID, {x,y,z,0}}
				if terraMode and not burryMode then
					local params = MakeMexTerraform(units, x, z, wallHeight)
					if params then
						commandArrayToIssue[#commandArrayToIssue + 1] = params
					end
				end
			end

			if makeMexEnergy then
				for i = 1, energyToMake do
					local addon = addons[myOctant][i]
					local xx = x+addon[1]
					local zz = z+addon[2]
					local yy = math.max(0, Spring.GetGroundHeight(xx, zz))
					local buildDefID = (Spring.TestBuildOrder(solarDefID, xx, yy, zz, 0) == 0 and windDefID) or solarDefID

					-- check if some other widget wants to handle the command before sending it to units.
					if not WG.GlobalBuildCommand or not WG.GlobalBuildCommand.CommandNotifyMex(-buildDefID, {xx, yy, zz, 0}, cmdOpts, true) then
						commandArrayToIssue[#commandArrayToIssue+1] = {-buildDefID, {xx,yy,zz,0} }
					end
				end
			end
		end

		for i = 1, #commandArrayToIssue do
			local command = commandArrayToIssue[i]
			if pregame then
				WG.InitialQueueHandleCommand(command[1], command[2], cmdOpts)
				if i == 1 then
					cmdOpts.shift = true
				end
			else
				WG.CommandInsert(command[1], command[2], cmdOpts, i - 1, true)
			end
		end
	end

	return true
end

function widget:CommandNotify(cmdID, params, cmdOpts)
	if not WG.metalSpots then
		return false
	end
	
	if (cmdID == CMD_AREA_MEX or cmdID == CMD_AREA_TERRA_MEX) and ((params[4] or 0) > 1 or not options.area_point_command.value) then
		local cx, cy, cz, cr = params[1], params[2], params[3], math.max((params[4] or 60),60)
		return HandleAreaMex(cmdID, cx, cy, cz, cr, cmdOpts)
	end

	if (cmdID == CMD_AREA_MEX or cmdID == CMD_AREA_TERRA_MEX or mexDefIDs[-cmdID]) and params[3] then
		-- Just area mex on the closest spot. Reuses all the code for key modifiers.
		local bx, bz = params[1], params[3]
		local closestSpot = GetClosestMetalSpot(bx, bz)
		if closestSpot then
			local cx, cz = closestSpot.x, closestSpot.z
			local cy = spGetGroundHeight(cx, cz)
			return HandleAreaMex(cmdID, cx, cy, cz, 30, cmdOpts)
		end
		return false
	end
end


function widget:UnitEnteredLos(unitID, teamID)
	if spGetSpectatingState() then
		return
	end

	local unitDefID = Spring.GetUnitDefID(unitID)
	if not mexDefIDs[unitDefID] or not WG.metalSpots then
		return
	end

	local x,_,z = Spring.GetUnitPosition(unitID)
	local spotID = WG.metalSpotsByPos[x] and WG.metalSpotsByPos[x][z]
	if not spotID then
		return
	end

	spotByID[unitID] = spotID
	spotData[spotID] = {unitID = unitID, team = teamID, enemy = true}
	updateMexDrawList()
end

local function DidMexDie(unitID, expectedSpotID) --> dead, idReusedForAnotherMex
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not mexDefIDs[unitDefID] then -- not just a nil check, the unitID could have gotten recycled for another unit
		return true, false
	end

	local spotID = spotByID[unitID]
	if spotID ~= expectedSpotID then
		return true, true -- the original died, unitID was recycled to another mex
	end

	return false
end

local function CheckEnemyMexes(spotID)
	local spotD = spotData[spotID]
	if not spotD or not spotD.enemy then
		return
	end

	local spotM = WG.metalSpots[spotID]
	local x = spotM.x
	local z = spotM.z
	local los = Spring.GetPositionLosState(x, 0, z)
	if not los then
		return
	end

	local unitID = spotD.unitID
	local dead, idReusedForAnotherMex = DidMexDie(unitID, spotID)
	if not dead then
		return
	end

	if not idReusedForAnotherMex then
		spotByID[unitID] = nil
	end

	spotData[spotID] = nil
	wantDrawListUpdate = true
end

local function CheckTerrainChange(spotID)
	local spot = WG.metalSpots[spotID]
	local x = spot.x
	local z = spot.z

	local y = max(0, spGetGroundHeight(x, z))

	-- some leeway to avoid too much draw list recreation
	-- since a lot of weapons have small but nonzero cratering
	if abs(y - spotHeights[spotID]) > 1 then
		spotHeights[spotID] = y
		wantDrawListUpdate = true
	end
end

local function CheckAllTerrainChanges()
	for i = 1, #WG.metalSpots do
		CheckEnemyMexes(i)
		CheckTerrainChange(i)
	end
end

------------------------------------------------------------
-- Callins
------------------------------------------------------------

function widget:MousePress(x, y, button)
	if pregame or button ~= 1 then
		-- Let initial queue handle mex placement.
		return false
	end
	local _, cmdID = spGetActiveCommand()
	if (cmdID and mexDefIDs[-cmdID] and WG.metalSpots) then
		return true
	end
	return false
end

function widget:MouseRelease(x, y, button)
	if pregame or (WG.Terraform_GetIsPlacingStructure and WG.Terraform_GetIsPlacingStructure()) then
		-- Let initial queue and terraform handle mex placement.
		return false
	end
	if button ~= 1 then
		Spring.SetActiveCommand(nil)
		return false
	end
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true)
	if coords then
		local _, retain = PlaceSingleMex(coords[1], coords[3])
		placedMexSinceShiftPressed = true
		if not retain then
			Spring.SetActiveCommand(nil)
		end
	end
	return true
end

function widget:GameFrame(n)
	pregame = false
	if not WG.metalSpots or (n % 5) ~= 0 then
		return
	end

	CheckAllTerrainChanges()
	if wantDrawListUpdate then
		wantDrawListUpdate = false
		updateMexDrawList()
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	local mexDefID = mexBuilderDefs[unitDefID]
	if mexDefID then
		mexBuilder[unitID] = mexDefID
		return
	end

	if not mexDefIDs[unitDefID] or not WG.metalSpots then
		return
	end

	local x,_,z = Spring.GetUnitPosition(unitID)
	local spotID = WG.metalSpotsByPos[x] and WG.metalSpotsByPos[x][z]
	if not spotID then
		return
	end

	spotByID[unitID] = spotID
	spotData[spotID] = {unitID = unitID, team = teamID}
	updateMexDrawList()
end

function widget:UnitDestroyed(unitID, unitDefID)
	if mexBuilder[unitID] then
		mexBuilder[unitID] = nil
	end

	local spotID = spotByID[unitID]
	if mexDefIDs[unitDefID] and spotID then
		local morpheeID = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
		if morpheeID then
			spotData[spotID].unitID = morpheeID
			spotByID[morpheeID] = spotID
		else
			spotData[spotID] = nil
		end
		spotByID[unitID] = nil
		updateMexDrawList()
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	local mexDefID = mexBuilderDefs[unitDefID]
	if mexDefID then
		mexBuilder[unitID] = mexDefID
	end
	if mexDefIDs[unitDefID] then
		widget:UnitCreated(unitID, unitDefID, newTeamID)
	end
end

local function Initialize()
	if WG.metalSpots then
		Spring.Echo("Mex Placement Initialised with " .. #WG.metalSpots .. " spots.")
		for i = 1, #WG.metalSpots do
			spotHeights[i] = WG.metalSpots[i].y
		end
	else
		Spring.Echo("Mex Placement Initialised with metal map mode.")
	end

	local units = spGetAllUnits()
	for i, unitID in ipairs(units) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, teamID)
	end

	pregame = (Spring.GetGameFrame() < 1)
	updateMexDrawList()

	WG.GetClosestMetalSpot = GetClosestMetalSpot
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, updateMexDrawList)
	end
end

local mexSpotToDraw = false
local drawMexSpots = false

local function UpdateOctant()
	myOctant = GetAllyTeamOctant(Spring.GetMyAllyTeamID()) or myOctant
	--Spring.Echo("myOctant", myOctant, GetAllyTeamOctant(Spring.GetMyAllyTeamID()))
end

function widget:PlayerChanged(playerID)
	if myPlayerID ~= playerID then
		return
	end
	UpdateOctant()
end

function widget:Initialize()
	if metalSpotsNil and WG.metalSpots ~= nil then
		Initialize()
		UpdateOctant()
		metalSpotsNil = false
	end
end

local wasFullView

local function CheckNeedsRecalculating()
	if not WG.metalSpots then
		return false
	end

	local isSpectating, isFullView = spGetSpectatingState()

	if wasSpectating ~= isSpectating then
		wasSpectating = isSpectating
		wasFullView = isFullView
		return true
	end
	if isSpectating and isFullView ~= wasFullView then
		wasFullView = isFullView
		return true
	end
	return false
end

local firstFewUpdates = 2
local cumDt = 0
local camDir
local debounceCamUpdate
local incomeLabelList
local DrawIncomeLabels
function widget:Update(dt)
	widget:Initialize()
	cumDt = cumDt + dt
	
	if firstFewUpdates then
		if Spring.GetGameRulesParam("waterLevelModifier") or Spring.GetGameRulesParam("mapgen_enabled") then
			Initialize()
			CheckAllTerrainChanges()
		end
		firstFewUpdates = firstFewUpdates - 1
		if firstFewUpdates <= 0 then
			firstFewUpdates = false
		end
		if wantDrawListUpdate then
			updateMexDrawList()
		end
		debounceCamUpdate = 0.1
	end

	if CheckNeedsRecalculating() then
		spotByID = {}
		spotData = {}
		local units = spGetAllUnits()
		for i, unitID in ipairs(units) do
			local unitDefID = spGetUnitDefID(unitID)
			local teamID = Spring.GetUnitTeam(unitID)
			if mexDefIDs[unitDefID] then
				widget:UnitCreated(unitID, unitDefID, teamID)
			end
		end
	end

	if debounceCamUpdate then
		debounceCamUpdate = debounceCamUpdate - dt
		if debounceCamUpdate < 0 then
			debounceCamUpdate = nil
		end
	else
		local cx, cy, cz = Spring.GetCameraDirection()
		local newCamDir = ((math.atan2(cx, cz) / math.pi) + 1) * 180
		if newCamDir ~= camDir then
			camDir = newCamDir
			if WG.metalSpots then
				gl.DeleteList(incomeLabelList)
				incomeLabelList = glCreateList(DrawIncomeLabels)
			end
			debounceCamUpdate = 0.1
		else
			-- this is really expensive, and *almost* never changes - cutscenes, cofc, or fps can change rotation. A slower initial recheck seems like an okay tradeoff.
			debounceCamUpdate = 1
		end
	end

	WG.mouseoverMexIncome = false

	if mexSpotToDraw and WG.metalSpots then
		WG.mouseoverMexIncome = mexSpotToDraw.metal
		WG.mouseoverMex = mexSpotToDraw
	else
		local _, cmd_id = spGetActiveCommand()
		if not cmd_id then
			return
		end

		local mexMult = mexDefIDs[cmd_id]
		if not mexMult then
			return
		end

		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if (not coords) then
			return
		end
		IntegrateMetal(coords[1], coords[3])
		WG.mouseoverMexIncome = extraction * mexMult
	end
end

function WG.OtherWidgetPlacedMex()
	placedMexSinceShiftPressed = true
end

-- widget:KeyRelease is called every time a mex is placed, for some reason, so this code works.
function widget:KeyRelease(key, modifier, isRepeat)
	if (key == KEYSYMS.LSHIFT or key == KEYSYMS.RSHIFT) and placedMexSinceShiftPressed then
		placedMexSinceShiftPressed = false
		local _, cmdID = Spring.GetActiveCommand()
		if cmdID and mexDefIDs[-cmdID] then
			Spring.SetActiveCommand(nil)
		end
	end
end

------------------------------------------------------------
-- Drawing
------------------------------------------------------------

local circleOnlyMexDrawList = 0
local minimapDrawList = 0

local function getSpotColor(id)
	local teamID = spotData[id] and spotData[id].team or Spring.GetGaiaTeamID()
	return Spring.GetTeamColor(teamID)
end

local function calcMainMexDrawList()
	if not WG.metalSpots then
		return
	end

	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local x,z = spot.x, spot.z
		local y = spotHeights[i]

		local r, g, b = getSpotColor(i)
		local width = (spot.metal > 0 and spot.metal) or 0.1
		width = width * metalmultInv

		glPushMatrix()

		gl.DepthTest(true)

		glColor(0,0,0,0.7)
		glLineWidth(width*2.4)
		glDrawGroundCircle(x, 1, z, 40, 32)
		glColor(r,g,b,0.7)
		glLineWidth(width*1.5)
		glDrawGroundCircle(x, 1, z, 40, 32)

		glPopMatrix()
	end

	glLineWidth(1.0)
	glColor(1,1,1,1)
end

local function calcMinimapMexDrawList()
	if not WG.metalSpots then
		return
	end
	if not glDrawCircle then
		glDrawCircle = gl.Utilities.DrawCircle -- FIXME make utilities available early enough to do this in init
	end
	
	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local x,z = spot.x, spot.z

		local r,g,b = getSpotColor(i)
		local width = (spot.metal > 0 and spot.metal) or 0.1
		width = width * metalmultInv

		glColor(0,0,0,1)
		glLineWidth(width*2.0)
		glDrawCircle(x, z, MINIMAP_DRAW_SIZE)
		glLineWidth(width*0.8)
		glColor(r,g,b,1.0)

		glDrawCircle(x, z, MINIMAP_DRAW_SIZE)
	end
	
	glLineWidth(1.0)
	glColor(1,1,1,1)
end

DrawIncomeLabels = function()
	glTexture("LuaUI/Images/ibeam.png")
	glDepthTest(false)
	glColor(1,1,1)

	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local x,z = spot.x, spot.z
		local y = math.max(0, spotHeights[i])

		glPushMatrix()
		glTranslate(x,y+5,z)
		glRotate(90,1,0,0)
		glRotate(-camDir, 0, 0, 1)

		if options.drawicons.value then
			local metal = spot.metal
			local size = options.size.value
			if metal >= 100 then
				size = size * 7
				metal = 1 -- capped so that the icons dont outgrow the map if somebody puts insane values
			elseif metal >= 10 then
				size = size * 3
				metal = metal / 10
			end
			local width = metal*size
			glTexRect(-width/2, 40, width/2, 40+size,0,0,metal,1)
		else
			-- Draws a metal bar at the center of the metal spot
			glTexRect(-25, -25, 25, 25,0,0,1,1)
		end

		glPopMatrix()
	end
	glTexture(false)

	if not options.drawicons.value then
		glColor(1,1,1,1)
		for i = 1, #WG.metalSpots do
			local spot = WG.metalSpots[i]
			local x,z = spot.x, spot.z
			local y = spGetGroundHeight(x,z)
			if y < 0 then y = 0 end

			local metal = spot.metal

			glPushMatrix()

			glTranslate(x, y, z)
			glRotate(-90, 1, 0, 0)
			glRotate(camDir, 0, 0, 1)
			glTranslate(0, -40 - options.size.value, 0)
			glText("+" .. ("%."..options.rounding.value.."f"):format(metal), 0.0, 0.0, options.size.value , "cno")

			glPopMatrix()
		end
	end
end

function updateMexDrawList()
	if not WG.metalSpots then
		return
	end

	if circleOnlyMexDrawList then
		gl.DeleteList(circleOnlyMexDrawList)
	end
	if minimapDrawList then
		gl.DeleteList(minimapDrawList)
	end
	circleOnlyMexDrawList = glCreateList(calcMainMexDrawList)
	minimapDrawList = glCreateList(calcMinimapMexDrawList)
	if not circleOnlyMexDrawList then
		Spring.Echo("Warning: Failed to update mex draw list.")
	end
end

function widget:Shutdown()
	if circleOnlyMexDrawList then
		gl.DeleteList(circleOnlyMexDrawList)
	end
	circleOnlyMexDrawList = nil
	if minimapDrawList then
		gl.DeleteList(minimapDrawList)
	end
	minimapDrawList = nil
	if incomeLabelList then
		gl.DeleteList(incomeLabelList)
	end
	incomeLabelList = nil
end

local function DoLine(x1, y1, z1, x2, y2, z2)
	gl.Vertex(x1, y1, z1)
	gl.Vertex(x2, y2, z2)
end

function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then
		return false
	end

	-- Check command is to build a mex
	local _, cmdID = spGetActiveCommand()
	local showecoMode = WG.showeco
	local peruse = spGetGameFrame() < 1 or showecoMode or spGetMapDrawMode() == 'metal'

	drawMexSpots = ((cmdID and mexDefIDs[-cmdID]) or CMD_AREA_MEX == cmdID or CMD_AREA_TERRA_MEX == cmdID or peruse)

	if WG.metalSpots and (drawMexSpots or WG.showeco_always_mexes) then
		gl.DepthTest(true)
		gl.DepthMask(true)

		if drawMexSpots and incomeLabelList then
			glCallList(incomeLabelList)
		end
		glCallList(circleOnlyMexDrawList)

		gl.DepthTest(false)
		gl.DepthMask(false)
	end
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return false
	end

	-- Check command is to build a mex
	local _, cmdID = spGetActiveCommand()
	local isMexCmd = cmdID and mexDefIDs[-cmdID]
	local mexDefID = isMexCmd and -cmdID or primaryMexDefID

	mexSpotToDraw = false
	local pregame = (spGetGameFrame() < 1)

	if WG.metalSpots and (isMexCmd or pregame or ((WG.showeco or WG.showeco_always_mexes) and WG.selectionEntirelyCons) or CMD_AREA_MEX == cmdID or CMD_AREA_TERRA_MEX == cmdID) then
		local mx, my, leftPressed = spGetMouseState()
		local _, pos = spTraceScreenRay(mx, my, true)

		if not pos then
			return
		end

		-- Find build position and check if it is valid (Would get 100% metal)
		local bx, by, bz = Spring.Pos2BuildPos(mexDefID, pos[1], pos[2], pos[3])
		local closestSpot, distance, index = GetClosestMetalSpot(bx, bz)
		local wantShow = (isMexCmd or distance <= 60)
		if (not wantShow) and (options.area_point_command.value and (CMD_AREA_MEX == cmdID or CMD_AREA_TERRA_MEX == cmdID)) then
			if leftPressed then
				local pressX, pressY = Spring.GetMouseStartPosition(1)
				if pressX then
					local _, windowHeight = gl.GetViewSizes() -- Not posioned by UI scaling.
					local distance = (pressX - mx)^2 + (pressY - (windowHeight - my))^2
					if distance < PRESS_DRAG_THRESHOLD_SQR then
						wantShow = true
					end
				end
			else
				wantShow = true
			end
		end

		if closestSpot and wantShow and IsSpotBuildable(index) then
			local bface = Spring.GetBuildFacing()
			if not isMexCmd then
				bx, by, bz = pos[1], pos[2], pos[3]
			end

			if (isMexCmd or distance <= 60) then
				mexSpotToDraw = closestSpot
			end

			local height = spGetGroundHeight(closestSpot.x,closestSpot.z)
			height = height > 0 and height or 0

			gl.DepthTest(false)

			gl.LineWidth(1.49)
			gl.Color(1, 1, 0, 0.5)
			gl.BeginEnd(GL.LINE_STRIP, DoLine, bx, by, bz, closestSpot.x, height, closestSpot.z)
			gl.LineWidth(1.0)

			gl.DepthTest(true)
			gl.DepthMask(true)

			gl.Color(1, 1, 1, 0.5)
			gl.PushMatrix()
			gl.Translate(closestSpot.x, height, closestSpot.z)
			gl.Rotate(90 * bface, 0, 1, 0)
			gl.UnitShape(mexDefID, Spring.GetMyTeamID(), false, true, false)
			gl.PopMatrix()

			gl.DepthTest(false)
			gl.DepthMask(false)
			gl.Color(1, 1, 1, 1)
		end
	end

end

function widget:DefaultCommand(cmdType, id)
	if mexSpotToDraw and not cmdType and (Spring.TestBuildOrder(primaryMexDefID, mexSpotToDraw.x, 0, mexSpotToDraw.z, 0) > 0) then
		return -primaryMexDefID -- FIXME: if modded mexes exist then get selected units and pick an appropriate modded mex
	end
end

function widget:DrawInMiniMap(minimapX, minimapY)
	if not WG.metalSpots then
		return
	end
	if drawMexSpots or WG.showeco_always_mexes then
		glPushMatrix()

		if GetMiniMapFlipped() then
			glTranslate(minimapY, 0, 0)
			glScale(-minimapX/mapX, minimapY/mapZ, 1)
		else
			glTranslate(0, minimapY, 0)
			glScale(minimapX/mapX, -minimapY/mapZ, 1)
		end

		glLighting(false)

		glCallList(minimapDrawList)

		glLineWidth(1.0)
		glColor(1,1,1,1)
		glPopMatrix()
	end
end
