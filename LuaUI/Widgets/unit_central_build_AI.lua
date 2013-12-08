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

local version = "v1.348"
function widget:GetInfo()
  return {
    name      = "Central Build AI",
    desc      = version.. " Common non-hierarchical permanent build queue\n\nInstruction: add constructor(s) to group 0 (use \255\90\255\90Auto Group\255\255\255\255 widget or manually), then give any of them a build queue. As a result: the whole group (group 0) will see the same build queue and they will distribute work automatically among them. Type \255\255\90\90/cba\255\255\255\255 to forcefully delete all stored queue",
    author    = "Troy H. Cheek, modified by msafwan",
    date      = "July 20, 2009, 19 September 2013",
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

local Echo					= Spring.Echo
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
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetModKeyState		= Spring.GetModKeyState
local spTestBuildOrder		= Spring.TestBuildOrder
local spSelectUnitMap		= Spring.SelectUnitMap
local spGetUnitsInCylinder 	= Spring.GetUnitsInCylinder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetUnitAllyTeam 	= Spring.GetUnitAllyTeam
local spGetUnitIsStunned 	= Spring.GetUnitIsStunned

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

local currentFrame = Spring.GetGameFrame()
local nextFrame	= currentFrame +30
local nextPathCheck = currentFrame + 400 --is used to check whether constructor can go to construction site
local myAllyID = Spring.GetMyAllyTeamID()
local textColor = {0.7, 1.0, 0.7, 1.0}
local textSize = 12.0
local enemyRange = 600 --range (in elmo) around build site to check for enemy
local enemyThreshold = 0.49--fraction of enemy around build site w.r.t. ally unit for it to be marked as unsafe

--	"global" for this widget.  This is probably not a recommended practice.
local myUnits = {}	--  list of units in the Central Build group
local myQueue = {}  --  list of commands for Central Build group
local groupHasChanged	--	Flag if group members have changed.
local myQueueUnreachable = {} -- list of queue which units can't reach

local cachedValue = {} --cached results for "EnemyControlBuildSite()" function to reduce cost for repeated call
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
	currentFrame = thisFrame
	if ( thisFrame > nextPathCheck ) then
		cachedValue = {}
		UpdateUnitsPathability()
		nextPathCheck = thisFrame + 300
	end
	if ( thisFrame < nextFrame ) then 
		return
	end
	if ( groupHasChanged == true ) then 
		UpdateOneGroupsDetails(myGroupId)
	end
	nextFrame = thisFrame + 60	-- try again in 2 second if nothing else triggers
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
		nextFrame = currentFrame + ping()
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
			if (ud.isBuilder and ud.canMove) then
				myUnits[unitID] = "idle"
				myQueueUnreachable[unitID]= {}
				UpdateOneUnitPathability(unitID)
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
			myQueueUnreachable[unitID]=nil
		end
	end
	groupHasChanged = nil
end

--	A compatibility function: receive broadcasted event from "cmd_mex_placement.lua" (ZK specific) which notify us that it has its own mex queue
function CommandNotifyMex(id,params,options, isAreaMex)
	local groundHeight = Spring.GetGroundHeight(params[1],params[3])
	params[2] = math.max(0, groundHeight)
	local returnValue = widget:CommandNotify(id, params, options, true,isAreaMex)
	return returnValue
end

--  If the command is issued to something in our group, flag it.
--  Thanks to Niobium for pointing out CommandNotify().

function widget:CommandNotify(id, params, options, isZkMex,isAreaMex)
	if id < 0 and params[1]==nil and params[2]==nil and params[3]==nil then --CentralBuildAI can't handle unit-build command for factory for the moment (is buggy).
		return
	end
	if options.meta then --skip special insert command (spacebar). Handled by CommandInsert() widget
		return
	end
	local selectedUnits = spGetSelectedUnits()
	for _, unitID in pairs(selectedUnits) do	-- check selected units...
		if ( myUnits[unitID] ) then	--  was issued to one of our units.
			if ( options.shift ) then -- used shift for:.
				if ( id < 0 ) then --for: building
					local x, y, z, h = params[1], params[2], params[3], params[4]
					local myCmd = { id=id, x=x, y=y, z=z, h=h }
					local isOverlap = CleanOrders(myCmd) -- check if current queue overlap with existing queue, and clear up any invalid queue 
					if not isOverlap then
						local hash = hash(myCmd)
						--[[ crude delete-duplicate-command code. Now is handled by CleanOrder():
						if ( myQueue[hash] ) then	-- if dupe of existing order
							myQueue[hash] = nil		-- must want to cancel
						else						-- if not a dupe
							myQueue[hash] = myCmd	-- add to CB queue
							UpdateUnitsPathabilityForOneQueue(hash)
						end
						--]]
						myQueue[hash] = myCmd	-- add to CB queue
						UpdateUnitsPathabilityForOneQueue(hash,nil)  --take note of build site reachability
					end
					nextFrame = currentFrame + 30 --wait 1 more second before distribute work, so user can queue more stuff
					return true	-- have to return true or Spring still handles command itself.
				else --for: moving/attacking/repairing, ect
					if myUnits[unitID] == "idle" then --unit is not doing anything
						myUnits[unitID] = "busy" --is doing irrelevant thing
					end
					-- do NOT return here because there may be more units.  Let Spring handle.
				end
			else
				if ( id < 0 ) and (not isAreaMex ) then --is building stuff & is direct command/not an area mex command
					local x, y, z, h = params[1], params[2], params[3], params[4]
					local myCmd = { id=id, x=x, y=y, z=z, h=h }
					local hash = hash(myCmd)
					myUnits[unitID] = hash --remember what command this unit is having
					UpdateUnitsPathabilityForOneQueue(hash,myCmd) --take note of build site reachability
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

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag,cmdParams) --this is called for each time a command is finished
	if ( myUnits[unitID] and cmdID < 0 ) then	-- one of us finish building something
		local myCmd1 = myUnits[unitID]
		local myCmd_header = myCmd1:sub(1,4)
		if myCmd_header ~= "asst" then --check if this unit was GUARDing another unit. If NOT then update unit status
			local cmd = GetFirstCommand(unitID)
			if ( cmd == nil ) then		-- no orders?  Must be idle. NOTE: this will fail if unit still have CMD.STOP and/or CMD.SET_WANTED_SPEED, therefore we depend on UnitIdle().
				myUnits[unitID]="idle"
			else -- have orders?  Must be busy. 
				myUnits[unitID]="busy" -- command done but still busy. eg: have user queue pending
			end
		end
		local buildFinished
		if cmdParams then
			--find out if widget:UnitCmdDone() call is due to building completion or due to interruption (this require Spring 95):
			local blockingUnits = spGetUnitsInRectangle(cmdParams[1]-4, cmdParams[3]-4, cmdParams[1]+4, cmdParams[3]+4)
			for i=1, #blockingUnits do
				if spGetUnitDefID(blockingUnits[i]) == -cmdID then
					local _,_,inBuild = spGetUnitIsStunned(blockingUnits[i])
					if not inBuild then
						buildFinished = true; --build order is finished, FORCE STOP other assisting constructors. This fix constructors won't stop when building transportable turret in NOTA.
					end
					break;
				end
			end
		end
		for unit2,myCmd in pairs(myUnits) do
			if ( unit2~=unitID ) and( myCmd == myCmd1 ) then --check if others is using same command as this unit (note: myCmd == "cmdID@x@z", if true:
				local cmd2 = GetFirstCommand(unit2)
				if ( cmd2 == nil ) then	-- no orders?  Must be idle.
					myUnits[unit2]="idle"
				else 
					if ( buildFinished and cmd2.id == cmdID ) then --having same order as finished order
						spGiveOrderToUnit(unit2, CMD_REMOVE, {cmd2.tag}, {} ) --remove
						spGiveOrderToUnit(unit2, CMD_INSERT, {0,CMD_STOP}, {"alt"} ) --stop current motion
					end
					myUnits[unit2]="busy" -- command done but still busy. Example scenario: unit attempt to assist a construction while user SHIFT queued a reclaim command, however the construction finishes first before this unit arrives, so this unit continue finishing the RECLAIM command with "busy" tag.
				end
			elseif ( myCmd == "asst "..unitID ) then  --check if this unit is being GUARDed
				spGiveOrderToUnit(unit2, CMD_REMOVE, {CMD_GUARD}, {"alt"} ) --remove the GUARD command from those units
				myUnits[unit2] = "idle" --set as "idle"
			end
		end		
		nextFrame = currentFrame + ping() --find new work
	end
end

--	If unit detected as idle and it's one of ours, time to find it some work.

function widget:UnitIdle(unitID, unitDefID, teamID)
	if ( myUnits[unitID] ) then
		for unit2,myCmd in pairs(myUnits) do
			if ( myCmd == "asst "..unitID ) then  --check if this unit is being GUARDed
				spGiveOrderToUnit(unit2, CMD_REMOVE, {CMD_GUARD}, {"alt"} ) --remove the GUARD command from those units
				myUnits[unit2] = "idle" --set as "idle"
			end
		end
		myUnits[unitID] = "idle"
		nextFrame = currentFrame + ping() --find new work
	end
end

--  One at a time, assign idle builders new tasks.

function FindIdleUnits(myUnits, thisFrame)
	local idle_myUnits = {}
	local idle_assigned = {}
	local numberOfIdle = 0
	for unitID,myCmd in pairs(myUnits) do --check if unit really idle or is actually busy, because UnitIdle() can be triggered by other widget and is overriden with new command afterward, thus making unit look idle but is busy (ie: cmd_mex_placement.lua, area mex widget)
		if myCmd == "idle" then --if unit is marked as idle, then double check it
			local cmd1 = GetFirstCommand(unitID)
			if ( cmd1 ) then
				if ( cmd1.id < 0 ) then --is build (any) stuff
					if ( cmd1.params[3] ) then --is not build unit command (build unit command has nil parameter (only for factory))
						local unitCmd = {id=cmd1.id,x=cmd1.params[1],y=cmd1.params[2],z=cmd1.params[3],h=cmd1.params[4]}
						local hash = hash(unitCmd)
						myUnits[unitID] = hash
					end
				else
					myUnits[unitID] = 'busy'
				end
			else
				if numberOfIdle <= 10 then
					numberOfIdle = numberOfIdle +1
					--NOTE: only allow up to 10 idler to be processed to prevent super lag.
					--The amount of external loop will be (numberOfmyunit^2+numberOfQueue)*numberOfIdle^2.
					--ie: if all variable were 50, then the amount of loop in total is 6375000 loop (6 million).
					idle_myUnits[numberOfIdle] = unitID
				end
			end
		end
	end

	--HOW THIS WORK:
	--*loopA for all idle CBA unit,
	--	*loopB for all idle CBA unit,
	--		*for each idle CBA unit: find nearest job (forA)
	--			>check nearest job for assisting other working constructor
	--			>check nearest job for building-stuff that not yet done by any working constructor
	--			>check whether assisting or construction is nearest
	--		*forA return nearest job for each idle CBA unit
	--	*loopB return all nearest jobs for all idle CBA units
	--	>check how many constructor has job order
	--	>check which constructor is most nearest to its job
	--	>register that constructor as working constructor
	--*loopA return command to be given to that constructor
	-->send all command to all CBA units.
	CleanOrders()	-- check build site(s) for blockage (also remove the build queue if construction have started).
	local orderArray={}
	local unitArray={}
	for i=1,numberOfIdle do
		local nearestOrders = {}
		for i=1,numberOfIdle do
			--[[
			local cmd1 = GetFirstCommand(unitID)
			if ( cmd1 == nil ) then		-- no orders?  Must be idle.
				myUnits[unitID] = "idle"
			--]]
			local unitID = idle_myUnits[i] --if unit is marked as idle, then use it.
			if (not idle_assigned[unitID] ) then --unit not yet assigned in previous iteration? find work
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
		local assignUnitID = close[1]
		if not EnemyAtBuildSiteCleanOrder(assignUnitID,close[3],close[5]) then --skip this job? is too dangerous?
			unitArray[#unitArray+1]= assignUnitID
			orderArray[#orderArray+1]={close[2], close[3], { "" }}
			if ( close[5] == 0 ) then --if GUARD command: then,
				myUnits[assignUnitID] = "asst "..unpack(close[3])	--  unitID we're assisting
				--Echo(close[3])
			else --if regular assisting: then,
				myUnits[assignUnitID] = close[5]	--  hash of command we're executing
				--Echo(close[5])
			end
			idle_assigned[assignUnitID] = true
		end
	end
	if #orderArray > 0 then --we should not give empty command else it will delete all unit's existing queue
		Spring.GiveOrderArrayToUnitArray (unitArray,orderArray, true) --send command to bulk of constructor
	end
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

--  Remove duplicate orders, process cancel requests, delete bad builds.

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
		if x_newCmd then
			if newCmd.h == 0 or newCmd.h == 2 then --get building facing. Reference: unit_prevent_lab_hax.lua by googlefrog
				xSize = UnitDefs[newCmdID].xsize*4
				zSize = UnitDefs[newCmdID].zsize*4
			else
				xSize = UnitDefs[newCmdID].zsize*4
				zSize = UnitDefs[newCmdID].xsize*4
			end
		end
	end
	for key,myCmd in pairs(myQueue) do
		local cmdID = abs( myCmd.id )
		local x, y, z, facing = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local canBuildThisThere,featureID = spTestBuildOrder(cmdID,x,y,z,facing) --check if build site is blocked by buildings & terrain
		
		if (canBuildThisThere == 1) or (newCmd and xSize and canBuildThisThere > 0) then --if unit blocking OR new build site was added
			if facing == 0 or facing == 2 then --check the size of the queued building
				xSize_queue = UnitDefs[cmdID].xsize*4
				zSize_queue = UnitDefs[cmdID].zsize*4
			else
				xSize_queue = UnitDefs[cmdID].zsize*4
				zSize_queue = UnitDefs[cmdID].xsize*4
			end	
		end
		
		if newCmd and xSize and (canBuildThisThere > 0) then --check if build site overlap new queue
			local minTolerance = xSize_queue + xSize --check minimum tolerance in x direction
			local axisDist = abs (x - x_newCmd) --check actual separation in x direction
			if axisDist < minTolerance then --if too close in x direction
				minTolerance = zSize_queue + zSize --check minimum tolerance in z direction
				axisDist = abs (z - z_newCmd) -- check actual separation in z direction
				if axisDist < minTolerance then --if too close in z direction
					canBuildThisThere = 0 --flag this queue for removal
					isOverlap = true --return true
					
					-- stop any constructor constructing this queue
					local unitArray = {}
					for unitID, queueKey in pairs(myUnits) do
						if queueKey == key then
							unitArray[#unitArray+1] = unitID
						end
					end
					Spring.GiveOrderToUnitArray (unitArray,CMD_STOP, {}, {}) --send STOP to units assigned to this queue. A scenario: user deleted this queue by overlapping old queue with new queue and it automatically stop any unit trying to build this queue
				end
			end
		end
		
		if ( canBuildThisThere==1 ) then --check if blocking unit can move away from our build site
			local blockingUnits = spGetUnitsInRectangle(x-xSize_queue, z-zSize_queue, x+xSize_queue, z+zSize_queue)
			for i=1, #blockingUnits do
				local blockerDefID = spGetUnitDefID(blockingUnits[i])
				if math.modf(UnitDefs[blockerDefID].speed*10) == 0 then -- ie: modf(0.01*10) == 00 (fractional speed is ignored)
					canBuildThisThere = 0 --blocking unit can't move away, cancel this queue
					break;
				end
			end
		end	
		
		--prevent build queue on ally feature
		if ( checkFeatures ) and ( featureID ) then --check if build site is blocked by feature
			if ( spGetFeatureTeam(featureID) == spGetMyTeamID() ) then --if feature belong to team, then don't reclaim or build there. (ie: dragon-teeth's wall)
				canBuildThisThere = 0
			end
		end
		--end feature check
		
		if (canBuildThisThere == 0) then --if queue is flagged for removal
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
		if ( busyUnitID ~= unitID ) then --if not observing ourself
			local cmd1 = GetFirstCommand(busyUnitID)
			local myCmd = myQueue[busyCmd1]
			if ( myCmd ) then --when busy unit has CentralBuild command (is using SHIFT)
				local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
				if ( cmd  and cmd < 0 ) then
					local x2, y2, z2 = spGetUnitPosition( busyUnitID)	-- location of busy unit
					local numOfAssistant = 0.0
					for assistantUnitID,assistantCmd1 in pairs(myUnits) do --find how many unit is assisting this busy unit
						if ( busyUnitID ~= assistantUnitID ) then --if busyUnit not observing itself
							local prefix = assistantCmd1:sub(1,4)
							if prefix ~= "asst" then
								if (assistantCmd1 == busyCmd1) then
									numOfAssistant = numOfAssistant + 0.11
								end
							else
								-- assistantCmd1:sub(1,5) == "asst "
								local assisting = tonumber(assistantCmd1:sub(6))
								if (assisting == busyUnitID) then
									numOfAssistant = numOfAssistant + 0.11
								end
							end
						end
					end
					local dist = ( Distance(ux,uz,x,z) + Distance(ux,uz,x2,z2) + Distance(x,z,x2,z2) ) / 2 --distance btwn busy unit & self,and btwn structure & self, and btwn structure & busy unit. A distance that is no less than btwn structure & busy unit but is 1.5 when opposite to the structure & the busy unit OR when is further away than btwn structure & busy unit
					local notaccessible = myQueueUnreachable[unitID] and myQueueUnreachable[unitID][busyCmd1] or 0 --check if I can reach this location
					dist = dist + notaccessible*4500 --increase perceived distance arbitrarity if cannot reach
					--local dist = Distance(ux,uz,x,z) --distance btwn structure & self
					dist = dist + dist*numOfAssistant --make the distance look further away than it actually is if there's too many assistance
					if ( dist < busyDist ) then
						busyClosestID = busyUnitID	-- busy unit who needs help
						busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
					end
				end
			elseif ( cmd1 and cmd1.id < 0) then --when busy unit is currently building a structure, is "busy" and not using SHIFT
				local x2, y2, z2 = spGetUnitPosition(busyUnitID)	-- location of busy unit
				--local x, z = cmd1.params[1], cmd1.params[3]
				local numOfAssistant = 0.0
				for assistantUnitID,assistantCmd1 in pairs(myUnits) do --find how many unit is assisting this busy unit
					if ( busyUnitID ~= assistantUnitID ) then --if busyUnit not observing itself
						local prefix = assistantCmd1:sub(1,4)
						if prefix ~= "asst" then
							local cmd2 = GetFirstCommand(assistantUnitID) --check using unit's command queue when we dont have its command stored
							if (cmd2 and (cmd2 == cmd1)) then
								numOfAssistant = numOfAssistant + 0.11
							end
						else
							-- assistantCmd1:sub(1,5) == "asst "
							local assisting = tonumber(assistantCmd1:sub(6))
							if (assisting == busyUnitID) then
								numOfAssistant = numOfAssistant + 0.11
							end
						end
					end
				end
				local dist = Distance(ux,uz,x2,z2) * 1.5 --distance between busy unit & self
				local notaccessible = myQueueUnreachable[unitID] and myQueueUnreachable[unitID][busyCmd1] or 0 --check if I can reach this location
				dist = dist + notaccessible*4500 --increase perceived distance arbitrarity if cannot reach
				--local dist = Distance(ux,uz,x,z) --distance btwn structure & self
				dist = dist + dist*numOfAssistant
				if ( dist < busyDist ) then
					busyClosestID = busyUnitID	-- busy unit who needs help
					busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
				end
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
			local dist = Distance(ux,uz,x,z) --distance btwn current unit & project to be started
			local notaccessible = myQueueUnreachable[unitID] and myQueueUnreachable[unitID][index] or 0 --check if I can reach this location
			dist = dist + notaccessible*4500 --increase perceived distance arbitrarity if cannot reach
			if ( dist < queueDist and canBuild ) then
				queueClose = index	-- # of the project we'll be starting
				queueDist = dist
			end	
		end
		
	end
	
	-- removed canHover tag since it's deprecated
	-- also, @special handling: why?
	if ( busyDist < huge or queueDist < huge ) then --there is work nearby
		local udid = spGetUnitDefID(unitID)
		local ud = UnitDefs[udid]
		if ( busyDist < queueDist ) then	-- assist is closer
			if ( ud.canFly ) then busyDist = busyDist * 0.50 end
			--if ( ud.canHover ) then busyDist = busyDist * 0.75 end
			local theCmd = myUnits[busyClosestID]
			local myCmd = myQueue[theCmd] --get orders stored in CBA's queue
			local canBuild = false	-- this flag determine if unit can assist by copying order instead of GUARD.
			if myCmd then
				local acmd = abs(myCmd.id)
				for _, options in ipairs(ud.buildOptions) do --check buildoptions for buildable
					if ( options == acmd ) then canBuild = true break end	-- if found, escape loop and mark as "canBuild=true".
				end
			end
			if canBuild then --if myCmd is not empty and unit can build that building: use the same build queue from myCmd (CBA's queue)
				return { unitID, myCmd.id, { myCmd.x, myCmd.y, myCmd.z, myCmd.h }, busyDist, theCmd } --assist the busy unit by copying order.
			else
				local cmd1 = GetFirstCommand(busyClosestID) --get orders stored in unit's queue
				if cmd1 then
					local acmd = abs(cmd1.id)
					for _, options in ipairs(ud.buildOptions) do
						if ( options == acmd ) then canBuild = true break end	-- if found, escape loop and mark as "canBuild=true".
					end
				end
				if canBuild then --see if unit can use the same exact queue from the unit to be assisted
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
		myQueueUnreachable[unitID] = nil --clear unit's accessibility list
	end
		
end

--	Prevent CBAI from canceling orders that just haven't made it to host yet
--	because of high ping. Donated by SkyStar.

function ping()
	local playerID = spGetLocalPlayerID()
	local tname, _, tspec, tteam, tallyteam, tping, tcpu = spGetPlayerInfo(playerID)  
	tping = (tping*1000-((tping*1000)%1)) /100 * 4
	return max( tping, 15 ) --wait minimum 0.5 sec delay
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
				if (ud.isBuilder and ud.canMove) then
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

--------------Additional Functions---------------------------
-- The following functions is grouped here for easy debugging
-- It add behaviour like path checking and enemy checks
-------------------------------------------------------------

-- This function check all build site whether it is accessible to all constructor OR blocked by enemy. Reference: http://springrts.com/phpbb/viewtopic.php?t&t=22953&start=2
-- NOTE: path check only work for Spring's Standard pathing because Spring.RequestPath() always return nil for qtpfs as in Spring 93.2.1+

function UpdateUnitsPathability()
	for unitID, _ in pairs(myUnits) do
		myQueueUnreachable[unitID] = {} --CLEAN. note: unitID entry is also cleared when unit die or exit CBA group
		UpdateOneUnitPathability(unitID)
	end
end

-- This function check ALL build site whether it is accessible to 1 constructor. Reference: http://springrts.com/phpbb/viewtopic.php?t&t=22953&start=2
function UpdateOneUnitPathability(unitID)
	local udid = spGetUnitDefID(unitID)
	local moveID = UnitDefs[udid].moveDef.id
	local ux, uy, uz = spGetUnitPosition(unitID)	-- unit location
	--check for build site in queue list
	for queueKey, location in pairs(myQueue) do 
		local x, y, z = location.x, location.y, location.z
		SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,queueKey) 
	end
	--check for build site NOT in queue list (such as order given without SHIFT)
	for unitID2, queueKey in pairs(myUnits) do
		if not myQueue[queueKey] and queueKey~='idle' and queueKey~='busy' then
			local cmd1 = GetFirstCommand(unitID2) --get orders stored in unit2's queue
			if cmd1 and cmd1.params[3] then
				local x, y, z = cmd1.params[1],cmd1.params[2],cmd1.params[3]
				SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,queueKey) 
			end
		end
	end
	--send STOP to units en-route to build site surrounded by enemy
	local unitArray = {}
	for unitID2, queueKey in pairs(myUnits) do
		local enemy = myQueueUnreachable[unitID2][queueKey]==1
		if enemy and myQueue[queueKey] then --was checked to contain enemy, and is a queue (not build assist or build order without SHIFT)
			unitArray[#unitArray+1] = unitID2
		end
	end
	Spring.GiveOrderToUnitArray (unitArray,CMD_STOP, {}, {}) --send stop
end

-- This function check 1 build site whether it is accessible to ALL constructor. Reference: http://springrts.com/phpbb/viewtopic.php?t&t=22953&start=2
function UpdateUnitsPathabilityForOneQueue(queueKey,customCoord)
	local location = myQueue[queueKey]
	customCoord = customCoord or {x=location.x,y=location.y,z=location.z}
	local x, y, z = customCoord.x, customCoord.y, customCoord.z --use provided coordinate or use from coordinate from myQueue
	for unitID, _ in pairs(myUnits) do
		local udid = spGetUnitDefID(unitID)
		local moveID = UnitDefs[udid].moveDef.id
		local ux, uy, uz = spGetUnitPosition(unitID)	-- unit location
		SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,queueKey)
	end
end

--This function determine what to fill into the "myQueueUnreachable" table based on input
function SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,queueKey)
	local reach = true --Note: first assume unit is flying and/or target always reachable
	if moveID then --Note: crane/air-constructor do not have moveID!
		local result,finCoord = IsTargetReachable(moveID, ux,uy,uz,x,y,z,128)
		if result == "outofreach" then --if result not reachable but we have the closest coordinate, then:
			result = IsTargetReachable(moveID, finCoord[1],finCoord[2],finCoord[3],x,y,z,8) --refine pathing
			if result ~= "reach" then --if result still not reach, then:
				reach = false --target is unreachable
			end
		else -- Spring.PathRequest() must be non-functional. (unsynced blocked?)
		end
		--Technical note: Spring.PathRequest() will return NIL(noreturn) if either origin is too close to target or when pathing is not functional (this is valid for Spring91, may change in different version)
	end
	if not reach then
		myQueueUnreachable[unitID][queueKey]=2
	elseif EnemyControlBuildSite({x,y,z}) then
		myQueueUnreachable[unitID][queueKey]=1
	else
		myQueueUnreachable[unitID][queueKey]=0
	end
end

--This function process result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable (moveID, ox,oy,oz,tx,ty,tz,radius)
	local returnValue1,returnValue2
	local path = Spring.RequestPath( moveID,ox,oy,oz,tx,ty,tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= radius+10 then --is within radius?
				returnValue1 = "reach"
				returnValue2 = finalCoord
			else
				returnValue1 = "outofreach"
				returnValue2 = finalCoord
			end
		end
	else
		returnValue1 = "noreturn"
		returnValue2 = nil
	end
	return returnValue1,returnValue2
	
	--[[ --step-by-step detailed path check: WARNING!: lag prone if path too long and unreachable.
	local dx,dy,dz = x-ux, y-uy, z-uz
	local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
	local exageratedYetReasonableDistance = math.sqrt(distance*distance+distance*distance)
	local walkedDistance = 0
	local nx,ny,nz = ux, uy, uz
	while (not ( walkedDistance>=exageratedYetReasonableDistance or reach )) do
		local nx1,ny1,nz1 = path:Next(nx,ny,nz)
		dx,dy,dz = abs(nx1-nx),abs(ny1-ny),abs(nz1-nz)
		walkedDistance =walkedDistance + dx + dy + dz --Note: is rough estimate,not accurate because not calculate hypotenus
		if nx1 and ny1 and nz1 then
			if abs(nx1-x) <200 and abs(ny1-y)<200 and abs(nz1-z)<200 then
				reach = true
			end
		end
		nx,ny,nz = nx1,ny1,nz1
	end
	--]]	
end


-- Helper function (detect enemy at build site)
function EnemyControlBuildSite(order)
	local coordString = order[1].." " .. order[3]
	if cachedValue[coordString] and cachedValue[coordString].frame == currentFrame then
		return cachedValue[coordString].enemy
	end
	
	local unitList = spGetUnitsInCylinder(order[1], order[3], enemyRange)
	local enemyCount = 0
	local totalCount = #unitList
	local returnValue = false
	for i=1, totalCount do
		local unitID = unitList[i]
		local unitAlly = spGetUnitAllyTeam(unitID)
		if unitAlly~=myAllyID then
			enemyCount = enemyCount + 1
		end
	end
	if enemyCount/totalCount > enemyThreshold then
		returnValue = true
	end
	
	cachedValue[coordString] = cachedValue[coordString] or {}
	cachedValue[coordString].enemy = returnValue
	cachedValue[coordString].frame = currentFrame
	return returnValue
end

--  Detect if enemy is present at build site, and cancel queue if there is.
--  this make sure constructor don't suicide into enemy if unattended.
 
function EnemyAtBuildSiteCleanOrder(unitID, order, queueKey)
	if queueKey ~= 0 then --can't handle GUARD assist yet if queueKey==0
		local enemyPresent = myQueueUnreachable[unitID] and myQueueUnreachable[unitID][queueKey]==1
		if enemyPresent or EnemyControlBuildSite(order) then
			if myQueue[queueKey] then				
				local unitArray = {}
				for unitID2, queueKey2 in pairs(myUnits) do
					if queueKey2 == queueKey then
						unitArray[#unitArray+1] = unitID2
					end
				end
				Spring.GiveOrderToUnitArray (unitArray,CMD_STOP, {}, {}) --send STOP to all units already assigned to this queue. A scenario: a newly built constructor decide to assist another old constructor (which is en-route toward an enemy infested build site), this stop the old constructor
				myQueue[queueKey] = nil  --remove queue
				return true --cancel order assignment
			else --can't handle build-assist without queue yet (myQueue[queueKey] == nil). A scenario: user directly order a build without SHIFT
				return nil
			end
		end
	end
	return nil
end