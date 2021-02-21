-- This is the list of name ("action name") related to unit command. This name won't work using command line (eg: /fight, won't activate FIGHT command) but it can be binded to a key (eg: /bind f fight, will activate FIGHT when f is pressed)
-- In reverse, one can use Spring.GetActionHotkey(name) to get the key binded to this name.
-- This table is used in Epicmenu for hotkey management.

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local custom_cmd_actions = {
	-- cmdTypes are:
	-- 1: Targeted commands (eg attack)
	-- 2: State commands (eg on/off). Parameter 'state' creates actions to set a particular state
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
	timewait = {cmdType = 3, name = "Wait: Timer"},
	deathwait = {cmdType = 3, name = "Wait: Death"},
	squadwait = {cmdType = 3, name = "Wait: Squad"},
	gatherwait = {cmdType = 3, name = "Wait: Gather"},
	repair = {cmdType = 1, name = "Repair"},
	reclaim = {cmdType = 1, name = "Reclaim"},
	resurrect = {cmdType = 1, name = "Resurrect"},
	manualfire = {cmdType = 1, name = "Fire Special Weapon"},
	loadunits = {cmdType = 1, name = "Load Units"},
	unloadunits = {cmdType = 1, name = "Unload Units"},
	areaattack = {cmdType = 1, name = "Area Attack"},

	rawmove = {cmdType = 1, name = "Move"},

	-- states
	wantonoff =       {cmdType = 2, cmdID = CMD_WANT_ONOFF, name = "On/Off", states = {'Off', 'On'}},
	['repeat'] =      {cmdType = 2, cmdID = CMD.REPEAT, name = "Repeat", states = {'Off', 'On'}},
	wantcloak =       {cmdType = 2, cmdID = CMD_WANT_CLOAK, name = "Cloak", states = {'Off', 'On'}},
	movestate =       {cmdType = 2, cmdID = CMD.MOVE_STATE, name = "Move State", states = {'Hold Position', 'Maneuver', 'Roam'}},
	firestate =       {cmdType = 2, cmdID = CMD.FIRE_STATE, name = "Fire State", states = {'Hold Fire', 'Return Fire', 'Fire At Will'}},
	idlemode =        {cmdType = 2, cmdID = CMD.IDLEMODE, name = "Air Idle State", states = {'Land', 'Fly'}},
	autorepairlevel = {cmdType = 2, name = "Air Retreat Threshold", states = {'Off', '30%', '50%', '80%'}},
	preventoverkill = {cmdType = 2, cmdID = CMD_PREVENT_OVERKILL, name = "Prevent Overkill", states = {'Off', 'On'}},
	preventbait     = {cmdType = 2, cmdID = CMD_PREVENT_BAIT, name = "Avoid Bad Targets", states = {'Disabled', '40', '100', '300', '600'}},
	trajectory      = {cmdType = 2, cmdID = CMD.TRAJECTORY, name = "Trajectory", states = {'Low', 'High'}},

	--CUSTOM COMMANDS
	sethaven = {cmdType = 1, name = "Add Retreat Zone"},
	excludeairpad = {cmdType = 1, name = "Exclude an Airpad"},
	--build = {cmdType = 1, name = "--build"},
	areamex = {cmdType = 1, name = "Area Mex"},
	mine = {cmdType = 1, name = "Mine"},
	build = {cmdType = 1, name = "Build"},
	jump = {cmdType = 1, name = "Jump"},
	find_pad = {cmdType = 3, name = "Return to Airbase"},
	exclude_pad = {cmdType = 1, name = "Exclude Airpad"},
	embark = {cmdType = 3, name = "Embark"},
	disembark = {cmdType = 3, name = "Disembark"},
	loadselected = {cmdType = 3, name = "Load Selected Units"},
	oneclickwep = {cmdType = 3, name = "Activate Special"},
	settargetcircle = {cmdType = 1, name = "Set Target"},
	settarget = {cmdType = 1, name = "Set Target (rectangle)"},
	canceltarget = {cmdType = 3, name = "Cancel Target"},
	setferry = {cmdType = 1, name = "Create Ferry Route"},
	setfirezone = {cmdType = 1, name = "Set Newton Fire Zone"},
	cancelfirezone = {cmdType = 3, name = "Cancel Newton Fire Zone"},
	--selectmissiles = {cmdType = 3, name = "Select Missiles"},	-- doesn't seem to appear, maybe it doesn't support widget commands?
	radialmenu = {cmdType = 3, name = "Open Radial Build Menu"},
	placebeacon = {cmdType = 1, name = "Place Lamp"},
	recalldrones = {cmdType = 3, name = "Recall Drones to Carrier"},
	buildprev = {cmdType = 1, name = "Build Previous"},
	areaguard = {cmdType = 1, name = "Area Guard"},
	dropflag = {cmdType = 3, name = "Drop Flag"},
	upgradecomm = {cmdType = 3, name = "Upgrade Commander"},
	upgradecommstop = {cmdType = 3, name = "Stop Upgrade Commander"},
	stopproduction = {cmdType = 3, name = "Stop Factory Production"},
	globalbuildcancel = {cmdType = 1, name = "Cancel Global Build Tasks"},
	evacuate = {cmdType = 3, name = "Evacuate"},
	morph = {cmdType = 3, name = "Morph (and stop morph)"},

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
	cloak_shield =      {cmdType = 2, cmdID = CMD_CLOAK_SHIELD, name = "Area Cloaker", states = {'Off', 'On'}},
	retreat =           {cmdType = 2, cmdID = CMD_RETREAT, name = "Retreat Threshold", states = {'Off', '30%', '65%', '99%'}, actionOverride = {'cancelretreat'}},
	['luaui noretreat'] = {cmdType = 2, name = "luaui noretreat"},
	priority =          {cmdType = 2, cmdID = CMD_PRIORITY, name = "Construction Priority", states = {'Low', 'Normal', 'High'}},
	miscpriority =      {cmdType = 2, cmdID = CMD_MISC_PRIORITY, name = "Misc. Priority", states = {'Low', 'Normal', 'High'}},
	ap_fly_state =      {cmdType = 2, cmdID = CMD_AP_FLY_STATE, name = "Air Idle State", states = {'Land', 'Fly'}},
	ap_autorepairlevel = {cmdType = 2, name = "Auto Repair", states = {'Off', '30%', '50%', '80%'}},
	floatstate =        {cmdType = 2, name = "Float State", states = {'Sink', 'When Shooting', 'Float'}},
	dontfireatradar =   {cmdType = 2, cmdID = CMD_DONT_FIRE_AT_RADAR, name = "Firing at Radar Dots", states = {'Off', 'On'}},
	antinukezone =      {cmdType = 2, name = "Ceasefire Antinuke Zone", states = {'Off', 'On'}},
	unitai =            {cmdType = 2, cmdID = CMD_UNIT_AI, name = "Unit AI", states = {'Off', 'On'}},
	selection_rank =    {cmdType = 2, name = "Selection Rank", states = {'0', '1', '2', '3'}},
	autocalltransport = {cmdType = 2, name = "Auto Call Transport", states = {'Off', 'On'}},
	unit_kill_subordinates = {cmdType = 2, cmdID = CMD_UNIT_KILL_SUBORDINATES, name = "Dominatrix Kill", states = {'Off', 'On'}},
	goostate =     {cmdType = 2, cmdID = CMD_GOO_GATHER, name = "Goo State", states = {'Off', 'When uncloaked', 'On'}},
	disableattack = {cmdType = 2, cmdID = CMD_DISABLE_ATTACK, name = "Allow Attack", states = {'Allowed', 'Blocked'}},
	pushpull =      {cmdType = 2, cmdID = CMD_PUSH_PULL, name = "Impulse Mode", states = {'Pull', 'Push'}},
	autoassist =    {cmdType = 2, cmdID = CMD_FACTORY_GUARD, name = "Factory Auto Assist", states = {'Off', 'On'}},
	airstrafe =     {cmdType = 2, cmdID = CMD_AIR_STRAFE, name = "Gunship Strafe", states = {'Off', 'On'}},
	divestate =     {cmdType = 2, cmdID = CMD_UNIT_BOMBER_DIVE_STATE, name = "Raven Dive", states = {'Never', 'Under Shields', 'For Mobiles', 'Always Low'}},
	globalbuild =   {cmdType = 2, cmdID = CMD_GLOBAL_BUILD, name = "Constructor Global AI", states = {'Off', 'On'}},
	toggledrones =  {cmdType = 2, cmdID = CMD_TOGGLE_DRONES, name = "Drone Construction.", states = {'Off', 'On'}},
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
	["preventbait"] = true,
	["retreat"] = true,
	["unitai"] = true,
	["settarget"] = true,
	["settargetcircle"] = true,
	["canceltarget"] = true,
	["embark"] = true,
	["disembark"] = true,
	["transportto"] = true,
	["wantonoff"] = true,
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
	["toggledrones"] = true,
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
	["exclude_pad"] = true,
	["setfirezone"] = true,
	["cancelfirezone"] = true,
	["selection_rank"] = true,
	["pushpull"] = true,
	["unit_kill_subordinates"] = true,
	["goostate"] = true,

	-- These actions are used, just not by selecting everything with default UI
	["globalbuild"] = true,
	["upgradecommstop"] = true,
	["autoeco"] = true,
	["evacuate"] = true,
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
	if data.states then
		for i = 1, #data.states do
			local cmdName = (data.actionOverride and data.actionOverride[i]) or (name .. " " .. (i-1))
			fullCustomCmdActions[cmdName] = {
				cmdType = data.cmdType,
				name = data.name .. ": set " .. data.states[i],
				setValue = (i - 1),
				cmdID = data.cmdID,
			}
		end
		data.name = data.name .. ": toggle"
	end
	fullCustomCmdActions[name] = data
end

return fullCustomCmdActions
