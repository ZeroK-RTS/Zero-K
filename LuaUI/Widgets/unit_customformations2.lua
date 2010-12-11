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
		name      = "CustomFormations2",
		desc      = "Allows you to draw your own formation line.",
		author    = "jK, gunblob, Niobium", -- Original framework by jK, hungarian algorithm by gunblob, modifications by Niobium (Including nox algorithm)
		version   = "v2.3", -- CustomFormations v2.3 as base
		date      = "Jan, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = 10000,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
-- User Configurable
--------------------------------------------------------------------------------

-- Minimum spacing between commands (Squared) when drawing a path for single unit, must be >= 17*17 (Or orders overlap and cancel)
local minPathSpacingSq = 50 * 50

-- How long should algorithms take. (>0.1 gives visible stutter, default: 0.05)
local maxHngTime = 0.05 -- Desired maximum time for hungarian algorithm
local maxNoXTime = 0.05 -- Strict maximum time for nox algorithm

-- Need a baseline to start from when no config data saved
local defaultHungarianUnits	= 20

-- If we kept reducing maxUnits, it can get to a point where it can never increase
-- So we enforce minimums on the algorithms, if peoples CPUs cannot handle these minimums then the widget is not suited to them
local minHungarianUnits		= 10

-- We only increase maxUnits if the units are great enough for time to be meaningful
local unitIncreaseThresh	= 0.85


options_section = 'Interface'
options = {
	
	disableForBuilders = {
		name = "Disable for groups of builders",
		type = 'bool',
		value = true,
		desc = 'This is needed to allow gesture menu for groups of builders. If you want to put workers into formation, use M + left mouse',
	},
}
--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

-- These get changed when loading config, they don't technically need values here
local maxHungarianUnits         = defaultHungarianUnits
local maxOptimizationUnits      = defaultOptimizationUnits

local fNodes = {}
local fNodeCount = 0
local fLength = 0
local fDists = {}
local totaldxy = 0  --// moved mouse distance 

local dimmNodes = {}
local dimmNodeCount = 0
local alphaDimm = 1

local draggingPath = false
local lastPathPos = {}

local inMinimap = false

local endShift = false
local activeCmdIndex = -1
local cmdTag = CMD.MOVE
local inButtonEvent = false  --//if you click the command menu the move/fight command is handled with left click instead of right one

local invertQueueKey = (Spring.GetConfigInt("InvertQueueKey", 0) == 1)
local dualMinimapOnLeft = (Spring.GetMiniMapDualScreen() == "left")

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------

local osclock	= os.clock

local GL_LINE_STRIP		= GL.LINE_STRIP
local glVertex			= gl.Vertex
local glLineStipple 	= gl.LineStipple
local glLineWidth   	= gl.LineWidth
local glColor       	= gl.Color
local glBeginEnd    	= gl.BeginEnd
local glPushMatrix		= gl.PushMatrix
local glPopMatrix		= gl.PopMatrix
local glScale			= gl.Scale
local glTranslate		= gl.Translate
local glLoadIdentity	= gl.LoadIdentity

local spEcho				= Spring.Echo

local spGetActiveCommand 	= Spring.GetActiveCommand
local spSetActiveCommand	= Spring.SetActiveCommand
local spGetDefaultCommand	= Spring.GetDefaultCommand

local spGetModKeyState		= Spring.GetModKeyState
local spGetInvertQueueKey	= Spring.GetInvertQueueKey
local spGetMouseState		= Spring.GetMouseState

local spIsAboveMiniMap		= Spring.IsAboveMiniMap
local spGetMiniMapGeometry	= (Spring.GetMiniMapGeometry or Spring.GetMouseMiniMapState)

local spGetSelUnitCount		= Spring.GetSelectedUnitsCount
local spGetSelUnits			= Spring.GetSelectedUnits
local spGetSelUnitsSorted	= Spring.GetSelectedUnitsSorted

local spGiveOrder			= Spring.GiveOrder
local spGetUnitDefID 		= Spring.GetUnitDefID
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetCommandQueue		= Spring.GetCommandQueue
local spGiveOrderToUnit   	= Spring.GiveOrderToUnit
local spGetUnitPosition		= Spring.GetUnitPosition

local spTraceScreenRay		= Spring.TraceScreenRay
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetFeaturePosition	= Spring.GetFeaturePosition

local mapWidth, mapHeight = Game.mapSizeX, Game.mapSizeZ
local maxUnits = Game.maxUnits

local uDefs = UnitDefs

local tinsert = table.insert

local sqrt	= math.sqrt
local huge	= math.huge

local CMD_INSERT = CMD.INSERT
local CMD_MOVE = CMD.MOVE
local CMD_FIGHT = CMD.FIGHT
local CMD_PATROL = CMD.PATROL
local CMD_ATTACK = CMD.ATTACK
local CMD_UNLOADUNIT = CMD.UNLOAD_UNIT
local CMD_UNLOADUNITS = CMD.UNLOAD_UNITS
local CMD_JUMP = 38521

local keyShift = 304

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local moveCmds = {
	[CMD_MOVE]=true,	[CMD_ATTACK]=true,	[CMD.RECLAIM]=true,	[CMD.RESTORE]=true,	[CMD.RESURRECT]=true,
	[CMD_PATROL]=true,	[CMD.CAPTURE]=true,	[CMD_FIGHT]=true,	[CMD.DGUN]=true,	[CMD_JUMP]=true, 
	[CMD_UNLOADUNIT]=true,	[CMD_UNLOADUNITS]=true,	[CMD.LOAD_UNITS]=true,
} -- Only used by GetUnitPosition

local function GetUnitPosition(uID)
	
	local x, y, z = spGetUnitPosition(uID)
	
	local cmds = spGetCommandQueue(uID) ; if not cmds then return x, y, z end
	
	for i = #cmds, 1, -1 do
		
		local cmd = cmds[i]
		
		if (cmd.id < 0) or moveCmds[cmd.id] then
			
			local params = cmd.params
			
			if (#params >= 3) then
				
				return params[1], params[2], params[3]
				
			else
				if (#params == 1) then
					
					local pID = params[1]
					local px, py, pz
					
					if pID > maxUnits then
						px, py, pz = spGetFeaturePosition(pID - maxUnits)
					else
						px, py, pz = spGetUnitPosition(pID)
					end
					
					if px then
						return px, py, pz
					end
				end
			end
		end
	end
	
	return x, y, z
end

local function MinimapMouseToWorld(mx, my)
	
	local posx, posy, sizex, sizey = spGetMiniMapGeometry()
	local rx, ry
	
	if dualMinimapOnLeft then
		rx, ry = (mx + sizex) / sizex, (my - posy) / sizey
	else
		rx, ry = (mx - posx) / sizex, (my - posy) / sizey
	end
	
	if (rx >= 0) and (rx <= 1) and
	   (ry >= 0) and (ry <= 1)
	then
		local mapx, mapz = mapWidth * rx, mapHeight * (1 - ry)
		return {mapx, spGetGroundHeight(mapx, mapz), mapz}
	else
		return nil
	end
end

local function setColor(cmdID, alpha)
	if (cmdID == CMD_MOVE) then glColor(0.5, 1.0, 0.5, alpha) -- Green
	elseif (cmdID == CMD_ATTACK) then glColor(1.0, 0.2, 0.2, alpha) -- Red
	elseif (cmdID == CMD_UNLOADUNIT) then glColor(1.0, 1.0, 0.0, alpha) -- Yellow
	else glColor(0.5, 0.5, 1.0, alpha) -- Blue
	end
end

local function commandApplies(uID, uDefID, cmdID)
	
	if (cmdID == CMD_UNLOADUNIT) then
		local transporting = spGetUnitIsTransporting(uID)
		return (transporting and #transporting > 0)
	end
	
	return (((cmdID == CMD_MOVE) or (cmdID == CMD_FIGHT) or (cmdID == CMD_PATROL)) and uDefs[uDefID].canMove) or
			((cmdID == CMD_ATTACK) and (uDefs[uDefID].weapons.n > 0)) or
			(cmdID == CMD_JUMP) -- TODO: How to tell if a unit can jump or not
end

local function AddFNode(pos)
	
	fNodeCount = fNodeCount + 1
	fNodes[fNodeCount] = pos
	
	if fNodeCount > 1 then
		local prevNode = fNodes[fNodeCount - 1]
		local dx, dz = pos[1] - prevNode[1], pos[3] - prevNode[3]
		local dist = sqrt(dx*dx + dz*dz)
		fLength = fLength + dist
		fDists[fNodeCount] = fLength
	end
	
	totaldxy = 0
end

local function ClearFNodes()
	
	fNodes = {}
	fNodeCount = 0
	fLength = 0
end

local function GetInterpNodes(number)
	
	local spacing = fLength / (number - 1)
	
	local interpNodes = {}
	
	local sPos = fNodes[1]
	local sX = sPos[1]
	local sZ = sPos[3]
	local sDist = 0
	
	local eIdx = 2
	local ePos = fNodes[2]
	local eX = ePos[1]
	local eZ = ePos[3]
	local eDist = fDists[2]
	
	interpNodes[1] = {sX, spGetGroundHeight(sX, sZ), sZ}
	
	for n=1, (number - 2) do
		
		local reqDist = n * spacing
		
		while (reqDist > eDist) do
			
			sX = eX
			sZ = eZ
			sDist = eDist
			
			eIdx = eIdx + 1
			ePos = fNodes[eIdx]
			eX = ePos[1]
			eZ = ePos[3]
			eDist = fDists[eIdx]
		end
		
		local nFrac = (reqDist - sDist) / (eDist - sDist)
		
		local nX = sX * (1 - nFrac) + eX * nFrac
		local nZ = sZ * (1 - nFrac) + eZ * nFrac
		
		interpNodes[n + 1] = {nX, spGetGroundHeight(nX, nZ), nZ}
	end
	
	ePos = fNodes[fNodeCount]
	eX = ePos[1]
	eZ = ePos[3]
	
	interpNodes[number] = {eX, spGetGroundHeight(eX, eZ), eZ}
	
	return interpNodes
end

--------------------------------------------------------------------------------
-- Mouse/keyboard Callins
--------------------------------------------------------------------------------

function widget:MousePress(mx, my, button)
	
  if (spGetSelUnitCount() == 1) then
      return false -- FIXME disabled path drawing for 1 unit, interferes with marking menu and commandinsert
  end
  
  
	local activeid
	endShift = false
	activeCmdIndex, activeid = spGetActiveCommand()
	
	if (activeid == CMD_UNLOADUNITS) then
		activeid = CMD_UNLOADUNIT -- Without this, the unloads issued will use the area of the last area unload
	end
	
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	inButtonEvent = (activeid) and (button == 1) and ((activeid == CMD_PATROL) or 
													(activeid == CMD_FIGHT) or 
													(activeid == CMD_MOVE) or 
													(activeid == CMD_JUMP) or 
													(alt and ((activeid == CMD_ATTACK) or (activeid == CMD_UNLOADUNIT)))
													)
	
	if not (inButtonEvent or ((activeid == nil) and (button == 3))) then return false end
	
	local _,defid    = spGetDefaultCommand()
	cmdTag = activeid or defid   --// CMD.MOVE or CMD.FIGHT
	
	if not (inButtonEvent or (defid == CMD_MOVE)) then return false end
	
	if options.disableForBuilders.value then 
		if (defid == CMD_MOVE and activeid == nil) then  -- this is needed for gestures
			local units = spGetSelUnitsSorted()
			units.n = nil
			local allWorkers = true
			for udefID,_ in pairs(units) do 
				if (not UnitDefs[udefID].builder) and UnitDefs[udefID].canMove then  -- if worker is selected dont handle it
					allWorkers = false
					break
				end 
			end 
			if allWorkers then
				Spring.Echo("Custom Break")
				return false
			end
		end 
	end
	
	inMinimap = spIsAboveMiniMap(mx, my)
	
	local pos
	
	if inMinimap then
		pos = MinimapMouseToWorld(mx, my)
	else
		_, pos = spTraceScreenRay(mx, my, true)
	end
	
	if pos then
		widgetHandler:UpdateWidgetCallIn("DrawInMiniMap", self)
		widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
		
		AddFNode(pos)
		
		if (spGetSelUnitCount() == 1) then
			-- Start ordering unit immediately
			-- Need keyState
			local keyState = {}
			if alt   then tinsert(keyState, "alt") end
			if ctrl  then tinsert(keyState, "ctrl") end
			if meta  then tinsert(keyState, "meta") end
			if shift then tinsert(keyState, "shift") end
			
      -- Issue order (Insert if meta)
			if meta then
				spGiveOrder(CMD_INSERT, {0, cmdTag, 0, pos[1], pos[2], pos[3]}, {"alt"})
			else
				spGiveOrder(cmdTag, pos, keyState)
			end
			
			lastPathPos = pos
			
			draggingPath = true
		end
		
		return true
	end
	
	return false
end

function widget:MouseMove(mx, my, dx, dy, button)
	
	if (inButtonEvent and (button == 3)) or
		(not inButtonEvent and (button ~= 3)) then
		
		return false
	end

	if (fNodeCount > 0) then
		
		if (totaldxy > 40) then
			
			local pos
			
			if inMinimap then
				pos = MinimapMouseToWorld(mx, my)
			else
				_, pos = spTraceScreenRay(mx, my, true)
			end
			
			if pos then
				
				AddFNode(pos)
				
				-- We may be giving path to a single unit, check
				if draggingPath then
					
					local dx, dz = pos[1] - lastPathPos[1], pos[3] - lastPathPos[3]
					
					if ((dx*dx + dz*dz) > minPathSpacingSq) then
						
						local alt, ctrl, meta, shift = spGetModKeyState()
						if meta then
							spGiveOrder(CMD_INSERT, {0, cmdTag, 0, pos[1], pos[2], pos[3]}, {"alt"})
						else
							spGiveOrder(cmdTag, pos, {"shift"})
						end
						
						lastPathPos = pos
					end
				end
			end
		end
		
		if inMinimap then
			local _, _, sizex, sizey = spGetMiniMapGeometry()
			totaldxy = totaldxy + (dx*dx)*1024/sizex + (dy*dy)*1024/sizey
		else
			totaldxy = totaldxy + (dx*dx) + (dy*dy)
		end
	end
	
	return false
end

function widget:MouseRelease(mx, my, button)
	
	-- Check for no nodes...
	if (fNodeCount == 0) then 
		return -1
	end
	
	--// Create modkeystate list
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	-- Shift inversion
	if spGetInvertQueueKey() then
		
		shift = not shift
		
		-- check for immediate mode mouse 'rocker' gestures
		local x, y, b1, b2, b3 = spGetMouseState()
		if (((button == 1) and b3) or
			((button == 3) and b1)) then
			shift = false
		end
	end
	
	--// end button event (user clicked command menu)
	if (inButtonEvent and not shift) then
		spSetActiveCommand(-1)
	end
	
	-- Check for single unit
	if draggingPath then
		
		-- Single unit - We simply return without doing anything
		-- We clear nodes / setdimm nodes etc before returning of course
		draggingPath = false
		
		dimmNodes = fNodes
		dimmNodeCount = fNodeCount
		
		alphaDimm = 1.0
		
		ClearFNodes()
		
		if shift and (activeCmdIndex > -1) then
			endShift = true
			return activeCmdIndex
		end
		
		return -1
	end
	
	-- Continue, work out keystates (keyState is for GiveOrder and keyState2 is for CommandNotify)
	local keyState, keyState2 = {}, {coded=0, alt=false, ctrl=false, shift=false, right=false}    
	
	if alt   then tinsert(keyState,"alt");   keyState2.alt =true;  end
	if ctrl  then tinsert(keyState,"ctrl");  keyState2.ctrl=true;  end
	if meta  then tinsert(keyState,"meta");                        end
	if shift then tinsert(keyState,"shift"); keyState2.shift=true; end
		
	if not inButtonEvent then                keyState2.right=true; end
	
	--// calc the "coded" number of keyState2
	if keyState2.alt   then keyState2.coded = keyState2.coded + CMD.OPT_ALT   end
	if keyState2.ctrl  then keyState2.coded = keyState2.coded + CMD.OPT_CTRL  end
	if keyState2.shift then keyState2.coded = keyState2.coded + CMD.OPT_SHIFT end
	if keyState2.right then keyState2.coded = keyState2.coded + CMD.OPT_RIGHT end
	
	--// single click? (no line drawn)
	if (fNodeCount == 1) then
		
		-- Check if other widgets want to handle it
		local retval = widgetHandler:CommandNotify(cmdTag, fNodes[1], keyState2) or false
		
		-- Don't do it if another widget is handling it
		if retval then
			ClearFNodes()
			return -1
		end
		
		spGiveOrder(cmdTag, fNodes[1], keyState)
		ClearFNodes()
		
		if shift and (activeCmdIndex > -1) then
			endShift = true
			return activeCmdIndex
		end
		
		return -1
	end
	
	-- Therefore, we have >1 nodes (due to previous 2 checks)
	
	--------------------------------------------------------------------------------
	-- Notify widgets of the command
	--------------------------------------------------------------------------------
	-- When we issue the command, it won't fire CommandNotify for any widgets
	-- For compatibility, we want to fire CommandNotify for all the widgets
	-- The problem is that we have multiple nodes, and each unit is going to one
	-- When we can only CommandNotify about one node, as if all units are going to it
	-- The purpose is only NOTIFYING, if one returns true, we still notify others
	-- There should not be any widgets which handle such basic actions as move/fight/attack/etc
	-- (An exception to the above is CommandInsert, which does not need to be 'notified', so we exclude)
	-- The best solution here, is if CommandNotify took as input the units affected..
	
	-- Loop over widgets with CommandNotify callin, calling it
	for _, w in ipairs(widgetHandler.CommandNotifyList) do
		
		-- Exclude CommandInsert (Note: We have other code which causes meta to insert the line at front of queues)
		local wName = w:GetInfo().name
		if (wName ~= "CommandInsert") then
			
			-- Notify widget
			local retval = w:CommandNotify(cmdTag, fNodes[1], keyState2) or false
			
			-- Check return value, if true, then we have a problem
			if retval then
				spEcho("<CustomFormations2> Conflict detected with " .. wName .. " widget on " .. CMD[cmdTag] .. " command, expect anomalies")
			end
		end
	end
	
	--------------------------------------------------------------------------------
	-- End of special widget notifying section
	--------------------------------------------------------------------------------
	
    local pos
	
    if inMinimap then
		pos = MinimapMouseToWorld(mx, my)
    else
		_, pos = spTraceScreenRay(mx, my, true)
	end
	
    if pos then
		AddFNode(pos)
    end
    
    local units  = spGetSelUnitsSorted()
    units.n = nil

    --// count moveable units
    local mUnits = {}
    local mUnitsCount = 0
	
	if cmdTag == CMD_UNLOADUNIT then
		for uDefID, uIDs in pairs(units) do
			if uDefs[uDefID].isTransport then
				for ui=1, #uIDs do
					local uID = uIDs[ui]
					if commandApplies(uID, uDefID, cmdTag) then
						mUnitsCount = mUnitsCount + 1
						mUnits[mUnitsCount] = uID
					end
				end
			end
		end
	else
		for uDefID, uIDs in pairs(units) do
			if commandApplies(0, uDefID, cmdTag) then
				for ui=1, #uIDs do
					mUnitsCount = mUnitsCount + 1
					mUnits[mUnitsCount] = uIDs[ui]
				end
			end
		end
	end
	
    if (mUnitsCount > 0) then
		
		local interNodes = GetInterpNodes(mUnitsCount) -- GetInterpolatedNodes(mUnitsCount)
		local orders
		
		if (mUnitsCount <= maxHungarianUnits) then
			orders = GetOrdersHungarian(interNodes, mUnits, mUnitsCount, shift and not meta)
		else
			orders = GetOrdersNoX(interNodes, mUnits, mUnitsCount, shift and not meta)
		end
		
		-- Issue the orders
		for i=1, #orders do
			
			local oPair = orders[i]
			
			if meta then
				local pos = oPair[1]
				spGiveOrderToUnit(oPair[2], CMD_INSERT, {0, cmdTag, keyState2.coded, pos[1], pos[2], pos[3]}, {"alt"})
			else
				spGiveOrderToUnit(oPair[2], cmdTag, oPair[1], keyState)
			end
		end
    end
	
    dimmNodes = fNodes
	dimmNodeCount = fNodeCount
	
	alphaDimm = 1.0
    
	ClearFNodes()
	
    if shift and (activeCmdIndex > -1) then
		endShift = true
		return activeCmdIndex
    end
	
	return -1
end

function widget:KeyRelease(key)
	if (key == keyShift) and endShift then
		endShift = false
		spSetActiveCommand(-1)
		return true
	end
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local function DrawFormationLine(dimmNodes)
	for _, v in pairs(dimmNodes) do
		glVertex(v[1],v[2],v[3])
	end
end

local function DrawMinimapFormationLine(dimmNodes)
	for _, v in pairs(dimmNodes) do
		glVertex(v[1], v[3], 1)
	end
end

function widget:DrawWorld()
	
	if (fNodeCount < 1) and (dimmNodeCount < 1) then
		widgetHandler:RemoveWidgetCallIn("DrawWorld", self)
		return
	end
	
	--// draw the lines
	glLineStipple(2, 4095)
	glLineWidth(2.0)
	
	setColor(cmdTag, 1.0)
	glBeginEnd(GL_LINE_STRIP, DrawFormationLine, fNodes)
	
	if (dimmNodeCount > 1) then
		
		setColor(cmdTag, alphaDimm)
		glBeginEnd(GL_LINE_STRIP, DrawFormationLine, dimmNodes)
		
		alphaDimm = alphaDimm - 0.03
		if (alphaDimm <= 0) then
			dimmNodes = {}
			dimmNodeCount = 0
		end
	end

	glColor(1, 1, 1, 1)
	glLineWidth(1.0)
	glLineStipple(false)
end

function widget:DrawInMiniMap()
	
	if (fNodeCount < 1) and (dimmNodeCount < 1) then
		widgetHandler:RemoveWidgetCallIn("DrawInMiniMap", self)
		return
	end
	
	--// draw the lines
	glLineStipple(1, 4095)
	glLineWidth(2.0)
	
	setColor(cmdTag, 1.0)
	
	glPushMatrix()
	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(1/mapWidth, -1/mapHeight, 1)
	
	glBeginEnd(GL_LINE_STRIP, DrawMinimapFormationLine, fNodes)
	
	if (dimmNodeCount > 1) then
		
		setColor(cmdTag, alphaDimm)
		glBeginEnd(GL_LINE_STRIP, DrawMinimapFormationLine, dimmNodes)
		
		alphaDimm = alphaDimm - 0.03
		if (alphaDimm <= 0) then 
			dimmNodes = {}
			dimmNodeCount = 0
		end
	end
	
	glPopMatrix()
	
	glColor(1, 1, 1, 1)
	glLineWidth(1.0)
	glLineStipple(false)
end

---------------------------------------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------------------------------------

function widget:GetConfigData() -- Saving
	local data = {}
	data["maxHungarianUnits"] = maxHungarianUnits
	return data
end

function widget:SetConfigData(data) -- Loading
	maxHungarianUnits = data["maxHungarianUnits"] or defaultHungarianUnits
end

---------------------------------------------------------------------------------------------------------
-- Matching Algorithms
---------------------------------------------------------------------------------------------------------

function GetOrdersNoX(nodes, units, unitCount, shifted)
	
	-- Remember when  we start
	-- This is for capping total time
	-- Note: We at least assign each unit to its closest free node
	local startTime = osclock()
	
	---------------------------------------------------------------------------------------------------------
	-- Find initial assignments (Each unit assigned to closest free node)
	---------------------------------------------------------------------------------------------------------
	local unitPos = {}
	local nodeTaken = {}
	local matches = {}
	
	-- For each unit...
	for u=1, unitCount do
		
		-- Get its position
		local ux, uz
		
		if shifted then
			ux, _, uz = GetUnitPosition(units[u])
		else
			ux, _, uz = spGetUnitPosition(units[u])
		end
		
		unitPos[u] = {ux, uz}
		
		-- Find the best free node
		local bestDist = huge
		local bestNode = -1
		
		for n=1, unitCount do
			
			if not nodeTaken[n] then
				
				local nPos = nodes[n]
				local dx, dz = nPos[1] - ux, nPos[3] - uz
				local dist = dx*dx + dz*dz
				
				if dist < bestDist then
					bestDist = dist
					bestNode = n
				end
			end
		end
		
		matches[u] = bestNode
		nodeTaken[bestNode] = true
	end
	
	---------------------------------------------------------------------------------------------------------
	-- Main part of algorithm
	---------------------------------------------------------------------------------------------------------
	
	-- M/C for each finished matching
	local Ms = {}
	local Cs = {}
	
	-- Stacks to hold finished and still-to-check units
	local stFin = {}
	local stFinCnt = 0
	local stChk = {}
	local stChkCnt = 0
	
	-- Add all units to check stack
	for u=1, unitCount do
		stChk[u] = u
	end
	stChkCnt = unitCount
	
	-- Begin algorithm
	while ((stChkCnt > 0) and (osclock() - startTime < maxNoXTime)) do
		
		-- Get unit
		local u = stChk[stChkCnt]
		local up = unitPos[u]
		local ux, uz = up[1], up[2]
		
		-- Get matching node
		local m = matches[u]
		local mn = nodes[m]
		local nx, nz = mn[1], mn[3]
		
		-- Calculate M/C
		local Mu = (nz - uz) / (nx - ux)
		local Cu = uz - Mu * ux
		
		-- Check for clashes against finished matches
		local clashes = false
		
		for i=1, stFinCnt do
			
			-- Get opposing unit
			local f = stFin[i]
			local fp = unitPos[f]
			
			-- Get opposing units matching node
			local t = matches[f]
			local tn = nodes[t]
			
			-- Get collision point
			local ix = (Cs[f] - Cu) / (Mu - Ms[f])
			local iz = Mu * ix + Cu
			
			-- Check bounds
			if ((ux - ix) * (ix - nx) >= 0) and
			   ((uz - iz) * (iz - nz) >= 0) and
			   ((fp[1] - ix) * (ix - tn[1]) >= 0) and
			   ((fp[2] - iz) * (iz - tn[3]) >= 0) then
			   
			   -- Lines cross
			   
			   -- Swap matches, note this retains solution integrity
			   matches[u] = t
			   matches[f] = m
			   
			   -- Remove clashee from finished
			   stFin[i] = stFin[stFinCnt]
			   stFinCnt = stFinCnt - 1
			   
			   -- Add clashee to top of check stack
			   stChkCnt = stChkCnt + 1
			   stChk[stChkCnt] = f
			   
			   -- No need to check further
			   clashes = true
			   break
			end
		end
		
		if not clashes then
			
			-- Add checked unit to finished
			stFinCnt = stFinCnt + 1
			stFin[stFinCnt] = u
			
			-- Remove from to-check stack (Easily done, we know it was one on top)
			stChkCnt = stChkCnt - 1
			
			-- We can set the M/C now
			Ms[u] = Mu
			Cs[u] = Cu
		end
	end
	
	---------------------------------------------------------------------------------------------------------
	-- Return orders
	---------------------------------------------------------------------------------------------------------
	local orders = {}
	
	for u=1, unitCount do
		orders[u] = {nodes[matches[u]], units[u]}
	end
	
	return orders
end

function GetOrdersHungarian(nodes, units, unitCount, shifted)
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- (the following code is written by gunblob)
	--   this code finds the optimal solution (slow, but effective!)
	--   it uses the hungarian algorithm from http://www.public.iastate.edu/~ddoty/HungarianAlgorithm.html
	--   if this violates gpl license please let gunblob and me know
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	local t = osclock()
	
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	-- cache node<->unit distances
	
	local distances = {}
	for n=1, unitCount do distances[n] = {} end
	
	for i=1, unitCount do
		
		local uID = units[i]
		local ux, uz 
		
		if shifted then
			ux, _, uz = GetUnitPosition(uID)
		else
			ux, _, uz = spGetUnitPosition(uID)
		end
		
		for n=1, unitCount do
			
			local nodePos   = nodes[n]
			local dx,dz     = nodePos[1] - ux, nodePos[3] - uz
			distances[n][i] = sqrt(dx*dx + dz*dz)
		end
	end
	
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	-- find optimal solution and send orders
	
	local result = findHungarian(distances, unitCount)
	
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	-- determine needed time and optimize the maxUnits limit
	
	local delay = osclock() - t
	
	if (delay > maxHngTime) and (maxHungarianUnits > minHungarianUnits) then
		
		-- Delay is greater than desired, we have to reduce units
		maxHungarianUnits = maxHungarianUnits - 1
	else
		local nUnits = #units
		
		-- Delay is less than desired, so thats OK
		-- To make judgements we need number of units to be close to max
		-- Because we are making predictions of time and we want them to be accurate
		if (nUnits > maxHungarianUnits*unitIncreaseThresh) then
			
			-- This implementation of Hungarian algorithm is O(n3)
			-- Because we have less than maxUnits, but are altering maxUnits...
			-- We alter the time, to 'predict' time we would be getting at maxUnits
			-- We then recheck that against maxHngTime
			
			local nMult = maxHungarianUnits / nUnits
			
			if ((delay*nMult*nMult*nMult) < maxHngTime) then
				maxHungarianUnits = maxHungarianUnits + 1
			else
				if (maxHungarianUnits > minHungarianUnits) then
					maxHungarianUnits = maxHungarianUnits - 1
				end
			end
		end
	end
	
	-- Return orders
	local orders = {}
	
	for j=1, unitCount do
		local rPair = result[j]
		orders[j] = {nodes[rPair[1]], units[rPair[2]]}
	end
	
	return orders
end

function findHungarian(array, n)
	
	local starmask = {}
	local colcover = {}
	local rowcover = {}
	
	for i=1, n do
		
		starmask[i] = {}
		rowcover[i] = false
		colcover[i] = false
		
		for j=1, n do
			starmask[i][j] = 0
		end
	end
	
	--subMinimumFromRows(array, n)
	for i=1, n do
		local row = array[i]
		local min = huge
		for j=1, n do
			if row[j] < min then
				min = row[j]
			end
		end
		for j=1, n do
			array[i][j] = row[j] - min
		end
	end
	
	--starZeroes(array, starmask, n)
	for i=1, n do
		local row = array[i]
		for j=1, n do
			if row[j] == 0 then
				maybeStar(starmask, i, j, n)
			end
		end
	end
	
	return stepCoverStarCol(array, starmask, colcover, rowcover, n)
end

function maybeStar(starmask, row, col, n)
	
	for i=1, n do
		if starmask[i][col] == 1 then
			return
		end
	end
	
	local starRow = starmask[row]
	for i=1, n do
		if starRow[i] == 1 then
			return
		end
	end
	
	starmask[row][col] = 1
end

function stepCoverStarCol(array, starmask, colcover, rowcover, n)
	
	--coverStarCol(starmask, colcover, n)
	for i=1, n do
		local starRow = starmask[i]
		for j=1, n do
			if starRow[j] == 1 then
				colcover[j] = true
			end
		end
	end
	
	for i=1, n do
		if not colcover[i] then
			-- A column isn't covered, keep working
			return stepPrimeZeroes(array, starmask, colcover, rowcover, n)
		end
	end
	
	-- All columns were covered
	-- Return the solution
	local pairings = {}
	local pairCount = 0
	
	for i=1, n do
		local starRow = starmask[i]
		for j=1, n do
			if starRow[j] == 1 then
				pairCount = pairCount + 1
				pairings[pairCount] = {i, j}
			end
		end
	end
	
	return pairings
end

function stepPrimeZeroes(array, starmask, colcover, rowcover, n)
	
	for i=1, n do
		local aRow = array[i]
		for j=1, n do
			if not colcover[j] and not rowcover[i] and (aRow[j] == 0) then
				starmask[i][j] = 2
				local starpos = findStarInRow(starmask, i, n)
				if starpos then
					rowcover[i] = true
					colcover[starpos] = false
				else
					return stepFiveStar(array,starmask,colcover,rowcover, {}, {{i,j}}, i, j, n)
				end
			end
		end
	end
	
	adjustValue(array, colcover, rowcover, n)
	return stepPrimeZeroes(array, starmask, colcover, rowcover, n)
end

function findStarInRow(starmask, row, n)
	
	local starRow = starmask[row]
	for j=1, n do
		if starRow[j] == 1 then
			return j
		end
	end
	return nil
end

function adjustValue(array, colcover, rowcover, n)
	
	local min = huge
	
	for i=1, n do
		if not rowcover[i] then
			local aRow = array[i]
			for j=1, n do
				if not colcover[j] and (aRow[j] < min) then
					min = aRow[j]
				end
			end
		end
	end
	
	for i=1, n do
		if rowcover[i] then
			local aRow = array[i]
			for j=1, n do
				array[i][j] = aRow[j] + min
			end
		end
	end
	
	for j=1, n do
		if not colcover[j] then
			for i=1, n do
				array[i][j] = array[i][j] - min
			end
		end
	end
end

function stepFiveStar(array, starmask, colcover, rowcover, stars, primes, row, col, n)
	
	local starrow = nil
	for i=1, n do
		if starmask[i][col] == 1 then
			tinsert(stars, {i, col})
			return stepFivePrime(array, starmask, colcover, rowcover, stars, primes, i, col, n)
		end
	end
	
	return stepFiveLast(array, starmask, colcover, rowcover, stars, primes, n)
end

function stepFivePrime(array, starmask, colcover, rowcover, stars, primes, row, col, n)
	
	local primecol = nil
	local starRow = starmask[row]
	for j=1, n do
		if starRow[j] == 2 then
			tinsert(primes, {row, j})
			return stepFiveStar(array, starmask, colcover, rowcover, stars, primes, row, j, n)
		end
	end
	
	return stepFiveLast(array, starmask, colcover, rowcover, stars, primes, n)
end

function stepFiveLast(array, starmask, colcover, rowcover, stars, primes, n)
	
	for s=1, #stars do
		local star = stars[s]
		starmask[star[1]][star[2]] = 0
	end
	
	for p=1, #primes do
		local prime = primes[p]
		starmask[prime[1]][prime[2]] = 1
	end
	
	for i=1, n do
		local starRow = starmask[i]
		for j=1, n do
			if starRow[j] == 2 then
				starmask[i][j] = 0
			end
		end
	end
	
	for ij=1, n do
		colcover[ij] = false
		rowcover[ij] = false
	end
	
	return stepCoverStarCol(array, starmask, colcover, rowcover, n)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------