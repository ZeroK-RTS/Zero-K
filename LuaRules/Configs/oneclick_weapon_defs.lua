-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	corcrw = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = "Superlaser", tooltip = "Fires a devastating laser beam under the Krow", weaponToReload = 2,},
	},
	amphtele = {
		{ functionToCall = "DeployTeleport", name = "Deploy", tooltip = "Deploy Djinn into teleport mode so it can receive units", },
	},
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then oneClickWepDefs[UnitDefNames[name].id] = data	end
end

return oneClickWepDefs