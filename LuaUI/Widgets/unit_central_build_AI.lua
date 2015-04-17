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
--              CAUTION! CAUTION! CAUTION!
-- Please avoid accidental removal of desireable behaviour! so 
-- only regular user of CBAI should make changes/clean-up.
-- (due to undocumented use-case & apparent complexity of this widget)


local version = "v1.359"
function widget:GetInfo()
  return {
    name      = "Central Build AI",
    desc      = version.. " Common non-hierarchical permanent build queue\n\nInstruction: add constructor(s) to group 0 "..
"(\255\200\200\200Ctrl+0\255\255\255\255, or \255\200\200\200Alt+0\255\255\255\255 if using \255\90\255\90Auto Group\255\255\255\255 widget), "..
"then give any of them a build queue. As a result: the whole group (group 0) will see the same build queue and they will distribute work automatically among them. Type \255\255\90\90/cba\255\255\255\255 to forcefully delete all stored queue",
    author    = "Troy H. Cheek, modified by xponen",
    date      = "July 20, 2009, 8 March 2014",
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

-- optional ToDo:
-- _ orders with shift+ctrl have higher priority ( insert in queue -> cons won't interrupt their current actions)

---- CHANGELOG -----
-- xponen			v1.360	(17Apr2015)	:	improve reassignment and enemy avoidance. Thanks to aeonios (mtroyka) for feedback.

-- msafwan(xponen)	v1.355	(26Jan2015)	:	1) all builder re-assign job every 4 second (even if already assigned a job)
--											2) keep queue for unfinished building
--											3) lower priority (and/or removal) for queue at enemy infested area
--
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
-------------CONFIG--------------------
-------------------------------------------
local myGroupId = 0	--//Constant: a group number (0 to 9) will be controlled by Central Build AI. NOTE: put "-1" to use a custom group instead (use the hotkey to add units;ie: ctrl+hotkey).
local hotkey = string.byte( "g" )	--//Constant: a custom hotkey to add unit to custom group. NOTE: set myGroupId to "-1" to use this hotkey.
local checkFeatures = false --//Constant: if true, Central Build will reject any build queue on top of allied features (eg: ally's wreck & dragon teeth).
-------------Speedup--------------------
-------------------------------------------
local Echo					= Spring.Echo
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetGroupList		= Spring.GetGroupList
local spGetGroupUnits		= Spring.GetGroupUnits
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spIsUnitInView 		= Spring.IsUnitInView
local spIsAABBInView		= Spring.IsAABBInView
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetCommandQueue    	= Spring.GetCommandQueue
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
local spValidUnitID = Spring.ValidUnitID

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
local modf = math.modf
local pow = math.pow

local currentFrame = Spring.GetGameFrame()
local nextFrame	= currentFrame +30
local nextPathCheck = currentFrame + 400 --is used to check whether constructor can go to construction site
local myAllyID = Spring.GetMyAllyTeamID()
local textColor = {0.7, 1.0, 0.7, 1.0}
local textSize = 12.0
local enemyRange = 600 --range (in elmo) around build site to check for enemy
local enemyThreshold = 0.49--fraction of enemy around build site w.r.t. ally unit for it to be marked as unsafe
local dangerThreshold = 3 --amount of constructor death that force the build site to be removed if constructor had no other job to do

--	"global" for this widget.  This is probably not a recommended practice.
local myUnits = {}	--  list of units in the Central Build group
local myQueue = {}  --  list of commands for Central Build group
local groupHasChanged	--	Flag if group members have changed.

local myQueueUnreachable = {} -- list of queue which units can't reach
local myQueueDanger = {} --list of queue which lead to dead constructors

local reassignedUnits = {} --list of units that had its task re-checked (to be re-tasked or remained with current task).
-----------Speedup2--------------------
----------optimization------------------
local cachedValue = {} --cached results for "EnemyControlBuildSite()" function to reduce cost for repeated call
local cachedMetalCost = {} --cached metalcost for "GetWorkFor()" function
local cachedCommand = {} --cached first command for "GetWorkFor{}" function
local cachedProgress = {} --cached build progress for "GetWorkFor()" function 

--------------------------------------------
--List of prefix used as value for myUnits[]
local queueType = {
	buildNew = 'drec', --appended with: cmdId .. "@" .. x .. "x" .. z. Indicate direct build command of a structure
	buildQueue = 'queu',--appended with: cmdId .. "@" .. x .. "x" .. z. Indicate unit have task. Its also a Key to myQueue[], if no longer a Key to myQueue[] then it meant the construction has already begun  
	--
	assistBuild = 'help', --appended with: queueType.buildQueue or queueType.buildNew (see GetWorkFor() for detail). Indicate an assist without GUARD command
	assistGuard = 'gard', --appended with: queueType.buildQueue or queueType.buildNew . Indicate assist using GUARD command
	--
	idle = 'idle',
	busy = 'busy', --indicate user command
}
--List of value used for myQueueUnreachable[]
local blockageType = {
	blocked = 1,
	clear = 0,
}
--List of type of work, used in GetWorkFor() & GiveWorkToUnits()
local assistType = {
	none = 0,
	guard = 1,
	copy = 2,
	copyExternal = 3,
}
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
			glText(myCmd:sub(1,4), -10.0, -15.0, textSize, "con")
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
			glUnitShape( cmd, spGetMyTeamID() )
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
		DecayDangerousQueue()
		AddDangerousQueue()
		StopDangerousQueue()
		
		nextPathCheck = thisFrame + 300 --10 second
	end
	if ( thisFrame < nextFrame ) then 
		return
	end
	if ( groupHasChanged == true ) then 
		UpdateOneGroupsDetails(myGroupId)
	end
	nextFrame = thisFrame + 60	-- try again in 2 second if nothing else triggers
	FindEligibleWorker()	-- compile list of eligible idle units for work
end

--	This function detects that a new group has been defined or changed.  Use it to set a flag
--	because it fires before all units it's going to put into group have actually been put in.
--  Borrowed from gunblob's UnitGroups v5.1

function widget:GroupChanged(groupId)  
	if groupId == myGroupId then
--		local units = spGetGroupUnits(myGroupId)
--		Echo( Spring.GetGameFrame() .. " Change detected in group." )
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
				myUnits[unitID] = queueType.idle
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
	
	local clearOldDirectCmd = false
	local newDirectCmdHash = nil
	
	local selectedUnits = spGetSelectedUnits()
	for _, unitID in pairs(selectedUnits) do	-- check selected units...
		if ( myUnits[unitID] ) then	--  was issued to one of our units.
			if ( options.shift ) then -- used shift for:.
				if ( id < 0 ) then --for: building
					local x, y, z, h = params[1], params[2], params[3], params[4]
					local myCmd = { id=id, x=x, y=y, z=z, h=h }
					local isOverlap = CleanOrders(myCmd) -- check if current queue overlap with existing queue, and clear up any invalid queue 
					if not isOverlap then
						local hash = queueType.buildQueue .. BuildHash(myCmd)
						myQueue[hash] = myCmd	-- add to CB queue
						UpdateUnitsPathabilityForOneQueue(hash,myCmd) --take note of build site reachability
					end
					nextFrame = currentFrame + 30 --wait 1 more second before distribute work, so user can queue more stuff
					return true	-- have to return true or Spring still handles command itself.
				else --for: moving/attacking/repairing, ect
					if myUnits[unitID] == queueType.idle then --unit is not doing anything
						myUnits[unitID] = queueType.busy --is doing irrelevant thing
					end
					-- do NOT return here because there may be more units.  Let Spring handle.
				end
			else
				--This is direct command. Is handled by engine. Note: we don't handle any unit performing direct command, but we record the commands for the benefit 
				--of Central Builder's assist mechanic
				
				if not clearOldDirectCmd then
					local oldHash = myUnits[unitID]
					if myQueue[oldHash] then
						if oldHash:sub(1,4) == queueType.buildNew then
							StopAnyAssistant(oldHash)
							myQueue[oldHash] = nil 
						else
							StopAnyAssistant(oldHash,true)
						end
						clearOldDirectCmd = true
					end
				end
				
				if ( id < 0 ) and (not isAreaMex ) then --is building stuff & is direct command/not an area mex command
					if not newDirectCmdHash then
						local x, y, z, h = params[1], params[2], params[3], params[4]
						local myCmd = { id=id, x=x, y=y, z=z, h=h }
						newDirectCmdHash = queueType.buildNew .. BuildHash(myCmd)
						myQueue[newDirectCmdHash] = myCmd
						UpdateUnitsPathabilityForOneQueue(newDirectCmdHash,myCmd) --take note of build site reachability
					end
					myUnits[unitID] = newDirectCmdHash
				else
					myUnits[unitID] = queueType.busy	-- direct command of something else.
				end
				-- do NOT return here because there may be more units.  Let Spring handle.
			end
		end
	end
end

--If one of our units finished a build order, cancel units guarding/assisting it.
--This replace UnitCmdDone() because UnitCmdDone() is called even if command is not finished, such as when new command is inserted into existing queue
--Credit to Niobium for pointing out UnitCmdDone() originally.

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	ConstructionFinishedEvent(unitID,unitDefID)
	nextFrame = currentFrame + ping() --find new work
end

--	If unit detected as idle (probably finished work) and it's one of ours, time to find it some work.

function widget:UnitIdle(unitID, unitDefID, teamID)
	if ( myUnits[unitID] ) then
		StopAnyAssistant(myUnits[unitID])
		myUnits[unitID] = queueType.idle
		nextFrame = currentFrame + ping() --find new work
	end
end

--select 10 worker from a pool of idle constructor or reuse some of the non-idle constructor as new worker

function FindEligibleWorker()
	--Fix conflict with other widgets--
	--gui_lasso_terraform.lua --
	for unitID,myCmd in pairs(myUnits) do --check if busy unit actually have recognizable command. This could happen if unit was doing other stuff then is programmatically queued to build stuff (eg: gui_lasso_terraform.lua added terraform then reissue build order).
		if myCmd == queueType.busy then
			local cmd1 = GetFirstCommand(unitID,true)
			if ( cmd1 and cmd1.id and cmd1.id<0) then
				--record build site so that other CBA units can help
				local x, y, z, h = cmd1.params[1], cmd1.params[2], cmd1.params[3], cmd1.params[4]
				local myCmd = { id=cmd1.id, x=x, y=y, z=z, h=h }
				local newDirectCmdHash = queueType.buildNew .. BuildHash(myCmd)
				myQueue[newDirectCmdHash] = myCmd
				UpdateUnitsPathabilityForOneQueue(newDirectCmdHash,myCmd) --take note of build site reachability
				myUnits[unitID] = newDirectCmdHash
			end
		end
	end
	--cmd_mex_placement.lua --
	for unitID,myCmd in pairs(myUnits) do --check if unit really idle or is actually busy, because UnitIdle() can be triggered by other widget and is overriden with new command afterward, thus making unit look idle but is busy (ie: cmd_mex_placement.lua, area mex widget)
		if myCmd == queueType.idle then --if unit is marked as idle, then double check it
			local cmd1 = GetFirstCommand(unitID,true)
			if ( cmd1 and cmd1.id) then
				-- if ( cmd1.id < 0 ) then --is build (any) stuff
					-- if ( cmd1.params[3] ) then --is not build unit command (build unit command has NIL parameter (because its only for factory))
						-- local unitCmd = {id=cmd1.id,x=cmd1.params[1],y=cmd1.params[2],z=cmd1.params[3],h=cmd1.params[4]}
						-- local hash = BuildHash(unitCmd)
						-- myUnits[unitID] = hash
					-- end
				-- else
				myUnits[unitID] = queueType.busy
				-- end
			end
		end
	end
	--Collect idle worker for work--
	local unitToWork = {}
	for unitID,myCmd in pairs(myUnits) do
		if myCmd == queueType.idle then
				if #unitToWork < 10 then
					--NOTE: only allow up to 10 idler to be processed to prevent super lag.
					--The amount of external loop will be (numberOfmyunit^2+numberOfQueue)*numberOfIdle^2.
					--ie: if all variable were 50, then the amount of loop in total is 6375000 loop (6 million).
					unitToWork[#unitToWork+1] = unitID
				else
					break;
				end
			end
	end
	--Collect busy worker for reassignment--
	if #unitToWork < 10 then
		local gaveWork = false
		local matchAssistOrBuildQueueType = {queueType.buildQueue,queueType.assistBuild,queueType.assistGuard}
		for unitID,myCmd in pairs(myUnits) do
			if (not reassignedUnits[unitID]) then
				local workType = myCmd:sub(1,4)
				if MatchAny(workType,matchAssistOrBuildQueueType) then
					unitToWork[#unitToWork+1] = unitID
					gaveWork = true
					reassignedUnits[unitID] = true --skip reassign in next loop
					if (#unitToWork == 10) then
						break
					end
				end
			end
		end
		if not gaveWork then --no more unit to be reassigned? then reset list 
			reassignedUnits = {}
		end
	end

	CleanOrders()	-- check build site(s) for blockage (also remove the build queue if construction have started).

	if (#unitToWork > 0) then
		GiveWorkToUnits(unitToWork)
		--clear cached item for next loop--
		cachedMetalCost = {}
		cachedProgress = {}
	end
	cachedCommand = {}
end

--  One at a time, assign builders new tasks.

function GiveWorkToUnits(unitToWork)
	--HOW THIS WORK:
	--*loopA, for all Workers, task: collect commands,
	--	*loopB, for idle Workers, task: get all work for all Workers,
	--		(In GetWorkFor)
	--			*loopC, for CBA Queue, task: find nearest job for one Worker,
	--				>check whether job for assist or building-new-stuff is nearest
	--			*endC (return: nearest job for one Worker)
	--		(Exit GetWorkFor)
	--		>collect works
	--	*endB (return: all works)
	--	>find which Worker is nearest to its job, remove from idle pool, and translate it into command
	--	>collect commands
	--*endA (return: all commands)
	-->send commands to Workers.

	local orderArray={}
	local unitArray={}
	local assignedAJob = {}
	for i=1,#unitToWork do
		local nearestOrders = {}
		for i=1,#unitToWork do
			--[[
			local cmd1 = GetFirstCommand(unitID,true)
			if ( cmd1 == nil ) then		-- no orders?  Must be idle.
				myUnits[unitID] = queueType.idle
			--]]
			local unitID = unitToWork[i] --if unit is marked as idle, then use it.
			if (not assignedAJob[unitID] ) then --unit not yet assigned in previous iteration? find work
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
		if close[6] == assistType.guard or not EnemyAtBuildSiteCleanOrder(assignUnitID,close[3],close[5]) then --skip this job? is too dangerous?
			local myQueueHash
			if ( close[6] == assistType.guard ) then --if GUARD command,
				myQueueHash = queueType.assistGuard .. close[5] --hash from unitID we're assisting --unpack(close[3])	--  unitID we're assisting
			elseif ( close[6] == assistType.copy ) then --if build assist without GUARD command,
				myQueueHash = queueType.assistBuild .. close[5] --hash from unitID we're assisting
			-- elseif ( close[6] == assistType.copyExternal ) then --assist of build no longer in myQueue[] (either under construction or is from manual order)
				-- myQueueHash = queueType.assistBuild .. assistType.copyExternal
			else --if new build,
				myQueueHash = close[5]	--  hash of command we're executing
			end
			if ( myUnits[assignUnitID] ~= myQueueHash ) then --a new command
				unitArray[#unitArray+1]= assignUnitID
				orderArray[#orderArray+1]={close[2], close[3], { "" }}
				myUnits[assignUnitID] = myQueueHash
			end
			assignedAJob[assignUnitID] = true
		end
	end
	if #orderArray > 0 then --we should not give empty command else it will delete all unit's existing queue
		Spring.GiveOrderArrayToUnitArray (unitArray,orderArray, true) --send command to bulk of constructor
	end
	unitArray = nil
	orderArray = nil
	assignedAJob = nil
	--nextFrame = currentFrame + ping()
end

--	Borrowed distance calculation from Google Frog's Area Mex

local function Distance(x1,z1,x2,z2)
  local dis = sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
end

--	Borrowed this from CarRepairer's Retreat.  Returns only first command in queue.

function GetFirstCommand(unitID, useCache)
	if (useCache) then
		if (not cachedCommand[unitID]) then
			local value = spGetCommandQueue(unitID, 1)
			cachedCommand[unitID] = value and value[1]
		end
		return cachedCommand[unitID]
	end

	local queue = spGetCommandQueue(unitID, 1)
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
	
	local blockageType = {
		obstructed = 0, --also applies to blocked by another structure
		mobiles = 1,
		free = 2,
	}

	for key,myCmd in pairs(myQueue) do
		local cmdID = abs( myCmd.id )
		local x, y, z, facing = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local blockage,featureID = spTestBuildOrder(cmdID,x,y,z,facing) --check if build site is blocked by buildings & terrain

		local newFree = (newCmd and xSize and blockage ~= blockageType.obstructed)
		local blocked = (blockage ~= blockageType.free)
		
		if (newCmd and xSize) or blocked then --is processing new command or blockage detected
			if facing == 0 or facing == 2 then --check the size of the queued building
				xSize_queue = UnitDefs[cmdID].xsize*4
				zSize_queue = UnitDefs[cmdID].zsize*4
			else
				xSize_queue = UnitDefs[cmdID].zsize*4
				zSize_queue = UnitDefs[cmdID].xsize*4
			end	
		end
		
		repeat --for emulating "continue", isn't looping

		myQueue[key].isStarted = false 
		if blocked then --unfeasible queue?
			local nonMobile = false
			local stillBuilding = nil
			local blockingUnits = spGetUnitsInRectangle(x-xSize_queue, z-zSize_queue, x+xSize_queue, z+zSize_queue)
			for i=1, #blockingUnits do
				local blockerDefID = spGetUnitDefID(blockingUnits[i])
				if blockerDefID == cmdID then
					local _,_,nanoframe = spGetUnitIsStunned(blockingUnits[i])
					if nanoframe then
						stillBuilding = blockingUnits[i]
					end
					break;
				elseif modf(UnitDefs[blockerDefID].speed*10) == 0 then -- immobile unit is blocking. ie: modf(0.01*10) == 00 (assume fractional speed as immobile)
					nonMobile = true --blocking unit can't move away, cancel this queue
					break;
				end
			end
			if (stillBuilding) then
				myQueue[key].isStarted = true --state it as nanoframe, and keep queue
				myQueue[key].unitID = stillBuilding
				break;
			end
			if blockage == blockageType.obstructed or (blockage == blockageType.mobile and nonMobile) then --terrain or static unit
				myQueue[key] = nil  --remove queue
				break;
			end
		end	

		if newFree then --check if build site overlap new queue
			local minTolerance = xSize_queue + xSize --check minimum tolerance in x direction
			local axisDist = abs (x - x_newCmd) --check actual separation in x direction
			if axisDist < minTolerance then --if too close in x direction
				minTolerance = zSize_queue + zSize --check minimum tolerance in z direction
				axisDist = abs (z - z_newCmd) -- check actual separation in z direction
				if axisDist < minTolerance then --if too close in z direction
					myQueue[key] = nil  --remove queue
					isOverlap = true --return true
					
					StopAnyLeader(key) --send STOP to units assigned to this queue. A scenario: user deleted this queue by overlapping old queue with new queue and it automatically stop any unit trying to build this queue
					StopAnyAssistant(key)
					break;
				end
			end
		end --end overlap check

		if ( checkFeatures ) and ( featureID ) then --build queue on ally feature? check if build site is blocked by feature
			if ( spGetFeatureTeam(featureID) == spGetMyTeamID() ) then --if feature belong to team, then don't reclaim or build there. (ie: dragon-teeth's wall)
				myQueue[key] = nil  --remove queue
				break;
			end
		end	--end feature check

		until true
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

	local matchBuildLeaderOnly = {queueType.buildQueue,queueType.buildNew}
	for busyUnitID,busyCmd1 in pairs(myUnits) do	-- see if any busy units need help.
		local queueType1 = busyCmd1:sub(1,4)
		if ( busyUnitID ~= unitID and MatchAny(queueType1,matchBuildLeaderOnly) ) then --if not observing ourself
			local cmd1 = GetFirstCommand(busyUnitID,true)
			local myCmd = myQueue[busyCmd1]
			if ( myCmd ) then --when busy unit has CentralBuild command (is using SHIFT)
				local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
				if ( cmd  and cmd < 0 ) then
					local dist = Distance(ux,uz,x,z) --distance btwn structure & self
					dist = dist + SituationalPenalty(unitID,busyCmd1) --cost penalty for any danger
					dist = dist + AssistantBenefit(busyUnitID,busyCmd1)
					dist = dist + ProgressBonus(busyCmd1)
					if ( dist < busyDist ) then
						busyClosestID = busyUnitID	-- busy unit who needs help
						busyDist = dist		-- dist to construction site
					end
				end
			-- elseif ( cmd1 and cmd1.id < 0) then --when busy unit is currently building a structure,
				-- local x, z = cmd1.params[1], cmd1.params[3]
				-- local dist = Distance(ux,uz,x,z) --distance btwn structure & self
				-- dist = dist + SituationalPenalty(unitID,busyCmd1) --cost penalty for any danger
				-- dist = dist + AssistantBenefit(busyUnitID,busyCmd1)
				-- if ( dist < busyDist ) then
					-- busyClosestID = busyUnitID	-- busy unit who needs help
					-- busyDist = dist		-- dist to said unit * 1.5 (divided by 2 instead of 3)
				-- end
			end
		end
	end
	
	for index,myCmd in pairs(myQueue) do	-- any new projects to be started?
		if ( index:sub(1,4) == queueType.buildQueue) then
			local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
			local alreadyWorkingOnIt = false	-- is some other unit already assigned this?
			for unit2,cmd2 in pairs(myUnits) do
				if ( unitID ~= unit2 and index == cmd2) then
					alreadyWorkingOnIt = true --a constructor is already on the job
					break
				end
			end
			if ( not alreadyWorkingOnIt ) then
				local udid = spGetUnitDefID(unitID)
				local ud = UnitDefs[udid]
				local dist = Distance(ux,uz,x,z) --distance btwn current unit & project to be started
				dist = dist + SituationalPenalty(unitID,index) --account for any danger
				dist = dist + ProgressBonus(index)
				if ( dist < queueDist and CanBuildThis(cmd, ud) ) then
					queueClose = index	-- # of the project we'll be starting
					queueDist = dist
				end	
			end
		end
	end
	
	--anonymous note 1: removed canHover tag since it's deprecated
	--anonymous note 2: also, @special handling: why?
	if ( busyDist < huge or queueDist < huge ) then --there is work nearby
		local udid = spGetUnitDefID(unitID)
		local ud = UnitDefs[udid]
		if ( busyDist < queueDist ) then	-- assist is closer
			if ( ud.canFly ) then busyDist = busyDist * 0.50 end
			--if ( ud.canHover ) then busyDist = busyDist * 0.75 end
			local theCmd = myUnits[busyClosestID]
			local myCmd = myQueue[theCmd] --get orders stored in CBA's queue
			if (myCmd) then
				if (CanBuildThis(myCmd.id, ud)) then --if myCmd is not empty and unit can build that building: use the same build queue from myCmd (CBA's queue)
					return { unitID, myCmd.id, { myCmd.x, myCmd.y, myCmd.z, myCmd.h }, busyDist, theCmd,assistType.copy} --assist the busy unit by copying order.
				else --simply GUARD the unit to be assisted when copy command failed
					return { unitID, CMD_GUARD, { busyClosestID }, busyDist, theCmd, assistType.guard} --assist the busy unit by GUARDING it.
				end
			-- else
				-- local cmd1 = GetFirstCommand(busyClosestID,true) --get orders stored in unit's queue
				-- if (cmd1 and CanBuildThis(cmd1.id, ud)) then --see if unit can use same queue from the unit to be assisted
					-- return { unitID, cmd1.id, { cmd1.params[1], cmd1.params[2], cmd1.params[3], cmd1.params[4] }, busyDist, nil ,assistType.copyExternal } --assist the busy unit by copying order.
				-- else
					-- return { unitID, CMD_GUARD, { busyClosestID }, busyDist, nil,assistType.guard } --assist the busy unit by GUARDING it.
				-- end
			end
		else	-- new project is closer
			if ( ud.canFly ) then queueDist = queueDist * 0.50 end
			--if ( ud.canHover ) then queueDist = queueDist * 0.75 end
			myCmd = myQueue[queueClose]
			local cmd, x, y, z, h = myCmd.id, myCmd.x, myCmd.y, myCmd.z, myCmd.h
			return { unitID, cmd, { x, y, z, h }, queueDist, queueClose,assistType.none }
		end
	end
end

--return some value to represent the benefit of being assistant to this UnitID
function AssistantBenefit(unitID,cmdHash)
	
	local readMetalCost = function(id) 
		if (not cachedMetalCost[id]) then
			cachedMetalCost[id] = UnitDefs[spGetUnitDefID(id)].metalCost
		end
		return cachedMetalCost[id]
	end
	
	local numOfAssistant = 1
	local totalWorkerCost = readMetalCost(unitID)
	local plusPlusAssistant = function(assistantID)
		numOfAssistant = numOfAssistant + 1
		totalWorkerCost = totalWorkerCost + readMetalCost(assistantID)
	end
	
	local matchOtherTypeOnly = {queueType.idle,queueType.busy}
	local matchAssistOnly = {queueType.assistBuild, queueType.assistGuard}
	for assistantUnitID,assistantCmd1 in pairs(myUnits) do --find how many unit is assisting this busy unit
		if ( unitID ~= assistantUnitID and not MatchAny(assistantCmd1,matchOtherTypeOnly)) then --if not observing ownself
			local prefix = assistantCmd1:sub(1,4)
			if MatchAny(prefix,matchAssistOnly) then
				if (cmdHash == assistantCmd1:sub(5)) then
					plusPlusAssistant(assistantUnitID)
				end
			end
		end
	end
	
	local projectID = -myQueue[cmdHash].id
	local projectCost = UnitDefs[projectID].metalCost
	local fractionOfWorker = ((totalWorkerCost - projectCost)/(totalWorkerCost + projectCost)) + 1 -- zero (0) when no Worker, 1 when adequate, 2 when project is too big
	return -1125*numOfAssistant + 1125*numOfAssistant*fractionOfWorker --lower when add some assistance, bigger when too much assistance
end

--return some value to represent danger
function SituationalPenalty(unitID, myQueueIndex)
	local notaccessible = myQueueUnreachable[unitID] and myQueueUnreachable[unitID][myQueueIndex] or blockageType.clear --check if I can reach this location
	local fatality = myQueueDanger[myQueueIndex] or 0
	local dist = 0
	dist = dist + notaccessible*9000 --increases cost arbitrarily if cannot reach
	dist = dist + fatality*2250 --increases cost arbitrarily if any unit had died trying to execute this command
	return dist --bigger when too much danger
end

--return some value to represent favourism toward build progress
function ProgressBonus( myQueueIndex)
	if not myQueue[myQueueIndex] .isStarted then 
		return 0 
	end
	local unitID = myQueue[myQueueIndex].unitID
	if cachedProgress[unitID] then 
		return cachedProgress[unitID] 
	end
	if not spValidUnitID(unitID) then
		cachedProgress[unitID] = 0
		return 0
	end
	local _,_,_,_,build = spGetUnitHealth(unitID)
	local dist =  max(-500*(pow(build, 6)),-500) --more bonus when building is almost finish. Source of math: "Spring/rts/game/CameraHandler.cpp"
	--shape:
	-- 0%                         100%
	-- /----------------------------> Percent complete
	-- |xxxxxxxxx                     0
	-- |         xxx xx xx
	-- |                 xxxxx
	-- |                      xxx
	-- |                         xx
	-- v                           x  -500
	-- distBonus
	cachedProgress[unitID] = dist
	return dist
end

function CanBuildThis(cmdID, unitDef)
	local acmd = abs(cmdID)
	for _, options in ipairs(unitDef.buildOptions) do
		if ( options == acmd ) then 
			return true 
		end
	end
	return false
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
	UnitGoByeBye(unitID,unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	UnitGoByeBye(unitID,unitDefID)
end

--  If unit in our group is destroyed, captured, dropped from group, cancel any
--  GUARD order from rest of group.

function UnitGoByeBye(unitID,unitDefID)
	if ( myUnits[unitID] ) then
		--dead unit
		local cmdIndex = myUnits[unitID]
		local prefix = cmdIndex:sub(1,4)
		if prefix == queueType.buildNew then --stop assisting leader which execute direct command (non-SHIFT) because by default it disappear when unit died
			if myQueue[cmdIndex] and not myQueue[cmdIndex].isStarted then
				StopAnyAssistant(cmdIndex) --building not yet started and leader died, stop!
			end
			myQueue[cmdIndex] = nil
		end
		
		myUnits[unitID] = nil
		myQueueUnreachable[unitID] = nil --clear unit's accessibility list
		--local assistGuard = queueType.assistGuard .. unitID
		--for unit2,myCmd in pairs(myUnits) do
			--if ( myCmd == assistGuard ) then
				--StopGuardingUnit(unit2) --stop construction when leader dies?
				--myUnits[unit2]= queueType.busy --busy until really idle.
			--end
		--end
	else
		ConstructionFinishedEvent(unitID,unitDefID)
	end
end

-- Convert damage into danger level

function widget:UnitDamaged(unitID, unitDefID, unitTeam,damage, paralyzer)
	if myUnits[unitID] then
		--increase danger level!
		local cmdIndex = myUnits[unitID]
		local prefix = cmdIndex:sub(1,4)
		if MatchAny(prefix,{queueType.assistBuild,queueType.assistGuard}) then
			local hash = cmdIndex:sub(5)
			myQueueDanger[hash] = (myQueueDanger[hash] or 0) + damage/UnitDefs[unitDefID].health
		elseif MatchAny(prefix,{queueType.buildNew,queueType.buildQueue})  then
			myQueueDanger[cmdIndex] = (myQueueDanger[cmdIndex] or 0) + damage/UnitDefs[unitDefID].health
		end
	end
end

-- Remove queue when construction is finished

function ConstructionFinishedEvent(unitID,unitDefID) --unitID & defID of building/unit finished construction
	local ux, _, uz = spGetUnitPosition(unitID)
	local myCmd = { id=-unitDefID, x=ux, z=uz, }
	local hash = BuildHash(myCmd)
	
	local typeQueue = queueType.buildQueue .. hash
	local typeNew = queueType.buildNew .. hash

	local toMatch
	if myQueue[typeQueue] then
		StopAnyAssistant(typeQueue)
		myQueue[typeQueue] = nil
	end
	if myQueue[typeNew] then 
		StopAnyAssistant(typeNew)
		myQueue[typeNew] = nil
	end
	
	--Random Note1: there would be only 1 instance of Shift order in myQueued because collision check in CleanOrders() remove duplicate
	--Random Note2: non-Shift order doesn't have collision check and can have duplicate
	
	--Construction finished, leader must continue for repair or other order, Set them to "busy". (UnitIdle() will be called later if Constructor is really idle)
	for unitID, queueKey in pairs(myUnits) do
		if MatchAny(queueKey,{typeQueue,typeNew}) then
			myUnits[unitID]= queueType.busy --leader is busy until really idle.
		end
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

function BuildHash(myCmd)
	return myCmd.id .. "@" .. myCmd.x .. "x" .. myCmd.z
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
					myUnits[unitID] = queueType.idle
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

--------------Helper Function--------------------------------
-- Some utility function that is not part of original widget,
-------------------------------------------------------------

-- Stop unit's build order in a way that probably respect user's queue

function StopOrder(unitID, targetID)
	spGiveOrderToUnit(unitID, CMD_REMOVE, {targetID}, {"alt"} ) --remove the GUARD command from those units
	spGiveOrderToUnit(unitID, CMD_INSERT, {0,CMD_STOP}, {"alt"} ) --stop current motion
	myUnits[unitID]= queueType.busy --busy until really idle. UnitIdle() will be called later to really 
end

--[[
-- Stop unit's GUARD order in a way that probably respect user's queue

function StopGuardingUnit(unitID)
	local cmd = GetFirstCommand(unitID)
	if ( cmd == nil ) then	-- no orders?  Must be idle.
		myUnits[unitID]= queueType.idle
	else
		if (cmd.id == CMD_GUARD) then
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmd.tag}, {""} ) --remove
		end
		spGiveOrderToUnit(unitID, CMD_INSERT, {0,CMD_STOP}, {"alt"} ) --stop current motion
		myUnits[unitID]= queueType.busy --busy until really idle. UnitIdle() will be called later to really set the idle status.
	end.
end
--]]

function MatchAny(string1, toMatch)
	for i=1,#toMatch do
		if (string1 == toMatch[i]) then
			return string1
		end
	end
	return nil
end

-- Tell any constructor assisting build of "myQueue[queueKey]" to stop immediately

function StopAnyAssistant(queueKey,onlyRemoveGuard)
	if not MatchAny(queueKey:sub(1,4), { queueType.buildNew, queueType.buildQueue}) then --skip Idle or busy or assist
		return
	end
	
	local assistGuard = queueType.assistGuard.. queueKey
	local assistBuild = queueType.assistBuild.. queueKey
	local guardianArray ={}
	local helperArray = {}
	for unit3,myCmd2 in pairs(myUnits) do
		if (not onlyRemoveGuard and myCmd2 == assistBuild) then
			helperArray[#helperArray+1] = unit3
			myUnits[unit3] = queueType.busy
		elseif myCmd2 == assistGuard then  --check if this unit is being GUARDed
			guardianArray[#guardianArray+1] = unit3
			myUnits[unit3] = queueType.busy --busy until really idle. UnitIdle() will be called later to really set the idle status.
		end
	end
	if #helperArray>0 then
		Spring.GiveOrderArrayToUnitArray (helperArray,{{CMD_REMOVE, {myQueue[queueKey].id}, {"alt"}},{CMD_INSERT, {0,CMD_STOP},{"alt"}}})
	end
	if #guardianArray>0 then --remove guard command
		Spring.GiveOrderArrayToUnitArray (guardianArray,{{CMD_REMOVE, {CMD_GUARD}, {"alt"}},{CMD_INSERT, {0,CMD_STOP},{"alt"}}})
	end
end

-- Tell any leader for construction of "myQueue[key]" to stop the job immediately

function StopAnyLeader(key,onlyOne)
	if key:sub(1,4) ~= queueType.buildQueue then --only order with SHIFT order should be stopped
		return
	end

	-- stop any constructor constructing this queue
	local builderArray = {}
	for unitID, queueKey in pairs(myUnits) do
		if queueKey == key then
			builderArray[#builderArray+1] = unitID
			myUnits[unitID]= queueType.busy --busy until really idle.
			if onlyOne then
				break
			end
		end
	end
	if #builderArray>0 then
		Spring.GiveOrderArrayToUnitArray (builderArray,{{CMD_REMOVE, {myQueue[key].id}, {"alt"}},{CMD_INSERT, {0,CMD_STOP},{"alt"}}})
	end
end

--------------Additional Functions---------------------------
-- The following functions is grouped here for easy debugging
-- It add behaviour like path checking and enemy checks
-------------------------------------------------------------

function AddDangerousQueue()
	for queueKey,details in pairs(myQueue) do
		if EnemyControlBuildSite({details.x,0,details.z}) then
			myQueueDanger[queueKey] = max(1,myQueueDanger[queueKey] or 1)
		end
	end
end

function DecayDangerousQueue()
	for key,value in pairs(myQueueDanger) do
		if value >0 then
			myQueueDanger[key] = value -1/12 --decay by 1 every 2 minute
		else
			myQueueDanger[key] = nil --clear
		end
	end
end

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
	-- for unitID2, queueKey in pairs(myUnits) do
		-- if not myQueue[queueKey] and queueKey~=queueType.idle and queueKey~=queueType.busy then
			-- local cmd1 = GetFirstCommand(unitID2) --get orders stored in unit2's queue
			-- if cmd1 and cmd1.params[3] then
				-- local x, y, z = cmd1.params[1],cmd1.params[2],cmd1.params[3]
				-- SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,queueKey) --note: this won't work, because key for Assist type is not unique (a duplicate)
			-- end
		-- end
	-- end
end

-- Stop any construction on queue with dangerous status, but dont remove it yet (is removed later by EnemyAtBuildSiteCleanOrder() when someone tried to use it)

function StopDangerousQueue()
	--send STOP to units en-route to build site surrounded by enemy
	for queueKey,danger in pairs(myQueueDanger) do
		if not myQueue[queueKey] then
			myQueueDanger[queueKey] = nil -- clear
		else
			if danger >= dangerThreshold then
				StopAnyLeader(queueKey)
				StopAnyAssistant(queueKey)
			end
		end
	end
end

-- This function check 1 build site whether it is accessible to ALL constructor. Reference: http://springrts.com/phpbb/viewtopic.php?t&t=22953&start=2
function UpdateUnitsPathabilityForOneQueue(hash,location)
	local x, y, z = location.x, location.y, location.z --
	for unitID, _ in pairs(myUnits) do
		local udid = spGetUnitDefID(unitID)
		local moveID = UnitDefs[udid].moveDef.id
		local ux, uy, uz = spGetUnitPosition(unitID)	-- unit location
		SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,hash)
	end
end

--This function determine what to fill into the "myQueueUnreachable" table (whether a constructor can reach build site or not)
function SetQueueUnreachableValue(unitID,moveID,ux,uy,uz,x,y,z,hash)
	local reach = true --Note: first assume unit is flying and/or target always reachable
	if moveID then --Note: crane/air-constructor do not have moveID!
		local result,finCoord = IsTargetReachable(moveID, ux,uy,uz,x,y,z,128)
		if result == "outofreach" then --if result not reachable but we have the closest coordinate, then:
			reach = false --target is unreachable
		else -- Spring.PathRequest() must be non-functional. (unsynced blocked?)
		end
		--Technical note: Spring.PathRequest() will return NIL(noreturn) if either origin is too close to target or when pathing is not functional (this is valid for Spring91, might change in different version)
	end
	if not reach then
		myQueueUnreachable[unitID][hash]= blockageType.blocked
	else
		myQueueUnreachable[unitID][hash]= blockageType.clear
	end
end

--This function process result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable (moveID, ox,oy,oz,tx,ty,tz,radius)
	local result,lastcoordinate, waypoints
	local path = Spring.RequestPath( moveID,ox,oy,oz,tx,ty,tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= radius+20 then --is within radius?
				result = "reach"
				lastcoordinate = finalCoord
				waypoints = waypoint
			else
				result = "outofreach"
				lastcoordinate = finalCoord
				waypoints = waypoint
			end
		end
	else
		result = "noreturn"
		lastcoordinate = nil
		waypoints = nil
	end
	return result, lastcoordinate, waypoints
	
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
	if cachedValue[coordString] and cachedValue[coordString].frame == currentFrame then --for spammy check in 1 frame
		return cachedValue[coordString].haveEnemies
	end

	local unitList = spGetUnitsInCylinder(order[1], order[3], enemyRange)
	local enemyCount = 0
	local totalCount = #unitList
	local haveEnemies = false
	for i=1, totalCount do
		local unitID = unitList[i]
		local unitAlly = spGetUnitAllyTeam(unitID)
		if unitAlly~=myAllyID then
			enemyCount = enemyCount + 1
		end
	end
	if enemyCount/totalCount > enemyThreshold then
		haveEnemies = true
	end
	
	cachedValue[coordString] = cachedValue[coordString] or {}
	cachedValue[coordString].haveEnemies = haveEnemies
	cachedValue[coordString].frame = currentFrame
	return haveEnemies
end

--  Detect if enemy is present at build site, and REMOVE queue if there is.
--  this make sure constructor don't suicide into enemy if left unattended.
--  (Typically constructor don't bother with this build-site unless its
--  the last one left.)
 
function EnemyAtBuildSiteCleanOrder(unitID, order, queueKey)
	if queueKey ~= 0 then --can't handle GUARD assist yet if queueKey==0
		local tooDangerous = (myQueueDanger[queueKey] or 0) >= dangerThreshold
		if tooDangerous or EnemyControlBuildSite(order) then
			if myQueue[queueKey] then
				-- local unitToStop = {}
				-- for unitID2, queueKey2 in pairs(myUnits) do
					-- if queueKey2 == queueKey then
						-- unitToStop[#unitToStop+1] = unitID2
					-- end
				-- end
				-- Spring.GiveOrderToUnitArray (unitToStop,CMD_STOP, {}, {}) --send STOP to all units already assigned to this queue. A scenario: a newly built constructor decide to assist another old constructor (which is en-route toward an enemy infested build site), this stop the old constructor
				if (tooDangerous or not myQueue[queueKey].isStarted) 
				and not spIsAABBInView(order[1]-1,order[2]-1,order[3]-1,order[1]+1,order[2]+1,order[3]+1) 
				then --not being constructed yet and not visible
					StopAnyLeader(queueKey)
					StopAnyAssistant(queueKey)
					myQueue[queueKey] = nil  --remove queue
					return true --cancel order assignment
				end
			end
		end
	end
	return nil
end