-- This is the list of name ("action name") related to unit command. This name won't work using command line (eg: /fight, won't activate FIGHT command) but it can be binded to a key (eg: /bind f fight, will activate FIGHT when f is pressed)
-- In reverse, one can use Spring.GetActionHotkey(name) to get the key binded to this name.
-- This table is used in Epicmenu for hotkey management.
local custom_cmd_actions = {
	-- states are 2, targeted commands (e.g. attack) are 1, instant commands (e.g. selfd) are 3
	-- can (probably) set to 1 instead of 3 if order doesn't need to be queueable
	--SPRING COMMANDS
	selfd=3,
	attack=1,
	stop=3,
	fight=1,
	guard=1,
	move=1,
	patrol=1,
	wait=3,
	repair=1,
	reclaim=1,
	resurrect=1,
	manualfire=1,
	loadunits=1,
	unloadunits=1,
	areaattack=1,
	
	-- states
	onoff=2,
	['repeat']=2,
	wantcloak=2,
	movestate=2,
	firestate=2,
	idlemode=2,
	autorepairlevel=2,
	preventoverkill = 2,
	
	      
	--CUSTOM COMMANDS
	sethaven=1,
	--build=1,
	areamex=1,
	mine=1,
	build=1,
	jump=1,
	find_pad=3,
	embark=3,
	disembark=3,
	loadselected=3,
	oneclickwep=3,
	settarget=1,
	settargetcircle=1,
	canceltarget=3,
	setferry=1, 
	setfirezone=1,
	cancelfirezone=3,
	radialmenu=3,
	placebeacon=1,
	buildprev=1,
	areaguard=1,
	dropflag=3,
	upgradecomm=3,
	upgradecommstop = 3,
	stopproduction = 3,
	
	-- terraform
	rampground=1,
	levelground=1,
	raiseground=1,
	smoothground=1,
	restoreground=1,
	--terraform_internal=1,
	
	resetfire=3,
	resetmove=3,
	
	--states
--	stealth=2, --no longer applicable
	cloak_shield=2,
	retreat=2,
	['luaui noretreat']=2,
	priority=2,
	miscpriority=2,
	ap_fly_state=2,
	ap_autorepairlevel=2,
	floatstate=2,
	dontfireatradar=2,
	antinukezone=2,
	unitai=2,
	unit_kill_subordinates=2,
	autoassist=2,	
	airstrafe=2,
	divestate=2,
	autoeco=2,
}

return custom_cmd_actions