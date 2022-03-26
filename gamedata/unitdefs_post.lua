
local modOptions = {}
if (Spring.GetModOptions) then
	modOptions = Spring.GetModOptions()
end

Spring.Echo("Loading UnitDefs_posts")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constants?
--

VFS.Include("LuaRules/Configs/constants.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility
--

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

local function lowerkeys(t)
	local tn = {}
	if type(t) == "table" then
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
	end
	return tn
end

--deep not safe with circular tables! defaults To false
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")
CopyTable = Spring.Utilities.CopyTable
MergeTable = Spring.Utilities.MergeTable

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- ud.customparams IS NEVER NIL

for _, ud in pairs(UnitDefs) do
	if not ud.customparams then
		ud.customparams = {}
	end
 end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Balance Testing
--

-- modOptions.tweakdefs = 'Zm9yIG5hbWUsIHVkIGluIHBhaXJzKFVuaXREZWZzKSBkbwoJaWYgdWQubWF4dmVsb2NpdHkgdGhlbgoJCXVkLm1heHZlbG9jaXR5ID0gdWQubWF4dmVsb2NpdHkqMTAKCWVuZAplbmQ='

do
	local append = false
	local name = "tweakdefs"
	while modOptions[name] and modOptions[name] ~= "" do
		local postsFuncStr = Spring.Utilities.Base64Decode(modOptions[name])
		local postfunc, err = loadstring(postsFuncStr)
		Spring.Echo("Loading tweakdefs modoption", append or 0)
		if postfunc then
			postfunc()
		end
		append = (append or 0) + 1
		name = "tweakdefs" .. append
	end
end

--modOptions.tweakunits = 'ewpjbG9ha3JhaWQgPSB7YnVpbGRDb3N0TWV0YWwgPSAxMCwKd2VhcG9uRGVmcyA9IHtFTUcgPSB7ZGFtYWdlID0ge2RlZmF1bHQgPSAyMDB9fX19LAp9'

do
	local append = false
	local modoptName = "tweakunits"
	while modOptions[modoptName] and modOptions[modoptName] ~= "" do
		local tweaks = Spring.Utilities.CustomKeyToUsefulTable(modOptions[modoptName])
		if type(tweaks) == "table" then
			Spring.Echo("Loading tweakunits modoption", append or 0)
			for name, ud in pairs(UnitDefs) do
				if tweaks[name] then
					Spring.Echo("Loading tweakunits for " .. name)
					Spring.Utilities.OverwriteTableInplace(ud, lowerkeys(tweaks[name]), true)
				end
			end
		end
		append = (append or 0) + 1
		modoptName = "tweakunits" .. append
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- because the way lua access to unitdefs and weapondefs is setup is insane
--

--[[for _, ud in pairs(UnitDefs) do
	if ud.collisionVolumeOffsets then
		ud.customparams.collisionVolumeOffsets = ud.collisionVolumeOffsets  -- For ghost site
	end
end]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Modular commander/PlanetWars handling
--

VFS.Include('gamedata/modularcomms/unitdefgen.lua')
VFS.Include('gamedata/planetwars/pw_unitdefgen.lua')
local Utilities = VFS.Include('gamedata/utilities.lua')

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Make Terraunit not decloak enemies
--

if Utilities.IsCurrentVersionNewerThan(104, 1400) and not Utilities.IsCurrentVersionNewerThan(104, 1470) then
	UnitDefs.terraunit.collisionvolumeoffsets = [[0 -550 0]]
	UnitDefs.terraunit.selectionvolumeoffsets = [[0 550 0]]
	UnitDefs.terraunit.customparams.midposoffset = [[0 -550 0]]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Convert all CustomParams to strings
--

-- FIXME: breaks with table keys
-- but why would you be using those anyway?
local function TableToString(tbl)
	local str = "{"
	for i, v in pairs(tbl) do
		if type(i) == "number" then
			str = str .. "[" .. i .. "] = "
		else
			str = str .. [[["]]..i..[["] = ]]
		end
		
		if type(v) == "table" then
			str = str .. TableToString(v)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. ";"
		elseif type(v) == "string" then
			str = str .. "[[" .. v .. "]];"
		else
			str = str .. v .. ";"
		end
	end
	str = str .. "};"
	return str
end

for name, ud in pairs(UnitDefs) do
	if (ud.customparams) then
		for tag, v in pairs(ud.customparams) do
			if (type(v) == "table") then
				local str = TableToString(v)
				ud.customparams[tag] = str
			elseif (type(v) ~= "string") then
				ud.customparams[tag] = tostring(v)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set units that ignore map-side gadgetted placement resitrctions
-- see http://springrts.com/phpbb/viewtopic.php?f=13&t=27550

for name, ud in pairs(UnitDefs) do
	if (ud.maxvelocity and ud.maxvelocity > 0) or ud.customparams.mobilebuilding then
		ud.customparams.ignoreplacementrestriction = "true"
	end
end

-- Set build options
local buildOpts = VFS.Include("gamedata/buildoptions.lua")
for name, ud in pairs(UnitDefs) do
	if ud.buildoptions and (#ud.buildoptions == 0) then
		ud.buildoptions = buildOpts
	end
end

local typeNames = {
	"CONSTRUCTOR",
	"RAIDER",
	"SKIRMISHER",
	"RIOT",
	"ASSAULT",
	"ARTILLERY",
	"WEIRD_RAIDER",
	"ANTI_AIR",
	"HEAVY_SOMETHING",
	"SPECIAL",
	"UTILITY",
}
local typeNamesLower = {}
for i = 1, #typeNames do
	typeNamesLower[i] = "pos_" .. typeNames[i]:lower()
end

-- Set build options from pos_ customparam
for name, ud in pairs(UnitDefs) do
	local cp = ud.customparams
	for i = 1, #typeNamesLower do
		local value = cp[typeNamesLower[i]]
		if value then
			ud.buildoptions = ud.buildoptions or {}
			ud.buildoptions[#ud.buildoptions + 1] = value
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3dbuildrange for all none plane builders
--

--for name, ud in pairs(UnitDefs) do
--	if (tobool(ud.builder) and not tobool(ud.canfly)) then
--		ud.buildrange3d = true
--	end
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Calculate mincloakdistance based on unit footprint size
--

local sqrt = math.sqrt
local cloakFootMult = 6 * sqrt(2)
for name, ud in pairs(UnitDefs) do
	local fx = ud.customparams.decloak_footprint or (ud.footprintx and tonumber(ud.footprintx) or 1)
	local fz = ud.customparams.decloak_footprint or (ud.footprintz and tonumber(ud.footprintz) or 1)
	-- Note that the full power of this equation is never used in practise, since units have square
	-- footprints and most structures don't cloak (the ones that do have square footprints).
	local radius = cloakFootMult * sqrt((fx * fx) + (fz * fz)) + 56
	-- 2x2 = 80
	-- 3x3 = 92
	-- 4x4 = 104
	if (not ud.mincloakdistance) then
		ud.mincloakdistance = radius
	elseif radius < ud.mincloakdistance then
		ud.customparams.cloaker_bestowed_radius = radius
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tell UnitDefs about script_reload and script_burst
--

for name, ud in pairs(UnitDefs) do
	if not ud.customparams.dynamic_comm then
		if ud.weapondefs then
			local cobWeapon = (ud.script and ud.script:find("%.cob"))
			for _, wd in pairs(ud.weapondefs) do
				if wd.customparams and wd.customparams.script_reload then
					ud.customparams.script_reload = wd.customparams.script_reload
				end
				if wd.customparams and wd.customparams.script_burst then
					ud.customparams.script_burst = wd.customparams.script_burst
				end
				if wd.customparams and wd.customparams.post_capture_reload then
					ud.customparams.post_capture_reload = wd.customparams.post_capture_reload
				end
				wd.customparams = wd.customparams or {}
				wd.customparams.is_unit_weapon = 1
				if cobWeapon then
					wd.customparams.cob_weapon = 1
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Units with shields cannot cloak
-- Set easily readible shield power
--
--Spring.Echo("Shield Weapon Def")
for name, ud in pairs(UnitDefs) do
	if not ud.customparams.dynamic_comm then
		local hasShield = false
		if ud.weapondefs then
			for _, wd in pairs(ud.weapondefs) do
				if wd.weapontype == "Shield" then
					hasShield = true
					if ud.activatewhenbuilt == nil then
						-- some aspects of shields require the unit to be enabled
						ud.activatewhenbuilt = true
					end
					ud.customparams.shield_radius = wd.shieldradius
					ud.customparams.shield_power = wd.shieldpower
					ud.customparams.shield_recharge_delay = (wd.customparams or {}).shield_recharge_delay or wd.shieldrechargedelay
					ud.customparams.shield_rate = (wd.customparams or {}).shield_rate or wd.shieldpowerregen
					break
				end
			end
		end
		if (hasShield or (((not ud.maxvelocity) or ud.maxvelocity == 0) and not ud.cloakcost)) then
			ud.customparams.cannotcloak = 1
			ud.mincloakdistance = 0
			ud.cloakcost = nil
			ud.cloakcostmoving = nil
			ud.cancloak = false
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UnitDefs Dont Repeat Yourself
--
local BP2RES = 0
local BP2RES_FACTORY = 0
local BP2TERRASPEED = 1000 --used to be 60 in most of the cases
--local SEISMICSIG = 4 --used to be 4 in most of the cases
for name, ud in pairs (UnitDefs) do
	local cost = math.max (ud.buildcostenergy or 0, ud.buildcostmetal or 0, ud.buildtime or 0) --one of these should be set in actual unitdef file

	--setting uniform buildTime, M/E cost
	if not ud.buildcostenergy then ud.buildcostenergy = cost end
	if not ud.buildcostmetal then ud.buildcostmetal = cost end
	if not ud.buildtime then ud.buildtime = cost end

	--setting uniform M/E storage
	local storage = math.max (ud.metalstorage or 0, ud.energystorage or 0)
	if storage > 0 then
		if not ud.metalstorage then ud.metalstorage = storage end
		if not ud.energystorage then ud.energystorage = storage end
	end

	--setting metalmake, energymake, terraformspeed for construction units
	if tobool(ud.builder) and ud.workertime then
		local bp = ud.workertime

		local mult = (ud.customparams.dynamic_comm and 0) or 1
		if ud.customparams.factorytab then
			if not ud.metalmake then ud.metalmake = bp * BP2RES_FACTORY * mult end
			if not ud.energymake then ud.energymake = bp * BP2RES_FACTORY * mult end
		else
			if not ud.metalmake then ud.metalmake = bp * BP2RES * mult end
			if not ud.energymake then ud.energymake = bp * BP2RES * mult end
		end

		if not ud.terraformspeed then
			ud.terraformspeed = bp * BP2TERRASPEED
		end
	end

	--setting standard seismicSignature
	--[[
	if ud.floater or ud.canhover or ud.canfly then
		if not ud.seismicsignature then ud.seismicsignature = 0 end
	else
		if not ud.seismicsignature then ud.seismicsignature = SEISMICSIG end
	end
	]]--

	--setting levelGround
	--[[
	if (ud.isBuilding == true or ud.maxAcc == 0) and (not ud.customParams.mobilebuilding) then --looks like a building
		if ud.levelGround == nil then
			ud.levelGround = false -- or true
		end
	end
	]]--
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lua implementation of energyUse
--

for name, ud in pairs(UnitDefs) do
	local energyUse = tonumber(ud.energyuse or 0)
	if energyUse and (energyUse > 0) then
		ud.customparams.upkeep_energy = energyUse
		ud.energyuse = 0
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable smoothmesh; allow use of airpads
--

for name, ud in pairs(UnitDefs) do
	if (ud.canfly) then
		ud.usesmoothmesh = false
		if not ud.maxfuel then
			ud.maxfuel = 1000000
			ud.refueltime = ud.refueltime or 1
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Maneuverability multipliers, useful for testing.

local TURNRATE_MULT_BOT = 1
local TURNRATE_MULT_VEH = 1
local ACCEL_MULT_BOT = 1
local ACCEL_MULT_VEH = 1

for name, ud in pairs(UnitDefs) do
	if ud.turnrate and ud.acceleration and ud.brakerate and ud.movementclass then
		local class = ud.movementclass

		if class:find("TANK") or class:find("BOAT") or class:find("HOVER") then
			-- NB: also contains some water-walking chickens (as hover)
			ud.turnrate = ud.turnrate * TURNRATE_MULT_VEH
			ud.acceleration = ud.acceleration * ACCEL_MULT_VEH
			ud.brakerate = ud.brakerate * ACCEL_MULT_VEH
		else
			ud.turnrate = ud.turnrate * TURNRATE_MULT_BOT
			ud.acceleration = ud.acceleration * ACCEL_MULT_BOT
			ud.brakerate = ud.brakerate * ACCEL_MULT_BOT
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Energy Bonus, fac cost mult
--


if (modOptions and modOptions.energymult) then
	for name in pairs(UnitDefs) do
		local em = UnitDefs[name].energymake
		if (em) then
			UnitDefs[name].energymake = em * modOptions.energymult
		end
	end
end

if (modOptions and modOptions.metalmult) then
	for name in pairs(UnitDefs) do
		UnitDefs[name].metalmake = (UnitDefs[name].metalmake or 0) * modOptions.metalmult
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Resurrect
--

if (modOptions and (modOptions.disableresurrect == 1 or modOptions.disableresurrect == "1")) then
	for name, unitDef in pairs(UnitDefs) do
		if (unitDef.canresurrect) then
			unitDef.canresurrect = false
		end
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- unitspeedmult
--

if (modOptions and modOptions.unitspeedmult and modOptions.unitspeedmult ~= 1) then
	local unitspeedmult = modOptions.unitspeedmult
	for unitDefID, unitDef in pairs(UnitDefs) do
		if (unitDef.maxvelocity) then
			unitDef.maxvelocity = unitDef.maxvelocity * unitspeedmult
		end
		if (unitDef.acceleration) then
			unitDef.acceleration = unitDef.acceleration * unitspeedmult
		end
		if (unitDef.brakerate) then
			unitDef.brakerate = unitDef.brakerate * unitspeedmult
		end
		if (unitDef.turnrate) then
			unitDef.turnrate = unitDef.turnrate * unitspeedmult
		end
	end
end

if (modOptions and modOptions.damagemult and modOptions.damagemult ~= 1) then
	local damagemult = modOptions.damagemult
	for _, unitDef in pairs(UnitDefs) do
		if (unitDef.autoheal) then
			unitDef.autoheal = unitDef.autoheal * damagemult
		end
		if (unitDef.idleautoheal) then
			unitDef.idleautoheal = unitDef.idleautoheal * damagemult
		end
		
		if (unitDef.capturespeed) then
			unitDef.capturespeed = unitDef.capturespeed * damagemult
		elseif (unitDef.workertime) then
			unitDef.capturespeed = unitDef.workertime * damagemult
		end
		
		if (unitDef.repairspeed) then
			unitDef.repairspeed = unitDef.repairspeed * damagemult
		elseif (unitDef.workertime) then
			unitDef.repairspeed = unitDef.workertime * damagemult
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set turnInPlace speed limits, reverse velocities (but not for ships)
--
for name, ud in pairs(UnitDefs) do
	if ud.turnrate then
		if ud.customparams.turnatfullspeed_hover then
			ud.turninplace = false
			ud.turninplacespeedlimit = (ud.maxvelocity or 0)*(ud.customparams.boost_speed_mult or 0.8)
			ud.turninplaceanglelimit = 90
		elseif (ud.turnrate > 600 or ud.customparams.turnatfullspeed) then
			ud.turninplace = false
			ud.turninplacespeedlimit = (ud.maxvelocity or 0)
		elseif ud.turninplace ~= true then
			ud.turninplace = false -- true
			ud.turninplacespeedlimit = ud.turninplacespeedlimit or (ud.maxvelocity and ud.maxvelocity*0.6 or 0)
			--ud.turninplaceanglelimit = 180
		end
	end

	if ud.category and not (ud.category:find("SHIP", 1, true) or ud.category:find("SUB", 1, true)) then
		if (ud.maxvelocity) and not ud.maxreversevelocity then
			if not name:find("chicken", 1, true) then
				ud.maxreversevelocity = ud.maxvelocity * 0.33
			end
		end
	end
end

-- Set to accelerate towards their destination regardless of heading
for name, ud in pairs(UnitDefs) do
	if ud.hoverattack then
		ud.turninplaceanglelimit = 180
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2x repair speed than BP
--

local REPAIR_ENERGY_COST_FACTOR = (Game and Game.repairEnergyCostFactor) or 0.666 -- Game.repairEnergyCostFactor

for name, unitDef in pairs(UnitDefs) do
	if (unitDef.repairspeed) then
		unitDef.repairspeed = unitDef.repairspeed / REPAIR_ENERGY_COST_FACTOR
	elseif (unitDef.workertime) then
		unitDef.repairspeed = unitDef.workertime / REPAIR_ENERGY_COST_FACTOR
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set higher default losEmitHeight. Engine default is 20.
--

for name, unitDef in pairs(UnitDefs) do
	if not unitDef.losEmitHeight then
		unitDef.losEmitHeight = 30
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Avoid firing at unarmed
--
for name, ud in pairs(UnitDefs) do
	if (ud.weapons and not ud.canfly) then
		for wName, wDef in pairs(ud.weapons) do
			if wDef.badtargetcategory then
				wDef.badtargetcategory = wDef.badtargetcategory .. " STUPIDTARGET"
			else
				wDef.badtargetcategory = "STUPIDTARGET"
			end
		end
	end
	if not ud.customparams.chase_everything then
		if not ud.canfly then
			ud.nochasecategory = (ud.nochasecategory or "") .. " STUPIDTARGET"
		else
			ud.nochasecategory = (ud.nochasecategory or "") .. " SOLAR"
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Avoid neutral	-- breaks explicit attack orders
--

--[[for name, ud in pairs(UnitDefs) do
	if (ud.weapondefs) then
		for wName,wDef in pairs(ud.weapondefs) do
			wDef.avoidneutral = true
		end
	end
end]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set airLOS
--
for name, ud in pairs(UnitDefs) do
	ud.airsightdistance = (ud.sightdistance or 0)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set mass
--
for name, ud in pairs(UnitDefs) do
	ud.mass = (((ud.buildtime/2) + (ud.maxdamage/8))^0.6)*6.5
	if ud.customparams.massmult then
		ud.mass = ud.mass*ud.customparams.massmult
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set incomes
--

for name, ud in pairs(UnitDefs) do
	if ud.metalmake and ud.metalmake > 0 then
		ud.customparams.income_metal = ud.metalmake
		ud.activatewhenbuilt = true
		ud.metalmake = 0
	end
	if ud.energymake and ud.energymake > 0 then
		ud.customparams.income_energy = ud.energymake
		ud.activatewhenbuilt = true
		ud.energymake = 0
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Cost Checking
--

--for name, ud in pairs(UnitDefs) do
--	if ud.buildcostmetal ~= ud.buildcostenergy or ud.buildtime ~= ud.buildcostenergy then
--		Spring.Echo("Inconsistent Cost for " .. ud.name)
--	end
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Festive units mod option (CarRepairer's WIP)
--

if (modOptions and tobool(modOptions.xmas)) then
	local gifts = {"present_bomb1.s3o", "present_bomb2.s3o","present_bomb3.s3o"}
	
	local function round(num)
		return num - (num%1)
	end

	local function GetRandom(s, c)
		local n = 0
		for i = 1, s:len() do
			n = n + s:byte(i)
		end
		n = (math.sin(n) + 1) * 0.5 * (c - 1) + 1
		return round(n)
	end

	for name, ud in pairs(UnitDefs) do
		if (type(ud.weapondefs) == "table") then
			for wname, wd in pairs(ud.weapondefs) do
				if (wd.weapontype == "AircraftBomb" or ( wd.name:lower() ):find("bomb")) and not wname:find("bogus") then
					--Spring.Echo(wname)
					wd.model = gifts[ GetRandom(wname, #gifts) ]
				end
			end
		end
	end --for
end


-- Remove initCloaked because cloak state is no longer used
--

for name, ud in pairs(UnitDefs) do
	if tobool(ud.initcloaked) then
		ud.initcloaked = false
		ud.customparams.initcloaked = "1"
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Automatically generate some big selection volumes.
--

local function Explode(div, str)
	if div == '' then
		return false
	end
	local pos, arr = 0, {}
	-- for each divider found
	for st, sp in function() return string.find(str, div, pos, true) end do
		table.insert(arr, string.sub(str, pos, st - 1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

local function GetDimensions(scale)
	if not scale then
		return false
	end
	local dimensionsStr = Explode(" ", scale)
	-- string conversion (required for MediaWiki export)
	local dimensions = {}
	for i,v in pairs(dimensionsStr) do
		dimensions[i] = tonumber(v)
	end
	local largest = (dimensions and dimensions[1] and tonumber(dimensions[1])) or 0
	for i = 2, 3 do
		largest = math.max(largest, (dimensions and dimensions[i] and tonumber(dimensions[i])) or 0)
	end
	return dimensions, largest
end

local VISUALIZE_SELECTION_VOLUME = false
local CYL_SCALE = 1.1
local CYL_LENGTH = 0.8
local CYL_ADD = 5
local SEL_SCALE = 1.5
local STATIC_SEL_SCALE = 1.35

for name, ud in pairs(UnitDefs) do
	local scale = STATIC_SEL_SCALE
	if ud.acceleration and ud.acceleration > 0 and ud.canmove then
		scale = SEL_SCALE
	end
	if ud.customparams.selectionscalemult then
		scale = ud.customparams.selectionscalemult
	end
	
	if ud.collisionvolumescales or ud.selectionvolumescales then
		-- Do not override default colvol because it is hard to measure.
		
		if ud.selectionvolumescales then
			local dim = GetDimensions(ud.selectionvolumescales)
			ud.selectionvolumescales  = math.ceil(dim[1]*scale) .. " " .. math.ceil(dim[2]*scale) .. " " .. math.ceil(dim[3]*scale)
		else
			local size = math.max(ud.footprintx or 0, ud.footprintz or 0)*15
			if size > 0 then
				local dimensions, largest = GetDimensions(ud.collisionvolumescales)
				local x, y, z = size, size, size
				if size > largest then
					ud.selectionvolumeoffsets = ud.selectionvolumeoffsets or "0 0 0"
					ud.selectionvolumetype    = ud.selectionvolumetype or "ellipsoid"
				elseif string.lower(ud.collisionvolumetype) == "cylx" then
					ud.selectionvolumeoffsets = ud.selectionvolumeoffsets or ud.collisionvolumeoffsets or "0 0 0"
					x = dimensions[1]*CYL_LENGTH
					y = math.max(dimensions[2], math.min(size, CYL_ADD + dimensions[2]*CYL_SCALE))
					z = math.max(dimensions[3], math.min(size, CYL_ADD + dimensions[3]*CYL_SCALE))
					ud.selectionvolumetype    = ud.selectionvolumetype or ud.collisionvolumetype
				elseif string.lower(ud.collisionvolumetype) == "cyly" then
					ud.selectionvolumeoffsets = ud.selectionvolumeoffsets or ud.collisionvolumeoffsets or "0 0 0"
					x = math.max(dimensions[1], math.min(size, CYL_ADD + dimensions[1]*CYL_SCALE))
					y = dimensions[2]*CYL_LENGTH
					z = math.max(dimensions[3], math.min(size, CYL_ADD + dimensions[3]*CYL_SCALE))
					ud.selectionvolumetype    = ud.selectionvolumetype or ud.collisionvolumetype
				elseif string.lower(ud.collisionvolumetype) == "cylz" then
					ud.selectionvolumeoffsets = ud.selectionvolumeoffsets or ud.collisionvolumeoffsets or "0 0 0"
					x = math.max(dimensions[1], math.min(size, CYL_ADD + dimensions[1]*CYL_SCALE))
					y = math.max(dimensions[2], math.min(size, CYL_ADD + dimensions[2]*CYL_SCALE))
					z = dimensions[3]*CYL_LENGTH
					ud.selectionvolumetype    = ud.selectionvolumetype or ud.collisionvolumetype
				elseif string.lower(ud.collisionvolumetype) == "box" then
					ud.selectionvolumeoffsets = ud.selectionvolumeoffsets or "0 0 0"
					x = dimensions[1]
					y = dimensions[2]
					z = dimensions[3]
					ud.selectionvolumetype    = ud.selectionvolumetype or ud.collisionvolumetype
				end
				ud.selectionvolumescales  = math.ceil(x*scale) .. " " .. math.ceil(y*scale) .. " " .. math.ceil(z*scale)
			end
		end
	else
		ud.customparams.lua_selection_scale = scale -- Scale default colVol units in lua, where we can read their model radius.
	end
	
	if VISUALIZE_SELECTION_VOLUME then
		if ud.selectionvolumescales then
			ud.collisionvolumeoffsets = ud.selectionvolumeoffsets
			ud.collisionvolumescales  = ud.selectionvolumescales
			ud.collisionvolumetype    = ud.selectionvolumetype
		end
	end
	
	--Spring.Echo("VISUALIZE_SELECTION_VOLUME", ud.name, ud.collisionvolumescales, ud.selectionvolumescales)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Altered unit health mod option
--

--modOptions.hpmult = 1.5 -- TEST CHANGE

if modOptions and modOptions.hpmult and modOptions.hpmult ~= 1 then
	local hpMulti = modOptions.hpmult
	for unitDefID, unitDef in pairs(UnitDefs) do
		if unitDef.maxdamage and unitDef.unitname ~= "terraunit" then
			unitDef.maxdamage = math.max(unitDef.maxdamage * hpMulti, 1)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Remove Restore
--

for name, ud in pairs(UnitDefs) do
	if tobool(ud.builder) then
		ud.canrestore = false
		--ud.shownanospray = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set chicken cost
--

--[[for name, ud in pairs(UnitDefs) do
	if (ud.unitname:sub(1,7) == "chicken") then
		ud.buildcostmetal = ud.buildtime
		ud.buildcostenergy = ud.buildtime
	end
end]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Category changes
--
for name, ud in pairs(UnitDefs) do
	if ((ud.maxvelocity or 0) > 0) then
		ud.category = ud.category .. " MOBILE"
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Implement modelcenteroffset
--
for name, ud in pairs(UnitDefs) do
	if ud.modelcenteroffset then
		ud.customparams.aimposoffset = ud.modelcenteroffset
		ud.customparams.midposoffset = ud.modelcenteroffset
		ud.modelcenteroffset = "0 0 0"
	end
end

-- Replace regeneration with Lua
local autoheal_defaults = VFS.Include("gamedata/unitdef_defaults/autoheal_defs.lua")
for name, ud in pairs(UnitDefs) do
	if (ud.autoheal and (ud.autoheal > 0)) then
		ud.customparams.idle_regen = ud.autoheal
		ud.idletime = 0
	else
		ud.customparams.idle_regen = ud.idleautoheal or autoheal_defaults.idleautoheal
		ud.idletime = ud.idletime or autoheal_defaults.idletime
	end

	ud.idleautoheal = 0
	ud.autoheal = 0
end

-- Set defaults for area cloak
local area_cloak_defaults = VFS.Include("gamedata/unitdef_defaults/area_cloak_defs.lua")
for name, ud in pairs(UnitDefs) do
	local cp = ud.customparams
	if cp.area_cloak and (cp.area_cloak ~= "0") then
		if not cp.area_cloak_upkeep then cp.area_cloak_upkeep = tostring(area_cloak_defaults.upkeep) end
		if not cp.area_cloak_radius then cp.area_cloak_radius = tostring(area_cloak_defaults.radius) end

		if not cp.area_cloak_grow_rate then cp.area_cloak_grow_rate = tostring(area_cloak_defaults.grow_rate) end
		if not cp.area_cloak_shrink_rate then cp.area_cloak_shrink_rate = tostring(area_cloak_defaults.shrink_rate) end
		if not cp.area_cloak_decloak_distance then cp.area_cloak_decloak_distance = tostring(area_cloak_defaults.decloak_distance) end

		if not cp.area_cloak_init then cp.area_cloak_init = tostring(area_cloak_defaults.init) end
		if not cp.area_cloak_draw then cp.area_cloak_draw = tostring(area_cloak_defaults.draw) end
		if not cp.area_cloak_self then cp.area_cloak_self = tostring(area_cloak_defaults.self) end
	end
end

-- Set defaults for jump
local jump_defaults = VFS.Include("gamedata/unitdef_defaults/jump_defs.lua")
for name, ud in pairs (UnitDefs) do
	local cp = ud.customparams
	if cp.canjump == "1" then
		if not cp.jump_range then cp.jump_range = tostring(jump_defaults.range) end
		if not cp.jump_height then cp.jump_height = tostring(jump_defaults.height) end
		if not cp.jump_speed then cp.jump_speed = tostring(jump_defaults.speed) end
		if not cp.jump_reload then cp.jump_reload = tostring(jump_defaults.reload) end
		if not cp.jump_delay then cp.jump_delay = tostring(jump_defaults.delay) end

		if not cp.jump_from_midair then cp.jump_from_midair = tostring(jump_defaults.from_midair) end
		if not cp.jump_rotate_midair then cp.jump_rotate_midair = tostring(jump_defaults.rotate_midair) end
		if not cp.jump_spread_exception then cp.jump_spread_exception = tostring(jump_defaults.spread_exception) end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Remove engine transport limits
--

if Utilities.IsCurrentVersionNewerThan(104, 600) then
	for name, ud in pairs (UnitDefs) do
		ud.transportmass = nil
		local buildCost = ud.buildcostmetal and tonumber(ud.buildcostmetal)
		if buildCost then
			if buildCost > TRANSPORT_MEDIUM_COST_MAX then
				ud.customparams.requireheavytrans = 1
			elseif buildCost > TRANSPORT_LIGHT_COST_MAX then
				ud.customparams.requiremediumtrans = 1
			end
		end
	end
else
	--[[ old engines handle transporting rules entirely on their own,
	     but mark units anyway so that other code doesn't need to
	     replicate these checks ]]
	local valkDef = UnitDefs.gunshiptrans
	local valkMaxMass = valkDef.transportmass
	local valkMaxSize = valkDef.transportsize
	for name, ud in pairs (UnitDefs) do
		if ud.mass > valkMaxMass or
				ud.footprintx > valkMaxSize or
				ud.footprintz > valkMaxSize then
			ud.customparams.requireheavytrans = 1
		end
	end
end

local ai_start_units = VFS.Include("LuaRules/Configs/ai_commanders.lua")
for i = 1, #ai_start_units do
	if UnitDefs[ai_start_units[i]] then -- valid entries can still be nil in wiki exporter script
		UnitDefs[ai_start_units[i]].customparams.ai_start_unit = true
	end
end
