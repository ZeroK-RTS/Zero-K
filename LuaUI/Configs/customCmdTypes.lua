-- This is the list of name ("action name") related to unit command. This name won't work using command line (eg: /fight, won't activate FIGHT command) but it can be binded to a key (eg: /bind f fight, will activate FIGHT when f is pressed)
-- In reverse, one can use Spring.GetActionHotkey(name) to get the key binded to this name.
-- This table is used in Epicmenu for hotkey management.
local custom_cmd_actions = {
	-- cmdTypes are:
	-- 1: Targeted commands (eg attack)
	-- 2: State commands (eg on/off). Parameter 'count' creates actions to set a particular state
	-- 3: Instant commands (eg self-d)
	
	--SPRING COMMANDS
	selfd = {cmdType = 3, name = "Self Destruct"},
	attack = {cmdType = 1, name = "Force Fire"},
	stop = {cmdType = 3, name = "Stop"},
	fight = {cmdType = 1, name = "Attack Move"},
	guard = {cmdType = 1, name = "Guard"},
	move = {cmdType = 1, name = "Move"},
	patrol = {cmdType = 1, name = "Patrol"},
	wait = {cmdType = 3, name = "Wait"},
	repair = {cmdType = 1, name = "Repair"},
	reclaim = {cmdType = 1, name = "Reclaim"},
	resurrect = {cmdType = 1, name = "Resurrect"},
	manualfire = {cmdType = 1, name = "Fire Special Weapon"},
	loadunits = {cmdType = 1, name = "Load Units"},
	unloadunits = {cmdType = 1, name = "Unload Units"},
	areaattack = {cmdType = 1, name = "Area Attack"},
	
	rawmove = {cmdType = 1, name = "Move"},
	
	-- states
	onoff = {cmdType = 2, name = "On/Off", count = 2},
	['repeat'] = {cmdType = 2, name = "Repeat", count = 2},
	wantcloak = {cmdType = 2, name = "Cloak", count = 2},
	movestate = {cmdType = 2, name = "Move State", count = 3},
	firestate = {cmdType = 2, name = "Fire State", count = 3},
	idlemode = {cmdType = 2, name = "Land/Fly", count = 2},
	autorepairlevel = {cmdType = 2, name = "Air Retreat Threshold", count = 4},
	preventoverkill = {cmdType = 2, name = "Prevent Overkill", count = 2},
	
	      
	--CUSTOM COMMANDS
	sethaven = {cmdType = 1, name = "Add Retreat Zone"},
	--build = {cmdType = 1, name = "--build"},
	areamex = {cmdType = 1, name = "Area Mex"},
	mine = {cmdType = 1, name = "Mine"},
	build = {cmdType = 1, name = "Build"},
	jump = {cmdType = 1, name = "Jump"},
	find_pad = {cmdType = 3, name = "Return to Airbase"},
	embark = {cmdType = 3, name = "Embark"},
	disembark = {cmdType = 3, name = "Disembark"},
	loadselected = {cmdType = 3, name = "Load Selected Units"},
	oneclickwep = {cmdType = 3, name = "Activate Special"},
	settarget = {cmdType = 1, name = "Set Target"},
	settargetcircle = {cmdType = 1, name = "Set Target (circle selection)"},
	canceltarget = {cmdType = 3, name = "Cancel Target"},
	setferry = {cmdType = 1, name = "Create Ferry Route"}, 
	setfirezone = {cmdType = 1, name = "Set Newton Fire Zone"},
	cancelfirezone = {cmdType = 3, name = "Cancel Newton Fire Zone"},
	radialmenu = {cmdType = 3, name = "Open Radial Build Menu"},
	placebeacon = {cmdType = 1, name = "Place Teleport Beacon"},
	recalldrones = {cmdType = 3, name = "Recall Drones to Carrier"},
	buildprev = {cmdType = 1, name = "Build Previous"},
	areaguard = {cmdType = 1, name = "Area Guard"},
	dropflag = {cmdType = 3, name = "Drop Flag"},
	upgradecomm = {cmdType = 3, name = "Upgrade Commander"},
	upgradecommstop  = {cmdType = 3, name = "Stop Upgrade Commander"},
	stopproduction  = {cmdType = 3, name = "Stop Factory Production"},
	globalbuildcancel  = {cmdType = 1, name = "Cancel Global Build Tasks"},
	
	-- terraform
	rampground = {cmdType = 1, name = "Terraform Ramp"},
	levelground = {cmdType = 1, name = "Terraform Level"},
	raiseground = {cmdType = 1, name = "Terraform Raise"},
	smoothground = {cmdType = 1, name = "Terraform Smooth"},
	restoreground = {cmdType = 1, name = "Terraform Restore"},
	--terraform_internal = {cmdType = 1, name = "--terraform_internal"},
	
	resetfire = {cmdType = 3, name = "Reset Fire"},
	resetmove = {cmdType = 3, name = "Reset Move"},
	
	--states
--	stealth = {cmdType = 2, name = "stealth"}, --no longer applicable
	cloak_shield = {cmdType = 2, name = "Area Cloaker", count = 2},
	retreat = {cmdType = 2, name = "Retreat Threshold", count = 4},
	['luaui noretreat'] = {cmdType = 2, name = "luaui noretreat"},
	priority = {cmdType = 2, name = "Construction Priority", count = 3},
	miscpriority = {cmdType = 2, name = "Misc. Priority", count = 3},
	ap_fly_state = {cmdType = 2, name = "Land/Fly", count = 2},
	ap_autorepairlevel = {cmdType = 2, name = "Auto Repair", count = 4},
	floatstate = {cmdType = 2, name = "Float State", count = 3},
	dontfireatradar = {cmdType = 2, name = "Firing at Radar Dots", count = 2},
	antinukezone = {cmdType = 2, name = "Ceasefire Antinuke Zone", count = 2},
	unitai = {cmdType = 2, name = "Unit AI", count = 2},
	selection_rank = {cmdType = 2, name = "Selection Rank", count = 4},
	unit_kill_subordinates = {cmdType = 2, name = "Dominatrix Seppuku", count = 2},
	autoassist = {cmdType = 2, name = "Factory Auto Assist", count = 2},
	airstrafe = {cmdType = 2, name = "Gunship Strafe", count = 2},
	divestate = {cmdType = 2, name = "Raven Dive", count = 4},
	globalbuild = {cmdType = 2, name = "Constructor Global AI", count = 2},
}

-- These actions are created from echoing all actions that appear when all units are selected.
-- See cmd_layout_handler for how to generate these actions.
local usedActions = {
	["stop"] = true,
	["attack"] = true,
	["wait"] = true,
	["timewait"] = true,
	["deathwait"] = true,
	["squadwait"] = true,
	["gatherwait"] = true,
	["selfd"] = true,
	["firestate"] = true,
	["movestate"] = true,
	["repeat"] = true,
	["loadonto"] = true,
	["rawmove"] = true,
	["patrol"] = true,
	["fight"] = true,
	["guard"] = true,
	["areaguard"] = true,
	["orbitdraw"] = true,
	["preventoverkill"] = true,
	["retreat"] = true,
	["unitai"] = true,
	["settarget"] = true,
	["settargetcircle"] = true,
	["canceltarget"] = true,
	["embark"] = true,
	["disembark"] = true,
	["transportto"] = true,
	["onoff"] = true,
	["miscpriority"] = true,
	["manualfire"] = true,
	["repair"] = true,
	["reclaim"] = true,
	["areamex"] = true,
	["priority"] = true,
	["rampground"] = true,
	["levelground"] = true,
	["raiseground"] = true,
	["smoothground"] = true,
	["restoreground"] = true,
	["jump"] = true,
	["idlemode"] = true,
	["areaattack"] = true,
	--["rearm"] = true, -- Not useful to send directly so unbindable to prevent confusion. Right click on pad is better.
	["find_pad"] = true,
	["recalldrones"] = true,
	["divestate"] = true,
	["wantcloak"] = true,
	["oneclickwep"] = true,
	["floatstate"] = true,
	["airstrafe"] = true,
	["dontfireatradar"] = true,
	["stockpile"] = true,
	["trajectory"] = true,
	["cloak_shield"] = true,
	["stopproduction"] = true,
	["resurrect"] = true,
	["loadunits"] = true,
	["unloadunits"] = true,
	["loadselected"] = true,
	["apFlyState"] = true,
	["placebeacon"] = true,
	["morph"] = true,
	--["prevmenu"] = true,
	--["nextmenu"] = true,
	["upgradecomm"] = true,
	["autoassist"] = true,
	["autocalltransport"] = true,
	["setferry"] = true,
	["sethaven"] = true,
	["setfirezone"] = true,
	["cancelfirezone"] = true,
	["selection_rank"] = true,
	
	-- These actions are used, just not by selecting everything with default UI
	["upgradecommstop"] = true,
	["autoeco"] = true,
}

-- Clear unused actions.
for name,_ in pairs(custom_cmd_actions) do
	if not usedActions[name] then
		custom_cmd_actions[name] = nil
	end
end

-- Add toggle-to-particular-state commands
local fullCustomCmdActions = {}
for name, data in pairs(custom_cmd_actions) do
	if data.count then
		for i = 0, data.count-1 do
			fullCustomCmdActions[name .. " " .. i] = {
				cmdType = data.cmdType,
				name = data.name .. ": " .. i,
			}
		end
	end
	fullCustomCmdActions[name] = data
end

return fullCustomCmdActions