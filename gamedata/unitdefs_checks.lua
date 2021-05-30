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

local function check_lasercannon_range(name, wd)
	if wd.weapontype ~= "LaserCannon" then
		return
	end

	local original_range = wd.range
	local v = wd.weaponvelocity / Game.gameSpeed

	local sanitized_range = math.max(1, math.floor((original_range + 0.5) / v)) * v
	if math.abs(original_range - sanitized_range) > 1 then
		-- Warning instead of Error for now, to let mods adjust
		-- instated on 2021-05-30, change to `error()` later
		Spring.Echo(name..".range is set to " .. original_range .. " but would actually be " .. sanitized_range .. " ingame!\nPlease put the correct value in the def (rounded to the nearest integer) or modify weaponVelocity")
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
		check_lasercannon_range(fullWeaponName, weaponDef)
	end
end

for unitDefName, unitDef in pairs (UnitDefs) do
	processWeapons(unitDefName, unitDef)
end
