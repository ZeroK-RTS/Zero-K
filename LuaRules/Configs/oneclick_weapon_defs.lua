-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	corcrw = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = "Carpet Bomb", tooltip = "Drop a huge number of bombs in a circle under the Krow", weaponToReload = 3, texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	fighter = {
		{ functionToCall = "Sprint", reloadTime = 850, name = "Speed Boost", tooltip = "Speed boost (5x for 1 second)", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	corawac = {
		{ functionToCall = "Cloak", reloadTime = 600, name = "Temp Cloak", tooltip = "Cloaks for 5 seconds", useSpecialReloadFrame = true},
	},
	
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then oneClickWepDefs[UnitDefNames[name].id] = data	end
end

return oneClickWepDefs