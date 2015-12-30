local moduleDefs = {
	{
		name = "gun",
		humanName = "Gun Thingy",
		description = "Gun Thingy",
		image = "unitpics/commweapon_beamlaser.png",
		limit = 2,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "rocket",
		humanName = "Rocket Thingy",
		description = "Rocket Thingy",
		image = "unitpics/commweapon_rocketlauncher.png",
		limit = 2,
		requireChassis = {"support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "health",
		humanName = "Health Thingy",
		description = "Health Thingy",
		image = "unitpics/module_ablative_armor.png",
		limit = 3,
		requireChassis = {"recon", "support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "bigHealth",
		humanName = "Health Thingy",
		description = "Big Health Thingy - Requires Health Thingy",
		image = "unitpics/module_heavy_armor.png",
		limit = 3,
		requireModules = {"health"},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "skull",
		humanName = "Skull Thingy",
		description = "Skull Thingy - Limit 3",
		image = "unitpics/module_dmg_booster.png",
		limit = 3,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullmodule",
		humanName = "No Module",
		description = "No Module",
		image = "LuaUI/Images/commands/Bold/cancel.png",
		limit = false,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullweapon",
		humanName = "No Weapon",
		description = "No Weapon",
		image = "LuaUI/Images/commands/Bold/cancel.png",
		limit = false,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
}

local chassisDefs = {
	{
		name = "recon",
		upgradeSlots = {
			{
				{
					defaultModule = 1,
					slotType = "weapon",
				},
				{
					defaultModule = 3,
					slotType = "module",
				},
				{
					defaultModule = 5,
					slotType = "module",
				},
			},
		},
	},
	{
		name = "support",
		upgradeSlots = {
			{
				{
					defaultModule = 4,
					slotType = "weapon",
				},
				{
					defaultModule = 1,
					slotType = "module",
				},
				{
					defaultModule = 1,
					slotType = "module",
				},
			},
		},
	}
}


------------------------------------------------------------------------
-- Processing
------------------------------------------------------------------------

-- Find the empty modules
local emptyModules = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].name == "nullmodule" then
		emptyModules.module = i
	elseif moduleDefs[i].name == "nullweapon" then
		emptyModules.weapon = i
	end
end

-- Transform from human readable format into number indexed format
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	
	-- Required modules are a list of moduleDefIDs
	if data.requireModules then
		local newRequire = {}
		for j = 1, #data.requireModules do
			for k = 1, #moduleDefs do
				if moduleDefs[k].name == data.requireModules[j] then
					newRequire[#newRequire + 1] = k
					break
				end
			end
		end
		data.requireModules = newRequire
	end
	
	-- Required chassis is a map indexed by chassisDefID
	if data.requireChassis then
		local newRequire = {}
		for j = 1, #data.requireChassis do
			for k = 1, #chassisDefs do
				if chassisDefs[k].name == data.requireChassis[j] then
					newRequire[k] = true
					break
				end
			end
		end
		data.requireChassis = newRequire
	end
end

------------------------------------------------------------------------
-- Return Values
------------------------------------------------------------------------

return moduleDefs, emptyModules, chassisDefs