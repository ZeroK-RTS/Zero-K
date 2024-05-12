function widget:GetInfo()
   return {
      name      = "Wiki Data Export",
      desc      = "Dumps unit and weapon defs to Lua files for the wiki.",
	  author    = "Histidine",
      date      = "2024-05-10",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = false,
   }
end

--------------------------------------------------------------------------------
--	- Run this widget every ZK update and replace the existing files on wiki with the exported ones
--	- namely, http://zero-k.info/mediawiki/Module:UnitData/data and http://zero-k.info/mediawiki/Module:WeaponData
--------------------------------------------------------------------------------
local strFormat = string.format

-- key = tag name in wiki infobox, value = name in Lua UnitDefs
local UNIT_EXPORT_MAP = {
	name = "humanName",
	--defname =	manual
	--description = manual
	image = "buildPicName",
	icontype = "iconType",
	cost = "metalCost",
	hitpoints = "health",
	mass = "mass",
	movespeed = "speed",
	turnrate = "turnRate",
	sight = "sightDistance",
	sonar = "sonarDistance",
	--transportable = manual
	altitude = "cruiseAltitude",
	--gridlink = manual
	
	-- the following are not part of the template, but specified here for convenience
	buildSpeed = "buildSpeed",
	--transportCapacity = "transportCapacity",
	canCloak = "canCloak",
	cloakCost = "cloakCost",
	cloakCostMoving = "cloakCostMoving",
	decloakDistance = "decloakDistance",
	decloakOnFire = "decloakOnFire",
	radarDistance = "radarDistance",
	jammerDistance = "radarDistanceJam",
	stealth = "stealth",
}

-- most of the weapon stats have to be done manually
local WEAPON_EXPORT_MAP = {
	name = "description",
}

local HITSCAN = {
	BeamLaser = true,
	LightningCannon = true,
}

local droneCarriers = include "LuaRules/Configs/drone_defs.lua"

local condensed_unit_defs = {}
local condensed_weapon_defs = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function comma_value(amount, displayPlusMinus, forceDecimal)
	local formatted	

	-- amount is a string when ToSI is used before calling this function
	if amount and type(amount) == "number" then
		if (amount == 0) then formatted = "0" else
			if (amount < 2 and (amount * 100)%100 ~=0) then
				if displayPlusMinus then formatted = strFormat("%+.2f", amount)
				else formatted = strFormat("%.2f", amount) end
			elseif (amount < 20 and (amount * 10)%10 ~=0) or forceDecimal then
				if displayPlusMinus then formatted = strFormat("%+.1f", amount)
				else formatted = strFormat("%.1f", amount) end
			else
				if displayPlusMinus then formatted = strFormat("%+d", amount)
				else formatted = strFormat("%d", amount) end
			end
		end
	elseif amount then
		formatted = amount
	else
		formatted = "0"
	end
	
	-- cringe-ass hax because somehow something like tonumber(2.6) gives floating point errors	
	local digits = tostring(tonumber(formatted)):len()
	if (digits > 5) then
		return formatted
	else 
		return tonumber(formatted)
	end
end

local function numformat(num, forceDecimal)
	return comma_value(num, false, forceDecimal)
end

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function getDamages(wd)
	local dam  = 0
	local damw = 0	-- paralyzer
	local dams = 0	-- slow
	local damd = 0	-- disarm
	local damc = 0	-- capture
	local stun_time = 0
	
	local cp = wd.customParams
	
	local baseDamage = tonumber(cp.stats_damage) or cp.shield_damage or 0
	local val = baseDamage

	if cp.disarmdamagemult then
		damd = val * cp.disarmdamagemult
		if (cp.disarmdamageonly == "1") then
			val = 0
		end
		stun_time = tonumber(cp.disarmtimer)
	end

	if cp.timeslow_damagefactor or cp.timeslow_onlyslow then
		dams = val * (cp.timeslow_damagefactor or 1)
		if (cp.timeslow_onlyslow == "1") then
			val = 0
		end
	end

	if cp.is_capture then
		damc = val
		val = 0
	end

	if cp.extra_damage then
		damw = tonumber(cp.extra_damage)
		stun_time = tonumber(wd.customParams.extra_paratime)
	end

	if wd.paralyzer then
		damw = val
		if stun_time == 0 then
			stun_time = wd.damages.paralyzeDamageTime
		end
	else
		dam = val
	end
	
	return dam, damw, dams, damd, damc, stun_time
end

local function getShieldRegenDrain(wd)
	local shieldRegen = wd.shieldPowerRegen
	if shieldRegen == 0 and wd.customParams and wd.customParams.shield_rate then
		shieldRegen = wd.customParams.shield_rate
	end
	
	local shieldDrain = wd.shieldPowerRegenEnergy
	if shieldDrain == 0 and wd.customParams and wd.customParams.shield_drain then
		shieldDrain = wd.customParams.shield_drain
	end
	return shieldRegen, shieldDrain
end

local function processShield(wsTemp, wd)
	local shieldRegen, shieldDrain = getShieldRegenDrain(wd)

	wsTemp.name = wd.description
	wsTemp.strength = numformat(wd.shieldPower)
	wsTemp.regen = numformat(shieldRegen)
	wsTemp.regencost = numformat(shieldDrain)
	wsTemp.radius = numformat(wd.shieldRadius)
	wsTemp.unlinked = tobool(wd.customParams.unlinked) and true or nil
end

local function nilIfZero(num)
	if type(num) ~= 'number' then num = tonumber(num) end
	return (num and num > 0) and num or nil
end

local function processWeapon(wsTemp, wd)
	--if wd == nil then Spring.Echo("omg " .. wsTemp.defname) end
	local cp = wd.customParams
	
	if wd.isShield then
		return processShield(wsTemp, wd)
	end
	
	--print("Processing weapon " .. wdEntry.name)
	
	wsTemp.name = wd.description or 'No name'
	local mult = tonumber(cp.statsprojectiles) or ((tonumber(cp.script_burst) or wd.salvoSize) * wd.projectiles)
	if mult ~= 1 then wsTemp.projectiles = mult end
	
	-- damage and dps	
	local dam, damPara, damSlow, damDisarm, damCapture, stunTime = getDamages(wd)
	dam = damCapture > 0 and damCapture or dam
	local reloadtime = tonumber(cp.script_reload) or wd.reload
	local multStr = (mult > 1) and ' × ' .. mult or ''
	
	wsTemp.damage = numformat(dam)
	wsTemp.empdamage = numformat(damPara)
	wsTemp.slowdamage = numformat(damSlow)
	wsTemp.disarmdamage = numformat(damDisarm)
	wsTemp.shielddamage = cp.damage_vs_shield and tonumber(cp.damage_vs_shield)
	wsTemp.stuntime = stunTime
	
	wsTemp.reloadtime = numformat(tonumber(cp.script_reload) or wd.reload)
		
	wsTemp.dps = math.floor(dam /reloadtime + 0.5)*mult
	wsTemp.empdps = math.floor(damPara/reloadtime + 0.5)*mult
	wsTemp.slowdps = math.floor(damSlow/reloadtime + 0.5)*mult
	wsTemp.disarmdps = math.floor(damDisarm/reloadtime + 0.5)*mult
	if cp.stats_typical_damage then
		wsTemp.dps = math.floor(tonumber(cp.stats_typical_damage)/reloadtime + 0.5)*mult
	end
	
	-- range
	wsTemp.range = cp.truerange or wd.range
	if cp.stats_hide_range then wsTemp.range = nil end
	local aoe = wd.impactOnly and 0 or wd.damageAreaOfEffect
	if (aoe > 15 and (not cp.stats_hide_aoe)) or cp.stats_aoe then
		wsTemp.aoe = numformat(cp.stats_aoe or aoe)
	end		
	
	-- projectile speed
	if not cp.stats_hide_projectile_speed and not HITSCAN[wd.type] then
		wsTemp.projectilespeed = numformat(wd.projectilespeed*30)
	end
	
	-- afterburn
	if cp.setunitsonfire then
		local afterburn_frames = (cp.burntime or (450 * (wd.fireStarter or 0)))
		wsTemp.afterburn = afterburn_frames/30
		wsTemp.afterburndps = (burntime or 450)/30
	end
	
	if wd.sprayAngle > 0 then
		wsTemp.inaccuracy = numformat(math.asin(wd.sprayAngle) * 90 / math.pi)
	end
	
	if wd.tracks and wd.turnRate > 0 then
		wsTemp.homing = numformat(wd.turnRate * 30 * 180 / math.pi)
	end
		
	if wd.wobble > 0 then
		wsTemp.wobbly = numformat(wd.wobble * 30 * 180 / math.pi)
	end
	
	if wd.trajectoryHeight > 0 then
		wsTemp.arcing = numformat(math.atan(wd.trajectoryHeight) * 180 / math.pi)
	end
	
	if wd.type == "BeamLaser" and wd.beamtime > 0.2 then
		wsTemp.bursttime = numformat(wd.beamtime)
	end	
	
	if wd.manualFire or cp.ui_manual_fire then
		wsTemp.manualfire = true
	end
	
	-- things that go in the weapon infobox's extra lines
	local extraData = {}
	
	if cp.shield_drain then
		table.insert(extraData, {type = "shielddrain", drain = tonumber(cp.shield_drain)})
	end
	
	if cp.needs_link then
		table.insert(extraData, {type = "needslink", power = tonumber(cp.needs_link)})
	end
	
	if cp.spawns_name then
		local spawn = {type = "spawn"}
		local spawnDef = UnitDefNames[cp.spawns_name]
		if spawnDef then
			spawn.name = spawnDef.humanName
			if tonumber(cp.spawns_expire) and tonumber(cp.spawns_expire) > 0 then
				spawn.expire = tonumber(cp.spawns_expire)
			end
			
			table.insert(extraData, spawn)
		end
	end
	
	if cp.area_damage then
		local grav = tobool(cp.area_damage_is_impulse)
		local areaDamage = {type = "areadamage", grav = grav}

		if not grav then
			areaDamage.dps = numformat(tonumber(cp.area_damage_dps))
		end
		areaDamage.radius = numformat(tonumber(cp.area_damage_radius))
		areaDamage.duration = numformat(tonumber(cp.area_damage_duration))
		table.insert(extraData, areaDamage)
	end
	
	-- stockpile
	if wsTemp.stockpile then
		local stockpile = {type = "stockpile"}		
		
		local time = (((tonumber(wsTemp.stockpiletime) or 0) > 0) and tonumber(wsTemp.stockpiletime) or wd.stockpileTime)
		stockpile.time = time
		str = str .. str2
		if ((not wsTemp.freestockpile) and ((tonumber(wsTemp.stockpilecost) or wd.metalcost or 0) > 0)) then
			local cost = tonumber(wsTemp.stockpilecost) or wd.metalcost
			stockpile.cost = cost
		end
	end
	
	if HITSCAN[wd.type] then
		table.insert(extraData, "hitscan")
	end
	
	if wd.interceptedByShieldType == 0 then
		table.insert(extraData, "ignoreshield")
	end
	
	if cp.smoothradius then
		table.insert(extraData, "smoothsground")
	end
		
	local highTraj = wsTemp.hightrajectory
	if highTraj == 1 then
		table.insert(extraData, "hightraj")
	elseif highTraj == 2 then
		table.insert(extraData, "trajtoggle")
	end
	wsTemp.hightrajectory = nil	
	
	if wd.waterWeapon and (wd.type ~= "TorpedoLauncher") then
		table.insert(extraData, "watercapable")
	end
	if not wd.avoidFriendly and not wd.noFriendlyCollide and not cp.ui_no_friendly_fire then
		table.insert(extraData, "friendlyfire")
	elseif cp.nofriendlyfire then
		table.insert(extraData, "nofriendlyfire")
	end
	if wd.noGroundCollide then
		table.insert(extraData, "nogroundcollide")
	end
	if (wd.noExplode or cp.pretend_no_explode) and not cp.thermite_frames then
		table.insert(extraData, "piercing")
	end
	if cp.dyndamageexp then
		table.insert(extraData, "damagefalloff")
	end
	if wd.targetMoveError > 0 then
		table.insert(extraData, "inaccuratevsmoving")
	end
	if tobool(wd.targetable) then
		table.insert(extraData, "interceptedbyantinuke")
	end
	
	wsTemp.extraData = extraData
end

local function condenseWeaponDef(weaponDefName, weaponTempData)
	local wd = WeaponDefNames[weaponDefName]
	local cwd = weaponTempData
	processWeapon(cwd, wd)
	
	-- purge unneeded data
	for k,v in pairs(cwd) do
		if v == 0 then cwd[k] = nil end
		if type(v) == 'table' and #v == 0 then cwd[k] = nil end
	end
	
	if cwd.count and cwd.count <= 1 then cwd.count = nil end
	if not cwd.damage then
		cwd.damage = 0
		cwd.dps = 0
	end
	cwd.weaponID = nil	-- no longer needed now that we've gotten the weapon count
	
	return cwd
end


local function condenseUnitDef(unitDefName)
	local ud = UnitDefNames[unitDefName]
	local unitDef = ud	-- because I didn't check all the copypasted code
	local cud = {}
	local cp = ud.customParams
	
	cud.defname = unitDefName
	cud.description = Spring.Utilities.GetDescription(ud, nil)
	
	for templateName, luaName in pairs(UNIT_EXPORT_MAP) do
		cud[templateName] = ud[luaName]
	end
	
	cud.movespeed = numformat(cud.movespeed)
	if cud.altitude then
		cud.altitude = cud.altitude * 1.5
	end
	
	cud.gridlink = cp.pylonrange
	if (ud.isImmobile) then
		cud.mass = nil
	else
		cud.mass = numformat(cud.mass, false)
		cud.transportable = (cp.requireheavytrans and "Heavy") or (cp.requiremediumtrans and "Medium") or "Light"
	end
	
	
	------------------------------
	-- abilities
	if cp.nobuildpower then cud.buildSpeed = nil end
	
	if not cud.canCloak then cud.canCloak = nil end
	cud.decloakDistance = numformat(cud.decloakDistance)
	
	local energy = ((ud.energyMake or 0) - (ud.customParams.upkeep_energy or 0) + (ud.customParams.income_energy or 0))
	cud.energy = numformat(energy)
	
	-- including drones in the unitdata turned out to be the easiest way
	local droneData = droneCarriers[unitDef.id]	
	if droneData then
		cud.drones = {}
		for i=1,#droneData do
			local droneEntry = droneData[i]
			local droneEntry2 = {}
			droneEntry2.drone = UnitDefs[droneEntry.drone].humanName
			droneEntry2.maxDrones = droneEntry.maxDrones
			droneEntry2.range = droneEntry.range
			droneEntry2.interval = droneEntry.reloadTime
			droneEntry2.spawnSize = droneEntry.spawnSize
			droneEntry2.buildTime = droneEntry.buildTime
			droneEntry2.maxBuilding = droneEntry.maxBuild
			cud.drones[#cud.drones+1] = droneEntry2
		end
	end
	
	if ud.transportCapacity and (ud.transportCapacity > 0) then
		cud.transport = (((ud.customParams.islightonlytransport) and "Light") or ((ud.customParams.islighttransport) and "Medium") or "Heavy")
		cud.transportLightSpeed = math.floor((tonumber(ud.customParams.transport_speed_light or "1")*100) + 0.5)
		if not ud.customParams.islightonlytransport then
			cud.transportMediumSpeed = math.floor((tonumber(ud.customParams.transport_speed_medium or "1")*100) + 0.5)
		end
		if not ud.customParams.islighttransport then
			cud.transportHeavySpeed = math.floor((tonumber(ud.customParams.transport_speed_heavy or "1")*100) + 0.5)
		end
	end
	
	cud.idleCloak = tobool(cp.idle_cloak) and true or nil
	cud.areaCloakRadius = tonumber(cp.area_cloak_radius)
	cud.areaCloakUpkeep = tonumber(cp.area_cloak_upkeep)
	if cud.decloakOnFire == true then cud.decloakOnFire = nil end
	cud.stealth = cud.stealth or nil
	
	if cp.canjump and (not cp.no_jump_handling) then
		cud.jumpRange = tonumber(cp.jump_range)
		cud.jumpReload = tonumber(cp.jump_reload)
		cud.jumpSpeed = numformat(30*tonumber(cp.jump_speed))
		cud.midairJump = tonumber(cp.jump_from_midair) == 0
	end
	
	if (ud.idleTime < 1800) or (cp.amph_regen) or (cp.armored_regen) then
		if ud.idleTime < 1800 then
			if ud.idleTime > 0 then
				cud.idleRegen = numformat(cp.idle_regen)
				cud.idleRegenTime = numformat(ud.idleTime / 30)
			else
				cud.combatRegen = numformat(cp.idle_regen)
			end
		end
		if cp.amph_regen then
			cud.waterRegen = tonumber(cp.amph_regen)
			cud.waterRegenDepth = tonumber(cp.amph_submerged_at)
		end
		if cp.armored_regen then
			cud.armoredRegen = numformat(cp.armored_regen)
		end
	end
	
	if cp.morphto then
		local to = UnitDefNames[cp.morphto]
		cud.morphTo = to.humanName
		cud.morphCost = to.buildTime - ud.buildTime
		cud.morphTime = cp.morphtime
		cud.combatMorph = tobool(cp.combatMorph)
	end
	
	if (ud.armoredMultiple or 1) < 1 then
		cud.armorDamageReduction = comma_value((1-ud.armoredMultiple)*100)
		if cp.force_close then
			cud.armorForceClose = tonumber(cp.force_close)
		end
	end	
	
	-- misc. stats
	if cp.ismex then cud.isMex = true end
	if tobool(cp.fireproof) then cud.fireproof = true end
	if cp.dontfireatradarcommand ~= nil then cud.dontFireAtRadar = true end
	if (ud.selfDestructCountdown or 0) <= 1 then cud.instaSelfDestruct = true end
	
	-- weapons
	local weaponStats = {}
	cud.weaponIDs = {}
	cud.shieldIDs = {}
	
	for i=1, #ud.weapons do
		if true then	-- in gui_contextmenu this if check would filter out comm weapons not on the current unit
			local weapon = ud.weapons[i]
			local weaponID = weapon.weaponDef
			local weaponDef = WeaponDefs[weaponID]

			local aa_only = true
			for cat in pairs(weapon.onlyTargets) do
				if ((cat ~= "fixedwing") and (cat ~= "gunship")) then
					aa_only = false
					break;
				end
			end

			local isDuplicate = false

			for i=1,#weaponStats do
				if weaponStats[i].weaponID == weaponID then
					weaponStats[i].count = weaponStats[i].count + 1	-- increments count of the previously detected weapon
					isDuplicate = true
					break
				end
			end
			
			if (not isDuplicate) and not weaponDef.customParams.fake_weapon then
				local wsTemp = weaponDef.isShield and {defname = weaponDef.name} or {
					weaponID = weaponID,	-- used for count detection later
					defname = weaponDef.name,
					count = 1,
					
					-- stuff that the weapon gets from the owner unit
					antiair = aa_only and true or nil,
					hightrajectory = nilIfZero(ud.highTrajectoryType),
					freestockpile = cp.freestockpile,
					stockpiletime = cp.stockpiletime,
					stockpilecost = cp.stockpilecost,
					firearc = weapon.maxAngleDif
				}
				if wsTemp.firearc == -1 then wsTemp.firearc = nil
				elseif wsTemp.firearc then wsTemp.firearc = numformat(360*math.acos(wsTemp.firearc)/math.pi) end
				
				local shield = weaponDef.isShield
				
				weaponStats[#weaponStats+1] = wsTemp
				if shield then 
					cud.shieldIDs[#cud.shieldIDs+1] = weaponDef.name
				else
					cud.weaponIDs[#cud.weaponIDs+1] = weaponDef.name
				end
			end
		end
	end
	
	-- add the kamikaze weapon if needed
	if ud.canKamikaze then
		local wDefName = ud.customParams.stats_detonate_weapon or ud.deathExplosion:lower()
		if WeaponDefNames[wDefName] then
			cud.weaponIDs[#cud.weaponIDs+1] = wDefName
			weaponStats[#weaponStats+1] = {defname = wDefName}
		end
	end
	
	-- heat
	if cp.heat_per_shot then
		cud.heatPerShot = numformat(cp.heat_per_shot*100)
		cud.heatDecay = numformat(cp.heat_decay*100)
		cud.heatMaxSlow = numformat(cp.heat_max_slow*100)
	end
	
	for index, tempData in pairs(weaponStats) do
		condensed_weapon_defs[tempData.defname] = condenseWeaponDef(tempData.defname, tempData)
	end
	
	-- remove unneeded values
	for k,v in pairs(cud) do
		if v == 0 then cud[k] = nil end
		if type(v) == 'table' and #v == 0 then cud[k] = nil end
	end
	
	return cud
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Spring.Echo("Preparing stat dump")
	
	local buildOpts = VFS.Include("gamedata/buildoptions.lua")
	local builtBySomething = {}
	
	for index, unitDefName in ipairs(buildOpts) do
		local def = UnitDefNames[unitDefName]
		builtBySomething[unitDefName] = def
	
		for index, buildeeId in pairs(def.buildOptions or {}) do
			local buildeeDef = UnitDefs[buildeeId]
			builtBySomething[buildeeDef.name] = buildeeDef
		end
	end
	
	for unitDefName, def in pairs(builtBySomething) do
		if not def.customParams.commtype then
			condensed_unit_defs[unitDefName] = condenseUnitDef(unitDefName)
		end
	end
	
	local folder = "temp/"
	local unitFile = "unitStats.lua"
	local weaponFile = "weaponStats.lua"
	
	WG.SaveTable(condensed_unit_defs, folder, unitFile, nil, {prefixReturn = true})
	Spring.Echo("Saved unit stats to " .. folder .. unitFile)
	WG.SaveTable(condensed_weapon_defs, folder, weaponFile, nil, {prefixReturn = true})
	Spring.Echo("Saved weapon stats to " .. folder .. weaponFile)
	
	Spring.Echo("Stat dump complete")
	
	widgetHandler:RemoveWidget()
end