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
		error (name.."."..key.. " is set to " .. original_value .. " but would actually be " .. sanitized_value .. " ingame! Please put the correct value in the def (with 3 digit precision)")
	end

	wd[key] = sanitized_value + 1E-5
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
	end
end

for unitDefName, unitDef in pairs (UnitDefs) do
	processWeapons(unitDefName, unitDef)
end
