local hp=500
local rep=5
local humanName="Bio Armor"
local description= "Bio Armor - Give " .. hp .. " hp and " .. rep .. " hp/s repair. Limit: 10"
return {
	moduledef={
		module_chickenbioarmor={
			name=humanName,
			description=description,
			func = function(unitDef)
				unitDef.health = unitDef.health + hp
				unitDef.autoheal = (unitDef.autoheal or 0) + rep
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
			requireLevel = 1,
			requireChassis = {"chicken","assault"},
			slotType = "module",
			applicationFunction = function (modules, sharedData)
				sharedData.autorepairRate = (sharedData.autorepairRate or 0) + rep*HP_MULT
				sharedData.healthBonus = (sharedData.healthBonus or 0) + hp*HP_MULT
			end
		}}
	end
}