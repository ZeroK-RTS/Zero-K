-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	corcrw = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = "Carpet Bomb", tooltip = "Drop a huge number of bombs in a circle under the Krow", weaponToReload = 3, texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	hoverdepthcharge = {
		{ functionToCall = "ShootDepthcharge", reloadTime = 256, name = "Drop Depthcharge", tooltip = "Drops a depthchage.", weaponToReload = 1, texture = "LuaUI/Images/Commands/Bold/dgun.png",},
	},
	armtick = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	corroach = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	corsktl = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	blastwing = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	--[[
	logkoda = {
		{ functionToCall = "FlameTrail", reloadTime = 850, name = "Flame Trail", tooltip = "Leave a path of flame in your wake", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--]]
	fighter = {
		{ functionToCall = "Sprint", reloadTime = 850, name = "Speed Boost", tooltip = "Speed boost (5x for 1 second)", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--corawac = {
	--	{ functionToCall = "Cloak", reloadTime = 600, name = "Temp Cloak", tooltip = "Cloaks for 5 seconds", useSpecialReloadFrame = true},
	--},
	corbtrans = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", tooltip = "Eject cargo!", useSpecialReloadFrame = true,},
	},
	corvalk = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", tooltip = "Eject cargo!", useSpecialReloadFrame = true,},
	},		
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then 
		oneClickWepDefs[UnitDefNames[name].id] = data
	end
end

return oneClickWepDefs