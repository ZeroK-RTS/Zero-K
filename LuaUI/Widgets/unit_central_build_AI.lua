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

local version = "v1.3"
function widget:GetInfo()
  return {
    name      = "Central Build AI",
    desc      = version.. " Common non-hierarchical permanent build queue\n\nInstruction: add constructor(s) to group zero (use \255\90\255\90Auto Group\255\255\255\255 widget or manual), then give any of them a build queue. As a result: the whole group (group 0) will see the same build queue and they will distribute work automatically among them. Type \255\255\90\90/cba\255\255\255\255 to forcefully delete all stored queue",
    author    = "Troy H. Cheek, modified by msafwan",
    date      = "July 20, 2009, 27 Oct 2012",
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

---- CHANGELOG -----
-- msafwan,			v1.21	(7oct2012)	: 	fix some cases where unit become 'idle' but failed to be registered by CBA, 
--											make CBA assign all job at once rather than sending 1 by 1 after every some gameframe delay,
-- msafwan,			v1.2	(4sept2012)	: 	made it work with ZK "cmd_mex_placement.lua" mex queue, 
--											reduce the tendency to make a huge blob of constructor (where all constructor do same job),
--											reduce chance of some constructor not given job when player have alot of constructor,
-- rafal,			v1.1	(2May2012)	:	Don't fetch full Spring.GetCommandQueue in cases when only the first command is needed - instead using
--											GetCommandQueue(unitID, 1)
-- KingRaptor,		v1.1	(24dec2011)	:	Removed the "remove in 85.0" stuff
-- versus666,		v1.1	(16dec2011)	: 	mostly changed the layer order to get a logical priority among widgets.
-- KingRaptor,		v1.1	(8dec2011)	:	Fixed the remaining unitdef tags for 85.0
-- versus666,		v1.1	(7jan2011)	: 	Made CBA, cmd_retreat, gui_nuke_button, gui_team_platter.lua, unit_auto_group to obey F5 (gui hidden).
-- KingRaptor,		v1.1	(2Nov2010)	:	Moved version number from name to description. 
-- lccquantum,		v1.1	(2Nov2010)	:	central_build_AI is disabled by default (people will wonder why their builders are acting wierd when in group 0)
-- versus666,		v1.1	(1Nov2010)	: 	introduced into ZK

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myGroupId = 0	--//Constant: a group number (0 to 9) will be controlled by Central Build AI. NOTE: put "-1" to use a custom group instead (use the hotkey to add units;ie: ctrl+hotkey).
local hotkey = string.byte( "g" )	--//Constant: a custom hotkey to add unit to custom group. NOTE: set myGroupId to "-1" to use this hotkey.
local checkFeatures = false --//Constant: if true, Central Build will reject any build queue on top of allied features (eg: ally's wreck & dragon teeth).

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
	widgetHandler:RegisterGlobal("CommandNotifyMex", CommandNotifyMex) --an event which is called everytime "cmd_mex_placement.lua" widget handle a mex command. Reference : http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
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
			if myCmd == "idle" then
				glText("idl", -10.0, -15.0, textSize, "con")
			elseif myCmd == "busy" then
				glText("bsy", -10.0, -15.0, textSize, "con")
			else
				glText("cb", -10.0, -15.0, textSize, "con")
			end
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
	if ( thisFrame < nextFrame ) then 
		return
	end
	if ( groupHasChanged == true ) then 
		UpdateOneGroupsDetails(myGroupId)
	end
	nextFrame = thisFrame + 30	-- try again in 1 second if nothing else triggers
	FindIdleUnits(myUnits,thisFrame)		-- locate idle units not found otherwise
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
			if (ud.builder and ud.canMove) then
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

--	A compatibility function: receive broadcasted event from "cmd_mex_placement.lua" (ZK specific) which notify us that it has its own mex queue
function CommandNotifyMex(id,params,options)
	return widget:CommandNotify(id, params, options, 1)
end

--  If the command is issued to something in our group, flag it.
--  Thanks to Niobium for pointing out CommandNotify().

function widget:CommandNotify(id, params, options, zkMex)
	local selectedUnits = spGetSelectedUnits()
	for _, unitID in ipairs(selectedUnits) do	-- check selected units...
		if ( myUnits[unitID] ) then	--  was issued to one of our units.
			if ( options.shift ) then -- used shift for:.
				if ( id < 0 ) then --for: building
					local x, y, z, h = params[1], params[2], params[3], params[4]
					local myCmd = { id=id, x=x, y=y, z=z, h=h }
					local isOverlap = CleanOrders(myCmd) -- check if current queue overlap with existing queue, and clear up any invalid queue 
					if not isOverlap then
						local hash = hash(myCmd)
						--[[
						if ( myQueue[hash] ) then	-- if dupe of existing order
							myQueue[hash] = nil		-- must want to cancel
						else						-- if not a dupe
							myQueue[hash] = myCmd	-- add to CB queue
						end
						--]]
						myQueue[hash] = myCmd	-- add to CB queue
					end
					nextFrame = spGetGameFrame() + 30 --wait 1 more second before distribute work, so user can queue more stuff
					return true	-- have to return true or Spring still handles command itself.
				else --for: moving/attacking/repairing, ect
					if myUnits[unitID] == "idle" then --unit is not doing anything
						myUnits[unitID] = "busy" --is doing irrelevant thing
					end
					-- do NOT return here because there may be more units.  Let Spring handle.
				end
			else
				if ( id < 0 ) then --direct command of building stuff
					local x, y, z, h = params[1], params[2], params[3], params[4]
					local myCmd = { id=id, x=x, y=y, z=z, h=h }
					local hash = hash(myCmd)
					myUnits[unitID] = hash
				else
					myUnits[unitID] = "busy"	-- direct command of something else.
				end
				-- do NOT return here because there may be more units.  Let Spring handle.
			end
		end
	end
end

--	If one of our units completed an order, cancel units guarding it.
--  Thanks again to Niobium for pointing out UnitCmdDone().

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if ( myUnits[unitID] and cmdID < 0 ) then	-- one of us finish building something
		local myCmd1 = myUnits[unitID]
		local myCmd_header = myCmd1:sub(1,4)
		if myCmd_header ~= "asst" then --check if this unit was GUARDing another unit. If NOT then:
			local cmd1 = GetFirstCommand(unitID)
			if ( cmd1 == nil ) then		-- no orders?  Must be idle.
				myUnits[unitID]="idle"
			else -- have orders?  Must be busy.
				myUnits[unitID]="busy" -- command done but still busy.
			end
		end
		for unit2,myCmd in pairs(myUnits) do
			if ( myCmd == myCmd1 ) then --check if others is using same command as this unit, if true:
				local cmd2 = GetFirstCommand(unit2)
				if ( cmd2 == nil ) then		-- no orders?  Must be idle.
					myUnits[unit2]="idle"
				else 
					myUnits[unit2]="busy" -- command done but still busy.
				end
			elseif ( myCmd == "asst "..unitID ) then  --check if this unit is being GUARDed
				spGiveOrderToUnit(unit2, CMD_REMOVE, {CMD_GUARD}, {"alt"} ) --remove the GUARD command from those units
				myUnits[unit2] = "idle" --set as "idle"
			end
		end		
		nextFrame = spGetGameFrame() + ping() --find new work
	end
end

--	If unit detected as idle and it's one of ours, time to find it some work.

function widget:UnitIdle(unitID, unitDefID, teamID)
	if ( myUnits[unitID] ) then
		myUnits[unitID] = "idle"
		nextFrame = spGetGameFrame() + ping() --find new work
	end
end

--  One at a time, assign idle builders new tasks.

function FindIdleUnits(myUnits, thisFrame)
	--HOW THIS WORK:
	--*loop for all CBA unit,
	--	*loop for all CBA unit,
	--		*for each CBA unit: find nearest job
	--			>check nearest job for assisting other constructor
	--			>check nearest job for constructing building queue
	--			>check whether assisting or construction is nearest
	--		*return nearest job for each CBA unit
	--	*return all matching jobs for all CBA units
	--	>check how many constructor has new job order
	--	>check which constructor is the nearest to its job
	--	>register that constructor as worker
	--*return command to be given to that constructor
	-->send all command to all CBA units.
	CleanOrders()	-- check build site for blockage. In case something's changed since last we checked.
	local orderArray={}
	local unitArray={}
	for _,_ in pairs(myUnits) do
		local nearestOrders = {}
		for unitID,myCmd in pairs(myUnits) do
			--[[
			local cmd1 = GetFirstCommand(unitID)
			if ( cmd1 == nil ) then		-- no orders?  Must be idle.
				myUnits[unitID] = "idle"
			--]]
			if myUnits[unitID] == "idle" then --if unit is marked as idle, then use it.
				local tmp = GetWorkFor(unitID)
				if ( tmp ~= nil ) then
					table.insert( nearestOrders, tmp )	-- indexed okay here
				end
			end
		end
		if ( # nearestOrders < 1 ) then 
			break -- no more job, escape the loop.
		end	-- nothing we can do
		local closeDist = huge
		local close = {}
		for _, cmd in ipairs(nearestOrders) do --find unit with the closest distance to their project
			if ( cmd[4] < closeDist ) then
				closeDist = cmd[4]
				close = cmd
			end
		end
		--spGiveOrderToUnit( close[1], close[2], close[3], { "" } )
		unitArray[#unitArray+1]=close[1]
		orderArray[#orderArray+1]={close[2], close[3], { "" }}
		if ( close[5] == 0 ) then
			myUnits[close[1]] = "asst "..unpack(close[3])	--  unitID we're assisting
			--Echo(close[3])
		else
			myUnits[close[1]] = close[5]	--  hash of command we're executing
			--Echo(close[5])
		end
	end
	Spring.GiveOrderArrayToUnitArray (unitArray,orderArray, true) --send command to bulk of constructor
	unitArray = nil
	orderArray = nil
	--nextFrame = thisFrame + ping()
end

--	Borrowed distance calculation from Google Frog's Area Mex

local function Distance(x1,z1,x2,z2)
  local dis = sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.

function GetFirstCommand(unitID)
	local queue = spGetUnitCommands(unitID, 1)
	return queue and queue[1]
end

--  Formerly remove duplicate orders, process cancel requests, delete bad builds.
--  Now, just test for and remove bad builds.
--  EDIT: added check for duplicate.

function CleanOrders(newCmd)
	local xSize = nil --variables for checking queue overlaping
	local zSize = nil
	local xSize_queue = nil
	local zSize_queue = nil
	local x_newCmd = nil
	local z_newCmd = nil
	local isOverlap = nil
	if newCmd then --check the size of the new queue
		local newCmdID = abs ( newCmd.id )
		x_newCmd = newCmd.x
		z_newCmd = newCmd.z
		if newCmd.h == 0 or newCmd.h == 2 then --get building facing. Reference: unit_prevent_lab_hax.lua by googlefrog
			xSize = UnitDefs[newCmdID].xsize*4
			zSize = UnitDefs[newCmdID].zsize*4
		else
			xSize = UnitDefs[newCmdID].zsize*4
			zSize = UnitDefs[newCmdID].xsize*4
		end
	end
	for key,myCmd in pairs(myQueue) do
		local cmdID = abs( myCmd.id )
		local x, y, z, facing = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		
		local canBuildThisThere,featureID = spTestBuildOrder(cmdID,x,y,z,facing) --check if build site is blocked by buildings & terrain
		if ( checkFeatures ) and ( featureID ) then --check if build site is blocked by feature
			if ( spGetFeatureTeam(featureID) == spGetMyTeamID() ) then --if feature belong to team, then don't reclaim or build there. (ie: dragon-teeth's wall)
				canBuildThisThere = 0
			end
		end
		if newCmd and (canBuildThisThere >= 1) then --check if build site overlap new queue
			if facing == 0 or facing == 2 then --check the size of the queued building
				xSize_queue = UnitDefs[cmdID].xsize*4
				zSize_queue = UnitDefs[cmdID].zsize*4
			else
				xSize_queue = UnitDefs[cmdID].zsize*4
				zSize_queue = UnitDefs[cmdID].xsize*4
			end
			local minTolerance = xSize_queue + xSize --check minimum tolerance in x direction
			local axisDist = abs (x - x_newCmd) --check actual separation in x direction
			if axisDist < minTolerance then --if too close in x directionL
				minTolerance = zSize_queue + zSize --check minimum tolerance in z direction
				axisDist = abs (z - z_newCmd) -- check actual separation in z direction
				if axisDist < minTolerance then --if too close in z direction
					canBuildThisThere = 0 --remove queue
					isOverlap = true
				end
			end
		end
		if (canBuildThisThere < 1) then --if queue is flagged for removal
			myQueue[key] = nil  --remove queue
		end
	end
	
	return isOverlap --return a value for "widget:CommandNotify()" to handle user's command.
end

--	This function returns closest work for a particular builder.

function GetWorkFor(unitID)
	local busyClosestID = 0		-- unitID of closest busy unit
	local busyDist = huge	-- how far away it is.  (Thanks to Niobium.)
	local queueClose = 0	-- command hash of closest project in the queue
	local queueDist = huge	-- how far away it is.  (Thanks to Niobium.)
	local ux, uy, uz = spGetUnitPosition(unitID)	-- unit location

	for busyUnitID,busyCmd1 in pairs(myUnits) do	-- see if any busy units need help.
		local cmd1 = GetFirstCommand(busyUnitID)
		local myCmd = myQueue[busyCmd1]
		if ( myCmd ) then --when busy unit has CentralBuild command
			local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
			if ( cmd  and cmd < 0 ) then
				local x2, y2, z2 = spGetUnitPosition( busyUnitID)	-- location of busy unit
				local numOfAssistant = 0.0
				for assistantUnitID,assistantCmd1 in pairs(myUnits) do --find how many unit is assisting this busy unit
					local prefix = assistantCmd1:sub(1,4)
					if prefix ~= "asst" then
						if (assistantCmd1 == busyCmd1) then
							numOfAssistant = numOfAssistant + 0.1
						end
					else
						-- assistantCmd1:sub(1,5) == "asst "
						local assisting = tonumber(assistantCmd1:sub(6))
						if (assisting == busyUnitID) then
							numOfAssistant = numOfAssistant + 0.1
						end
					end
				end
				local dist = ( Distance(ux,uz,x,z) + Distance(ux,uz,x2,z2) + Distance(x,z,x2,z2) ) / 2 --distance between busy unit & self,and btwn structure & self, and between structure & busy unit.
				dist = dist + dist*numOfAssistant
				if ( dist < busyDist ) then
					busyClosestID = busyUnitID	-- busy unit who needs help
					busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
				end
			end
		elseif ( cmd1 and cmd1.id < 0) then --when busy unit is currently building a structure
			local x2, y2, z2 = spGetUnitPosition(busyUnitID)	-- location of busy unit
			local numOfAssistant = 0.0
			for assistantUnitID,assistantCmd1 in pairs(myUnits) do --find how many unit is assisting this busy unit
				local prefix = assistantCmd1:sub(1,4)
				if prefix ~= "asst" then
					local cmd2 = GetFirstCommand(assistantUnitID)
					if (cmd2 and (cmd2 == cmd1)) then
						numOfAssistant = numOfAssistant + 0.1
					end
				else
					-- assistantCmd1:sub(1,5) == "asst "
					local assisting = tonumber(assistantCmd1:sub(6))
					if (assisting == busyUnitID) then
						numOfAssistant = numOfAssistant + 0.1
					end
				end
			end
			local dist = Distance(ux,uz,x2,z2) * 1.5 --distance between busy unit & self
			dist = dist + dist*numOfAssistant
			if ( dist < busyDist ) then
				busyClosestID = busyUnitID	-- busy unit who needs help
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
			local theCmd = myUnits[busyClosestID]
			local myCmd = myQueue[theCmd]
			if myCmd then --see if unit can use the same build queue from CentralBuildQueue
				return { unitID, myCmd.id, { myCmd.x, myCmd.y, myCmd.z, myCmd.h }, busyDist, theCmd } --assist the busy unit by copying order.
			else
				local cmd1 = GetFirstCommand(busyClosestID)
				if cmd1 then --see if unit can use the same exact queue from the unit to be assisted
					return { unitID, cmd1.id, { cmd1.params[1], cmd1.params[2], cmd1.params[3], cmd1.params[4] }, busyDist, theCmd } --assist the busy unit by copying order.
				else --simply GUARD the unit to be assisted when all fail
					return { unitID, CMD_GUARD, { busyClosestID }, busyDist, 0 } --assist the busy unit by GUARDING it.
				end
			end
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
				spGiveOrderToUnit(unit2, CMD_REMOVE, {CMD_GUARD}, {"alt"} ) --remove the GUARD command
				myUnits[unit2] = "idle"
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
	return max( tping, 15 )
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
				if (ud.builder and ud.canMove) then
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

-- Function to help clear ALL existing command instantenously

function widget:TextCommand(command)
	if command == "cba" then
		for key,myCmd in pairs(myQueue) do
			myQueue[key]=nil
		end
		Spring.Echo("cba's command queue cleared")
		return true
	end
	return false
end