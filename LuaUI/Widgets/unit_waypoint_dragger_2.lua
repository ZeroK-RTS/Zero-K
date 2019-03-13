
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local sprGetActiveCommand    = Spring.GetActiveCommand
local sprGetDefaultCommand   = Spring.GetDefaultCommand
local sprGetGameSeconds      = Spring.GetGameSeconds
local sprGetSelectedUnits    = Spring.GetSelectedUnits
local sprGetCommandQueue     = Spring.GetCommandQueue
local sprGetMouseState       = Spring.GetMouseState
local sprGetModKeyState      = Spring.GetModKeyState
local sprGiveOrderToUnit     = Spring.GiveOrderToUnit
local sprSelectUnitArray     = Spring.SelectUnitArray
local sprIsAboveMiniMap      = Spring.IsAboveMiniMap
local sprTestBuildOrder      = Spring.TestBuildOrder
local sprGetBuildFacing      = Spring.GetBuildFacing
local sprGetMyTeamID         = Spring.GetMyTeamID

local sprWorldToScreenCoords = Spring.WorldToScreenCoords
local sprTraceScreenRay      = Spring.TraceScreenRay

local floor = math.floor

local glVertex           = gl.Vertex
local glBeginEnd         = gl.BeginEnd
local glColor            = gl.Color
local glLineStipple      = gl.LineStipple
local glDrawGroundCircle = gl.DrawGroundCircle

local glPushMatrix       = gl.PushMatrix
local glRotate           = gl.Rotate
local glTranslate        = gl.Translate
local glUnitShape        = gl.UnitShape
local glPopMatrix        = gl.PopMatrix

local CMD_JUMP = 38521

local CMD_BUILD = -1
local cmdColorsTbl = {
	[CMD.MOVE]         = {0.5, 1.0, 0.5, 0.7},
	[CMD_RAW_MOVE]     = {0.5, 1.0, 0.5, 0.7},
	[CMD.PATROL]       = {0.3, 0.3, 1.0, 0.7},
	[CMD.RECLAIM]      = {1.0, 0.2, 1.0, 0.7},
	[CMD.REPAIR]       = {0.3, 1.0, 1.0, 0.7},
	[CMD.ATTACK]       = {1.0, 0.2, 0.2, 0.7},
	[CMD.AREA_ATTACK]  = {1.0, 0.2, 0.2, 0.7},
	[CMD.FIGHT]        = {0.5, 0.5, 1.0, 0.7},
	[CMD.LOAD_UNITS]   = {0.3, 1.0, 1.0, 0.7},
	[CMD.UNLOAD_UNITS] = {1.0, 1.0, 0.0, 0.7},
	[CMD.RESURRECT]    = {0.2, 0.6, 1.0, 0.7},
	[CMD.RESTORE]      = {0.0, 1.0, 0.0, 0.7},
	[CMD_BUILD]        = {0.0, 1.0, 0.0, 0.7},
	[CMD_JUMP]         = {0.0, 1.0, 0.0, 0.7},
}

-- CMD_RAW_BUILD is intentionally not included because it will always be below another command
local POINT_COMMAND = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD.PATROL] = true,
	[CMD_JUMP] = true,
	[CMD.FIGHT] = true,
}

local AREA_COMMAND = {
	[CMD.RECLAIM] = true,
	[CMD.REPAIR] = true,
	[CMD.RESURRECT] = true,
	[CMD.LOAD_UNITS] = true,
	[CMD.UNLOAD_UNITS] = true,
	[CMD.UNLOAD_UNIT] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.RESTORE] = true,
}

local wayPtSelDist = 30
local selWayPtsTbl = {}

function widget:GetInfo()
	return {
		name      = "Waypoint Dragger",
		desc      = "Enables Waypoint Dragging",
		author    = "Kloot",
		date      = "Aug. 8, 2007 [updated Aug. 14, 2009]",
		license   = "GNU GPL v2",
		layer     = 5,
		enabled   = false
	}
end

function widget:Initialize()
end

function widget:Shutdown()
end

local function GetCommandColor(cmdID)
	if (cmdID < 0) then
		return cmdColorsTbl[CMD_BUILD][1], cmdColorsTbl[CMD_BUILD][2], cmdColorsTbl[CMD_BUILD][3], cmdColorsTbl[CMD_BUILD][4]
	else
		if (cmdColorsTbl[cmdID] ~= nil) then
			return cmdColorsTbl[cmdID][1], cmdColorsTbl[cmdID][2], cmdColorsTbl[cmdID][3], cmdColorsTbl[cmdID][4]
		end
	end

	return 1.0, 1.0, 1.0, 1.0
end

local function GetMouseWorldCoors(mx, my)
	local _, cwc = Spring.TraceScreenRay(mx, my, true, sprIsAboveMiniMap(mx, my))
	return cwc
end

local function GetSqDist2D(x, y, p, q)
	local dx = x - p
	local dy = y - q
	return (dx * dx + dy * dy)
end

local function GetCommandWorldPosition(cmd)
	local cmdID   = cmd.id
	local cmdPars = cmd.params
	local x, y, z, radius

	if POINT_COMMAND[cmdID] then
		x, z, radius = cmdPars[1], cmdPars[3], 0
	end
	
	if AREA_COMMAND[cmdID] then
		if (#cmdPars >= 4) then
			x, z, radius = cmdPars[1], cmdPars[3], cmdPars[4]
		end
	end

	if (cmdID == CMD.ATTACK) then
		if (#cmdPars >= 3) then
		x, z, radius = cmdPars[1], cmdPars[3], 0
		end
	end

	if (cmdID < 0) then
		-- include the build facing (if non-default)
		x, z, radius = cmdPars[1], cmdPars[3], (cmdPars[4] or 0)
		local ud = UnitDefs[-cmdID]
		if ud then
			local evenX = ((ud.xsize/2)%2)*8
			local evenZ = ((ud.zsize/2)%2)*8
			x = math.floor((x + 8 - evenX)/16)*16 + evenX
			z = math.floor((z + 8 - evenZ)/16)*16 + evenZ
		end
	end
	
	if x then
		y = Spring.GetGroundHeight(x,z)
	end

	return x,y,z,radius
end

-- measure distance from waypoint to cursor in screen-space coordinates
-- (so that at greater zoom-levels, waypoints are less easily dragged)
local function GetCommandCursorScreenSqDist(cmd, mx, my)
	local x, y, z, _ = GetCommandWorldPosition(cmd)

	if (x ~= nil and y ~= nil and z ~= nil) then
		local p, q = sprWorldToScreenCoords(x, y, z)
		local d    = GetSqDist2D(mx, my, p, q)

		return d
	end

	return -1
end

local function IsCommandNearCursor(cmd, mx, my)
	local d = GetCommandCursorScreenSqDist(cmd, mx, my)

	return (d >= 0 and d < (wayPtSelDist * wayPtSelDist))
end

local function GetWayPointsNearCursor(wpTbl, mx, my, wantAverage)
	local selUnitsTbl = sprGetSelectedUnits()
	local numSelWayPts = 0

	if (selUnitsTbl == nil or #selUnitsTbl == 0) then
		return numSelWayPts
	end

	for i = 1, #selUnitsTbl do
		local unitID = selUnitsTbl[i]
		local commands = sprGetCommandQueue(unitID, -1)

		for cmdNum = 1, #commands do
			local curCmd      = commands[cmdNum    ]
			local nxtCmd      = commands[cmdNum + 1]
			local x, y, z, fr = GetCommandWorldPosition(curCmd)
			if (IsCommandNearCursor(curCmd, mx, my)) then
				-- save the tag of the next command
				local wpLink = (nxtCmd and nxtCmd.tag) or nil
				local wpData = {x, y, z, fr, wpLink, curCmd, unitID}
				local wpKey  = tostring(unitID) .. "-" .. tostring(curCmd.tag)

				wpTbl[wpKey] = wpData
				numSelWayPts = numSelWayPts + 1
			end
		end
	end
	
	if wantAverage and numSelWayPts ~= 0 then
		local aX = 0
		local aZ = 0
		for _, data in pairs(wpTbl) do
			aX = aX + data[1]
			aZ = aZ + data[3]
		end
		aX = aX/numSelWayPts
		aZ = aZ/numSelWayPts
		for _, data in pairs(wpTbl) do
			data[8] = data[1] - aX
			data[9] = data[3] - aZ
		end
	end

	return numSelWayPts
end

local function MoveWayPoints(wpTbl, mx, my, finalize)
	local cursorWorldCoors = GetMouseWorldCoors(mx, my)

	if (cursorWorldCoors ~= nil) then
		local wpTblTmp = {}
		local cx, cy, cz = cursorWorldCoors[1], cursorWorldCoors[2], cursorWorldCoors[3]
		local alt, ctrl, _, _ = sprGetModKeyState()

		if (ctrl) then
			-- merge waypoints that are currently near
			-- the cursor with those that were near it
			-- at the time of the MousePress event
			GetWayPointsNearCursor(wpTblTmp, mx, my, true)

			for wpKey, wpData in pairs(wpTblTmp) do
				wpTbl[wpKey] = wpData
			end
		end

		for wpKey, wpData in pairs(wpTbl) do
			-- facing for build orders,
			-- radius for area orders
			local cmdFacRad = wpData[4]
			local cmdLink   = wpData[5]
			local cmdID     = wpData[6].id
			local cmdPars   = wpData[6].params
			local cmdTag    = wpData[6].tag
			local cmdUnitID = wpData[7]
			local offsetX  	= wpData[8]
			local offsetZ  	= wpData[9]

			if (finalize) then
				if (cmdLink == nil) then
					cmdLink = cmdTag
				end

				if (cmdFacRad > 0) then
					-- sprGiveOrderToUnit(cmdUnitID, CMD.INSERT, {cmdNum, cmdID, 0, cx, cy, cz, cmdFacRad}, CMD.OPT_ALT)
					sprGiveOrderToUnit(cmdUnitID, CMD.INSERT, {cmdLink, cmdID, 0, cx+offsetX, cy, cz+offsetZ, cmdFacRad}, 0)
				else
					-- sprGiveOrderToUnit(cmdUnitID, CMD.INSERT, {cmdNum, cmdID, 0, cx, cy, cz}, CMD.OPT_ALT)
					sprGiveOrderToUnit(cmdUnitID, CMD.INSERT, {cmdLink, cmdID, 0, cx+offsetX, cy, cz+offsetZ}, 0)
				end

				if (not alt) then
					sprGiveOrderToUnit(cmdUnitID, CMD.REMOVE, {cmdTag}, 0)
				end
			else
				wpData[1] = cx
				wpData[2] = cy
				wpData[3] = cz
			end
		end
	end

	if (finalize) then
		for wpKey, _ in pairs(wpTbl) do
			selWayPtsTbl[wpKey] = nil
		end
	end
end

local function UpdateWayPoints(wpTbl)
	local _, _, _, shift = sprGetModKeyState()
	local badWayPtsTbl = {}

	for wpKey, wpData in pairs(wpTbl) do
		local cmdTag    = wpData[6].tag
		local cmdUnitID = wpData[7]
		local cmdValid  = false

		local unitCmds = sprGetCommandQueue(cmdUnitID, -1)

		-- check if the command has not been completed
		-- since the MousePress() event occurred (tags
		-- don't wrap around within a unit's cmd queue
		-- until 1 << 24 of them have been assigned, so
		-- this should be safe)
		for unitCmdNum = 1, #unitCmds do
			if (unitCmds[unitCmdNum].tag == cmdTag) then
				cmdValid = true; break
			end
		end

		-- if shift was released while dragging,
		-- make sure to erase all waypoints here
		if ((not cmdValid) or (not shift)) then
			badWayPtsTbl[wpKey] = true
		end
	end

	for wpKey, _ in pairs(badWayPtsTbl) do
		wpTbl[wpKey] = nil
	end
end



function widget:MousePress(mx, my, mb)
	-- decide whether to steal this press from the engine
	-- so that we get the subsequent MouseMove() call-ins
	--
	-- we do this when the following conditions are true:
	--   1. we have at least one unit selected
	--   2. we have the shift key pressed
	--   3. we pressed the LEFT mouse button (otherwise shift-move orders would break)
	--   4. our default command is Move (ie. we haven't clicked on a build-icon, etc.) [?]
	--   5. our mouse cursor is within "grabbing" radius of (at least)
	--      one waypoint of at least one of the units we have selected
	--
	local _, actCmdID, _, _      = sprGetActiveCommand()
	local _, defCmdID, _, _      = sprGetDefaultCommand()
	local alt, ctrl, meta, shift = sprGetModKeyState()
	local numWayPts              = 0

	if (not shift)                                     then  return false  end
	if (mb ~= 1)                                       then  return false  end
--	if (actCmdID ~= CMD.MOVE and defCmdID ~= CMD.MOVE) then  return false  end

	numWayPts = GetWayPointsNearCursor(selWayPtsTbl, mx, my, true)

	if (numWayPts == 0) then
		return false
	end

	return true
end

function widget:MouseMove(mx, my, mdx, mdy, mb)
	MoveWayPoints(selWayPtsTbl, mx, my, false)
	return false
end

function widget:MouseRelease(mx, my, mb)
	MoveWayPoints(selWayPtsTbl, mx, my, true)
	return false
end



function widget:Update(_)
	-- remove waypoints that units have
	-- "passed" in some sense since the
	-- MousePress event was received
	UpdateWayPoints(selWayPtsTbl)
end

function widget:DrawWorld()
	local mx, my, _, _, _ = sprGetMouseState()
	local _, _, _, shift = sprGetModKeyState()
	local wpTblTmp = {}

	if (not shift) then
		return
	end

	-- we want to draw selection circles even when no
	-- MousePress event has occurred (more intuitive)
	-- note: only call this if selWayPtsTbl is empty?
	GetWayPointsNearCursor(wpTblTmp, mx, my, false)

	for _, wpData in pairs(wpTblTmp) do
		local cmd        = wpData[6]
		local x, y, z, _ = GetCommandWorldPosition(cmd)
		local p, q       = sprWorldToScreenCoords(x, y, z)
		local r, g, b, a = GetCommandColor(cmd.id)

		glColor(r, g, b, a)
		glDrawGroundCircle(x, y, z, wayPtSelDist, 16)
	end

	for _, wpData in pairs(selWayPtsTbl) do
		local cmd           = wpData[6]
		local nx, ny, nz    = wpData[1], wpData[2], wpData[3]
		local ox, oy, oz, _ = GetCommandWorldPosition(cmd)
		local p, q          = sprWorldToScreenCoords(ox, oy, oz)
		local d             = GetSqDist2D(mx, my, p, q)
		local r, g, b, a    = GetCommandColor(cmd.id)

		glColor(r, g, b, a)

		if (d > (wayPtSelDist * wayPtSelDist)) then
			glDrawGroundCircle(ox, oy, oz, wayPtSelDist, 16)
		end


		if (cmd.id < 0) then
			local ret, _ = sprTestBuildOrder(-cmd.id, nx, ny, nz, sprGetBuildFacing())
			if (ret == 0) then
				-- bad position for this UnitDefID
				glColor(1.0, 0.0, 0.0, 1.0)
			end
			glPushMatrix()
			glTranslate(nx, ny, nz)
			glRotate(wpData[4] * 90.0, 0.0, 1.0, 0.0)
			glUnitShape(-cmd.id, sprGetMyTeamID(), false, true, false)
			glPopMatrix()
		end


		local pattern = (65536 - 775)
		local offset = floor((sprGetGameSeconds() * 16) % 16)

		glLineStipple(2, pattern, -offset)
		glBeginEnd(GL.LINES,
			function()
				glVertex(ox, oy, oz)
				glVertex(nx, ny, nz)
			end
		)
		glLineStipple(false)
	end

	glColor(1.0, 1.0, 1.0, 1.0)
end
