--[[ Sanitize to whole frames (plus leeways because float arithmetic is bonkers).
     The engine uses full frames for actual reload times, but forwards the raw
     value to LuaUI (so for example calculated DPS is incorrect without sanitisation). ]]
local function round_to_frames(name, wd, key)
	local original_value = wd[key]
	if not original_value then
		-- even reloadtime can be nil (shields, death explosions)
		return
	end

	local frames = math.max(1, math.floor((original_value + 1E-3) * Game.gameSpeed))

	local sanitized_value = frames / Game.gameSpeed
	if math.abs (original_value - sanitized_value) > 1E-3 then
		-- don't just silently fix since else people can change values around
		-- thinking they're doing something while not having any effect
		error (name.."."..key.. " is set to " .. original_value .. " but would actually be " .. sanitized_value .. " ingame! Please put the correct value in the def (with 3 digit precision)")
	end

	wd[key] = sanitized_value + 1E-5
end

local function print_bounce_warning(name, wd)
	if (wd.numbounce or wd.bouncerebound or wd.bounceslip) and not (
			(wd.customparams and wd.customparams.stays_underwater == 1) or
			name == "hoverdepthcharge.depthcharge" or name == "hoverdepthcharge.fake_depthcharge" or
			wd.weapontype == "Cannon") then
		Spring.Echo("===============================================================")
		Spring.Echo("*************************** WARNING ***************************")
		Spring.Echo("Ground bounce detected for", name, wd.weapontype)
		Spring.Echo("There is a risk of it falling through the ground indefinitely.")
		Spring.Echo("Ensure appropriate hax is in place.")
		Spring.Echo("For torpedoes use \"stays_underwater\" customParam.")
		Spring.Echo("See LuaRules/Gadgets/weapon_torpedo_stay_underwater.lua.")
		Spring.Echo("************************* END WARNING *************************")
		Spring.Echo("===============================================================")
	end
end

local function check_lasercannon_range(name, wd)
	if wd.weapontype ~= "LaserCannon" then
		return
	end

	local original_range = wd.range
	local v = wd.weaponvelocity / Game.gameSpeed

	local frames = math.max(1, math.floor((original_range + 0.5) / v))
	local sanitized_range = frames * v
	local next_range = (frames + 1) * v
	local velocty_for_current_range = (original_range / frames) * Game.gameSpeed
	if math.abs(original_range - sanitized_range) > 1 then
		-- Warning instead of Error for now, to let mods adjust
		-- stabled in 2021-06, change to `error()` later
		Spring.Echo(name..".range is set to " .. original_range .. " but would actually be " .. sanitized_range .. " ingame! Please either:\n" ..
			" - set range to " .. math.floor(sanitized_range + 0.5) .. " (no logic change)\n" ..
			" - set range to " .. math.floor(next_range + 0.5) .. " (next available breakpoint)\n" ..
			" - set weaponVelocity to " .. velocty_for_current_range .. " (to keep current range)")
	end

	wd.range = sanitized_range + 1E-5
end

local function processWeapons(unitDefName, unitDef)
	local weaponDefs = unitDef.weapondefs
	if not weaponDefs then
		return
	end

	for weaponDefName, weaponDef in pairs (weaponDefs) do
		local fullWeaponName = unitDefName .. "." .. weaponDefName
		round_to_frames(fullWeaponName, weaponDef, "reloadtime")
		round_to_frames(fullWeaponName, weaponDef, "burstrate")
		print_bounce_warning(fullWeaponName, weaponDef)
		check_lasercannon_range(fullWeaponName, weaponDef)
	end
end

for unitDefName, unitDef in pairs (UnitDefs) do
	processWeapons(unitDefName, unitDef)
end
