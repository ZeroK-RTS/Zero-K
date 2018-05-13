-- reloadTime is in seconds

local cmds = {
	[CMD_ONECLICK_WEAPON] = true,
	[CMD_DETONATE] = true,
	[CMD_CANCELTERRA] = true,
	[CMD_SPEEDBOOST] = true,
	[CMD_DROPCARGO] = true,
	[CMD_SELECTCARGO] = true
}

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	terraunit = {
		{ cmdID = CMD_CANCELTERRA, functionToCall = "Detonate", name = "Cancel", action = "cancelterra", tooltip = "Cancel selected terraform units.", texture = "LuaUI/Images/Commands/Bold/cancel.png", partBuilt = true},
	},
	gunshipkrow = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = "Carpet Bomb", tooltip = "Drop Bombs: Drop a huge number of bombs in a circle under the Krow", weaponToReload = 3, texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	hoverdepthcharge = {
		{ functionToCall = "ShootDepthcharge", reloadTime = 256, name = "Drop Depthcharge", tooltip = "Drop Depthcharge: Drops a on the sea surface or ground.", weaponToReload = 1, texture = "LuaUI/Images/Commands/Bold/dgun.png",},
	},
	cloakbomb = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldbomb = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	jumpbomb = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	gunshipbomb = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	amphbomb = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldscout = {
		{ cmdID = CMD_DETONATE, functionToCall = "Detonate", name = "Detonate", action = "detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	bomberdisarm = {
		{ functionToCall = "StartRun", name = "Start Run", tooltip = "Unleash Lightning: Manually activate Thunderbird run.", texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	--[[
	tankraid = {
		{ functionToCall = "FlameTrail", reloadTime = 850, name = "Flame Trail", tooltip = "Leave a path of flame in your wake", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--]]
	planefighter = {
		{ cmdID = CMD_SPEEDBOOST, functionToCall = "Sprint", reloadTime = 850, name = "Speed Boost", action = "speedboost", tooltip = "Speed boost (5x for 1 second)", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--planescout = {
	--	{ functionToCall = "Cloak", reloadTime = 600, name = "Temp Cloak", tooltip = "Cloaks for 5 seconds", useSpecialReloadFrame = true},
	--},
	gunshipheavytrans = {
		{ cmdID = CMD_DROPCARGO, functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", action = "dropcargo", tooltip = "Eject Cargo", useSpecialReloadFrame = true,},
	},
	gunshiptrans = {
		{ cmdID = CMD_DROPCARGO, functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", action = "dropcargo", tooltip = "Eject Cargo", useSpecialReloadFrame = true,},
	},
	
	staticmissilesilo = {
		dummy = true,
		{ cmdID = CMD_SELECTCARGO, functionToCall = nil, name = "Select Missiles", action = "selectcargo", tooltip = "Select missiles", texture = "LuaUI/Images/Commands/Bold/missile.png"},
	},
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then
		for i, ability in ipairs(data) do
			ability.cmdID = ability.cmdID or CMD_ONECLICK_WEAPON
		end
		oneClickWepDefs[UnitDefNames[name].id] = data
	end
end

return oneClickWepDefs, cmds