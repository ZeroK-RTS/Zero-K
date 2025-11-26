local chassisDefs = {
	
}

local chassisAllDefs=VFS.Include("gamedata/modularcomms/chassises_all_defs.lua")

for i = 1, #chassisAllDefs do
	local chassisDef = chassisAllDefs[i].dyncomm_chassis_generator
	chassisDefs[#chassisDefs+1]=chassisDef
end

local commanderCost = 1100

local statOverrides = {
	cloakcost       = 5, -- For personal cloak
	cloakcostmoving = 10,
	onoffable       = true, -- For jammer and cloaker toggling
	canmanualfire   = true, -- For manualfire weapons.
	metalcost       = commanderCost,
	energycost      = commanderCost,
	buildtime       = commanderCost,
	power           = 1200,
}

for i = 1, #chassisDefs do
	local name = chassisDefs[i].name
	local unitDef = UnitDefs[name]
	if unitDef then
		for wreckName, wreckDef in pairs(unitDef.featuredefs or {}) do
			wreckDef.metal = commanderCost * (wreckName == "heap" and 0.2 or 0.4)
			wreckDef.reclaimtime = wreckDef.metal
		end
		
		for key, data in pairs(statOverrides) do
			unitDef[key] = data
		end
		
		for j = 1, 7 do
			unitDef.sfxtypes.explosiongenerators[j] = unitDef.sfxtypes.explosiongenerators[j] or [[custom:NONE]]
		end
		
		for num = 1, #chassisDefs[i].weapons do
			local weaponName = chassisDefs[i].weapons[num]
			DynamicApplyWeapon(unitDef, weaponName, num)
		end
		
		if #chassisDefs[i].weapons > 31 then
			-- Limit of 31 for shield space.
			Spring.Echo("Too many commander weapons on:", name, "Limit is 31, found weapons:", #chassisDefs[i].weapons)
		end
	else
		Spring.Log("gamedata/modularcomms/dyncomm_chassis_generator.lua","error","UnitDef " .. name .. " Not Found")
	end
	
end
