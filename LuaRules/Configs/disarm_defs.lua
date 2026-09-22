
local FRAMES_PER_SECOND = Game.gameSpeed
local disarmWeapons = {}
local paraWeapons = {}
local overstunDamageMult = {}
local wantedWeaponList = {}

for wid = 1, #WeaponDefs do
	local wd = WeaponDefs[wid]
	local wcp = wd.customParams or {}
	if wcp.disarmdamagemult then
		disarmWeapons[wid] = {
			damageMult = wcp.disarmdamagemult,
			normalDamage = 1 - (wcp.disarmdamageonly or 0),
			disarmTimer = wcp.disarmtimer*FRAMES_PER_SECOND,
			overstunTime = wcp.overstun_time*FRAMES_PER_SECOND,
		}
		wantedWeaponList[#wantedWeaponList + 1] = wid
	elseif wd.paralyzer or wd.customParams.extra_damage then
		local paraTime = wd.paralyzer and wd.customParams.emp_paratime or wd.customParams.extra_paratime
		paraWeapons[wid] = {
			empTime = paraTime * FRAMES_PER_SECOND,
			overstunTime = wcp.overstun_time*FRAMES_PER_SECOND,
		}
		wantedWeaponList[#wantedWeaponList + 1] = wid
	end
	if wd.customParams and wd.customParams.overstun_damage_mult then
		overstunDamageMult[wid] = tonumber(wd.customParams.overstun_damage_mult)
	end
end
return disarmWeapons, paraWeapons, overstunDamageMult, wantedWeaponList
