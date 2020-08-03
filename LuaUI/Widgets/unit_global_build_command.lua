--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_global_build_command.lua
--  brief:   Fork of Central Build AI, which originally replaced Central Build Group AI
--
--  author: aeonios (mtroyka)
--  Copyright (C) 2015.
--
--  original by:  Troy H. Cheek
--  Copyright (C) 2009.
--
--  Licensed under the terms of the GNU GPL, v2 or later.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              CAUTION! CAUTION! CAUTION!
-- This widget is very complicated and very easy to break.
-- Only regular users who are familiar with its behavior should make changes/clean-up.

local version = "v1.1"
function widget:GetInfo()
	return {
		name      = "Global Build Command",
		desc      = version.. "\nGlobal Build Command gives you a global, persistent build queue for all workers that automatically assigns workers to the nearest jobs.\n \nInstructions: Enable this " ..
"then give any worker build-related commands. Placing buildings on top of existing jobs while holding \255\200\200\200Shift\255\255\255\255 cancels them, and without shift replaces them. \n" ..
"You can also exclude workers from GBC's control by using the state toggle button in the unit's orders menu. " ..
"Units also get a job area removal command, the default hotkey is \255\255\90\90alt-s\255\255\255\255.\n \n" .. "It can also handle repair/reclaim/res, and automatically converts area res to reclaim for targets that cannot be resurrected.\n \n" ..
"Configuration is in \nGame->Worker AI",
		author    = "aeonios",
		date      = "July 20, 2009, 8 March 2014",
		license   = "GNU GPL, v2 or later",
		layer     = 10,
		handler   = true,
		enabled   = false  --  loaded by default?
	}
end

--  Global Build Command creates and manages a global, persistent build queue for all
--  workers that automatically assigns workers to the nearest jobs based on a cost model.
--  It manages all the workers that are added to a user-configurable control group
--  and captures and manages build jobs as well as repair, reclaim and resurrect
--  in both single-target and area forms.

-- Organization:
-- 1) Top (init, GameFrame)
-- 2) GL Drawing Code
-- 3) Event Handlers (Callins)
-- 4) Core Logic
-- 5) Helper Functions

-- Note: Some of the code here is specific to Zero-K, however there are notes for this
-- if you are porting it to another game. If you have any questions feel free to ask
-- on the forums or email me at aeonioshaplo@gmail.com.

-- CHANGELOG (NEW) --
--  v1.0 (aeonios) Apr, 2015 --
--    -Removed code for detecting enemies, due to bad/intractable behavior.
--    -Cleaned/organized/reduced the old code. Added comments, sections, and section headers for easier browsing.
--    -Simplified the way workers are handled and removed references to 'assist' and 'guard' mechanics.
--    -Implemented a simplified, consistent cost model to replace the old convoluted one.
--    -Implemented handling of reclaim/repair/resurrect and area forms.
--    -Implemented an area job remove tool.
--    -Added user configurability through Chili options.
--    -Improved performance somewhat and fixed numerous bugs and unhandled edge cases from the old code.
--    -Improved the interface a bit and made it more consistent with the game's normal interface conventions.
--    - ++ bells and whistles.

---- CHANGELOG (OLD)-----
--  the following is from Central Build AI, which contains information that I found useful in understanding
--  how the code works, and which documents certain Spring/ZK quirks that you may want to know about.
--
-- msafwan(xponen)v1.355  (26Jan2015)    :  1) all builder re-assign job every 4 second (even if already assigned a job)
--                                          2) keep queue for unfinished building
--                                          3) lower priority (and/or removal) for queue at enemy infested area
--
-- msafwan,       v1.21   (7oct2012)     :  fix some cases where unit become 'idle' but failed to be registered by CBA,
--                                          make CBA assign all job at once rather than sending 1 by 1 after every some gameframe delay,
-- msafwan,       v1.2    (4sept2012)    :  made it work with ZK "cmd_mex_placement.lua" mex queue,
--                                          reduce the tendency to make a huge blob of constructor (where all constructor do same job),
--                                          reduce chance of some constructor not given job when player have alot of constructor,
-- rafal,         v1.1    (2May2012)     :  Don't fetch full Spring.GetCommandQueue in cases when only the first command is needed - instead using
--                      GetCommandQueue(unitID, 1)
-- KingRaptor,    v1.1    (24dec2011)    :  Removed the "remove in 85.0" stuff
-- versus666,     v1.1    (16dec2011)    :  mostly changed the layer order to get a logical priority among widgets.
-- KingRaptor,    v1.1    (8dec2011)     :  Fixed the remaining unitdef tags for 85.0
-- versus666,     v1.1    (7jan2011)     :  Made CBA, cmd_retreat, gui_nuke_button, gui_team_platter.lua, unit_auto_group to obey F5 (gui hidden).
-- KingRaptor,    v1.1    (2Nov2010)     :  Moved version number from name to description.
-- lccquantum,    v1.1    (2Nov2010)     :  central_build_AI is disabled by default (people will wonder why their builders are acting wierd when in group 0)
-- versus666,     v1.1    (1Nov2010)     :  introduced into ZK

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Declarations ----------------------------------------------------------------
include("keysym.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

options_path = 'Settings/Unit Behaviour/Worker AI'

options_order = {
	'updateRate',
	'separateConstructors',
	'splitArea',
	'autoConvertRes',
	'autoRepair',
	'cleanWrecks',
	'chicken',
	'intelliCost',
	'alwaysShow',
	'drawIcons',
}

options = {
	updateRate = {
		name = 'Worker Update Rate (higher numbers are faster but more CPU intensive):',
		type = 'number',
		min = 1, max = 4, step = 1,
		value = 1,
	},

	separateConstructors = {
		name = 'Separate Constructors',
		type = 'bool',
		desc = 'Replace factory inherited orders for constructors so that they can be assigned jobs immediately.\n (default = true)',
		value = true,
	},

	splitArea = {
		name = 'Split Area Commands',
		type = 'bool',
		desc = 'Automatically capture single targets from area commands so that more workers will be assigned to those jobs.\n (default = true)',
		value = true,
	},

	autoConvertRes = {
		name = 'Convert Resurrect',
		type = 'bool',
		desc = 'Convert area resurrect into reclaim for targets that can\'t be resurrected.\n (Note: Only has any effect if Split Area Commands is enabled)\n (default = true)',
		value = true,
	},

	autoRepair = {
		name = 'Auto-Repair',
		type = 'bool',
		desc = 'Automatically add repair jobs whenever units are damaged.\n (Note: If this is enabled, repair jobs will only be visible when \255\200\200\200shift\255\255\255\255 is held!) \n (default = false)',
		value = false,
	},

	cleanWrecks = {
		name = 'Auto-Reclaim/Resurrect',
		type = 'bool',
		desc = 'Automatically add reclaim/res for wrecks near your base. This does not target map features and is not a replacement for area reclaim/res.\n (default = false)',
		value = false,
	},

	chicken = {
		name = 'Auto-Chicken',
		type = 'bool',
		desc = 'Retreats auto-repairing/reclaiming units when they\'re attacked.\n (default = true)',
		value = false,
	},

	intelliCost = {
		name = 'Intelligent Cost Model',
		type = 'bool',
		desc = 'Tries to optimize build order for better worker safety and faster overall construction, but makes it \nmore difficult to control what gets built first.\n (default = true)',
		value = true,
	},

	alwaysShow = {
		name = 'Always Show',
		type = 'bool',
		desc = 'If this is enabled queued commands will always be displayed, otherwise they are only visible when \255\200\200\200shift\255\255\255\255 is held.\n (default = false)',
		value = false,
	},

	drawIcons = {
		name = 'Draw Status Icons',
		type = 'bool',
		desc = 'Check to draw status icons over each unit, which shows its command state.\n (default = true)',
		value = true,
	},
}

include('LuaUI/Widgets/gbc/Pathfinding.lua', nil, VFS.RAW_FIRST)
-- luacheck: read globals RenderUpdate RenderPreUnit RenderWorld RenderCleanupUnit

-- This is made visible to Rendering for display.
--List of prefix used as value for includedBuilders[]
commandType = {
	drec = 'drec', -- indicates direct orders from the user, or from other source external to this widget.
	buildQueue = 'queu', -- indicates that the worker is under GBC control.
	idle = 'idle',
	mov = 'mov', -- indicates that the constructor was in the way of another constructor's job, and is being moved
	ckn = 'ckn' -- indicates that the unit is running away from enemies (only applies to autoreclaim)
}

include('LuaUI/Widgets/gbc/Rendering.lua', nil, VFS.RAW_FIRST)
-- luacheck: read globals UpdateOneWorkerPathing UpdateOneJobPathing CleanPathing

-- "Localized" API calls, because they run ~33% faster in lua.
local Echo                    = Spring.Echo
local spIsGUIHidden           = Spring.IsGUIHidden
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetFeatureDefID       = Spring.GetFeatureDefID
local spGetSelectedUnits      = Spring.GetSelectedUnits
local spGetTeamUnits          = Spring.GetTeamUnits
local spGetUnitsInCylinder    = Spring.GetUnitsInCylinder
local spGetCommandQueue       = Spring.GetCommandQueue
local spGetUnitPosition       = Spring.GetUnitPosition
local spGetUnitDirection      = Spring.GetUnitDirection
local spGetUnitHealth         = Spring.GetUnitHealth
local spGetUnitTeam           = Spring.GetUnitTeam
local spIsUnitAllied          = Spring.IsUnitAllied
local spGiveOrderToUnit       = Spring.GiveOrderToUnit
local spGetMyTeamID           = Spring.GetMyTeamID
local spGetMyAllyTeamID       = Spring.GetMyAllyTeamID
local spGetFeaturePosition    = Spring.GetFeaturePosition
local spGetFeaturesInCylinder = Spring.GetFeaturesInCylinder
local spGetAllFeatures        = Spring.GetAllFeatures
local spGetSpectatingState    = Spring.GetSpectatingState
local spGetKeyState           = Spring.GetKeyState
local spTestBuildOrder        = Spring.TestBuildOrder
local spGetUnitIsStunned      = Spring.GetUnitIsStunned
local spValidUnitID           = Spring.ValidUnitID
local spValidFeatureID        = Spring.ValidFeatureID
local spUnitIsDead            = Spring.GetUnitIsDead
local spIsPosInLos            = Spring.IsPosInLos
local spGetGroundHeight       = Spring.GetGroundHeight

local spWorldToScreenCoords   = Spring.WorldToScreenCoords
local spTraceScreenRay        = Spring.TraceScreenRay

local CMD_REPAIR    = CMD.REPAIR
local CMD_RESURRECT = CMD.RESURRECT
local CMD_REMOVE    = CMD.REMOVE
local CMD_RECLAIM   = CMD.RECLAIM
local CMD_STOP      = CMD.STOP
local CMD_OPT_ALT   = CMD.OPT_ALT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_SELFD     = 65 -- See: rts/Sim/Units/CommandAI/Command.h

local abs  = math.abs
local sqrt = math.sqrt
local max  = math.max

local EMPTY_TABLE = {}

local frame = 0
local longCount = 0
local myTeamID = spGetMyTeamID()

local Terraunit_ID = UnitDefNames.terraunit.id
local Solar_ID     = UnitDefNames.energysolar.id
local Wind_ID      = UnitDefNames.energywind.id
local Caretaker_ID = UnitDefNames.staticcon.id
local Mex_ID       = UnitDefNames.staticmex.id
local Claw_ID      = UnitDefNames.wolverine_mine.id

--  "global" for this widget.  This is probably not a recommended practice.
local includedBuilders = {}  --  list of units in the Central Build group, of the form includedBuilders[unitID] = commandType
local buildQueue = {}  --  list of commands for Central Build group, of the form buildQueue[BuildHash(cmd)] = cmd
local busyUnits = {} -- list of units that are currently assigned jobs, of the form busyUnits[unitID] = BuildHash(cmd)
local idlers = {} -- list of units marked idle by widget:UnitIdle, which need to be double checked due to gadget conflicts. Form is idlers[index] = unitID
local lastCommand = {} -- Mapping of units to frame of last command we sent. Work gets assigned anyway if the last command we sent was more than five seconds (150 frames) ago.
local allBuilders = {} -- list of all mobile builders, which saves whether they are GBC-enabled or not.
local newBuilders = {} -- a list of newly finished builders that have been added to includedBuilders. These units are assigned immediately on UnitIdle and then removed from the list.
local activeJobs = {} -- list of jobs that have been started, using the UnitID of the building so that we can check completeness via UnitFinished
local movingUnits = {} -- a list of workers that are being moved out of the way, of the form movingUnits[unitID] = lastMoveFrame
local idleCheck = false -- flag if any units went idle
local areaCmdList = {} -- a list of area commands, for persistently capturing individual reclaim/repair/resurrect jobs from LOS-limited areas. Same form as buildQueue.
local reassignedUnits = {} -- list of units that have already been assigned/reassigned jobs and which don't need to be reassigned until we've cycled through all workers.
local hasRes = false

local territoryPos = {x = 0, z = 0}
local territoryCount = 0
local territoryCenter = {x = 0, z = 0}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Top -------------------------------------------------------------------------

function widget:Initialize()
	-- add all existing workers to GBC.
	local units = spGetTeamUnits(myTeamID)
		for _, uid in ipairs(units) do
			local unitDefID = spGetUnitDefID(uid)
			UnitGained(uid, unitDefID, myTeamID)
		end

	-- ZK compatability stuff
	WG.icons.SetPulse('gbcidle', true)
	WG.GlobalBuildCommand = { -- add compatibility functions to a table in widget globlals
		CommandNotifyPreQue = CommandNotifyPreQue, --an event which is called by "unit_initial_queue.lua" to notify other widgets that it is giving pregame commands to the commander.
		CommandNotifyMex = CommandNotifyMex, --an event which is called by "cmd_mex_placement.lua" to notify other widgets of mex build commands.
		CommandNotifyTF = CommandNotifyTF, -- an event called by "gui_lasso_terraform.lua" to notify other widgets of terraform commands.
		CommandNotifyRaiseAndBuild = CommandNotifyRaiseAndBuild -- an event called by "gui_lasso_terraform.lua" to notify other widgets of raise-and-build commands.
	}
	widget:PlayerChanged()
	--[[if spGetSpectatingState() then
		Echo( "<Global Build Command>: Spectator mode. Widget removed." )
		widgetHandler:RemoveWidget()
		return
	end--]]
end

-- cleans up if the widget is disabled.
function widget:Shutdown()
	WG.GlobalBuildCommand = nil
	WG.icons.SetDisplay('gbcicon', false)
	WG.icons.SetDisplay('gbcidle', false)
end

--  The main process loop, which calls the core code to update state and assign orders as often as ping allows.
function widget:GameFrame(thisFrame)
	frame = thisFrame
	if frame % 15 == 0 then
		if idleCheck then -- if our idle list has been updated
			CheckIdlers() -- then check and process it
		end

		CheckForRes() -- check if our group includes any units with resurrect, update the global flag
	end

	if frame % 25 == 0 then
		if longCount > 2 then longCount = 0 end

		if longCount == 0 then
			if options.splitArea.value then -- if splitting area jobs is enabled
				UpdateAreaCommands() -- capture targets from area repair/reclaim/resurrect commands as they fall into LOS.
			end
		elseif longCount == 1 then
			if options.cleanWrecks.value then -- if auto-reclaim/res is enabled
				CleanWrecks() -- capture all non-map-feature targets in LOS
			end
		else
			CaptureTF() -- ZK-Specific: captures "terraunits" from ZK terraform, and adds repair jobs for them.
		end

		longCount = longCount + 1
	end

	if frame % 30 == 0 then
		CheckMovingUnits()
		CleanBuilders() -- remove any dead/captured/nonexistent constructors from includedBuilders and update bookkeeping
		for _, cmd in pairs(buildQueue) do -- perform validity checks for all the jobs in the queue, and remove any which are no longer valid
			if not cmd.tfparams then -- ZK-specific: prevents combo TF-build operations from being removed by CleanOrders until the terraform is finished.
				CleanOrders(cmd, false) -- note: also marks workers whose jobs are invalidated as idle, so that they can be reassigned immediately.
			end
		end
	end

	if frame % (4 - (options.updateRate.value - 1)) == 0 then
		CleanBusy() -- removes workers from busyUnits if the job they're assigned to doesn't exist. Prevents crashes.
		local unitToWork = FindEligibleWorker()  -- get an eligible worker and assign it a job.
		if unitToWork then
			CleanPathing(unitToWork, includedBuilders, buildQueue) -- garbage collect pathing for jobs that no longer exist
			GiveWorkToUnit(unitToWork)
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- GL Drawing Callins  ---------------------------------------------------------

-- Run pre-draw visibility checks, and sort buildQueue for drawing.
function widget:Update(dt)
	if spIsGUIHidden() then
		return
	end
	RenderUpdate(dt, includedBuilders, allBuilders, buildQueue)
end

-- Draw area command circles, building outlines and other ground decals
function widget:DrawWorldPreUnit()
	if (WG.Cutscene and WG.Cutscene.IsInCutscene()) or spIsGUIHidden() then
		return
	end

	RenderPreUnit()
end

--  Paint 'cb' tags on units, draw ghosts of items in central build queue.
--  Text stuff mostly borrowed from gunblob's Group Label and trepan/JK's BuildETA.
--  Ghost stuff borrowed from very_bad_soldier's Ghost Radar.
function widget:DrawWorld()
	if spIsGUIHidden() then
		return
	end
	RenderWorld(myTeamID)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Event Handlers --------------------------------------------------------------
--[[
HOW THIS WORKS:
	widget:PlayerChanged()
		Detects when the player resigns, and disables the widget.
	widget:UnitDamaged()
		Automatically adds repair jobs for damaged units, if enabled.
	widget:UnitFromFactory()
		Separates constructors from the factory stream, if enabled. Uses ZK-specific,
		factory-dependent values for clearing distance.
	widget:UnitCreated()
		Detects when new non-factory units are started, and if the builder is one of ours
		it records the association between the started unit and the job it represents.
		It also removes jobs when start-nanoframe-only mode is used, and updates ZK-specific
		raise-and-build commands to normal commands after the terraform finishes.
	widget:UnitFinished()
		Detects when a finished unit is from one of our jobs, and performs necessary cleanup.
	widget:UnitDestroyed()
		Performs cleanup whenever a worker or building nanoframe dies.
	widget:UnitTaken()
		Performs cleanup whenever a worker or building nanoframe is captured by the enemy.
	widget:UnitIdle()
		This catches units from our group as they go idle, and marks them for
		deferred processing. This is necessary because UnitIdle sometimes misfires
		during build jobs, for unknown reasons.
	CommandNotifyMex()
		ZK-Specific: Captures mex commands from the cmd_mex_placement widget.
	CommandNotifyTF()
		ZK-Specific: Captures terraform commands from gui_lasso_terraform widget.
	CommandNotifyRaiseAndBuild()
		ZK-Specific: Captures raise-and-build commands from gui_lasso_terraform widget.
	widget:CommandNotify()
		This captures all the build-related commands from units in our group,
		and adds them to the global queue.
]]--


--  Detect when player enters spectator mode (thanks to SeanHeron).
function widget:PlayerChanged(playerID)
	if spGetSpectatingState() then
		Echo( "<Global Build Command> Spectator mode. Widget removed." )
		widgetHandler:RemoveWidget(widget)
		return
	end
	myTeamID = spGetMyTeamID()
end

-- Returns true if this is now one of our units that we should immediately direct.
function UnitGained(unitID, unitDefID, unitTeam, doInitialCheck)
	if unitTeam ~= myTeamID then return end

	-- update territory info when new mexes are created.
	if unitDefID == Mex_ID and not doInitialCheck then
		-- To make sure Gained and Gone have a one to one relationship wrt
		-- territory processing, only update territory center on completed mexes.
		local _,_,nanoframe = spGetUnitIsStunned(unitID)
		if not nanoframe then
			local x, _, z = spGetUnitPosition(unitID)
			territoryPos.x = territoryPos.x + x
			territoryPos.z = territoryPos.z + z
			territoryCount = territoryCount + 1
			territoryCenter.x = territoryPos.x/territoryCount
			territoryCenter.z = territoryPos.z/territoryCount
		end
		return false
	end

	local ud = UnitDefs[unitDefID]
	if not ud.isMobileBuilder then return false end
	-- if the new unit is a mobile builder
	local builderState = allBuilders[unitID]
	if builderState == nil then
		-- add the builder to the global builder tracking table, initialize as controlled by GBC.
		allBuilders[unitID] = true
	elseif not builderState then
		-- We expressly removed this from GBC (while it was still a nanoframe?)
		return false
	end
	allBuilders[unitID] = true

	if spGetCommandQueue(unitID, 0) ~= 0 then -- if so we mark it as drec
		includedBuilders[unitID] = {cmdtype=commandType.drec, unreachable={}}
	else -- otherwise we mark it as idle
		includedBuilders[unitID] = {cmdtype=commandType.idle, unreachable={}}
	end
	UpdateOneWorkerPathing(unitID, includedBuilders, buildQueue) -- then precalculate pathing info

	if doInitialCheck then
		-- init our commander as idle, since the initial queue widget will notify us later when it gives the com commands.
		local _,_,nanoframe = spGetUnitIsStunned(unitID)
		if not nanoframe then
			includedBuilders[unitID].cmdtype = commandType.idle
			return -- don't apply constructor separator to commanders
		end
	end

	return true
end

-- This function detects when our workers have started a job
function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not unitTeam == myTeamID then
		return -- if it's not our unit then ignore it!
	end

	if busyUnits[builderID] then -- if the builder is one of our busy workers
		local key = busyUnits[builderID]
		local myCmd = buildQueue[key]

		if myCmd.tfparams then -- ZK-Specific: For combo terraform-build commands, convert to normal build commands once the building has started
			buildQueue[key].tfparams = nil
			UpdateOneJobPathing(key, includedBuilders, buildQueue) -- update pathing, since terraform can change the results
		end

		if myCmd.q then -- if given with 'start-only', then cancel the job as soon as it's started
			StopAnyWorker(key)
		else -- otherwise track the unitID in activeJobs so that UnitFinished can remove it from the queue
			activeJobs[unitID] = key
		end
	end

	if UnitGained(unitID, unitDefID) then
		-- constructor separator
		if options.separateConstructors.value then -- if constructor separator is enabled
			local facDef = UnitDefs[spGetUnitDefID(builderID)]
			local facScale -- how far our unit will be told to move
			if not next(buildQueue) then -- if the queue is empty, we need to increase clearance to stop the fac from getting jammed with idle workers
				facScale = 350
			elseif facDef.name == 'factoryship' then -- boatfac, needs a huge clearance
				facScale = 250
			elseif facDef.name == 'factoryhover' then -- hoverfac, needs extra clearance
				facScale = 140
			else -- other facs (and athenas, which are built by regular constructors)
				facScale = 120
			end

			local dx,_,dz = spGetUnitDirection(unitID)
			local x,y,z = spGetUnitPosition(unitID)
			dx = dx*facScale
			dz = dz*facScale
			spGiveOrderToUnit(unitID, CMD_RAW_MOVE, {x+dx, y, z+dz}, 0) -- replace the fac rally orders with a short distance move.
		end
	end
end

-- This function detects when a unit was finished and it was from a job on the queue, and does necessary cleanup
function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if activeJobs[unitID] then
		local key = activeJobs[unitID]
		if buildQueue[key] then
			StopAnyWorker(key)
		end
		activeJobs[unitID] = nil
	end

	if UnitGained(unitID, unitDefID, unitTeam) then
		newBuilders[unitID] = true
	end
end

local function UnitGone(unitID, unitDefID, unitTeam, doRemoveMatchingJobs)
	if unitTeam ~= myTeamID then
		return
	end

	if includedBuilders[unitID] then
		UnassignWorker(nil, unitID, nil)
	elseif activeJobs[unitID] then
		if doRemoveMatchingJobs then
			-- check if the captured unit was a nanoframe
			local key = activeJobs[unitID]
			if buildQueue[key] then
				StopAnyWorker(key) -- remove jobs from the queue when nanoframes are captured, since the job will be obstructed anyway
			end
		end
		activeJobs[unitID] = nil
	end

	if allBuilders[unitID] then
		allBuilders[unitID] = nil
		RenderCleanupUnit(unitID)
	end

	if unitDefID == Mex_ID then
		local x, _, z = spGetUnitPosition(unitID)
		territoryPos.x = territoryPos.x - x
		territoryPos.z = territoryPos.z - z
		territoryCount = territoryCount - 1
		if territoryCount > 0 then
			territoryCenter.x = territoryPos.x/territoryCount
			territoryCenter.z = territoryPos.z/territoryCount
		else
			territoryPos.x = 0
			territoryPos.z = 0
		end
	end
end

-- This function cleans up when workers or building nanoframes are killed
function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	UnitGone(unitID, unitDefID, unitTeam)
end

-- This function cleans up when workers or nanoframes are captured by an enemy
function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	UnitGone(unitID, unitDefID, unitTeam)
end

-- This function adds new workers when they are captured from the enemy.
function widget:UnitGiven(unitID, unitDefID, newTeam, unitTeam)
	if newTeam ~= myTeamID then
		return -- if it doesn't involve us, don't do anything.
	end

	if UnitGained(unitID, unitDefID, newTeam) then
		GiveWorkToUnit(unitID)
	end
end


-- This function implements auto-repair
function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if spIsUnitAllied(unitID) and options.autoRepair.value and unitDefID ~= Claw_ID then
		local myCmd = {id=CMD_REPAIR, target=unitID, assignedUnits={}}
		local hash = BuildHash(myCmd)
		if not buildQueue[hash] then
			buildQueue[hash] = myCmd
			if UnitDefs[unitDefID].isImmobile then
				UpdateOneJobPathing(hash, includedBuilders, buildQueue)
			end
		end
	end

	-- chicken autoreclaiming units to the center of your territory if they get attacked.
	if busyUnits[unitID] and includedBuilders[unitID].cmdtype == commandType.buildQueue
	  and ((options.cleanWrecks.value and buildQueue[busyUnits[unitID]].id == CMD_RECLAIM) or (options.autoRepair.value and buildQueue[busyUnits[unitID]].id == CMD_REPAIR))
	  and options.chicken.value and territoryCount > 0 then
		local job = buildQueue[busyUnits[unitID]]
		if job.id == CMD_REPAIR and job.target then
			local unitDef = UnitDefs[spGetUnitDefID(job.target)]
			if unitDef and unitDef.isImmobile and unitDef.reloadTime > 0 then
				return -- don't retreat units that are repairing porc, since continuing to repair the porc is safer!
			end
		end
		spGiveOrderToUnit(unitID, CMD_REMOVE, {CMD_REPAIR}, CMD_OPT_ALT) -- remove repair/reclaim orders
		spGiveOrderToUnit(unitID, CMD_REMOVE, {CMD_RECLAIM}, CMD_OPT_ALT)
		spGiveOrderToUnit(unitID, CMD_STOP, EMPTY_TABLE, 0)
		local y = spGetGroundHeight(territoryCenter.x, territoryCenter.z)
		spGiveOrderToUnit(unitID, CMD_RAW_MOVE, {territoryCenter.x, y, territoryCenter.z}, 0)
		UnassignWorker(nil, unitID, commandType.ckn)
		movingUnits[unitID] = frame
	end
end

--  If unit detected as idle and it's one of ours, mark it as idle so that it can be assigned work. Note: some ZK gadgets cause false positives for this, which is why we use deferred checks.
function widget:UnitIdle(unitID, unitDefID, teamID)
	if includedBuilders[unitID] then -- if it's one of ours
		idlers[#idlers+1] = unitID -- add it to the idle list to be double-checked at assignment time.
		idleCheck = true -- set the flag so that the idle list will be processed
		return
	end
end

-- This function adds a state toggle to constructors that sets whether they participate in gbc or not.
function widget:CommandsChanged()
	local units = Spring.GetSelectedUnits()
	for i, id in pairs(units) do
		if allBuilders[id] ~= nil then
			local customCommands = widgetHandler.customCommands
			local order = 0
			if allBuilders[id] then
				order = 1
			end
			-- add state toggle command
			table.insert(customCommands, {
				id      = CMD_GLOBAL_BUILD,
				type    = CMDTYPE.ICON_MODE,
				tooltip = 'Toggle using global build command for workers.',
				name    = 'Global Build',
				cursor  = 'Repair',
				action  = 'globalbuild',
				params  = {order, 'off', 'on'},
			})

			-- add the cancel jobs command
			table.insert(customCommands, {
				id      = CMD_GBCANCEL,
				type    = CMDTYPE.ICON_AREA,
				tooltip = 'Cancel Global Build tasks.',
				name    = 'Global Build Cancel',
				cursor  = 'Repair',
				action  = 'globalbuildcancel',
				--params  = {order, 'off', 'on'},
			})

			break
		end
	end
end

--  A ZK compatibility function: receive broadcasted event from "unit_initial_queue.lua" (ZK specific)
function CommandNotifyPreQue(unitID)
	if includedBuilders[unitID] then
		includedBuilders[unitID].cmdtype = commandType.drec
	end
end

--  A ZK compatibility function: receive broadcasted event from "cmd_mex_placement.lua" (ZK specific) which notify us that it has its own mex queue
function CommandNotifyMex(id,params,options, isAreaMex)
	local groundHeight = spGetGroundHeight(params[1],params[3])
	params[2] = max(0, groundHeight)
	local returnValue = widget:CommandNotify(id, params, options, true, isAreaMex)
	return returnValue
end

-- A ZK compatibility function: recieves command events broadcast from "gui_lasso_terraform.lua"
function CommandNotifyTF(unitArray, shift)
	local ours = false -- ensure that the order was given to at least one unit that's in our group
	for i=1, #unitArray do
		local unitID = unitArray[i]
		if includedBuilders[unitID] then
			ours = true
			break
		end
	end
	if not ours then
		return false -- and stop here if not
	end

	if shift then
		return true -- tell lasso terraform not to give any orders besides terraform internal, so that our units won't be disturbed.
	else
		-- if the order was direct, we need to update our workers' status and set them to drec.
		for i=1, #unitArray do
			local unitID = unitArray[i]
			if includedBuilders[unitID] then -- if it's one of our units
				-- mark our unit as under direct orders and let gui_lasso_terraform handle it
				UnassignWorker(nil, unitID, commandType.drec)
			end
		end
	end
	return false
end

-- ZK-Specific: This function captures combination raise-and-build commands
function CommandNotifyRaiseAndBuild(unitArray, cmdID, x, y, z, h, shift)
	local ours = false -- ensure that the order was given to at least one unit that's in our group
	for i=1, #unitArray do
		local unitID = unitArray[i]
		if includedBuilders[unitID] then
			ours = true
			break
		end
	end
	if not ours then
		return false -- and stop here if not
	end

	local hotkey = string.byte("q")
	local isQ = spGetKeyState(hotkey)
	local myCmd
	if isQ then
		myCmd = {id=cmdID, x=x, y=y, z=z, h=h, tfparams=true, assignedUnits={}, q=true}
	else
		myCmd = {id=cmdID, x=x, y=y, z=z, h=h, tfparams=true, assignedUnits={}}
	end

	local hash = BuildHash(myCmd)

	buildQueue[hash] = myCmd
	UpdateOneJobPathing(hash, includedBuilders, buildQueue)
	if shift then
		return true -- tell the terraform widget not to give any orders besides terraform internal, so that our units won't be disturbed.
	else
		-- if the order was direct, we need to update our workers' status and set them to drec.
		for i=1, #unitArray do
			local unitID = unitArray[i]
			if includedBuilders[unitID] then
				AssignWorker(hash, unitID, commandType.drec)
			end
		end
	end
	return false
end

--  This function captures build-related commands given to units in our group and adds them to the queue, and also tracks unit state (ie direct orders vs queued).
--  Thanks to Niobium for pointing out CommandNotify().
function widget:CommandNotify(id, params, options, isZkMex, isAreaMex)
	if id == CMD_GLOBAL_BUILD then
		ApplyState(params and params[1] == 1)
		return true
	end

	if id == CMD_GBCANCEL then -- implements the job cancelling command
		local x, _, z, r = unpack(params)
		RemoveJobs(x, z, r)
		return true
	end

	if id < 0 and params[1]==nil and params[2]==nil and params[3]==nil then -- Global Build Command doesn't handle unit-build commands for factories.
		return
	end
	if options.meta then --skip special insert command (spacebar). Handled by CommandInsert() widget
		return
	end

	local selectedUnits = spGetSelectedUnits()
	for _, unitID in pairs(selectedUnits) do  -- check selected units...
		if includedBuilders[unitID] then  --  was issued to one of our units.
			if ( id < 0 ) then --if the order is for building something
				local hotkey = string.byte("q")
				local isQ = spGetKeyState(hotkey)
				local x, y, z, h = params[1], params[2], params[3], params[4]
				local myCmd
				if isQ then
					myCmd = {id=id, x=x, y=y, z=z, h=h, assignedUnits={}, q=true}
				else
					myCmd = {id=id, x=x, y=y, z=z, h=h, assignedUnits={}}
				end
				local hash = BuildHash(myCmd)
				if CleanOrders(myCmd, true) or not options.shift then -- check if the job site is obstructed, and clear up any other jobs that overlap.
					buildQueue[hash] = myCmd  -- add it to queue if clear
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end

				if ( options.shift ) then -- if the command was given with shift
					return true  -- we return true to take ownership of the command from Spring.
				else -- for direct orders
					AssignWorker(hash, unitID, commandType.drec)
				end
			elseif id == CMD_REPAIR or id == CMD_RECLAIM or id == CMD_RESURRECT then -- if the command is for repair, reclaim or ressurect
				if #params > 1 then -- if the order is an area order
					local x, y, z, r = params[1], params[2], params[3], params[4]

					if id == CMD_RECLAIM then -- check for specific unit reclaim
						local mx,my = spWorldToScreenCoords(x, y, z) -- convert the center point to screen coords
						local cType,uid = spTraceScreenRay(mx,my) -- trace a screen ray back to see if it was placed on top of a unit
						if cType == "unit" and spGetUnitTeam(uid) == myTeamID then -- if it's a unit, and one of ours, then convert to specific unit reclaim
							local unitDefID = spGetUnitDefID(uid)
							ReclaimSpecificUnit(unitDefID, x, z, r, options.shift)
							return true -- capture the command regardless, since this can't easily be given as a direct order
						end
					end

					local myCmd
					if options.alt then -- ZK-Specific Behavior: alt makes area jobs 'permanent', thus we need to record if it was used so we can maintain that behavior.
						-- note if you wanted to emulate this same behavior for some other game, it would require only a minor change to IdleCheck().
						myCmd = {id=id, x=x, y=y, z=z, r=r, alt=true, assignedUnits={}}
					else
						myCmd = {id=id, x=x, y=y, z=z, r=r, alt=false, assignedUnits={}}
					end
					local hash = BuildHash(myCmd)
					buildQueue[hash] = myCmd -- add the job to the queue
					areaCmdList[hash] = myCmd -- and also to the area command update list, for capturing single targets.
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
					if options.shift then -- for queued jobs
						return true -- capture the command
					else -- for direct orders
						AssignWorker(hash, unitID, commandType.drec)
					end
				else --otherwise if it was single-target
					local target = params[1]
					local x, y, z
					local myCmd
					-- cache job position for features, since the targets are unlikely to move
					if target >= Game.maxUnits then -- if the target is a feature (such as a wreck)
						x, y, z = spGetFeaturePosition((target - Game.maxUnits)) -- translate targetID to featureID, get the position
						myCmd = {id=id, target=target, x=x, y=y, z=z, assignedUnits={}}
					else -- if the target is a unit
						myCmd = {id=id, target=target, assignedUnits={}}

						-- Cancel inverse jobs
						if id == CMD_RECLAIM then
							-- A reclaim command on a target cancels jobs to repair, resurect, or build that target.
							local inverseHash = BuildHash({id=CMD_REPAIR, target=target})
							if buildQueue[inverseHash] then
								StopAnyWorker(inverseHash)
							end
							inverseHash = BuildHash({id=CMD_RESURRECT, target=target})
							if buildQueue[inverseHash] then
								StopAnyWorker(inverseHash)
							end
							local ux,_,uz = spGetUnitPosition(target)
							local udID = spGetUnitDefID(target)
							inverseHash = BuildHash({id=-udID, x=ux, z=uz})
							if buildQueue[inverseHash] then
								StopAnyWorker(inverseHash)
							end
						elseif id == CMD_RESURRECT or id == CMD_REPAIR then
							-- A resurect or repair command cancels jobs to reclaim that target.
							local inverseHash = BuildHash({id=CMD_RECLAIM, target=target})
							if buildQueue[inverseHash] then
								StopAnyWorker(inverseHash)
							end
						end
					end

					local hash = BuildHash(myCmd)
					if not buildQueue[hash] then -- if the job wasn't already on the queue
						buildQueue[hash] = myCmd -- add the command to the queue
						if myCmd.x then -- if our target is not a unit
							UpdateOneJobPathing(hash, includedBuilders, buildQueue) -- then cache pathing info
						end
					elseif options.shift then -- if it was already on the queue, and given with shift then cancel it
						StopAnyWorker(hash)
					end

					-- note: area repair/reclaim/resurrect commands are add only, and do not cancel anything if used twice on the same targets.
					-- single-target repair/reclaim/resurrect commands on the other hand are add/cancel, as with other jobs.
					if options.shift then --and if the command was given with shift
						return true -- return true to capture it
					else
						AssignWorker(hash, unitID, commandType.drec)
					end
				end
			else -- if the order is not for build-power related things, ex move orders
				-- then the unit is just marked as under user direction and we let spring handle it.
				UnassignWorker(nil, unitID, commandType.drec)
			end
		end
	end
	return false
end

function ApplyState(desiredState)
	local selectedUnits = spGetSelectedUnits()
	for _,unitID in pairs(selectedUnits) do
		-- if we know about the builder, and it's not already in its desired state...
		if allBuilders[unitID] ~= nil and allBuilders[unitID] ~= desiredState then
			allBuilders[unitID] = desiredState
			if allBuilders[unitID] then
				-- newly enabled
				local _,_,nanoframe = spGetUnitIsStunned(unitID)
				if not includedBuilders[unitID] and not nanoframe then
					if spGetCommandQueue(unitID, 0) ~= 0 then -- if so we mark it as drec
						includedBuilders[unitID] = {cmdtype=commandType.drec, unreachable={}}
					else -- otherwise we mark it as idle
						includedBuilders[unitID] = {cmdtype=commandType.idle, unreachable={}}
					end
					UpdateOneWorkerPathing(unitID, includedBuilders, buildQueue) -- then precalculate pathing info
				end
			elseif includedBuilders[unitID] then
				-- newly disabled
				UnassignWorker(nil, unitID, nil)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Core Logic ------------------------------------------------------------------

--[[
HOW THIS WORKS:
	FindEligibleWorker()
		Sorts through our group and returns a worker to be assigned,
		ensuring that we cycle through all workers (more or less) evenly. Does not consider workers that are under direct orders.
	GiveWorkToUnit()
		Takes a unit as input, calls FindCheapestJob(),
		and if FindCheapestJob() returns a job it gives the command to the worker and updates relevant info.
	FindCheapestJob()
		For a given worker as input, iterates over buildQueue, checking each job to see if the worker can build and reach it,
		and if so calls CostOfJob() for each job to get the cost.
		It caches the cheapest job it finds and returns it after iterating over all jobs.
	CostOfJob()
		Implements the cost model used to find the cheapest job, and can be modified,
		extended or replaced to adjust the assignment behavior. (or if porting)
	CheckForRes()
		Determines if any of the units in our group can use resurrect, and sets a global flag.
	UpdateAreaCommands()
		Calls SplitAreaCommand for each area command on the queue, if the splitArea option is enabled.
	SplitAreaCommand()
		Captures individual targets from area repair/reclaim/resurrect orders and adds them to the queue as they enter LOS.
	CleanWrecks()
		Captures ALL wreckage/debris/eggs that fall into los, and implements the auto-reclaim-res feature. Ignores map features.
	CheckIdlers()
		Processes units that had UnitIdle called on them to ensure that they were really idle, and does cleanup for jobs such as
		area commands where there's no other way to tell if the job is done.
	CaptureTF()
		ZK-Specific, locates 'terraunits' that mark terraform points and adds repair jobs for them.
	CleanOrders()
		Takes a build command as input, and checks the build site for blockage or overlap with existing jobs,
		then removes any jobs that are blocked, finished, invalid or conflicting.
]]--


-- This function returns a worker from our group to be assigned/reassigned to a job.
-- We only process one worker at a time, every couple of frames to keep performance reasonable.
function FindEligibleWorker()
	for unitID,myCmd in pairs(includedBuilders) do
		if not spValidUnitID(unitID) or spUnitIsDead(unitID) or spGetUnitTeam(unitID) ~= myTeamID then
			-- clean units that don't exist, are dead, or no longer belong to our team..
			-- remove the unit from the list of constructors
			UnassignWorker(nil, unitID, nil)
		elseif myCmd.cmdtype == commandType.idle and not reassignedUnits[unitID] then -- first we assign idle units
			return unitID
		end
	end
	--if there are no idlers available, reassign an already assigned unit to see if there is a better job it can be doing.
	for unitID,cmdstate in pairs(includedBuilders) do
		if (not reassignedUnits[unitID]) and cmdstate.cmdtype == commandType.buildQueue then
			return unitID
		end
	end
	reassignedUnits = {} --no more unit to be reassigned? then reset list
	return
end

-- This function finds work for all the workers compiled in our eligible worker list and issues the orders.
function GiveWorkToUnit(unitID)
	reassignedUnits[unitID] = true -- We have tried to give this unit work, so don't try to reassign it right away.
	local myJob = FindCheapestJob(unitID) -- find the cheapest job
	if not myJob then
		-- Nothing to do, mark us as idle
		includedBuilders[unitID].cmdtype = commandType.idle
		return
	end
	local hash = BuildHash(myJob)
	local lastHash = busyUnits[unitID]
	if lastHash then
		if (lastHash == hash) then
			-- Extra sanity check: Is the unit actually doing what it's supposed to be doing?
			-- This works somewhat around very bad lag conditions
			if spGetCommandQueue(unitID, 0) ~= 0 then
				-- We're already on it
				return
			else
				if myJob.id < 0 and lastCommand[unitID] and lastCommand[unitID] + 150 >= frame then
					-- Try to compensate for lag (?) in order assignment when it comes to build orders, which cancel each other out. If we sent the same build order to this unit recently, don't try sending one again so soon.
					-- Spring.Echo('GBC: Warning: Withholding recent repeat build order ' .. hash .. ' to unitID ' .. unitID .. ' (for another ' .. (lastCommand[unitID] + 150 - frame) .. ' frames)')
					return
				end
				-- Spring.Echo('GBC: Warning, unit was supposed to working on something, but has empty command queue. Assigning work anyway, check the cache state!')
			end
		end
		-- Spring.Echo('GBC: Reassigning unit', unitID, 'from', lastHash, 'to', hash)
	end
	-- if the unit has already been assigned to the same job, we also prevent order spam
	-- note, order spam stops workers from moving other workers out of the way if they're standing on each other's jobs, and also causes network spam and path-calculation spam.
	if myJob.id < 0 then -- for build jobs
		if not myJob.tfparams then -- for normal build jobs, ZK-specific guard, remove if porting
			spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.h}, 0) -- issue the cheapest job as an order to the unit
			lastCommand[unitID] = frame
			AssignWorker(hash, unitID, commandType.buildQueue)
		else -- ZK-Specific: for combination raise-and-build jobs
			local localUnits = spGetUnitsInCylinder(myJob.x, myJob.z, 200)
			for i=1, #localUnits do -- locate the 'terraunit' if it still exists, and give a repair order for it
				local target = localUnits[i]
				local udid = spGetUnitDefID(target)
				-- Note: This can be nil if eg. it's a radar dot we don't know the unit type for
				if Terraunit_ID == udid and spGetUnitTeam(target) == myTeamID then
					spGiveOrderToUnit(unitID, CMD_REPAIR, {target}, 0)
					break
				end
			end
			lastCommand[unitID] = frame
			spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.h}, CMD_OPT_SHIFT) -- add the build part of the command to the end of the queue with options shift
			AssignWorker(hash, unitID, commandType.buildQueue)
		end -- end zk-specific guard
	else -- for repair/reclaim/resurrect
		if not myJob.target then -- for area commands
			if not spIsPosInLos(myJob.x, myJob.y, myJob.z, spGetMyAllyTeamID()) then -- if the job is outside of LOS, we need to convert it to a move command or else the units won't bother exploring it.
				spGiveOrderToUnit(unitID, CMD_RAW_MOVE, {myJob.x, myJob.y, myJob.z}, 0)
				if myJob.alt then -- if alt was held, the job should remain 'permanent'
					spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.r}, CMD_OPT_ALT + CMD_OPT_SHIFT)
				else -- for normal area jobs
					spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.r}, CMD_OPT_SHIFT) -- note: we add options->shift here to add our reclaim job to the unit's queue after the move order, to prevent it from falsely going idle.
				end
			elseif myJob.alt then -- if alt was held, the job should remain 'permanent'
				spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.r}, CMD_OPT_ALT)
			else -- for normal area jobs
				spGiveOrderToUnit(unitID, myJob.id, {myJob.x, myJob.y, myJob.z, myJob.r}, 0)
			end
			AssignWorker(hash, unitID, commandType.buildQueue)
		else -- for single-target commands
			spGiveOrderToUnit(unitID, myJob.id, {myJob.target}, 0) -- issue the cheapest job as an order to the unit
			AssignWorker(hash, unitID, commandType.buildQueue)
		end
	end
end

-- This function returns the cheapest job for a given worker, given the cost model implemented in CostOfJob().
function FindCheapestJob(unitID)
	local cachedJob = nil -- the cheapest job that we've seen
	local cachedCost = 0 -- the cost of the currently cached cheapest job
	local ux, _, uz = spGetUnitPosition(unitID)  -- unit location

	-- if the worker has already been assigned to a job, we cache it first to increase job 'stickiness'
	-- This looks redundant but it is not, because cleanorders may remove a worker from busyUnits without necessarily returning false,
	-- ie if it's standing on top of the job that it's been assigned to and has to be cleared off.
	if busyUnits[unitID] and CleanOrders(buildQueue[busyUnits[unitID]], false) and busyUnits[unitID] then
		local key = busyUnits[unitID]
		local jx, jz
		cachedJob = buildQueue[key]

		if not cachedJob then
			Spring.Echo("GBC FindCheapestJob: cachedJob doesn't exist!!!")
		end

		if cachedJob.x then -- for jobs with explicit locations, or for which we've cached locations
			jx, jy, jz = cachedJob.x, cachedJob.y, cachedJob.z --the location of the current job
		else -- for repair jobs and reclaim jobs targetting units
			jx, jy, jz = spGetUnitPosition(cachedJob.target)
		end

		local unitDefID = spGetUnitDefID(unitID)
		local buildDist = UnitDefs[unitDefID].buildDistance
		local moveID = UnitDefs[unitDefID].moveDef.id

		if moveID then -- for ground units, cache the cost, and only very slightly reduce the cost of the current job to avoid eg. repeat turning around for builders with a low turn rate
			if options.intelliCost.value then
				cachedCost = IntelliCost(unitID, key, ux, uz, jx, jz) - 30
			else
				cachedCost = FlatCost(unitID, key, ux, uz, jx, jz) - 30
			end
		else -- for air units, reduce the cost of their current job since they tend to wander around while building
			if options.intelliCost.value then
				cachedCost = IntelliCost(unitID, key, ux, uz, jx, jz) - (buildDist + 40)
			else
				cachedCost = FlatCost(unitID, key, ux, uz, jx, jz) - (buildDist + 40)
			end
		end
	end

	for hash, tmpJob in pairs(buildQueue) do -- here we compare our unit to each job in the queue
		local jx, jz

		if not tmpJob.target or tmpJob.target ~= unitID then -- ignore self-targetting commands

			-- get job position
			if tmpJob.x then -- for jobs with explicit locations, or for which we've cached locations
				jx, jy, jz = tmpJob.x, tmpJob.y, tmpJob.z --the location of the current job
			else -- for repair jobs and reclaim jobs targetting units
				jx, jy, jz = spGetUnitPosition(tmpJob.target)
			end

			-- check pathing and/or whether the worker can build the job or not (stored in the same key)
			local isReachableAndBuildable = true
			if includedBuilders[unitID].unreachable[hash] then -- check cached values
				isReachableAndBuildable = false
			elseif not tmpJob.x then -- for jobs targetting units, which may be mobile, always calculate pathing.
				if not CleanOrders(tmpJob, false) or includedBuilders[unitID].unreachable[hash] then
					isReachableAndBuildable = false
				end
			end

			if isReachableAndBuildable then
				local tmpCost -- calculate the job cost, depending on the cost model the user has chosen
				if options.intelliCost.value then
					tmpCost = IntelliCost(unitID, hash, ux, uz, jx, jz)
				else
					tmpCost = FlatCost(unitID, hash, ux, uz, jx, jz)
				end
				if not cachedJob or tmpCost < cachedCost then -- then if there is no cached job or if tmpJob is cheaper, replace the cached job with tmpJob and update the cost
					cachedJob = tmpJob
					cachedCost = tmpCost
				end
			end
		end
	end
	return cachedJob -- after iterating over the entire queue, the resulting cached job will be the cheapest, return it.
end

-- This function implements the 'intelligent' cost model for assigning jobs.
function IntelliCost(unitID, hash, ux, uz, jx, jz)
	local job = buildQueue[hash]
	local distance = Distance(ux, uz, jx, jz) -- the distance between our worker and job

	local costMod = 1 -- our cost modifier, the number of other units assigned to the same job + 1.

	-- note we only count workers that are roughly closer/equal distance to the job,
	-- so that can achieve both "find the job closest to worker x" and "find the worker closest to their job"
	-- at the same time. You probably should not change this, since it accounts for a lot of edge cases
	-- but does not directly determine the behavior.
	for unit,_ in pairs(job.assignedUnits) do -- for all units that have been recorded as assigned to this job
		if ( unitID ~= unit) and spValidUnitID(unit) then -- excluding our current worker.
			local ix, _, iz = spGetUnitPosition(unit)
			local idist = Distance(ix, iz, jx, jz)
			local rdist = max(distance, 200) -- round distance up to 200, to equalize priority at small distances
			local deltadist = abs(idist - distance) -- calculate the absolute difference in distance, for considering large distances
			if idist < rdist or (distance > 500 and deltadist < 500) then -- and for each one that is rounded closer/equal-dist to the job vs our worker, we increment our cost weight.
				costMod = costMod + 1 -- this way we naturally prioritize closer workers so that more distant workers won't kick us off an otherwise efficient job.
			end
		end
	end

	-- The following cost calculation produces a number of different effects:

	-- It prioritizes small defenses highly, and encourages two workers per small defense structure.
	-- This is to improve worker safety and deter light raiding more effectively.

	-- Small energy is penalized slightly to encourage workers to cap mexes consistently earlier when expanding.

	-- Expensive jobs have an initial starting penalty, which disappears once a worker has been assigned
	-- to that job, and after that there is no penalty for additional mobbing so that the jobs are
	-- generally guaranteed to finish quickly once started.

	-- Resurrect always has a high priority and no mobbing penalty, due to its exclusivity.

	-- Repair and reclaim have the same cost penalty as for starting expensive jobs,
	-- but the second worker on those jobs is free. This is mainly to prevent workers
	-- from trampling trees that other workers are trying to reclaim, but also works
	-- well for repair since mobbing is usually beneficial for that. It also helps
	-- to keep workers from advancing too far ahead of your combat units when
	-- reclaiming wreckage, and reclaim also helps to distract workers from following
	-- combat units into the enemy's base trying to repair them.

	-- If you want to change the assignment behavior, the stuff below is what you should edit.
	-- Note that cost represents a distance, which is why cost modifiers use addition,
	-- and the 'magic constants' for that were chosen based on typical map scaling.
	-- Metal cost for "expensive" jobs is also based on Zero-K scaling, so you may want to adjust that if porting.
	-- FindCheapestJob() always chooses the shortest apparent distance, so smaller cost values mean higher priority.

	local cost
	local unitDef = nil
	local unitDefID
	if job.id < 0 then
		unitDefID = abs(job.id)
		unitDef = UnitDefs[unitDefID]
	end
	local metalCost = false

	if job.id < 0 then -- for build jobs, get the metal cost
		metalCost = unitDef.metalCost
	end

	if costMod == 1 then -- for starting new jobs
		if (metalCost and metalCost > 300) then -- for expensive jobs
			cost = (distance/sqrt(sqrt(distance))) + 400
		elseif job.id == CMD_RECLAIM then -- for reclaim
			cost = distance + 400
		elseif job.id == CMD_REPAIR then -- for repair
			if job.target then
				unitDef = UnitDefs[spGetUnitDefID(job.target)]
				if unitDef.isImmobile and unitDef.reloadTime > 0 then -- repair orders for porc should be high prio.
					cost = distance - 150
				else
					cost = distance + 400
				end
			else
				cost = distance + 400
			end
		elseif (unitDef and unitDef.reloadTime > 0) or job.id == CMD_RESURRECT then -- for small defenses and resurrect
			cost = distance - 150
		elseif unitDef and (unitDefID == Solar_ID or unitDefID == Wind_ID) then -- for small energy
			cost = distance + 100
		else -- for resurrect and all other small build jobs
			cost = distance
		end
	else -- for assisting other workers
		if (metalCost and metalCost > 300) or job.id == CMD_RESURRECT then -- for expensive buildings and resurrect
			cost = (distance/2) + (200 * (costMod - 2))
		elseif unitDef and (unitDefID == Caretaker_ID or unitDef.reloadTime > 0) then -- for small defenses and caretakers, allow up to two workers before increasing cost
			cost = distance - 150 + (800 * (costMod - 2))
		elseif job.id == CMD_REPAIR then -- for repair
			if job.target then
				unitDef = UnitDefs[spGetUnitDefID(job.target)]
				if unitDef.isImmobile and unitDef.reloadTime > 0 then -- repair orders for porc should be high prio.
					cost = distance - 150 + (800 * (costMod - 2))
				else
					cost = distance + (200 * costMod)
				end
			else
				cost = distance + (200 * costMod)
			end
		elseif job.id == CMD_REPAIR or job.id == CMD_RECLAIM then -- for reclaim
			cost = distance + (200 * costMod)
		else -- for all other small build jobs
			cost = distance + (600 * costMod)
		end
	end
	return cost
end

-- This function implements the 'flat' cost model for assigning jobs.
function FlatCost(unitID, hash, ux, uz, jx, jz)
	local job = buildQueue[hash]
	local distance = Distance(ux, uz, jx, jz) -- the distance between our worker and job

	local costMod = 1 -- our cost modifier, the number of other units assigned to the same job + 1.

	-- note we only count workers that are roughly closer/equal distance to the job,
	-- so that can achieve both "find the job closest to worker x" and "find the worker closest to their job"
	-- at the same time. You probably should not change this, since it accounts for a lot of edge cases
	-- but does not directly determine the behavior.
	for unit,_ in pairs(job.assignedUnits) do -- for all units that have been recorded as assigned to this job
		if ( unitID ~= unit) and spValidUnitID(unit) then -- excluding our current worker.
			local ix, _, iz = spGetUnitPosition(unit)
			local idist = Distance(ix, iz, jx, jz)
			local rdist = max(distance, 200) -- round distance up to 200, to equalize priority at small distances
			local deltadist = abs(idist - distance) -- calculate the absolute difference in distance, for considering large distances
			if idist < rdist or (distance > 500 and deltadist < 500) then -- and for each one that is rounded closer/equal-dist to the job vs our worker, we increment our cost weight.
				costMod = costMod + 1 -- this way we naturally prioritize closer workers so that more distant workers won't kick us off an otherwise efficient job.
			end
		end
	end

	-- The goal of the flat cost model is to provide consistent behavior that is easily directed
	-- by the player's actions.

	-- Repair, reclaim and resurrect are the same as for intellicost.

	-- All build jobs are cost=distance for starting new jobs.

	-- Expensive jobs have no mobbing penalty, while small defenses
	-- allow up to 2 workers per job before the cost increases.

	-- all other small jobs have a high penalty for assisting.

	-- If you want to change the assignment behavior, the stuff below is what you should edit.
	-- Note that cost represents a distance, which is why cost modifiers use addition,
	-- and the 'magic constants' for that were chosen based on typical map scaling.
	-- Metal cost for "expensive" jobs is also based on Zero-K scaling, so you may want to adjust that if porting.
	-- FindCheapestJob() always chooses the shortest apparent distance, so smaller cost values mean higher priority.

	local cost
	local unitDef = nil
	if job.id < 0 then
		unitDef = UnitDefs[abs(job.id)]
	end
	local metalCost = false

	if job.id < 0 then -- for build jobs, get the metal cost
		metalCost = unitDef.metalCost
	end

	if costMod == 1 then -- for starting new jobs
		if job.id == CMD_REPAIR or job.id == CMD_RECLAIM then -- for repair and reclaim
			cost = distance + 400
		else -- for everything else
			cost = distance
		end
	else -- for assisting other workers
		if (metalCost and metalCost > 300) or job.id == CMD_RESURRECT then -- for expensive jobs and resurrect, no mobbing penalty
			cost = distance
		elseif unitDef and unitDef.reloadTime > 0 then -- for small defenses, allow up to two workers before increasing cost
			cost = distance + (800 * (costMod - 2))
		elseif job.id == CMD_REPAIR or job.id == CMD_RECLAIM then -- for repair and reclaim
			cost = distance + (200 * costMod)
		else
			cost = distance + (600 * costMod) -- for all other jobs, assist is expensive
		end
	end
	return cost
end

-- This function checks if our group includes a unit that can resurrect
function CheckForRes()
	hasRes = false -- check whether the player has any units that can res
	for unitID, _ in pairs(includedBuilders) do
		local udid = spGetUnitDefID(unitID)
		if UnitDefs[udid].canResurrect then
			hasRes = true
			break
		end
	end
end

-- This function updates area commands and captures individual targets as they fall into LOS.
function UpdateAreaCommands()
	for _, cmd in pairs(areaCmdList) do -- update area commands as new targets fall into LOS
		SplitAreaCommand(cmd.id, cmd.x, cmd.z, cmd.r)
	end
end

-- This function splits area repair/reclaim/resurrect commands into single-target commands so that we can assign workers to them more efficiently.
function SplitAreaCommand(id, x, z, r)
	if id == CMD_REPAIR then -- for repair commands
		local unitList = spGetUnitsInCylinder(x, z, r*1.1)
		for i=1, #unitList do -- for all units in our selected area
			local unitID = unitList[i]
			local hp, maxhp, _, _, _ = spGetUnitHealth(unitID)
			if hp ~= maxhp and spIsUnitAllied(unitID) then -- if the unit is damaged, allied, and alive
				local myCmd = {id=id, target=unitID, assignedUnits={}}
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					-- note we don't cache pathing for repair jobs, since they may target mobile units with varying pathing types
				end
			end
		end
	elseif id == CMD_RECLAIM then -- else for reclaim
		local featureList = spGetFeaturesInCylinder(x, z, r*1.1)
		for i=1, #featureList do
			local featureID = featureList[i]
			local fdef = spGetFeatureDefID(featureID)
			if FeatureDefs[fdef].reclaimable then -- if it's reclaimable
				local target = featureID + Game.maxUnits -- convert FeatureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=id, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end
			end
		end
	else -- else for resurrect
		local featureList = spGetFeaturesInCylinder(x, z, r*1.1)
		for i=1, #featureList do -- for each feature in our selection area
			local featureID = featureList[i]
			local fdef = spGetFeatureDefID(featureID)
			local thisfeature = FeatureDefs[fdef]
			if string.match(thisfeature["tooltip"], "reck") then -- if it's resurrectable
				local target = featureID + Game.maxUnits -- convert featureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=id, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end
			elseif FeatureDefs[fdef].reclaimable and options.autoConvertRes.value then -- otherwise if it's reclaimable, and res-conversion is enabled convert to a reclaim order
				local target = featureID + Game.maxUnits -- convert featureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=CMD_RECLAIM, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end
			end
		end
	end
end

-- This function implements specific-unit reclaim
function ReclaimSpecificUnit(unitDefID, x, z, r, shift)
	local targets = spGetUnitsInCylinder(x, z, r)

	for i=1, #targets do -- identify all the intended targets and add them to the queue
		local target = targets[i]
		if spGetUnitDefID(target) == unitDefID and spGetUnitTeam(target) == myTeamID then -- if the unit is ours and of the specified type
		-- note: the "is ours" part can be removed for games that allow reclaiming the enemy
			local myCmd = {id=CMD_RECLAIM, target=target, assignedUnits={}}
			local hash = BuildHash(myCmd)
			if not buildQueue[hash] then -- build a new command and add it to the queue if it isn't already
				buildQueue[hash] = myCmd
			end
		end
	end
end

-- This function double checks units marked idle to ensure that they actually don't have any commands, then officially marks them idle if not.
function CheckIdlers()
	for i=1, #idlers do
		local unitID = idlers[i]
		if includedBuilders[unitID] then -- we need to ensure that the unit hasn't died or left the group since it went idle, because this check is deferred
			-- we need to check that the unit's command queue is empty, because other gadgets may invoke UnitIdle erroneously.
			-- if there's a command on the queue, do nothing and let it be removed from the idle list.
			if spGetCommandQueue(unitID, 0) == 0 then
				UnassignWorker(nil, unitID, commandType.idle) -- then mark it as idle
				if newBuilders[unitID] then -- for new units that have just been added and finished following their constructor separator orders.
					newBuilders[unitID] = nil
					GiveWorkToUnit(unitID)
				else
					movingUnits[unitID] = nil
					if busyUnits[unitID] then -- if the worker is also still on our busy list
						local key = busyUnits[unitID]
						if areaCmdList[key] then -- if it was an area command
							areaCmdList[key] = nil -- remove it from the area update list
							StopAnyWorker(key) -- remove the job from the queue, since UnitIdle is the only way to tell completeness for area jobs.
							busyUnits[unitID] = nil
						end
					end
				end
			end
		end
	end
	table.clear(idlers) -- clear the idle list, since we've processed it.
	idleCheck = false -- reset the flag
end

-- this function checks units that are on commandType.mov and unsticks them if they have been moving for more than 5 seconds.
function CheckMovingUnits()
	for unitID, lastMovFrame in pairs(movingUnits) do
		if spValidUnitID(unitID) and spIsUnitAllied(unitID) and not spUnitIsDead(unitID) then -- sanity check
			if includedBuilders[unitID].cmdtype == commandType.mov and frame - lastMovFrame > 150 then
				local x,y,z = spGetUnitPosition(unitID)
				local dx, _, dz = spGetUnitDirection(unitID)
				dx = dx*-125
				dz = dz*-125
				spGiveOrderToUnit(unitID, CMD_RAW_MOVE, {x+dx, y, z+dz}, 0) -- move it in the opposite direction it was facing.
				movingUnits[unitID] = frame
			elseif includedBuilders[unitID].cmdtype == commandType.ckn and frame - lastMovFrame > 600 then
				spGiveOrderToUnit(unitID, CMD_REMOVE, {CMD_RAW_MOVE}, CMD_OPT_ALT) -- remove the current order
				-- note: options "alt" with CMD_REMOVE tells it to use params as command ids, which is what we want.
				spGiveOrderToUnit(unitID, CMD_STOP, EMPTY_TABLE, 0) -- and replace it with a stop order
				UnassignWorker(nil, unitID, commandType.idle)
			end
		else -- for units that are actually dead, etc.
			movingUnits[unitID] = nil
		end
	end
end

--This function captures res/reclaim targets near the player's base/workers.
function CleanWrecks()
	local featureList = spGetAllFeatures() -- returns all features in LOS, as well as all map features, which we ignore here because they may cause units to suicide into enemy territory.

	if hasRes and options.autoConvertRes.value then
		for i=1, #featureList do
			local featureID = featureList[i]
			local fdef = spGetFeatureDefID(featureID)
			local thisfeature = FeatureDefs[fdef]
			if string.match(thisfeature["tooltip"], "reck") then -- if it's resurrectable
				local target = featureID + Game.maxUnits -- convert featureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=CMD_RESURRECT, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue) -- and to prevent redundant pathing calculations
				end
			elseif string.match(thisfeature["tooltip"], "ebris") or string.match(thisfeature["tooltip"], "Egg") then -- otherwise if it's a reclaimable wreck
				local target = featureID + Game.maxUnits -- convert featureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=CMD_RECLAIM, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end
			end
		end
	else
		for i=1, #featureList do
			local featureID = featureList[i]
			local fdef = spGetFeatureDefID(featureID)
			local thisfeature = FeatureDefs[fdef]

			if string.match(thisfeature["tooltip"], "ebris") or string.match(thisfeature["tooltip"], "Egg") or string.match(thisfeature["tooltip"], "reck") then -- if it's a non-map-feature reclaimable
				local target = featureID + Game.maxUnits -- convert featureID to absoluteID for spGiveOrderToUnit
				local tx, ty, tz = spGetFeaturePosition(featureID)
				local myCmd = {id=CMD_RECLAIM, target=target, x=tx, y=ty, z=tz, assignedUnits={}} -- construct a new command
				local hash = BuildHash(myCmd)
				if not buildQueue[hash] then -- if the job isn't already on the queue, add it.
					buildQueue[hash] = myCmd -- note: this is to prevent assignedUnits from being invalidated
					UpdateOneJobPathing(hash, includedBuilders, buildQueue)
				end
			end
		end
	end
end

-- ZK-Specific: Adds repair commands for 'terraunits'
function CaptureTF()
	local teamUnits = spGetTeamUnits(myTeamID) -- get all of the player's units
	for i=1, #teamUnits do
		local unitID = teamUnits[i]
		local unitDID = spGetUnitDefID(unitID)
		if unitDID == Terraunit_ID then -- identify 'terraunits'
			local myCmd = {id=CMD_REPAIR, target=unitID, assignedUnits={}}
			local hash = BuildHash(myCmd)
			if not buildQueue[hash] then -- add repair jobs for them if they're not already on the queue
				buildQueue[hash] = myCmd
			end
		end
	end
end

-- This function removes dead/captured constructors from includedBuilders, needed because Spring calls widget:GameFrame before anything else.
function CleanBuilders()
	for unitID,_ in pairs(includedBuilders) do
		if not spValidUnitID(unitID) or spUnitIsDead(unitID) or spGetUnitTeam(unitID) ~= myTeamID then
			-- if a unit does not exist, is dead, or no longer belongs to our team..
			-- remove the unit from the list of constructors
			UnassignWorker(nil, unitID, nil)
		end
	end
end

-- This function removes workers from the busy list in the case that the job the worker is assigned to does not actually exist.
-- It is unclear why this happens, but it is known to cause crashes.
function CleanBusy()
	for unitID, key in pairs(busyUnits) do
		if not buildQueue[key] then
			Spring.Echo("GBC: A busy unit was found with a nonexistent job: " .. key)
			busyUnits[unitID] = nil
		end
	end
end

-- This function removes duplicate orders, processes cancel requests, and handles blocked builds. Returns true when a job site is clean or cleanable, false otherwise.
function CleanOrders(cmd, isNew)
	local isClear = true
	local hash = BuildHash(cmd)
	if cmd.id < 0 then -- for build orders
		local isNano = false
		local isObstructed = false

		local blockageType = {
			obstructed = 0, --also applies to blocked by another structure
			mobiles = 1,
			free = 2
		}


		local cmdID = abs(cmd.id)
		local cx = cmd.x
		local cy = cmd.y
		local cz = cmd.z
		local ch = cmd.h -- building facing

		local xSize, zSize = GetBuildingSize(cmdID, ch)

		local canBuildThisThere,_ = spTestBuildOrder(cmdID,cx,cy,cz,ch) --check if build site is blocked by buildings & terrain

		if canBuildThisThere ~= blockageType.free then -- if our job is not obstructed by anything, do nothing, leave isClear set to true
			local r = ( sqrt(xSize^2+zSize^2) /2 )+75 -- convert the rectangular diagonal into a radius, buffer it for increased reliability with small buildings.
			local blockingUnits = spGetUnitsInCylinder(cx+(xSize/2), cz+(zSize/2), r)
			for i=1, #blockingUnits do
				local blockerID = blockingUnits[i]
				local blockerDefID = spGetUnitDefID(blockerID)
				if blockerDefID == cmdID and myTeamID == spGetUnitTeam(blockerID) then -- if the blocker matches the building we're trying to build, and is ours
					local _,_,nanoframe = spGetUnitIsStunned(blockerID) -- determine if it's still under construction
					if nanoframe then
						isNano = true -- set isNano to true so that it will not be removed.
					else -- otherwise the job is finished, and we should garbage collect activeJobs
						activeJobs[blockerID] = nil -- note this only stops a tiny space leak should a free starting fac be added to the queue
						-- but it was cheap, so whatever.
					end
				elseif canBuildThisThere == blockageType.mobiles and includedBuilders[blockerID] and UnitDefs[blockerDefID].moveDef.id and (includedBuilders[blockerID].cmdtype == commandType.idle or includedBuilders[blockerID].cmdtype == commandType.buildQueue) and next(cmd.assignedUnits) then
				-- if blocked by a mobile unit, and it's one of our constructors, and not a flying unit, and it's not under direct orders, and there's actually a worker assigned to the job...
					local x,y,z = spGetUnitPosition(blockerID)
					local dx, dz = GetNormalizedDirection(cx, cz, x, z)
					dx = dx*75
					dz = dz*75
					spGiveOrderToUnit(blockerID, CMD_RAW_MOVE, {x+dx, y, z+dz}, 0) -- move it out of the way
					UnassignWorker(nil, blockerID, commandType.mov) -- and mark it with a special state so the move order doesn't get clobbered
					movingUnits[blockerID] = frame
				end
			end

			if canBuildThisThere == blockageType.obstructed and not isNano then -- terrain or other un-clearable obstruction is blocking, mark as obstructed.
					isObstructed = true
			end

			if isObstructed and not isNano then -- note, we need to wait until ALL obstructions have been accounted for before cleaning up blocked jobs, or else we may not correctly identify the nanoframe if it's the main obstructor.
				if buildQueue[hash] then
					StopAnyWorker(hash)
				end
				isClear = false
			end
		end

		if isNew and isClear then -- if the job we're checking is new and the construction site is clear, then we need to check for overlap with existing jobs and remove any that are in the way.
			for key,qcmd in pairs(buildQueue) do
				if qcmd.id < 0 then -- if the command we're looking at is actually a build order
					local x, z, h = qcmd.x, qcmd.z, qcmd.h
					local aqcmd = abs(qcmd.id)

					local xSize_queue, zSize_queue = GetBuildingSize(aqcmd, h)

					local minTolerance = xSize_queue + xSize -- check minimum tolerance in x direction
					local axisDist = abs (x - cx) -- check actual separation in x direction
					if axisDist < minTolerance then -- if too close in x direction
						minTolerance = zSize_queue + zSize -- check minimum tolerance in z direction
						axisDist = abs (z - cz) -- check actual separation in z direction
						if axisDist < minTolerance then -- if too close in z direction
							-- then there is overlap and we should remove the old job from the queue.
							StopAnyWorker(key)
							isClear = false
						end
					end
				end
			end
		end
	elseif cmd.target then -- for repair, reclaim and resurrect orders that are not area orders
		if cmd.id == CMD_REPAIR then -- for repair orders
			local target = cmd.target
			local good = false

			if spValidUnitID(target) and spIsUnitAllied(target) and not spUnitIsDead(target) then -- if the unit still exists, and hasn't been captured
				local hp, maxhp, _, _, _= spGetUnitHealth(target) -- get the unit hp
				local _,_,isNano = spGetUnitIsStunned(target) -- and determine if it's still under construction (note: this is an annoying edge case)
				if hp ~= maxhp or isNano then -- if our target is still damaged or under construction
					good = true
				end
			end
			if not good then -- if our target is no longer valid, or has full hp
				StopAnyWorker(hash)
				isClear = false
			end
		else -- for reclaim and resurrect orders
			local target = cmd.target
			local good = false

			if hasRes then
				if cmd.id == CMD_RESURRECT then -- for resurrect, check for conflicting reclaim orders, and remove them
					local myCmd = {id=CMD_RECLAIM, target=target}
					local xhash = BuildHash(myCmd)
					if buildQueue[xhash] then
						StopAnyWorker(xhash)
						buildQueue[xhash] = nil
					end
				end
			elseif cmd.id == CMD_RESURRECT then -- otherwise if there are no units that can resurrect in our group, remove res orders
				StopAnyWorker(hash)
				return false
			end

			if target >= Game.maxUnits then -- if the target is a feature, ex wreckage
				local featureID = target - Game.maxUnits
				if spValidFeatureID(featureID) then -- if the feature still exists, then it hasn't finished being reclaimed or resurrected
					good = true
				end
			else -- if the target is a unit
				if spValidUnitID(target) and not spUnitIsDead(target) then -- if the unit still exists, then it hasn't been reclaimed fully yet
					good = true
				end
			end
			if not good then -- if our target no longer exists, ie fully reclaimed or resurrected
				StopAnyWorker(hash)
				isClear = false
			end
		end
	end
	return isClear
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper Functions ------------------------------------------------------------
--[[
HOW THIS WORKS:
	RemoveJobs()
		Takes an area select as input, and removes any job from the queue that falls within it. Used by the job
		removal tool.
	Distance()
		Simple 2D distance calculation.
	BuildHash()
		Takes a command (formatted for buildQueue) as input, and returns a unique identifier
		to use as a hash table key. Allows duplicate jobs to be easily identified, and to easily
		check for the presence of any arbitrary job in buildQueue.
	StopAnyWorker()
		Takes a key to buildQueue as input, stops all workers moving towards a given job, removes them from the relevant lists, and marks
		them idle if not under direct orders. Called when jobs are finished, cancelled, or otherwise
		invalidated.
--]]

-- This function implements area removal for GBC jobs.
function RemoveJobs(x, z, r)
	local _
	local rSq = r*r
	for key, cmd in pairs(buildQueue) do
		local inRadius = false

		if cmd.id < 0 then -- for build jobs
			local cmdID = abs(cmd.id)
			local cx = cmd.x
			local cz = cmd.z
			local ch = cmd.h -- building facing
			local xSize, zSize = GetBuildingSize(cmdID, ch)

			 -- get the distances to the four corner vertices of the building footprint
			local dist1 = DistanceSq(x, z, cx, cz)
			local dist2 = DistanceSq(x, z, cx+xSize, cz)
			local dist3 = DistanceSq(x, z, cx, cz+zSize)
			local dist4 = DistanceSq(x, z, cx+xSize, cz+zSize)

			if dist1 < rSq or dist2 < rSq or dist3 < rSq or dist4 < rSq then -- if any of the corners falls within the radius, then mark the job for removal
				inRadius = true
			end
		elseif cmd.x then -- for area reclaim/repair/resurrect
			local jdist = DistanceSq(x, z, cmd.x, cmd.z)
			if jdist < rSq then
				inRadius = true
			end
		else -- for single-target repair/reclaim/resurrect
			local jx, jz
			local jdist
			local target = cmd.target
			if target >= Game.maxUnits and spValidFeatureID(target-Game.maxUnits) then -- note wrecks and things become invalid/nil when outside of LOS, which we need to check for
				jx, _, jz = spGetFeaturePosition(target-Game.maxUnits)
				jdist = DistanceSq(x, z, jx, jz)
				if jdist < rSq then
					inRadius = true
				end
			elseif target < Game.maxUnits and spValidUnitID(target)then
				jx, _, jz = spGetUnitPosition(target)
				jdist = DistanceSq(x, z, jx, jz)
				if jdist < rSq then
					inRadius = true
					local udid = spGetUnitDefID(target)
					if udid == Terraunit_ID then -- if the target was a 'terraunit', self-destruct it
						spGiveOrderToUnit(target, CMD_SELFD, EMPTY_TABLE, 0)
					end
				end
			end
		end
		if inRadius then -- if the job was inside of our circle
			StopAnyWorker(key) -- release any workers assigned to the job and remove it from the queue
			areaCmdList[key] = nil -- and from area commands
		end
	end
end

function Distance(x1,z1,x2,z2)
	local dist = sqrt(DistanceSq(x1,z1,x2,z2))
	return dist
end

function DistanceSq(x1,z1,x2,z2)
	local dx, dz = x1-x2, z1-z2
	local distSq = dx*dx+dz*dz
	return distSq
end

-- Produces a normalized direction from two points.
function GetNormalizedDirection(x1, z1, x2, z2)
	local x = x2 - x1
	local z = z2 - z1
	local d = sqrt((x*x) + (z*z))

	x = x/d
	z = z/d
	return x, z
end

--  Generate unique key value for each command using its parameters.
--  Much easier than expected once I learned Lua can use *anything* for a key.
function BuildHash(myCmd)
	if myCmd.id < 0 then -- for build orders
		return myCmd.id .. "@" .. myCmd.x .. "x" .. myCmd.z
	elseif myCmd.target then -- for single-target repair/reclaim/ressurect
		return myCmd.id .. "@" .. myCmd.target
	else -- for area repair/reclaim/resurrect
		return myCmd.id .. "@" .. myCmd.x .. "x" .. myCmd.z .. "z" .. myCmd.r .. "r" .. tostring(myCmd.alt)
	end
end

-- Tell any worker for construction of "buildQueue[key]" to stop the job immediately
-- Used only when jobs are known to be finished or cancelled
function StopAnyWorker(key)
	-- debugging crap
	if not buildQueue[key] then
		Spring.Echo("GBC: Fatal error, tried to stop workers for a nonexisting job:" .. key)
	end
	-- end debugging crap
	local myCmd = buildQueue[key]
	for unit,_ in pairs(myCmd.assignedUnits) do
		if includedBuilders[unit].cmdtype == commandType.buildQueue then -- for units that are under GBC control
			spGiveOrderToUnit(unit, CMD_REMOVE, {myCmd.id}, CMD_OPT_ALT) -- remove the current order
			-- note: options "alt" with CMD_REMOVE tells it to use params as command ids, which is what we want.
			spGiveOrderToUnit(unit, CMD_STOP, EMPTY_TABLE, 0) -- and replace it with a stop order
			-- note: giving a unit a stop order does not automatically cancel other orders as it does when a player uses it, which is why we also have to use CMD_REMOVE here.
			UnassignWorker(nil, unit, commandType.idle) -- mark them as idle
		else -- otherwise for units under drec
			busyUnits[unit] = nil -- we remove the unit from busyUnits and let Spring handle it until it goes idle on its own.
		end
	end
	buildQueue[key] = nil
end

-- Marks a worker as assigned to one of our jobs.
-- cmdtype is commandType.drec when this assignment came from a direct order.
-- cmdtype is commandType.buildQueue when this assignment was automatic.
function AssignWorker(key, unitID, cmdtype)
	UnassignWorker(nil, unitID, cmdtype)
	busyUnits[unitID] = key
	buildQueue[key].assignedUnits[unitID] = true
end

-- Marks a worker as not assigned to one of our jobs.
-- when cmdtype is nil, removes all state related to the unit.
function UnassignWorker(key, unitID, cmdtype)
	movingUnits[unitID] = nil
	if cmdtype == commandType.idle then
		reassignedUnits[unitID] = nil -- Remove them from our reassigned units list, so that they will be immediately processed
	end
	if not cmdtype then
		-- Destroy ALL state tracking this builder (except allBuilders?)
		includedBuilders[unitID] = nil
		-- We don't remove from idlers, since CheckIdlers explicitly handles removal via includedBuilders check.
		lastCommand[unitID] = nil
		-- allBuilders is handled separately. While often this branch is taken
		--   when a builder is destroyed or otherwise removed, we can also
		--   expressly ask for a builder to not be under GBC control.
		-- newBuilders retains units only very briefly.
		-- However, CheckIdlers only processes a unit if includedBuilders is not nil.
		-- This would leak a very small amount every time a builder was killed
		-- almost immediately after being created.
		newBuilders[unitID] = nil
		-- reassignedUnits resets itself regularly
	else
		includedBuilders[unitID].cmdtype = cmdtype
	end
	if not key then key = busyUnits[unitID] end
	if not key then return end
	busyUnits[unitID] = nil
	buildQueue[key].assignedUnits[unitID] = nil
end

-- returns: xSize, zSize
function GetBuildingSize(unitDefID, heading)
	local unitDef = UnitDefs[unitDefID]
	if heading == 0 or heading == 2 then --get building facing for queued jobs. Reference: unit_prevent_lab_hax.lua by googlefrog
		return unitDef.xsize*4, unitDef.zsize*4
	else
		return unitDef.zsize*4, unitDef.xsize*4
	end
end
