--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    central_build_AI.lua
--  brief:   Replacement for Central Build Group AI
--  author:  Troy H. Cheek
--
--  Copyright (C) 2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--to do : correct  bug that infinitely order to build mobile constructors instead of just 1.
-- because it never test the end of the build but test the validity to build another one at the same place.

function widget:GetInfo()
  return {
    name      = "Central Build AI",
    desc      = "v1.1 Common non-hierarchical permanent build queue",
    author    = "Troy H. Cheek",
    date      = "July 20, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = false  --  loaded by default?
  }
end

--  Central Build AI creates a common build order queue for all units in the
--	group.  Select this group (or any member of it) and issue build orders
--  while holding down the shift key to add orders to the common queue.
--  Idle builders in the group will automatically move to carry out orders
--  or assist other builders.  Issue same build order again to cancel.
--  Orders issued without shift will be carried out immediately.

-- optionnally to do:
-- _ orders with shift+ctrl have higher priority ( insert in queue -> cons won't interrupt their current actions)

local myGroupId = 0	--	Group number (0 to 9) to be controlled by Central Build AI.
--  -1 = Use custom group (hotkey to select, ctrl-hotkey to add units) similar old Group AI.
local hotkey = string.byte( "g" )	--  Change "g" to select new hotkey.

local Echo                 	= Spring.Echo
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetGroupList		= Spring.GetGroupList
local spGetGroupUnits		= Spring.GetGroupUnits
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spIsUnitInView 		= Spring.IsUnitInView
local spIsAABBInView		= Spring.IsAABBInView
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitCommands    	= Spring.GetUnitCommands
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitHealth		= Spring.GetUnitHealth
local spGiveOrderToUnit    	= Spring.GiveOrderToUnit
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetMyTeamID			= Spring.GetMyTeamID
local spGetFeatureTeam		= Spring.GetFeatureTeam
local spGetLocalPlayerID	= Spring.GetLocalPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetGameFrame       	= Spring.GetGameFrame
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetModKeyState		= Spring.GetModKeyState
local spTestBuildOrder		= Spring.TestBuildOrder
local spSelectUnitMap		= Spring.SelectUnitMap

local glPushMatrix	= gl.PushMatrix
local glPopMatrix	= gl.PopMatrix
local glTranslate	= gl.Translate
local glBillboard	= gl.Billboard
local glColor		= gl.Color
local glText		= gl.Text
local glBeginEnd	= gl.BeginEnd
local GL_LINE_STRIP	= GL.LINE_STRIP
local glDepthTest	= gl.DepthTest
local glRotate		= gl.Rotate
local glUnitShape	= gl.UnitShape
local glVertex		= gl.Vertex

local CMD_WAIT    	= CMD.WAIT
local CMD_MOVE     	= CMD.MOVE
local CMD_PATROL  	= CMD.PATROL
local CMD_REPAIR    = CMD.REPAIR
local CMD_INSERT    = CMD.INSERT
local CMD_REMOVE    = CMD.REMOVE
local CMD_RECLAIM	= CMD.RECLAIM
local CMD_GUARD		= CMD.GUARD
local CMD_STOP		= CMD.STOP

local abs	= math.abs
local floor	= math.floor
local huge	= math.huge
local sqrt 	= math.sqrt
local max	= math.max

local nextFrame	= spGetGameFrame() +30
local textColor = {0.7, 1.0, 0.7, 1.0}
local textSize = 12.0

--	"global" for this widget.  This is probably not a recommended practice.
local myUnits = {}	--  list of units in the Central Build group
local myQueue = {}  --  list of commands for Central Build group
local groupHasChanged	--	Flag if group members have changed.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
--  Borrowed from xyz's Action Finder and very_bad_soldier's Ghost Radar
	if spGetSpectatingState() then
		Echo( "<Central Build AI>: Spectator mode. Widget removed." )
		widgetHandler:RemoveWidget()
		return
	end
end

--function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
-- Spring.Echo(#cmdOpts,#cmdParams)
--end

--  Paint 'cb' tags on units, draw ghosts of items in central build queue.
--  Text stuff mostly borrowed from gunblob's Group Label and trepan/JK's BuildETA.
--  Ghost stuff borrowed from very_bad_soldier's Ghost Radar.

function widget:DrawWorld()
if not Spring.IsGUIHidden() then
	local alt, ctrl, meta, shift = spGetModKeyState()

	for unitID,myCmd in pairs(myUnits) do	-- show user which units are in CB
		if spIsUnitInView(unitID) then
--			local udid = spGetUnitDefID(unitID)
--			local ud = UnitDefs[udid]
			local ux, uy, uz = spGetUnitViewPosition(unitID)
			glPushMatrix()
			glTranslate(ux, uy, uz)
			glBillboard()
			glColor(textColor)
--			glText("cb "..myCmd, -10.0, -15.0, textSize, "con")
			glText("cb", -10.0, -15.0, textSize, "con")
			glPopMatrix()
			glColor(1, 1, 1, 1)
		end -- if InView
	end -- for unitID in group

	for key, myCmd in pairs(myQueue) do	-- show items in build queue
		local cmd = myCmd.id
		cmd = abs( cmd )
		local x, y, z, h = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local degrees = h * 90
		if spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
			if ( shift ) then
				glColor(0.0, 1.0, 0.0, 1 )
				glBeginEnd(GL_LINE_STRIP, DrawOutline, cmd, x, y, z, h)
			end
			glColor(1.0, 1.0, 1.0, 0.35 )	-- ghost value 0.35
			glDepthTest(true)
			glPushMatrix()
			glTranslate( x, y, z )
			glRotate( degrees, 0, 1.0, 0 )
			glUnitShape( cmd, spGetMyPlayerID() )
			glRotate( degrees, 0, -1.0, 0 )
			glBillboard()					-- also show some debug stuff
			glColor(textColor)
--			glText(key, -10.0, -15.0, textSize/2, "con")
			glText(cmd, -10.0, -15.0, textSize, "con")
			glPopMatrix()
			glDepthTest(false)
			glColor(1, 1, 1, 1)
		end -- if inview
	end
end
end

function DrawOutline(cmd,x,y,z,h)
	local ud = UnitDefs[cmd]
	local baseX = ud.xsize * 4 -- ud.buildingDecalSizeX
	local baseZ = ud.zsize * 4 -- ud.buildingDecalSizeY
	if (h == 1 or h==3) then
		baseX,baseZ = baseZ,baseX
	end
	glVertex(x-baseX,y,z-baseZ)
	glVertex(x-baseX,y,z+baseZ)
	glVertex(x+baseX,y,z+baseZ)
	glVertex(x+baseX,y,z-baseZ)
	glVertex(x-baseX,y,z-baseZ)
end

--	Stuff which needs to run regularly but isn't covered elsewhere.
--  Was Update(), but Niobium says GameFrame() is more better.

function widget:GameFrame(thisFrame)
	if ( thisFrame < nextFrame ) then return end
	nextFrame = thisFrame + 30	-- try again in 1 second if nothing else triggers
	if ( groupHasChanged == true ) then UpdateOneGroupsDetails(myGroupId) end
	FindIdleUnits(myUnits)		-- locate idle units not found otherwise
end

--	This function detects that a new group has been defined or changed.  Use it to set a flag
--	because it fires before all units it's going to put into group have actually been put in.
--  Borrowed from gunblob's UnitGroups v5.1

function widget:GroupChanged(groupId)  
	if groupId == myGroupId then
--		local units = spGetGroupUnits(myGroupId)
--		Echo( spGetGameFrame() .. " Change detected in group." )
		groupHasChanged = true
		nextFrame = spGetGameFrame() + ping()
	end
end

--  This function actually updates the list of builders in the CB group (myGroup).
--	Also borrowed from gunblob's UnitGroups v5.1

function UpdateOneGroupsDetails(myGroupId)
	local units = spGetGroupUnits(myGroupId)
	for _, unitID in ipairs(units) do	--  add the new units
		if ( not myUnits[unitID] ) then
			local udid = spGetUnitDefID(unitID)
			local ud = UnitDefs[udid]
			if ((ud.isBuilder or ud.builder) --[[TODO: remove isBuilder after 85.0]] and ud.canMove) then
				myUnits[unitID] = "idle"
			end
		end
	end
	for unitID,_ in pairs(myUnits) do	--  remove any old units
		local isInThere = false
		for _,unit2 in ipairs(units) do
			if ( unitID == unit2 ) then
				isInThere = true
				break
			end
		end
		if ( not isInThere ) then
			myUnits[unitID] = nil
		end
	end
	groupHasChanged = nil
end

--  If the command is issued to something in our group, flag it.
--  Thanks to Niobium for pointing out CommandNotify().

function widget:CommandNotify(id, params, options)
	local selectedUnits = spGetSelectedUnits()
	for _, unitID in ipairs(selectedUnits) do	-- check selected units...
		if ( myUnits[unitID] ) then	--  was issued to one of our units.
			if ( options.shift and id < 0 ) then	-- used shift for build.
				local x, y, z, h = params[1], params[2], params[3], params[4]
				local myCmd = { id=id, x=x, y=y, z=z, h=h }
				local hash = hash(myCmd)
				if ( myQueue[hash] ) then	-- if dupe of existing order
					myQueue[hash] = nil		-- must want to cancel
				else						-- if not a dupe
					myQueue[hash] = myCmd	-- add to CB queue
				end
				CleanOrders(myQueue)	-- don't add if can't build there
				return true	-- have to return true or Spring still handles command itself.
			else
				myUnits[unitID] = "busy"	-- direct command instead of queued.
				-- do NOT return here because there may be more units.  Let Spring handle.
			end
		end
	end
end

--	If one of our units completed an order, cancel units guarding it.
--  Thanks again to Niobium for pointing out UnitCmdDone().

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if ( myUnits[unitID] and cmdID < 0) then	-- one of us building something
--		myUnits[unitID] = "idle"
		for unit2,myCmd in pairs(myUnits) do
			if ( myCmd == "asst "..unitID ) then
				spGiveOrderToUnit( unit2, CMD_STOP, {}, { "" } )
			end
		end
	end
end

--	If unit detected as idle and it's one of ours, time to find it some work.

function widget:UnitIdle(unitID, unitDefID, teamID)
	if ( myUnits[unitID] ) then
--		myUnits[unitID] = "idle"
		nextFrame = spGetGameFrame() + ping()
	end
end

--  One at a time, assign idle builders new tasks.

function FindIdleUnits(myUnits)
	local nearestOrders = {}
	for unitID,myCmd in pairs(myUnits) do
		local cmd1 = GetFirstCommand(unitID)
		if ( cmd1 == nil ) then		-- no orders?  Must be idle.
			myUnits[unitID] = "idle"
			local tmp = GetWorkFor(unitID)
			if ( tmp ~= nil ) then
				table.insert( nearestOrders, tmp )	-- indexed okay here
			end
		end
	end
	if ( # nearestOrders < 1 ) then return end	-- nothing we can do
	local closeDist = huge
	local close = {}
	for _, cmd in ipairs(nearestOrders) do
		if ( cmd[4] < closeDist ) then
			closeDist = cmd[4]
			close = cmd
		end
	end
	spGiveOrderToUnit( close[1], close[2], close[3], { "" } )
	if ( close[5] == 0 ) then
		myUnits[close[1]] = "asst "..unpack(close[3])	--  unitID we're assisting
--		Echo(close[3])
	else
		myUnits[close[1]] = close[5]	--  hash of command we're executing
--		Echo(close[5])
	end
	nextFrame = spGetGameFrame() + ping()
end

--	Borrowed distance calculation from Google Frog's Area Mex

local function Distance(x1,z1,x2,z2)
  local dis = sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.

function GetFirstCommand(unitID)
	local queue = spGetUnitCommands(unitID)
	return queue and queue[1]
end

--  Formerly remove duplicate orders, process cancel requests, delete bad builds.
--  Now, just test for and remove bad builds.

function CleanOrders(myQueue)
	for key,myCmd in pairs(myQueue) do
		local cmd = myCmd.id
		cmd = abs( cmd )
		local x, y, z, h = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local canBuildThatThere,featureID = spTestBuildOrder(cmd,x,y,z,h)
		if ( featureID ) then
			if ( spGetFeatureTeam(featureID) == spGetMyTeamID() ) then
				canBuildThatThere = 0
			end
		end
		if (canBuildThatThere < 1) then
			myQueue[key] = nil
		end
	end
end

--	This function returns closest work for a particular builder.

function GetWorkFor(unitID)
	local busyClose = 0		-- unitID of closest busy unit
	local busyDist = huge	-- how far away it is.  (Thanks to Niobium.)
	local queueClose = 0	-- command hash of closest project in the queue
	local queueDist = huge	-- how far away it is.  (Thanks to Niobium.)
	local ux, uy, uz = spGetUnitPosition(unitID)	-- unit location
	
	CleanOrders(myQueue)	-- just in case something's changed since last we checked.

	for unit,theCmd in pairs(myUnits) do	-- see if any busy units need help.
		local cmd1 = GetFirstCommand(unit)
		local myCmd = myQueue[theCmd]
		if ( myCmd ) then
			local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
			if ( cmd  and cmd < 0 ) then
				local x2, y2, z2 = spGetUnitPosition(unit)	-- location of busy unit
				local dist = ( Distance(ux,uz,x,z) + Distance(ux,uz,x2,z2) + Distance(x,z,x2,z2) ) / 2
				if ( dist < busyDist ) then
					busyClose = unit	-- busy unit who needs help
					busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
				end
			end
		elseif ( cmd1 and cmd1.id < 0 ) then
			local x2, y2, z2 = spGetUnitPosition(unit)	-- location of busy unit
			local dist = Distance(ux,uz,x2,z2) * 1.5
			if ( dist < busyDist ) then
				busyClose = unit	-- busy unit who needs help
				busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
			end
		end
	end
	
	for index,myCmd in pairs(myQueue) do	-- any new projects to be started?
		local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local alreadyWorkingOnIt = false	-- is some other unit already assigned this?
		for unit2,cmd2 in pairs(myUnits) do
			if ( index == cmd2 ) then
				alreadyWorkingOnIt = true
				break
			end
		end
		if ( not alreadyWorkingOnIt ) then
			local acmd = abs(cmd)
			local udid = spGetUnitDefID(unitID)
			local ud = UnitDefs[udid]
			local canBuild = false	-- if this unit can't build it, skip it.
			for _, options in ipairs(ud.buildOptions) do
				if ( options == acmd ) then canBuild = true break end	-- only one to find.
			end
			local dist = Distance(ux,uz,x,z)
			if ( dist < queueDist and canBuild ) then
				queueClose = index	-- # of the project we'll be starting
				queueDist = dist
			end	
		end
		
	end
	
	-- removed canHover tag since it's deprecated
	-- also, @special handling: why?
	if ( busyDist < huge or queueDist < huge ) then
		local udid = spGetUnitDefID(unitID)
		local ud = UnitDefs[udid]
		if ( busyDist < queueDist ) then	-- assist is closer
			if ( ud.canFly ) then busyDist = busyDist * 0.50 end
			--if ( ud.canHover ) then busyDist = busyDist * 0.75 end
			return { unitID, CMD_GUARD, { busyClose }, busyDist, 0 }
		else	-- new project is closer
			if ( ud.canFly ) then queueDist = queueDist * 0.50 end
			--if ( ud.canHover ) then queueDist = queueDist * 0.75 end
			myCmd = myQueue[queueClose]
			local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
			return { unitID, cmd, { x, y, z, h }, queueDist, queueClose }
		end
		
	end
end

--  Detect when player enters spectator mode (thanks to SeanHeron).

function widget:PlayerChanged(playerID)
	if spGetSpectatingState() then
--		Echo( "<Central Build> Spectator mode. Widget removed." )
		widgetHandler:RemoveWidget()
		return
	end
end

--  Concept borrowed from Dave Rodger (trepan) MetalMakers widget

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	UnitGoByeBye(unitID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	UnitGoByeBye(unitID)
end

--  If unit in our group is destroyed, captured, dropped from group, cancel any
--  GUARD order from rest of group.  Probably not necessary for destroyed units.

function UnitGoByeBye(unitID)
	if ( myUnits[unitID] ) then
		myUnits[unitID] = nil
		for unit2,myCmd in pairs(myUnits) do
			if ( myCmd == "asst "..unitID ) then
				spGiveOrderToUnit( unit2, CMD_STOP, {}, { "" } )
			end
		end
	end
		
end

--	Prevent CBAI from canceling orders that just haven't made it to host yet
--	because of high ping.  May no longer be necessary.  Donated by SkyStar.

function ping()
	local playerID = spGetLocalPlayerID()
	local tname, _, tspec, tteam, tallyteam, tping, tcpu = spGetPlayerInfo(playerID)   
	tping = (tping*1000-((tping*1000)%1)) /100 * 4
	return max( tping, 3 )
end

--	Generate unique key value for each command using its parameters.
--  Much easier than expected once I learned Lua can use *anything* for a key.

function hash(myCmd)
	local hash = myCmd.id .. "@" .. myCmd.x .. "x" .. myCmd.z
	return hash
end

function widget:KeyPress(key, mods, isRepeat)
--Spring.Echo("<central_build_AI.lua DEBUG>: (KeyPress): ".. key)
	if ( myGroupId > -1 ) then return end
	if ( key ~= hotkey ) then return end
	if ( mods.ctrl ) then	-- ctrl means add selected units to group
	--Spring.Echo("<central_build_AI.lua DEBUG>: (KeyPress): CTRL")
		local units = spGetSelectedUnits()
		for _, unitID in ipairs(units) do	--  add the new units
			if ( not myUnits[unitID] ) then
				local udid = spGetUnitDefID(unitID)
				local ud = UnitDefs[udid]
				if ((ud.isBuilder or ud.builder) --[[TODO: remove isBuilder after 85.0]] and ud.canMove) then
					myUnits[unitID] = "idle"
				end
			end
		end
		for unitID,_ in pairs(myUnits) do	--  remove any old units
			local isInThere = false
			for _,unit2 in ipairs(units) do
				if ( unitID == unit2 ) then
					isInThere = true
					break
				end
			end
			if ( not isInThere ) then
				myUnits[unitID] = nil
			end
		end
	elseif ( mods.shift ) then	-- add group to selected units
	--Spring.Echo("<central_build_AI.lua DEBUG>: (KeyPress): shift")
		spSelectUnitMap(myUnits,true)
	else	-- select our group or center our group if already selected.
		local myUnitsCount = 0
		for unitID,_ in pairs(myUnits) do
			myUnitsCount = myUnitsCount + 1
		end
		if ( myUnitsCount < 1 ) then return end
		local isInThere = true
		local units = spGetSelectedUnits()
		if ( # units ~= myUnitsCount ) then
			isInThere = false
		end
		for _, unitID in ipairs(units) do
			if ( not myUnits[unitID] ) then
				isInThere = false
				break
			end
		end
		if ( isInThere ) then	-- center screen on our group
			local xc,yc,zc = 0,0,0	-- composite mappos
			for unitID,_ in pairs(myUnits) do
				local x, y, z = spGetUnitPosition(unitID)
				xc,yc,zc = xc+x,yc+y,zc+z
			end
			xc,yc,zc = xc/myUnitsCount,yc/myUnitsCount,zc/myUnitsCount
			Spring.SetCameraTarget(xc, yc, zc)
		end
		spSelectUnitMap(myUnits)
	end
end
