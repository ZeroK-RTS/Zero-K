-- This is the list of name ("action name") related to unit command. This name won't work using command line (eg: /fight, won't activate FIGHT command) but it can be binded to a key (eg: /bind f fight, will activate FIGHT when f is pressed)
-- In reverse, one can use Spring.GetActionHotkey(name) to get the key binded to this name.
-- This table is used in Epicmenu for hotkey management.
local custom_cmd_actions = {
	-- cmdTypes are:
	-- 1: Targeted commands (eg attack)
	-- 2: State commands (eg on/off)
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
	
	-- states
	onoff = {cmdType = 2, name = "On/Off"},
	['repeat'] = {cmdType = 2, name = "Repeat"},
	wantcloak = {cmdType = 2, name = "Cloak"},
	movestate = {cmdType = 2, name = "Move State"},
	firestate = {cmdType = 2, name = "Fire State"},
	idlemode = {cmdType = 2, name = "Land/Fly"},
	autorepairlevel = {cmdType = 2, name = "Air Retreat Threshold"},
	preventoverkill = {cmdType = 2, name = "Prevent Overkill"},
	
	      
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
	cloak_shield = {cmdType = 2, name = "Area Cloaker"},
	retreat = {cmdType = 2, name = "Retreat Threshold"},
	['luaui noretreat'] = {cmdType = 2, name = "luaui noretreat"},
	priority = {cmdType = 2, name = "Construction Priority"},
	miscpriority = {cmdType = 2, name = "Misc. Priority"},
	ap_fly_state = {cmdType = 2, name = "Land/Fly"},
	ap_autorepairlevel = {cmdType = 2, name = "Auto Repair"},
	floatstate = {cmdType = 2, name = "Float State"},
	dontfireatradar = {cmdType = 2, name = "Firing at Radar Dots"},
	antinukezone = {cmdType = 2, name = "Ceasefire Antinuke Zone"},
	unitai = {cmdType = 2, name = "Unit AI"},
	unit_kill_subordinates = {cmdType = 2, name = "Dominatrix Seppuku"},
	autoassist = {cmdType = 2, name = "Factory Auto Assist"},	
	airstrafe = {cmdType = 2, name = "Gunship Strafe"},
	divestate = {cmdType = 2, name = "Raven Dive"},
	globalbuild = {cmdType = 2, name = "Constructor Global AI"},
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
	["move"] = true,
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
	["autorepairlevel"] = true,
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
	["setferry"] = true,
	["sethaven"] = true,
	["setfirezone"] = true,
	["cancelfirezone"] = true,
	
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

return custom_cmd_actions