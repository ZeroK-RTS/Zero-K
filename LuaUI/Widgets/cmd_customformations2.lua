function widget:GetInfo()
	return {
		name      = "CustomFormations2",
		desc      = "Allows you to draw a formation line:"..
					"\n mouse drag draw various command on ground."..
					"\n ALT+Attack draw attack command on the ground.",
		author    = "Niobium, modified by Skasi", -- Based on 'Custom Formations' by jK and gunblob
		version   = "v3.4", -- With modified dot drawing from v4.3
		date      = "Mar, 2010",
		license   = "GNU GPL, v2 or later",
		layer     = 1000000,
		enabled   = true,
		handler   = true,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Command Visibility'--/Formations'
options_order = { 'drawmode_v2', 'linewidth', 'dotsize' }
options = {
	drawmode_v2 = {
		name = 'Draw mode',
		-- desc is not supported here :(
		-- desc = 'Change the formation display. Formations are drawn by moving the mouse while the mouse button is pressed. Supported commands are Move, Fight, Patrol, Manual attacks, Jump and with the ALT key held down Attack, Set target and Unload.'
		-- (new) players might not even know about custom formations, so ultimately this should probably be displayed above these options
		type = 'radioButton',
		value = 'both',
		items={
			{key='lines', name='Lines only', desc='Draw stippled lines along the drawn formation'},
			{key='dots', name='Dots only', desc='Draw dots at command locations'},
			{key='both', name='Draw both', desc='Draw lines and dots'},
		},
		noHotkey = true,
	},
	
	linewidth = {
		name = 'Width of lines',
		type = 'number',
		value = 2,
		min = 1, max = 2, step=1,
		-- For some reason drawing lines fails for numbers higher than 2. 
	},
	
	dotsize = {
		name = 'Size of dots',
		type = 'number',
		value = 1,
		min = 0.5, max = 2, step=0.1,
	},
}

--------------------------------------------------------------------------------
-- User Configurable Constants
--------------------------------------------------------------------------------
-- Minimum spacing between commands (Squared) when drawing a path for a single unit, must be >16*16 (Or orders overlap and cancel)
local minPathSpacingSq = 50 * 50

-- Minimum line length to cause formation move instead of single-click-style order
local minFormationLength = 20

-- How long should algorithms take. (~0.1 gives visible stutter, default: 0.05)
local maxHngTime = 0.05 -- Desired maximum time for hungarian algorithm
local maxNoXTime = 0.05 -- Strict maximum time for backup algorithm

local defaultHungarianUnits	= 20 -- Need a baseline to start from when no config data saved
local minHungarianUnits		= 10 -- If we kept reducing maxUnits it can get to a point where it can never increase, so we enforce minimums on the algorithms.
local unitIncreaseThresh	= 0.85 -- We only increase maxUnits if the units are great enough for time to be meaningful

-- Alpha loss per second after releasing mouse
local lineFadeRate = 2.0

-- What commands are eligible for custom formations
local formationCmds = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD.FIGHT] = true,
	[CMD.ATTACK] = true,
	[CMD.MANUALFIRE] = true,
	[CMD.PATROL] = true,
	[CMD.UNLOAD_UNIT] = true,
	[CMD_JUMP] = true, -- jump
	[CMD_PLACE_BEACON] = true, -- teleport beacon
	[CMD_UNIT_SET_TARGET] = true, -- settarget
	[CMD_UNIT_SET_TARGET_CIRCLE] = true, -- settarget
}

-- What commands require alt to be held (Must also appear in formationCmds)
local requiresAlt = {
	[CMD.ATTACK] = true,
	[CMD.MANUALFIRE] = true,
	[CMD.UNLOAD_UNIT] = true,
	[CMD_UNIT_SET_TARGET] = true, -- settarget
	[CMD_UNIT_SET_TARGET_CIRCLE] = true, -- settarget
}

-- Context-based default commands that can be overridden (i.e. guard when mouseover unit)
-- If the mouse remains on the same target for both Press/Release then the formation is ignored and original command is issued.
-- Normal logic will follow after override, i.e. must be a formationCmd to get formation, alt must be held if requiresAlt, etc.
local overrideCmds = {
	[CMD.GUARD] = CMD_RAW_MOVE,
	[CMD_WAIT_AT_BEACON] = CMD_RAW_MOVE,
}

-- What commands are issued at a position or unit/feature ID (Only used by GetUnitPosition)
local positionCmds = {
	[CMD.MOVE]=true,		[CMD_RAW_MOVE]=true,	[CMD_RAW_BUILD]=true,	[CMD.ATTACK]=true,		[CMD.RECLAIM]=true,		[CMD.RESTORE]=true,		[CMD.RESURRECT]=true,
	[CMD.PATROL]=true,		[CMD.CAPTURE]=true,		[CMD.FIGHT]=true, 		[CMD.MANUALFIRE]=true,		[CMD_JUMP]=true, -- jump
	[CMD.UNLOAD_UNIT]=true,	[CMD.UNLOAD_UNITS]=true,[CMD.LOAD_UNITS]=true,	[CMD.GUARD]=true,		[CMD.AREA_ATTACK] = true,
}

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------
local maxHungarianUnits = defaultHungarianUnits -- Also set when loading config

local fNodes = {} -- Formation nodes, filled as we draw
local fDists = {} -- fDists[i] = distance from node 1 to node i
local totaldxy = 0 -- Measure of distance mouse has moved, used to unjag lines drawn in minimap
local lineLength = 0 -- Total length of the line

local dimmCmd = nil -- The dimming command (Used for color)
local dimmNodes = {} -- The current nodes of dimming line
local dimmAlpha = 0 -- The current alpha of dimming line

local pathCandidate = false -- True if we should start a path on mouse move
local draggingPath = false -- True if we are dragging a path for unit(s) to follow
local lastPathPos = nil -- The last point added to the path, used for min-distance check

local overriddenCmd = nil -- The command we ignored in favor of move
local overriddenTarget = nil -- The target (for params) we ignored

local usingCmd = nil -- The command to execute across the line
local usingRMB = false -- If the command is the default it uses right click, otherwise it is active and uses left click
local inMinimap = false -- Is the line being drawn in the minimap
local endShift = false -- True to reset command when shift is released

local MiniMapFullProxy = (Spring.GetConfigInt("MiniMapFullProxy", 0) == 1)

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local GL_LINE_STRIP = GL.LINE_STRIP
local glVertex = gl.Vertex
local glLineStipple = gl.LineStipple
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glScale = gl.Scale
local glTranslate = gl.Translate
local glLoadIdentity = gl.LoadIdentity

local spGetActiveCommand = Spring.GetActiveCommand
local spSetActiveCommand = Spring.SetActiveCommand
local spGetDefaultCommand = Spring.GetDefaultCommand
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spGetModKeyState = Spring.GetModKeyState
local spGetInvertQueueKey = Spring.GetInvertQueueKey
local spIsAboveMiniMap = Spring.IsAboveMiniMap
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrder = Spring.GiveOrder
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitHeight = Spring.GetUnitHeight
local spGetCameraPosition = Spring.GetCameraPosition
local spGetViewGeometry = Spring.GetViewGeometry
local spTraceScreenRay = Spring.TraceScreenRay

local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local maxUnits = Game.maxUnits

local osclock = os.clock
local tsort = table.sort
local floor = math.floor
local ceil = math.ceil
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local max = math.max
local huge = math.huge
local pi2 = 2*math.pi

local CMD_INSERT = CMD.INSERT
local CMD_MOVE = CMD.MOVE
local CMD_ATTACK = CMD.ATTACK
local CMD_UNLOADUNIT = CMD.UNLOAD_UNIT
local CMD_UNLOADUNITS = CMD.UNLOAD_UNITS
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED
local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local REMOVED_SET_WANTED_MAX_SPEED = not CMD.SET_WANTED_MAX_SPEED

local keyShift = 304

local filledCircleOutFading = {} --Table of display lists keyed by cmdID

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function CulledTraceScreenRay(mx, my, coords, minimap)
	local targetType, params = spTraceScreenRay(mx, my, coords, minimap)
	if targetType == "ground" then
		params[4], params[5], params[6] = nil, nil, nil
		return targetType, params
	end
	return targetType, params
end

local function GetModKeys()
	
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	if spGetInvertQueueKey() then -- Shift inversion
		shift = not shift
	end
	
	return alt, ctrl, meta, shift
end
local function GetUnitFinalPosition(uID)
	
	local ux, uy, uz = spGetUnitPosition(uID)
	
	local cmds = spGetCommandQueue(uID, -1)
	if not cmds then
		return 0, 0, 0
	end
	for i = #cmds, 1, -1 do
		
		local cmd = cmds[i]
		if (cmd.id < 0) or positionCmds[cmd.id] then
			
			local params = cmd.params
			if #params >= 3 then
				return params[1], params[2], params[3]
			else
				if #params == 1 then
					
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
	
	return ux, uy, uz
end
local function SetColor(cmdID, alpha)
	if     cmdID == CMD_MOVE or cmdID == CMD_RAW_MOVE then glColor(0.5, 1.0, 0.5, alpha) -- Green
	elseif cmdID == CMD_ATTACK                 then glColor(1.0, 0.2, 0.2, alpha) -- Red
	elseif cmdID == CMD.MANUALFIRE             then glColor(1.0, 1.0, 1.0, alpha) -- White
	elseif cmdID == CMD_UNLOADUNIT             then glColor(1.0, 1.0, 0.0, alpha) -- Yellow
	elseif cmdID == CMD_UNIT_SET_TARGET        then glColor(1.0, 0.75, 0.0, alpha) -- Orange
	elseif cmdID == CMD_UNIT_SET_TARGET_CIRCLE then glColor(1.0, 0.75, 0.0, alpha) -- Orange
	elseif cmdID == CMD_JUMP                   then glColor(0.2, 1.0, 0.2, alpha) -- Deeper Green
	else                                            glColor(0.5, 0.5, 1.0, alpha) -- Blue
	end
end
local function CanUnitExecute(uID, cmdID)
	
	if cmdID == CMD_UNLOADUNIT then
		local transporting = spGetUnitIsTransporting(uID)
		return (transporting and #transporting > 0)
	end
	
	return (spFindUnitCmdDesc(uID, cmdID) ~= nil)
end
local function GetExecutingUnits(cmdID)
	local units = {}
	local selUnits = spGetSelectedUnits()
	for i = 1, #selUnits do
		local uID = selUnits[i]
		if CanUnitExecute(uID, cmdID) then
			units[#units + 1] = uID
		end
	end
	return units
end

local function AddFNode(pos)
	
	local px, pz = pos[1], pos[3]
	if px < 0 or pz < 0 or px > mapSizeX or pz > mapSizeZ then
		return false
	end
	
	local n = #fNodes
	if n == 0 then
		fNodes[1] = pos
		fDists[1] = 0
	else
		local prevNode = fNodes[n]
		local dx, dz = px - prevNode[1], pz - prevNode[3]
		local distSq = dx*dx + dz*dz
		if distSq == 0.0 then -- Don't add if duplicate
			return false
		end
		
		local dis = sqrt(distSq)
		
		fNodes[n + 1] = pos
		fDists[n + 1] = fDists[n] + dis
		lineLength = lineLength + dis
	end
	
	totaldxy = 0
	return true
end

local function HasWaterWeapon(UnitDefID)
	local haswaterweapon = false
	local numweapons = #(UnitDefs[UnitDefID]["weapons"])
	for j=1, numweapons do
		local weapondefid = UnitDefs[UnitDefID]["weapons"][j]["weaponDef"]
		local iswaterweapon = WeaponDefs[weapondefid]["waterWeapon"]
		if iswaterweapon then haswaterweapon=true end
	end	
	return haswaterweapon
end

local function GetInterpNodes(mUnits)
		
	local number = #mUnits
	local spacing = fDists[#fNodes] / (#mUnits - 1)

	local haswaterweapon = {}
	for i=1, number do
		local UnitDefID = spGetUnitDefID(mUnits[i])
		haswaterweapon[i] = HasWaterWeapon(UnitDefID)
	end
	--result of this and code below is that the height of the aimpoint for a unit [i] will be:
	--(a) on GetGroundHeight(units aimed position), if the unit has a waterweapon
	--(b) on whichever is highest out of water surface (=0) and GetGroundHeight(units aimed position), if the unit does not have water weapon. 
	--in BA this must match the behaviour of prevent_range_hax or commands will get modified.
	
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
	
	local sY 
	if haswaterweapon[1] then 
		sY = spGetGroundHeight(sX, sZ) 
	else 
		sY = math.max(0,spGetGroundHeight(sX,sZ)) 
	end
	interpNodes[1] = {sX, sY, sZ}
	
	for n = 1, number - 2 do
		
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
		local nY 
		if haswaterweapon[number+1] then 
			nY = spGetGroundHeight(nX, nZ) 
		else 
			nY = math.max(0,spGetGroundHeight(nX, nZ)) 
		end
		interpNodes[n + 1] = {nX, nY, nZ}
	end
	
	ePos = fNodes[#fNodes]
	eX = ePos[1]
	eZ = ePos[3]
	local eY 
	if haswaterweapon[number] then  eY=spGetGroundHeight(eX, eZ) else eY=math.max(0,spGetGroundHeight(eX, eZ)) end
	interpNodes[number] = {eX, eY, eZ}
	
	--DEBUG for i=1,number do Spring.Echo(interpNodes[i]) end
	
	return interpNodes
end

local function GetCmdOpts(alt, ctrl, meta, shift, right)
	
	local opts = { alt=alt, ctrl=ctrl, meta=meta, shift=shift, right=right }
	local coded = 0
	
	if alt   then coded = coded + CMD_OPT_ALT   end
	if ctrl  then coded = coded + CMD_OPT_CTRL  end
	if meta  then coded = coded + CMD_OPT_META  end
	if shift then coded = coded + CMD_OPT_SHIFT end
	if right then coded = coded + CMD_OPT_RIGHT end
	
	opts.coded = coded
	return opts
end

local function GiveNotifyingOrder(cmdID, cmdParams, cmdOpts)
	if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
		return
	end
	spGiveOrder(cmdID, cmdParams, cmdOpts.coded)
end

local function GiveNonNotifyingOrder(cmdID, cmdParams, cmdOpts)
	spGiveOrder(cmdID, cmdParams, cmdOpts.coded)
end

local function GiveNotifyingOrderToUnit(uID, cmdID, cmdParams, cmdOpts)
	if widgetHandler:UnitCommandNotify(uID, cmdID, cmdParams, cmdOpts) then
		return
	end
	spGiveOrderToUnit(uID, cmdID, cmdParams, cmdOpts.coded)
end

local function SendSetWantedMaxSpeed(alt, ctrl, meta, shift)
	-- Move Speed (Applicable to every order)
	local wantedSpeed = 99999 -- High enough to exceed all units speed, but not high enough to cause errors (i.e. vs math.huge)
	if ctrl then
		local selUnits = spGetSelectedUnits()
		for i = 1, #selUnits do
			local ud = UnitDefs[spGetUnitDefID(selUnits[i])]
			local uSpeed = ud and ud.speed
			if uSpeed and uSpeed > 0 and uSpeed < wantedSpeed then
				wantedSpeed = uSpeed
			end
		end
	elseif REMOVED_SET_WANTED_MAX_SPEED then
		wantedSpeed = -1
	end
	
	-- Directly giving speed order appears to work perfectly, including with shifted orders ...
	-- ... But other widgets CMD.INSERT the speed order into the front (Posn 1) of the queue instead (which doesn't work with shifted orders)
	if REMOVED_SET_WANTED_MAX_SPEED then
		local units = Spring.GetSelectedUnits()
		Spring.GiveOrderToUnitArray(units, CMD_WANTED_SPEED, {wantedSpeed}, 0)
	else
		local speedOpts = GetCmdOpts(alt, ctrl, meta, shift, true)
		GiveNotifyingOrder(CMD_SET_WANTED_MAX_SPEED, {wantedSpeed / 30}, speedOpts)
	end
end

--------------------------------------------------------------------------------
-- Mouse/keyboard Callins
--------------------------------------------------------------------------------
function widget:MousePress(mx, my, mButton)
	-- Where did we click
	inMinimap = spIsAboveMiniMap(mx, my)
	if inMinimap and not MiniMapFullProxy then
		return false
	end
	if (mButton == 1 or mButton == 3) and fNodes and #fNodes > 0 then
		-- already issuing command
		return true 
	end
	
	lineLength = 0
	
	-- Get command that would've been issued
	local _, activeCmdID = spGetActiveCommand()
	if activeCmdID then
		if mButton ~= 1 then 
			return false 
		end
		
		usingCmd = activeCmdID
		usingRMB = false
	else
		if mButton ~= 3 then 
			return false 
		end
		
		local _, defaultCmdID = spGetDefaultCommand()
		if not defaultCmdID then return false end
		
		local overrideCmdID = overrideCmds[defaultCmdID]
		if overrideCmdID then
			
			local targType, targID = CulledTraceScreenRay(mx, my, false, inMinimap)
			if targType == 'unit' then
				overriddenCmd = defaultCmdID
				overriddenTarget = targID
			elseif targType == 'feature' then
				overriddenCmd = defaultCmdID
				overriddenTarget = targID + maxUnits
			else
				-- We can't reversibly override a command if we can't get the original target, so we give up overriding it.
				return false
			end
			
			usingCmd = overrideCmdID
		else
			overriddenCmd = nil
			overriddenTarget = nil
			
			usingCmd = defaultCmdID
		end
		
		usingRMB = true
	end
	
	-- Without this, the unloads issued will use the area of the last area unload
	if usingCmd == CMD_UNLOADUNITS then
		usingCmd = CMD_UNLOADUNIT
	end
	
	-- Is this command eligible for a custom formation ?
	local alt, ctrl, meta, shift = GetModKeys()
	if not (formationCmds[usingCmd] and (alt or not requiresAlt[usingCmd])) then
		return false
	end
	
	-- Get clicked position
	local _, pos = CulledTraceScreenRay(mx, my, true, inMinimap)
	if not pos then return false end
	
	-- Setup formation node array
	if not AddFNode(pos) then return false end
	
	-- Is this line a path candidate (We don't do a path off an overriden command)
	pathCandidate = (not overriddenCmd) and (spGetSelectedUnitsCount()==1 or (alt and not requiresAlt[usingCmd]))
	
	-- We handled the mouse press
	return true
end

function widget:MouseMove(mx, my, dx, dy, mButton)
	
	-- It is possible for MouseMove to fire after MouseRelease
	if #fNodes == 0 then
		return false
	end
	
	-- Minimap-specific checks
	if inMinimap then
		totaldxy = totaldxy + dx*dx + dy*dy
		if (totaldxy < 5) or not spIsAboveMiniMap(mx, my) then
			return false
		end
	end
	
	-- Get clicked position
	local _, pos = CulledTraceScreenRay(mx, my, true, inMinimap)
	if not pos then return false end
	
	-- Add the new formation node
	if not AddFNode(pos) then return false end
	
	-- Have we started drawing a line?
	if #fNodes == 2 then
		
		-- We have enough nodes to start drawing now
		widgetHandler:UpdateWidgetCallIn("DrawInMiniMap", self)
		widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
		
		-- If the line is a path, start the units moving to this node
		if pathCandidate then
			
			local alt, ctrl, meta, shift = GetModKeys()
			local cmdOpts = GetCmdOpts(false, ctrl, meta, shift, usingRMB) -- using alt uses springs box formation, so we set it off always
			GiveNotifyingOrder(usingCmd, pos, cmdOpts)
			lastPathPos = pos
			
			draggingPath = true
			SendSetWantedMaxSpeed(alt, ctrl, meta, shift)
		end
	else
		-- Are we dragging a path?
		if draggingPath then
			
			local dx, dz = pos[1] - lastPathPos[1], pos[3] - lastPathPos[3]
			if (dx*dx + dz*dz) > minPathSpacingSq then
				
				local alt, ctrl, meta, shift = GetModKeys()
				local cmdOpts = GetCmdOpts(false, ctrl, meta, true, usingRMB) -- using alt uses springs box formation, so we set it off always
				GiveNonNotifyingOrder(usingCmd, pos, cmdOpts)
				lastPathPos = pos
			end
		end
	end
	
	return false
end

local function StopCommandAndRelinquishMouse()
	local ownerName = widgetHandler.mouseOwner and widgetHandler.mouseOwner.GetInfo and widgetHandler.mouseOwner.GetInfo()
	ownerName = ownerName and ownerName.name
	if ownerName == "CustomFormations2" then
		widgetHandler.mouseOwner = nil
	end
	-- Cancel the command
	fNodes = {}
	fDists = {}
	
	-- Modkeys / command reset
	local alt, ctrl, meta, shift = GetModKeys()
	if not usingRMB then
		if shift then
			endShift = true -- Reset on release of shift
		else
			spSetActiveCommand(0) -- Reset immediately
		end
	end
end

function widget:MouseRelease(mx, my, mButton)
	if (mButton == 1 or mButton == 3) and (not usingRMB) == (mButton == 3) then
		StopCommandAndRelinquishMouse()
		return false
	end
	
	-- It is possible for MouseRelease to fire after MouseRelease
	if #fNodes == 0 then
		return false
	end
	
	-- Modkeys / command reset
	local alt, ctrl, meta, shift = GetModKeys()
	if not usingRMB then
		if shift then
			endShift = true -- Reset on release of shift
		else
			spSetActiveCommand(0) -- Reset immediately
		end
	end
	-- Are we going to use the drawn formation?
	local usingFormation = true
	
	-- Override checking
	if overriddenCmd then
		
		local targetID
		local targType, targID = CulledTraceScreenRay(mx, my, false, inMinimap)
		if targType == 'unit' then
			targetID = targID
		elseif targType == 'feature' then
			targetID = targID + maxUnits
		end
		
		if targetID and targetID == overriddenTarget then
			
			-- Signal that we are no longer using the drawn formation
			usingFormation = false
			
			-- Process the original command instead
			local cmdOpts = GetCmdOpts(alt, ctrl, meta, shift, usingRMB)
			GiveNotifyingOrder(overriddenCmd, {overriddenTarget}, cmdOpts)
		end
	end
	
	-- Using path? If so then we do nothing
	if draggingPath then
		
		draggingPath = false
		
	-- Using formation? If so then it's time to calculate and issue orders.
	elseif usingFormation then
		
		-- Add final position (Sometimes we don't get the last MouseMove before this MouseRelease)
		if (not inMinimap) or spIsAboveMiniMap(mx, my) then
			local _, pos = CulledTraceScreenRay(mx, my, true, inMinimap)
			if pos then
				AddFNode(pos)
			end
		end
		
		-- Get command options
		local cmdOpts = GetCmdOpts(alt, ctrl, meta, shift, usingRMB)
		
		-- Single click ? (no line drawn)
		--if (#fNodes == 1) then
		if fDists[#fNodes] < minFormationLength then
			-- We should check if any units are able to execute it,
			-- but the order is small enough network-wise that the tiny bug potential isn't worth it.
			GiveNotifyingOrder(usingCmd, fNodes[1], cmdOpts)
		else
			-- Order is a formation
			-- Are any units able to execute it?
			local mUnits = GetExecutingUnits(usingCmd)
			if #mUnits > 0 then
				
				local interpNodes = GetInterpNodes(mUnits)
				
				local orders
				if (#mUnits <= maxHungarianUnits) then
					orders = GetOrdersHungarian(interpNodes, mUnits, #mUnits, shift and not meta)
				else
					orders = GetOrdersNoX(interpNodes, mUnits, #mUnits, shift and not meta)
				end
				
				if meta then
					local altOpts = GetCmdOpts(true, false, false, false, false)
					for i = 1, #orders do
						local orderPair = orders[i]
						local orderPos = orderPair[2]
						GiveNotifyingOrderToUnit(orderPair[1], CMD_INSERT, {0, usingCmd, cmdOpts.coded, orderPos[1], orderPos[2], orderPos[3]}, altOpts)
					end
				else
					for i = 1, #orders do
						local orderPair = orders[i]
						GiveNotifyingOrderToUnit(orderPair[1], usingCmd, orderPair[2], cmdOpts)
					end
				end
			end
		end
		
		SendSetWantedMaxSpeed(alt, ctrl, meta, shift)
	end
	
	if #fNodes > 1 then
		dimmCmd = usingCmd
		dimmNodes = fNodes
		dimmAlpha = 1.0
		widgetHandler:UpdateWidgetCallIn("Update", self)
	end
	
	fNodes = {}
	fDists = {}
	local ownerName = widgetHandler.mouseOwner and widgetHandler.mouseOwner.GetInfo and widgetHandler.mouseOwner.GetInfo()
	ownerName = ownerName and ownerName.name
	if ownerName == "CustomFormations2" then
		widgetHandler.mouseOwner = nil
	end
	return true
end

function widget:KeyRelease(key)
	if (key == keyShift) and endShift then
		spSetActiveCommand(0)
		endShift = false
	end
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local function tVerts(verts)
	for i = 1, #verts do
		local v = verts[i]
        if v[1] and v[2] and v[3] then
            glVertex(v[1], v[2], v[3])
        end
	end
end

local function tVertsMinimap(verts)
	for i = 1, #verts do
		local v = verts[i]
		if v[1] and v[3] then
            glVertex(v[1], v[3], 1)
        end
	end
end

local function filledCircleVerts(cmd, cornerCount)
	SetColor(cmd, 1)
	glVertex(0,0,0)
	SetColor(cmd, 0)
	for t = 0, pi2, pi2 / cornerCount do
		glVertex(sin(t), 0, cos(t))
	end
end

-- local function DrawFilledCircle(pos, size, cornerCount)
-- 	glPushMatrix()
-- 	glTranslate(pos[1], pos[2], pos[3])
-- 	glScale(size, 1, size)
-- 	gl.CallList(filledCircleVerts)
-- 	glPopMatrix()
-- end

local function DrawFilledCircleOutFading(pos, size, cornerCount)
	glPushMatrix()
	glTranslate(pos[1], pos[2], pos[3])
	glScale(size, 1, size)
	local cmd = usingCmd
	if filledCircleOutFading[usingCmd] == nil then
		cmd = 0
	end
	gl.CallList(filledCircleOutFading[cmd])
	-- glBeginEnd(GL.TRIANGLE_FAN, function()
		-- glVertex(0,0,0)
		-- for t = 0, pi2, pi2 / cornerCount do
		-- 	glVertex(sin(t), 0, cos(t))
		-- end
	-- end)
	-- draw extra glow as base
	-- has hardly any effect but doubles gpuTime, so disabled for now
	-- glBeginEnd(GL.TRIANGLE_FAN, function()
		-- SetColor(usingCmd, 1/15)
		-- glVertex(0,0,0)
		-- SetColor(usingCmd, 0)
		-- local baseSize = size * 2.8
		-- for t = 0, pi2, pi2 / 8 do
			-- glVertex(sin(t) * baseSize, 0, cos(t) * baseSize)
		-- end
	-- end)
	glPopMatrix()
end

local function DrawFormationDots(vertFunction, zoomY, unitCount)
	local currentLength = 0
	local lengthPerUnit = lineLength / (unitCount-1)
	local lengthUnitNext = lengthPerUnit
	local dotSize = sqrt(zoomY*0.1)*options.dotsize.value
	if (#fNodes > 1) and (unitCount > 1) then
		SetColor(usingCmd, 1)
		DrawFilledCircleOutFading(fNodes[1], dotSize, 8)
		if (#fNodes > 2) then
			for i=1, #fNodes-2 do -- first and last circle are drawn before and after the for loop
				local x = fNodes[i][1]
				local y = fNodes[i][3]
				local x2 = fNodes[i+1][1]
				local y2 = fNodes[i+1][3]
				local dx = x - x2
				local dy = y - y2
				local length = sqrt((dx*dx)+(dy*dy))
				while (currentLength + length >= lengthUnitNext) do
					local factor = (lengthUnitNext - currentLength) / length
					local factorPos =
						{fNodes[i][1] + ((fNodes[i+1][1] - fNodes[i][1]) * factor),
						fNodes[i][2] + ((fNodes[i+1][2] - fNodes[i][2]) * factor),
						fNodes[i][3] + ((fNodes[i+1][3] - fNodes[i][3]) * factor)}
					DrawFilledCircleOutFading(factorPos, dotSize, 8)
					lengthUnitNext = lengthUnitNext + lengthPerUnit
				end
				currentLength = currentLength + length
			end
		end
		DrawFilledCircleOutFading(fNodes[#fNodes], dotSize, 8)
	end
end

local function DrawFormationLines(vertFunction, lineStipple)
	
	glLineStipple(lineStipple, 4095)
	glLineWidth(options.linewidth.value)
	
	if #fNodes > 1 then
		SetColor(usingCmd, 1.0)
		glBeginEnd(GL_LINE_STRIP, vertFunction, fNodes)
		glColor(1,1,1,1)
	end
	
	if #dimmNodes > 1 then
		SetColor(dimmCmd, dimmAlpha)
		glBeginEnd(GL_LINE_STRIP, vertFunction, dimmNodes)
		glColor(1,1,1,1)
	end
	
	glLineWidth(1.0)
	glLineStipple(false)
end

local Xs, Ys = spGetViewGeometry()
Xs, Ys = Xs*0.5, Ys*0.5
function widget:ViewResize(viewSizeX, viewSizeY)
	Xs, Ys = spGetViewGeometry()
	Xs, Ys = Xs*0.5, Ys*0.5
end

function widget:DrawWorld()
	-- Draw lines when a path is drawn instead of a formation, OR when drawmode_v2 for formations is not "dots" only
	if pathCandidate or options.drawmode_v2.value ~= "dots" then
		DrawFormationLines(tVerts, 2)
	end
	-- Draw dots when no path is drawn AND nodenumber is high enough AND drawmode_v2 for formations is not "lines" only
	if not pathCandidate and (#fNodes > 1 or #dimmNodes > 1) and options.drawmode_v2.value ~= "lines" then
		local camX, camY, camZ = spGetCameraPosition()
		local at, p = CulledTraceScreenRay(Xs,Ys,true,false,false)
		if at == "ground" then 
			local dx, dy, dz = camX-p[1], camY-p[2], camZ-p[3]
			--zoomY = ((dx*dx + dy*dy + dz*dz)*0.01)^0.25	--tests show that sqrt(sqrt(x)) is faster than x^0.25
			zoomY = sqrt(dx*dx + dy*dy + dz*dz)
		else
			--zoomY = sqrt((camY - max(spGetGroundHeight(camX, camZ), 0))*0.1)
			zoomY = camY - max(spGetGroundHeight(camX, camZ), 0)
		end
		if zoomY < 6 then 
			zoomY = 6 
		end
		if lineLength > 0 then  --don't try and draw if the command was cancelled by having two mouse buttons pressed at once
			local unitCount = spGetSelectedUnitsCount()
			DrawFormationDots(tVerts, zoomY, unitCount)
		end
	end
end
function widget:DrawInMiniMap()
	
	glPushMatrix()
		glLoadIdentity()
		glTranslate(0, 1, 0)
		glScale(1 / mapSizeX, -1 / mapSizeZ, 1)
		
		DrawFormationLines(tVertsMinimap, 1)
	glPopMatrix()
end

function InitFilledCircle(cmdID)
	filledCircleOutFading[cmdID] = gl.CreateList(gl.BeginEnd, GL.TRIANGLE_FAN, filledCircleVerts, cmdID, 8) 
end

function widget:Initialize()
	-- filledCircle = gl.CreateList(gl.BeginEnd, GL.TRIANGLE_FAN, filledCircleVerts, 8)
	InitFilledCircle(CMD_MOVE)
	InitFilledCircle(CMD_RAW_MOVE)
	InitFilledCircle(CMD_ATTACK)
	InitFilledCircle(CMD.MANUALFIRE)
	InitFilledCircle(CMD_UNLOADUNIT)
	InitFilledCircle(CMD_UNIT_SET_TARGET)
	InitFilledCircle(CMD_UNIT_SET_TARGET_CIRCLE)
	InitFilledCircle(CMD_JUMP)
	InitFilledCircle(0)
end

function widget:Update(deltaTime)
	
	dimmAlpha = dimmAlpha - lineFadeRate * deltaTime
	
	if dimmAlpha <= 0 then
		
		dimmNodes = {}
		widgetHandler:RemoveWidgetCallIn("Update", self)
		
		if #fNodes == 0 then
			widgetHandler:RemoveWidgetCallIn("DrawWorld", self)
			widgetHandler:RemoveWidgetCallIn("DrawInMiniMap", self)
		end
	end
end

---------------------------------------------------------------------------------------------------------
-- Config
---------------------------------------------------------------------------------------------------------
function widget:GetConfigData() -- Saving
	return {
		['maxHungarianUnits'] = maxHungarianUnits,
	}
end
function widget:SetConfigData(data) -- Loading
	maxHungarianUnits = data['maxHungarianUnits'] or defaultHungarianUnits
end

---------------------------------------------------------------------------------------------------------
-- Matching Algorithms
---------------------------------------------------------------------------------------------------------
function GetOrdersNoX(nodes, units, unitCount, shifted)
	
	-- Remember when  we start
	-- This is for capping total time
	-- Note: We at least complete initial assignment
	local startTime = osclock()
	
	---------------------------------------------------------------------------------------------------------
	-- Find initial assignments
	---------------------------------------------------------------------------------------------------------
	local unitSet = {}
	local fdist = -1
	local fm
	
	for u = 1, unitCount do
		
		-- Get unit position
		local ux, uz
		if shifted then
			ux, _, uz = GetUnitFinalPosition(units[u])
		else
			ux, _, uz = spGetUnitPosition(units[u])
		end
		unitSet[u] = {ux, units[u], uz, -1} -- Such that x/z are in same place as in nodes (So we can use same sort function)
		
		-- Work on finding furthest points (As we have ux/uz already)
		for i = u - 1, 1, -1 do
			
			local up = unitSet[i]
			local vx, vz = up[1], up[3]
			local dx, dz = vx - ux, vz - uz
			local dist = dx*dx + dz*dz
			
			if (dist > fdist) then
				fdist = dist
				fm = (vz - uz) / (vx - ux)
			end
		end
	end
	
	-- Maybe nodes are further apart than the units
	for i = 1, unitCount - 1 do
		
		local np = nodes[i]
		local nx, nz = np[1], np[3]
		
		for j = i + 1, unitCount do
			
			local mp = nodes[j]
			local mx, mz = mp[1], mp[3]
			local dx, dz = mx - nx, mz - nz
			local dist = dx*dx + dz*dz
			
			if (dist > fdist) then
				fdist = dist
				fm = (mz - nz) / (mx - nx)
			end
		end
	end
	
	local function sortFunc(a, b)
		-- y = mx + c
		-- c = y - mx
		-- c = y + x / m (For perp line)
		return (a[3] + a[1] / fm) < (b[3] + b[1] / fm)
	end
	
	tsort(unitSet, sortFunc)
	tsort(nodes, sortFunc)
	
	for u = 1, unitCount do
		unitSet[u][4] = nodes[u]
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
	for u = 1, unitCount do
		stChk[u] = u
	end
	stChkCnt = unitCount
	
	-- Begin algorithm
	while ((stChkCnt > 0) and (osclock() - startTime < maxNoXTime)) do
		
		-- Get unit, extract position and matching node position
		local u = stChk[stChkCnt]
		local ud = unitSet[u]
		local ux, uz = ud[1], ud[3]
		local mn = ud[4]
		local nx, nz = mn[1], mn[3]
		
		-- Calculate M/C
		local Mu = (nz - uz) / (nx - ux)
		local Cu = uz - Mu * ux
		
		-- Check for clashes against finished matches
		local clashes = false
		
		for i = 1, stFinCnt do
			
			-- Get opposing unit and matching node position
			local f = stFin[i]
			local fd = unitSet[f]
			local tn = fd[4]
			
			-- Get collision point
			local ix = (Cs[f] - Cu) / (Mu - Ms[f])
			local iz = Mu * ix + Cu
			
			-- Check bounds
			if ((ux - ix) * (ix - nx) >= 0) and
			   ((uz - iz) * (iz - nz) >= 0) and
			   ((fd[1] - ix) * (ix - tn[1]) >= 0) and
			   ((fd[3] - iz) * (iz - tn[3]) >= 0) then
				
				-- Lines cross
				
				-- Swap matches, note this retains solution integrity
				ud[4] = tn
				fd[4] = mn
				
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
	for i = 1, unitCount do
		local unit = unitSet[i]
		orders[i] = {unit[2], unit[4]}
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
	--for i = 1, unitCount do distances[i] = {} end
	
	for i = 1, unitCount do
		
		local uID = units[i]
		local ux, uz 
		
		if shifted then
			ux, _, uz = GetUnitFinalPosition(uID)
		else
			ux, _, uz = spGetUnitPosition(uID)
		end
		
		distances[i] = {}
		local dists = distances[i]
		for j = 1, unitCount do
			
			local nodePos = nodes[j]
			local dx, dz = nodePos[1] - ux, nodePos[3] - uz
			dists[j] = floor(sqrt(dx*dx + dz*dz) + 0.5)
			 -- Integer distances = greatly improved algorithm speed
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
		-- Delay is less than desired, so thats OK
		-- To make judgements we need number of units to be close to max
		-- Because we are making predictions of time and we want them to be accurate
		if (#units > maxHungarianUnits*unitIncreaseThresh) then
			
			-- This implementation of Hungarian algorithm is O(n3)
			-- Because we have less than maxUnits, but are altering maxUnits...
			-- We alter the time, to 'predict' time we would be getting at maxUnits
			-- We then recheck that against maxHngTime
			
			local nMult = maxHungarianUnits / #units
			
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
	for i = 1, unitCount do
		local rPair = result[i]
		orders[i] = {units[rPair[1]], nodes[rPair[2]]}
	end
	
	return orders
end

function findHungarian(array, n)
	
	-- Vars
	local colcover = {}
	local rowcover = {}
	local starscol = {}
	local primescol = {}
	
	-- Initialization
	for i = 1, n do
		rowcover[i] = false
		colcover[i] = false
		starscol[i] = false
		primescol[i] = false
	end
	
	-- Subtract minimum from rows
	for i = 1, n do
		
		local aRow = array[i]
		local minVal = aRow[1]
		for j = 2, n do
			if aRow[j] < minVal then
				minVal = aRow[j]
			end
		end
		
		for j = 1, n do
			aRow[j] = aRow[j] - minVal
		end
	end
	
	-- Subtract minimum from columns
	for j = 1, n do
		
		local minVal = array[1][j]
		for i = 2, n do
			if array[i][j] < minVal then
				minVal = array[i][j]
			end
		end
		
		for i = 1, n do
			array[i][j] = array[i][j] - minVal
		end
	end
	
	-- Star zeroes
	for i = 1, n do
		local aRow = array[i]
		for j = 1, n do
			if (aRow[j] == 0) and not colcover[j] then
				colcover[j] = true
				starscol[i] = j
				break
			end
		end
	end
	
	-- Start solving system
	while true do
		
		-- Are we done ?
		local done = true
		for i = 1, n do
			if not colcover[i] then
				done = false
				break
			end
		end
		
		if done then
			local pairings = {}
			for i = 1, n do
				pairings[i] = {i, starscol[i]}
			end
			return pairings
		end
		
		-- Not done
		local r, c = stepPrimeZeroes(array, colcover, rowcover, n, starscol, primescol)
		stepFiveStar(colcover, rowcover, r, c, n, starscol, primescol)
	end
end
function doPrime(array, colcover, rowcover, n, starscol, r, c, rmax, primescol)
	
	primescol[r] = c
	
	local starCol = starscol[r]
	if starCol then
		
		rowcover[r] = true
		colcover[starCol] = false
		
		for i = 1, rmax do
			if not rowcover[i] and (array[i][starCol] == 0) then
				local rr, cc = doPrime(array, colcover, rowcover, n, starscol, i, starCol, rmax, primescol)
				if rr then
					return rr, cc
				end
			end
		end
		
		return
	else
		return r, c
	end
end
function stepPrimeZeroes(array, colcover, rowcover, n, starscol, primescol)
	
	-- Infinite loop
	while true do
		
		-- Find uncovered zeros and prime them
		for i = 1, n do
			if not rowcover[i] then
				local aRow = array[i]
				for j = 1, n do
					if (aRow[j] == 0) and not colcover[j] then
						local i, j = doPrime(array, colcover, rowcover, n, starscol, i, j, i-1, primescol)
						if i then
							return i, j
						end
						break -- this row is covered
					end
				end
			end
		end
		
		-- Find minimum uncovered
		local minVal = huge
		for i = 1, n do
			if not rowcover[i] then
				local aRow = array[i]
				for j = 1, n do
					if (aRow[j] < minVal) and not colcover[j] then
						minVal = aRow[j]
					end
				end
			end
		end
		
		-- There is the potential for minVal to be 0, very very rarely though. (Checking for it costs more than the +/- 0's)
		
		-- Covered rows = +
		-- Uncovered cols = -
		for i = 1, n do
			local aRow = array[i]
			if rowcover[i] then
				for j = 1, n do
					if colcover[j] then
						aRow[j] = aRow[j] + minVal
					end
				end
			else
				for j = 1, n do
					if not colcover[j] then
						aRow[j] = aRow[j] - minVal
					end
				end
			end
		end
	end
end
function stepFiveStar(colcover, rowcover, row, col, n, starscol, primescol)
	
	-- Star the initial prime
	primescol[row] = false
	starscol[row] = col
	local ignoreRow = row -- Ignore the star on this row when looking for next
	
	repeat
		local noFind = true
		
		for i = 1, n do
			
			if (starscol[i] == col) and (i ~= ignoreRow) then
				
				noFind = false
				
				-- Unstar the star
				-- Turn the prime on the same row into a star (And ignore this row (aka star) when searching for next star)
				
				local pcol = primescol[i]
				primescol[i] = false
				starscol[i] = pcol
				ignoreRow = i
				col = pcol
				
				break
			end
		end
	until noFind
	
	for i = 1, n do
		rowcover[i] = false
		colcover[i] = false
		primescol[i] = false
	end
	
	for i = 1, n do
		local scol = starscol[i]
		if scol then
			colcover[scol] = true
		end
	end
end
