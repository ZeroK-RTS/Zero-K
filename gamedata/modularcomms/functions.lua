function lowerkeys(t)
  local tn = {}
  for i,v in pairs(t) do
    local typ = type(i)
    if type(v)=="table" then
      v = lowerkeys(v)
    end
    if typ=="string" then
      tn[i:lower()] = v
    else
      tn[i] = v
    end
  end
  return tn
end

mapWeaponToCEG = {
	[3] = {3,4},
	[5] = {1,2},
}


function DynamicApplyWeapon(unitDef, weapon, slot)
	if not weapons[weapon] then
		Spring.Echo("Cannont find weapon", weapon)
	end
	
	slot = slot or (#unitDef.weapons + 1)
	
	weapons[weapon].customparams = weapons[weapon].customparams or {}
	local wcp = weapons[weapon].customparams
	
	unitDef.weapons = unitDef.weapons or {}
	--unitDef.weapondefs = unitDef.weapondefs or {}
	
	if weapons[weapon].weapontype == "Shield" then
		unitDef.customparams.shield_radius = weapons[weapon].shieldradius
		unitDef.customparams.shield_power = weapons[weapon].shieldpower
		unitDef.customparams.shield_rate = (weapons[weapon].customparams or {}).shield_rate or weapons[weapon].shieldpowerregen
	end
	
	unitDef.weapons[slot] = {
		def = weapon,
		badtargetcategory = wcp.badtargetcategory or [[FIXEDWING]],
		onlytargetcategory = wcp.onlytargetcategory or [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
	}
	--unitDef.weapondefs[weapon] = CopyTable(weapons[weapon], true)

	-- add CEGs
	unitDef.sfxtypes = unitDef.sfxtypes or {}
	unitDef.sfxtypes.explosiongenerators = unitDef.sfxtypes.explosiongenerators or {}
	
	unitDef.sfxtypes.explosiongenerators[6 + slot*2] = wcp.muzzleeffectfire or "custom:NONE"
	unitDef.sfxtypes.explosiongenerators[7 + slot*2] = wcp.muzzleeffectshot or "custom:NONE"
end

function ApplyWeapon(unitDef, weapon, replace, forceslot)
	weapons[weapon].customparams = weapons[weapon].customparams or {}
	local wcp = weapons[weapon].customparams
	local slot = tonumber(wcp.slot) or 5
	local isDgun = (tonumber(wcp.slot) == 3)
	local altslot = tonumber(wcp.altslot or 3)
	local dualwield = false
	
	if (not isDgun) and unitDef.customparams.alreadyhasweapon and not replace then	-- dual wield
		slot = altslot
		dualwield = true
	end
	if weapons[weapon].weapontype == "Shield" then
		unitDef.customparams.shield_radius = weapons[weapon].shieldradius
		unitDef.customparams.shield_power = weapons[weapon].shieldpower
		unitDef.customparams.shield_rate = (weapons[weapon].customparams or {}).shield_rate or weapons[weapon].shieldpowerregen
	end
	
	slot = forceslot or slot
	
	--Spring.Echo(weapons[weapon].name .. " into slot " .. slot)
	
	unitDef.weapons = unitDef.weapons or {}
	unitDef.weapondefs = unitDef.weapondefs or {}
	
	unitDef.weapons[slot] = {
		def = weapon,
		badtargetcategory = wcp.badtargetcategory or [[FIXEDWING]],
		onlytargetcategory = wcp.onlytargetcategory or [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
	}
	unitDef.weapondefs[weapon] = CopyTable(weapons[weapon], true)
	
	if isDgun then
		unitDef.candgun = true
	end
	
	-- upgrade by level -- no longer used
	--[[
	local level = (tonumber(unitDef.customparams.level) - 1) or 0
	local wd = unitDef.weapondefs[weapon]
	if wd.range then
		wd.range = wd.range + (wd.customparams.rangeperlevel or 0) * level
	end
	if wd.damage then
		wd.damage.default = wd.damage.default + (wd.customparams.damageperlevel or 0) * level
	end
	]]--

	-- add CEGs
	if mapWeaponToCEG[slot] and unitDef.sfxtypes and unitDef.sfxtypes.explosiongenerators then
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][1]] = wcp.muzzleeffectfire or [[custom:NONE]]
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][2]] = wcp.muzzleeffectshot or [[custom:NONE]]
	end
	
	local wcp_unique = unitDef.weapondefs[weapon].customparams
	wcp_unique.rangemod = 0
	wcp_unique.reloadmod = 0
	wcp_unique.damagemod = 0
	
	if (not isDgun) and not (dualwield or replace) then
		unitDef.customparams.alreadyhasweapon = true
	end
end

function RemoveWeapons(unitDef)
end

function ReplaceWeapon(unitDef, oldWeapon, newWeapon)
	local weapons = unitDef.weapons or {}
	local weaponDefs = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
 		if v.def and weaponDefs[v.def] and (weaponDefs[v.def].customparams.idstring == oldWeapon) then
			--Spring.Echo("replacing " .. oldWeapon .. " with " .. newWeapon)
			ApplyWeapon(unitDef, newWeapon, true, i)
			break -- one conversion, one weapon changed. Get 2 if you want 2
		end
	end
end

function ModifyWeaponRange(unitDef, factor, includeCustomParams)
	local weapons = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
		local mod = factor
		if includeCustomParams and v.customparams then
			mod = mod + (v.customparams.rangemod or 0)
		end
		if v.range then v.range = v.range * (mod + 1) end
	end
end

function ModifyWeaponDamage(unitDef, factor, includeCustomParams)
	if unitDef.customparams.dynamic_comm then
		-- Change the name of the used weapon.
		local damageMod = (unitDef.customparams.damagemod or 0)
		for i,v in pairs(unitDef.weapons) do
			v.name = damageMod .. "_" .. v.def
			v.def = nil
		end
	else
		-- Modify weapons which are included in unitdef
		local weapons = unitDef.weapondefs or {}
		for i,v in pairs(weapons) do
			local mod = factor
			if includeCustomParams and v.customparams then
				mod = mod + (v.customparams.damagemod or 0)
			end
			for armorname, dmg in pairs(v.damage) do
				v.damage[armorname] = dmg + dmg * mod
			end
		end
	end
end
