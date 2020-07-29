local UPDATES_PER_SECOND = 30

local redDefault = {1.0,0.1,0.1,0.9}
local orangeDefault = {0.9,0.5,0.1,0.8}
local greenDefault = {0.1,0.9,0.2,0.8}
local blueDefault = {0.1,0.3,0.9,0.9}

local highAltFadeIn = 10*UPDATES_PER_SECOND
local lowAltFadeIn = 5*UPDATES_PER_SECOND

local trackedMissiles = {
  -- Trinity/Nuke
	[WeaponDefNames.staticnuke_crblmssl.id] = {
		color = redDefault,
		humanName = "Nuclear Missile",
		fadeIn = 30*UPDATES_PER_SECOND
	},
}
	--[[ Disable everything except Trinity for now, until missile prediction with acceleration is fixed
	-- EOS/Tacnuke
	[WeaponDefNames.tacnuke_weapon.id] = {
		color = redDefault,
		humanName = "Tactical Nuke (Missile Silo)",
		fadeIn = lowAltFadeIn
	},
	-- Shockley
	[WeaponDefNames.empmissile_emp_weapon.id] = {
		color = blueDefault,
		humanName = "EMP Missile",
		fadeIn = highAltFadeIn
	},
	-- Inferno
	[WeaponDefNames.napalmmissile_weapon.id] = {
		color = orangeDefault,
		humanName = "Inferno Missile",
		fadeIn = lowAltFadeIn
	},
	-- Quake
	[WeaponDefNames.seismic_seismic_weapon.id] = {
		color = greenDefault,
		humanName = "Seismic Missile",
		fadeIn = lowAltFadeIn
	},
	-- Scylla
	[WeaponDefNames.subtacmissile_tacnuke.id] = {
		color = redDefault,
		humanName = "Tactical Nuke (Nuclear Submarine)",
		fadeIn = lowAltFadeIn
	},
}

local slamDefaults = {
	color = redDefault,
	humanName = "Tactical Nuke (Commander S.L.A.M Rocket)",
	fadeIn = lowAltFadeIn
}
for i=0,8 do
  -- S.L.A.M variants
  trackedMissiles[WeaponDefNames[i .. '_commweapon_slamrocket'].id] = slamDefaults
end
--]]

return trackedMissiles
