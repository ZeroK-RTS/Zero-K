-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	terraunit = {
		{ functionToCall = "Detonate", name = WG.Translate("common", "cancel"), tooltip = WG.Translate("interface", "tera_cancel"), texture = "LuaUI/Images/Commands/Bold/cancel.png", partBuilt = true},
	},
	gunshipkrow = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = WG.Translate("interface", "gskrow_dgun"), tooltip = WG.Translate("interface", "gskrow_dgun_tooltip"), weaponToReload = 3, texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	--hoverdepthcharge = {
	--	{ functionToCall = "ShootDepthcharge", reloadTime = 256, name = "Drop Depthcharge", tooltip = "Drop Depthcharge: Drops a on the sea surface or ground.", weaponToReload = 1, texture = "LuaUI/Images/Commands/Bold/dgun.png",},
	--},
	cloakbomb = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"),  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldbomb = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"), texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	jumpbomb = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"),  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	gunshipbomb = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"), texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	amphbomb = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"),  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldscout = {
		{ functionToCall = "Detonate", name = WG.Translate("interface", "walkingbomb_detonate"), tooltip = WG.Translate("interface", "walkingbomb_detonate_tooltip"), texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	bomberdisarm = {
		{ functionToCall = "StartRun", name = WG.Translate("interface", "bombdisarm_run"), tooltip = WG.Translate("interface", "bombdisarm_run_tooltip"), texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	--[[
	tankraid = {
		{ functionToCall = "FlameTrail", reloadTime = 850, name = "Flame Trail", tooltip = "Leave a path of flame in your wake", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--]]
	planefighter = {
		{ functionToCall = "Sprint", reloadTime = 850, name = WG.Translate("interface", "swift_kesselrun"), tooltip = WG.Translate("interface", "swift_kesselrun_tooltip"), useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--planescout = {
	--	{ functionToCall = "Cloak", reloadTime = 600, name = "Temp Cloak", tooltip = "Cloaks for 5 seconds", useSpecialReloadFrame = true},
	--},
	gunshipheavytrans = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = WG.Translate("interface", "transport_eject"), tooltip = WG.Translate("interface", "transport_eject_tooltip"), useSpecialReloadFrame = true,},
	},
	gunshiptrans = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = WG.Translate("interface", "transport_eject"), tooltip = WG.Translate("interface", "transport_eject_tooltip"), useSpecialReloadFrame = true,},
	},
	
	--staticmissilesilo = {
	--	dummy = true,
	--	{ functionToCall = nil, name = "Select Missiles", tooltip = "Select missiles", texture = "LuaUI/Images/Commands/Bold/missile.png"},
	--},
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then
		oneClickWepDefs[UnitDefNames[name].id] = data
	end
end

return oneClickWepDefs
