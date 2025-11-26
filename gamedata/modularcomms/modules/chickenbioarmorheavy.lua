local hp=1500
local rep=10
local speed=-0.04
local humanName="Heavy Bio Armor"
local description= "Heavy Bio Armor - Give " .. hp .. " hp and " .. rep .. " hp/s repair and ".. speed*100 .. "% speed. Limit: 5"

return {
	moduledef={
		module_chickenbioarmor={
			name=humanName,
			description=description,
			func = function(unitDef,attributeMods)
				unitDef.health = unitDef.health + hp
				unitDef.autoheal = (unitDef.autoheal or 0) + rep
				attributeMods.speed = attributeMods.speed + speed
			end,
		},
		
	},
	dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared -- for luals
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
		return {{
			name = "module_chickenbioarmor",
			humanName = humanName,
			description = description,
			image = moduleImagePath .. "module_repair_field.png",
			limit = 10,
			cost = 150 * COST_MULT,
			requireLevel = 2,
			requireChassis = {"chicken","assault"},
			slotType = "module",
			applicationFunction = function (modules, sharedData)
				sharedData.autorepairRate = (sharedData.autorepairRate or 0) + rep*HP_MULT
				sharedData.healthBonus = (sharedData.healthBonus or 0) + hp*HP_MULT
				sharedData.speedMultPost = (sharedData.speedMultPost or 1) + speed
			end
		}}
	end
}