
function widget:GetInfo()
	return {
		name      = "Mex Placement Handler",
		desc      = "Places mexes in the correct position DO NOT DISABLE",
		author    = "Google Frog with some from Niobium and Evil4Zerggin.",
		version   = "v1",
		date      = "22 April, 2012", --2 April 2013
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

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

local floor = math.floor
local min, max = math.min, math.max
local strFind = string.find
local strFormat = string.format

local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local sqrt = math.sqrt
local tasort = table.sort
local taremove = table.remove

local myAllyTeam = spGetMyAllyTeamID()

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

------------------------------------------------------------
-- Config
------------------------------------------------------------

local TEXT_SIZE = 16
local TEXT_CORRECT_Y = 1.25

local MINIMAP_DRAW_SIZE = math.max(mapX,mapZ) * 0.0145

options_path = 'Settings/Interface/Map/Metal Spots'
options_order = { 'drawicons', 'size', 'rounding'}
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
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Mexes and builders

local mexDefID = UnitDefNames["staticmex"].id
local lltDefID = UnitDefNames["turretlaser"].id
local solarDefID = UnitDefNames["energysolar"].id
local windDefID = UnitDefNames["energywind"].id

local mexUnitDef = UnitDefNames["staticmex"]
local mexDefInfo = {
	extraction = 0.001,
	oddX = mexUnitDef.xsize % 4 == 2,
	oddZ = mexUnitDef.zsize % 4 == 2,
}

local mexBuilder = {}

local mexBuilderDefs = {}
for udid, ud in ipairs(UnitDefs) do
	for i, option in ipairs(ud.buildOptions) do
		if mexDefID == option then
			mexBuilderDefs[udid] = true
		end
	end
end

local addons = { -- coordinates of solars for the Alt modifier key
	{ 16, -64 },
	{ 64,  16 },
	{-16,  64 },
	{-64, -16 },
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

WG.mouseoverMexIncome = 0

local spotByID = {}
local spotData = {}

local wasSpectating = spGetSpectatingState()
local metalSpotsNil = true

local metalmult = tonumber(Spring.GetModOptions().metalmult) or 1
local metalmultInv = metalmult > 0 and (1/metalmult) or 1

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

function widget:CommandNotify(cmdID, params, options)
	if (cmdID == CMD_AREA_MEX and WG.metalSpots) then
		local cx, cy, cz, cr = params[1], params[2], params[3], math.max((params[4] or 60),60)

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

		local units = spGetSelectedUnits()

		for i = 1, #units do
			local unitID = units[i]
			if mexBuilder[unitID] then
				local x,_,z = spGetUnitPosition(unitID)
				ux = ux+x
				uz = uz+z
				us = us+1
			end
		end

		if (us == 0) then
			return
		else
			aveX = ux/us
			aveZ = uz/us
		end
		
		local makeMexEnergy = options.alt

		for i = 1, #WG.metalSpots do
			local mex = WG.metalSpots[i]
			--if (mex.x > xmin) and (mex.x < xmax) and (mex.z > zmin) and (mex.z < zmax) then -- square area, should be faster
			if (Distance(cx, cz, mex.x, mex.z) < cr*cr) and (makeMexEnergy or IsSpotBuildable(i)) then -- circle area, slower
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

		local shift = options.shift

		do --issue ordered order to unit(s)
			local commandArrayToIssue={}
			local unitArrayToReceive ={}
			for i = 1, #units do --prepare unit list
				local unitID = units[i]
				if mexBuilder[unitID] then
					unitArrayToReceive[#unitArrayToReceive+1] = unitID
				end
			end
			--prepare command list
			if not (options.meta or shift) then
				commandArrayToIssue[1] = {CMD.STOP, {} , {}}
			end
			for i, command in ipairs(orderedCommands) do
				local x = command.x
				local z = command.z
				local y = Spring.GetGroundHeight(x, z)

				-- check if some other widget wants to handle the command before sending it to units.
				if not WG.GlobalBuildCommand or not WG.GlobalBuildCommand.CommandNotifyMex(-mexDefID, {x, y, z, 0}, options, true) then
					commandArrayToIssue[#commandArrayToIssue+1] = {-mexDefID, {x,y,z,0} , {"shift"}}
				end

				if makeMexEnergy then
					for i=1, #addons do
						local addon = addons[i]
						local xx = x+addon[1]
						local zz = z+addon[2]
						local yy = Spring.GetGroundHeight(xx, zz)
						local buildDefID = (Spring.TestBuildOrder(solarDefID, xx, yy, zz, 0) == 0 and windDefID) or solarDefID

						-- check if some other widget wants to handle the command before sending it to units.
						if not WG.GlobalBuildCommand or not WG.GlobalBuildCommand.CommandNotifyMex(-buildDefID, {xx, yy, zz, 0}, options, true) then
							commandArrayToIssue[#commandArrayToIssue+1] = {-buildDefID, {xx,yy,zz,0}, {"shift"}}
						end
					end
				end
			end
			
			if options.meta then
				for i = #commandArrayToIssue, 1, -1 do
					local command = commandArrayToIssue[i]
					WG.CommandInsert(command[1], command[2], options)
				end
			else
				if (#commandArrayToIssue > 0) then
					Spring.GiveOrderArrayToUnitArray(unitArrayToReceive, commandArrayToIssue)
				end
			end
		end

		return true
	end

	if -mexDefID == cmdID and WG.metalSpots then

		local bx, bz = params[1], params[3]
		local closestSpot = GetClosestMetalSpot(bx, bz)
		if closestSpot then
			local units = spGetUnitsInRectangle(closestSpot.x-1, closestSpot.z-1, closestSpot.x+1, closestSpot.z+1)
			local foundUnit = false
			local myAlly = spGetMyAllyTeamID()
			for i = 1, #units do
				local unitID = units[i]
				local unitDefID = Spring.GetUnitDefID(unitID)
				if unitDefID and mexDefID == unitDefID and spGetUnitAllyTeam(unitID) == myAlly then
					foundUnit = unitID
					break
				end
			end

			if foundUnit then
				local build = select(5, spGetUnitHealth(foundUnit))
				if build ~= 1 then
					if options.meta then
						WG.CommandInsert(CMD.REPAIR, {foundUnit}, options)
					else
						spGiveOrder(CMD.REPAIR, {foundUnit}, options)
					end
				end
				return true
			else
				-- check if some other widget wants to handle the command before sending it to units.
				local commandHeight = math.max(0, Spring.GetGroundHeight(closestSpot.x, closestSpot.z))
				local GBC_processed = WG.GlobalBuildCommand and WG.GlobalBuildCommand.CommandNotifyMex(cmdID, {closestSpot.x, commandHeight, closestSpot.z, params[4]}, options, false)
				if not GBC_processed then
					if options.meta then
						WG.CommandInsert(cmdID, {closestSpot.x, commandHeight, closestSpot.z, params[4]}, options)
					else
						spGiveOrder(cmdID, {closestSpot.x, commandHeight, closestSpot.z, params[4]}, options)
					end
				end
				return true
			end
		end
	end

end


function widget:UnitEnteredLos(unitID, teamID)
	if spGetSpectatingState() then
		return
	end

	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID ~= mexDefID or not WG.metalSpots then
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
	if unitDefID ~= mexDefID then -- not just a nil check, the unitID could have gotten recycled for another unit
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
	updateMexDrawList()
end

function widget:GameFrame(n)
	if not WG.metalSpots or (n % 30) ~= 0 then
		return
	end

	for i = 1, #WG.metalSpots do
		CheckEnemyMexes(i)
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	if mexBuilderDefs[unitDefID] then
		mexBuilder[unitID] = true
		return
	end

	if unitDefID ~= mexDefID or not WG.metalSpots then
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
	if unitDefID == mexDefID and spotByID[unitID] then
		spotData[spotByID[unitID]] = nil
		spotByID[unitID] = nil
		updateMexDrawList()
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if mexBuilderDefs[unitDefID] then
		mexBuilder[unitID] = true
	end
	if unitDefID == mexDefID then
		widget:UnitCreated(unitID, unitDefID, newTeamID)
	end
end

local function Initialize()

	local units = spGetAllUnits()
	for i, unitID in ipairs(units) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, teamID)
	end
	if WG.metalSpots then
		Spring.Echo("Mex Placement Initialised with " .. #WG.metalSpots .. " spots.")
		updateMexDrawList()
	else
		Spring.Echo("Mex Placement Initialised with metal map mode.")
	end

	WG.GetClosestMetalSpot = GetClosestMetalSpot
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, updateMexDrawList)
	end
end

local mexSpotToDraw = false
local drawMexSpots = false

function widget:Update()
	local isSpectating = spGetSpectatingState()
	if WG.metalSpots and (wasSpectating ~= isSpectating) then
		spotByID = {}
		spotData = {}
		wasSpectating = isSpectating
		local units = spGetAllUnits()
		for i, unitID in ipairs(units) do
			local unitDefID = spGetUnitDefID(unitID)
			local teamID = Spring.GetUnitTeam(unitID)
		if unitDefID == mexDefID then
			widget:UnitCreated(unitID, unitDefID, teamID)
		end
		end
	end
	if metalSpotsNil and WG.metalSpots ~= nil then
		Initialize()
		metalSpotsNil = false
	end

	WG.mouseoverMexIncome = false

	if mexSpotToDraw and WG.metalSpots then
		WG.mouseoverMexIncome = mexSpotToDraw.metal
		WG.mouseoverMex = mexSpotToDraw
	else
		local _, cmd_id = spGetActiveCommand()
		if -mexDefID ~= cmd_id then
			return
		end
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if (not coords) then
			return
		end
		IntegrateMetal(coords[1], coords[3])
		WG.mouseoverMexIncome = extraction
	end
end

------------------------------------------------------------
-- Drawing
------------------------------------------------------------

local centerX
local centerZ
local extraction = 0

local mainMexDrawList = 0
local circleOnlyMexDrawList = 0

local function getSpotColor(id)
	local teamID = spotData[id] and spotData[id].team or Spring.GetGaiaTeamID()
	return Spring.GetTeamColor(teamID)
end

function calcMainMexDrawList(onlyDrawCircle)
	local specatate = spGetSpectatingState()

	if WG.metalSpots then
		for i = 1, #WG.metalSpots do
			local spot = WG.metalSpots[i]
			local x,z = spot.x, spot.z
			local y = spGetGroundHeight(x,z)
			if y < 0 then y = 0 end

			local r, g, b = getSpotColor(i)
			local width = (spot.metal > 0 and spot.metal) or 0.1
			width = width * metalmultInv

			glPushMatrix()

			gl.DepthTest(true)

			glColor(0,0,0,0.7)
			-- glDepthTest(false)
			glLineWidth(width*2.4)
			glDrawGroundCircle(x, 1, z, 40, 21)
			glColor(r,g,b,0.7)
			glLineWidth(width*1.5)
			glDrawGroundCircle(x, 1, z, 40, 21)

			--glColor(0,1,1)
			--glRect(x-width/2, z+18, x+width/2, z+20)
			--glDepthTest(false)
			glPopMatrix()
		end

		glColor(1,1,1)
		if not onlyDrawCircle then
			glTexture("LuaUI/Images/ibeam.png")
			glDepthTest(false)
			for i = 1, #WG.metalSpots do
				local spot = WG.metalSpots[i]
				local x,z = spot.x, spot.z
				local y = spGetGroundHeight(x,z)
				if y < 0 then y = 0 end

				local metal = spot.metal

				glPushMatrix()

				if options.drawicons.value then
					local size = 1
					if metal > 10 then
						if metal > 100 then
							metal = metal*0.01
							size = 5
						else
							metal = metal*0.1
							size = 2.5
						end
					end

					size = options.size.value

					glRotate(90,1,0,0)
					glTranslate(0,0,-y-10)


					local width = metal*size
					glTexRect(x-width/2, z+40, x+width/2, z+40+size,0,0,metal,1)
				else
					-- Draws a metal bar at the center of the metal spot
					glRotate(90,1,0,0)
					glTranslate(0,0,-y)

					glTexRect(x-25, z-25, x+25, z+25,0,0,1,1)
				end

				glPopMatrix()
			end
			glTexture(false)
		
			if not options.drawicons.value then
				--glColor(1,1,1) --already set
				for i = 1, #WG.metalSpots do
					local spot = WG.metalSpots[i]
					local x,z = spot.x, spot.z
					local y = spGetGroundHeight(x,z)
					if y < 0 then y = 0 end

					local metal = spot.metal

					glPushMatrix()

					glTranslate(x, y, z)
					glRotate(-90, 1, 0, 0)
					glTranslate(0, -40 - options.size.value, 0)
					glText("+" .. ("%."..options.rounding.value.."f"):format(metal), 0.0, 0.0, options.size.value , "cno")

					glPopMatrix()
				end
			end
		end

		glLineWidth(1.0)
		glColor(1,1,1,1)
	end
end
--[[
function calcMiniMexDrawList()
	local specatate = spGetSpectatingState()

	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(mapXinv , -mapZinv, 1)
	glRotate(270,1,0,0)

	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local x,z = spot.x, spot.z
		local y = spGetGroundHeight(x,z)

		local r, g, b = getSpotColor(i)

		glLineWidth(spot.metal)
		glColor(r, g, b)

		glDrawGroundCircle(x, 0, z, 40, 32)

		glPushMatrix()

		glPopMatrix()
	end

	glLineWidth(1.0)
	glColor(1,1,1,1)
end
--]]
function updateMexDrawList()
	if not WG.metalSpots then
		return
	end

	if (mainMexDrawList) then
		gl.DeleteList(mainMexDrawList)
		mainMexDrawList = nil
	end
	if (circleOnlyMexDrawList) then
		gl.DeleteList(circleOnlyMexDrawList)
		circleOnlyMexDrawList = nil
	end
	mainMexDrawList = glCreateList(calcMainMexDrawList)
	circleOnlyMexDrawList = glCreateList(calcMainMexDrawList, true)
	if not mainMexDrawList then
		Spring.Echo("Warning: Failed to update mex draw list.")
	end
end

function widget:Shutdown()
	gl.DeleteList(mainMexDrawList)
	gl.DeleteList(circleOnlyMexDrawList)
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

	drawMexSpots = WG.metalSpots and (-mexDefID == cmdID or CMD_AREA_MEX == cmdID or peruse)

	if drawMexSpots or WG.showeco_always_mexes then

			gl.DepthTest(true)
			gl.DepthMask(true)
			if drawMexSpots then
				glCallList(mainMexDrawList)
			else
				glCallList(circleOnlyMexDrawList)
			end

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
	local showecoMode = WG.showeco or WG.showeco_always_mexes
	local pregame = (spGetGameFrame() < 1)
	local peruse = pregame or showecoMode or spGetMapDrawMode() == 'metal'


	local mx, my = spGetMouseState()
	local _, pos = spTraceScreenRay(mx, my, true)

	mexSpotToDraw = false

	if WG.metalSpots and pos and (pregame or WG.selectionEntirelyCons) and (-mexDefID == cmdID or peruse or CMD_AREA_MEX == cmdID) then

		-- Find build position and check if it is valid (Would get 100% metal)
		local bx, by, bz = Spring.Pos2BuildPos(mexDefID, pos[1], pos[2], pos[3])
		local bface = Spring.GetBuildFacing()
		local closestSpot, distance, index = GetClosestMetalSpot(bx, bz)
		if -mexDefID ~= cmdID then
			bx, by, bz = pos[1], pos[2], pos[3]
		end

		if closestSpot and (-mexDefID == cmdID or not ((CMD_AREA_MEX == cmdID or peruse) and distance > 60)) and IsSpotBuildable(index) then

			mexSpotToDraw = closestSpot

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
		end
	end

	gl.Color(1, 1, 1, 1)
end

function widget:DefaultCommand(type, id)
	if mexSpotToDraw and WG.selectionEntirelyCons and not type and (Spring.TestBuildOrder(mexDefID, mexSpotToDraw.x, 0, mexSpotToDraw.z, 0) > 0) then
		return -mexDefID
	end
end

function widget:DrawInMiniMap(minimapX, minimapY)

	if drawMexSpots or WG.showeco_always_mexes then
		if not glDrawCircle then
			glDrawCircle = gl.Utilities.DrawCircle
		end

		local specatate = spGetSpectatingState()

		glPushMatrix()
		glTranslate(0,minimapY,0)
		glScale(minimapX/mapX, -minimapY/mapZ, 1)

		for i = 1, #WG.metalSpots do
			local spot = WG.metalSpots[i]
			local x,z = spot.x, spot.z
			local y = spGetGroundHeight(x,z)

			local r,g,b = getSpotColor(i)
			local width = (spot.metal > 0 and spot.metal) or 0.1
			width = width * metalmultInv

			glLighting(false)
			glColor(0,0,0,1)
			glLineWidth(width*2.0)
			glDrawCircle(x, z, MINIMAP_DRAW_SIZE)
			glLineWidth(width*0.8)
			glColor(r,g,b,1.0)

			glDrawCircle(x, z, MINIMAP_DRAW_SIZE)
		end

		glLineWidth(1.0)
		glColor(1,1,1,1)
		glPopMatrix()
	end
end

--[[
local function DrawTextWithBackground(text, x, y, size, opt)
	local width = glGetTextWidth(text) * size
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)

	glColor(0.25, 0.25, 0.25, 0.75)
	if (opt) then
		if (strFind(opt, "r")) then
			glRect(x, y, x - width, y + size * TEXT_CORRECT_Y)
		elseif (strFind(opt, "c")) then
			glRect(x + width * 0.5, y, x - width * 0.5, y + size * TEXT_CORRECT_Y)
		else
			glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
		end
	else
		glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
	end
	glColor(0.75, 0.75, 0.75, 1)
	glText(text, x, y, size, opt)

end

function widget:DrawScreen()
	if mexSpotToDraw and WG.metalSpots then
		local mx, my = spGetMouseState()
		DrawTextWithBackground("\255\255\255\255Metal extraction: " .. strFormat("%.2f", mexSpotToDraw.metal), mx, my, TEXT_SIZE, "d")
		glColor(1, 1, 1, 1)
	else
		local _, cmd_id = spGetActiveCommand()
		if -mexDefID ~= cmd_id then
			return
		end
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if (not coords) then
			return
		end
		IntegrateMetal(coords[1], coords[3])
		DrawTextWithBackground("\255\255\255\255Metal extraction: " .. strFormat("%.2f", extraction), mx, my, TEXT_SIZE, "d")
		glColor(1, 1, 1, 1)
	end
end
--]]
