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

function ApplyWeapon(unitDef, weapon)
	local wcp = weapons[weapon].customparams or {}
	local slot = tonumber(wcp and wcp.slot) or 4
	unitDef.weapons[slot] = {
		def = weapon,
		badtargetcategory = wcp.badtargetcategory or [[FIXEDWING]],
		onlytargetcategory = wcp.onlytargetcategory or [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
	}
	unitDef.weapondefs[weapon] = CopyTable(weapons[weapon], true)
	
	if slot == 3 then
		unitDef.candgun = true
	end
	
	-- upgrade by level
	
	local level = (tonumber(unitDef.customparams.level) - 1) or 0
	local wd = unitDef.weapondefs[weapon]
	--[[
	if wd.range then
		wd.range = wd.range + (wd.customparams.rangeperlevel or 0) * level
	end
	if wd.damage then
		wd.damage.default = wd.damage.default + (wd.customparams.damageperlevel or 0) * level
	end
	]]--
	
	-- clear other weapons
	if slot > 3 then
		for i=4,6 do	-- subject to change
			if unitDef.weapons[i] and i ~= slot then
				unitDef.weapons[i] = nil
			end
		end
	end
	-- add CEGs
	if mapWeaponToCEG[slot] and unitDef.sfxtypes and unitDef.sfxtypes.explosiongenerators then
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][1]] = wcp.muzzleeffect or unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][1]] or [[custom:NONE]]
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][2]] = wcp.misceffect or unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][2]] or [[custom:NONE]]
	end
	
	--base customparams
	wcp.baserange = tostring(wd.range)
	for armorname,dmg in pairs(wd.damage) do
		wcp["basedamage_"..armorname] = tostring(dmg)
		--Spring.Echo(armorname, v.customparams["basedamage_"..armorname])
	end
end

function ModifyWeaponRange(unitDef, factor)
	local weapons = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
		v.range = v.range * factor
	end
end

function ModifyWeaponDamage(unitDef, factor)
	local weapons = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
		for armorname, dmg in pairs(v.damage) do
			v.damage[armorname] = dmg * factor
		end
	end
end