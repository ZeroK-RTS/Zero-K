-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	corcrw = {
		{ functionToCall = "ClusterBomb", reloadTime = 569, name = "Cluster Bomb", tooltip = "Drop a huge number of bombs in a circle under the Krow (\255\0\255\0D)", weaponToReload = 2,},
	},
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then oneClickWepDefs[UnitDefNames[name].id] = data	end
end

return oneClickWepDefs