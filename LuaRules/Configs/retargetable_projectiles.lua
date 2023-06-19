-- In elmos/frame
local projectileDefs = {
	[WeaponDefNames["bomberheavy_arm_pidr"].id] = {
		speed = 19,
		rangeSqr = 121,
		leadMult = 0.4,
	},
	[WeaponDefNames["hoverdepthcharge_depthcharge"].id] = {
		speed = 3.53,
		track = true,
		alwaysBurnblow = true,
		rangeSqr = 121,
		underwaterTrack = true,
		leadMult = 0.6,
	},
	[WeaponDefNames["hoverdepthcharge_fake_depthcharge"].id] = {
		speed = 8, -- For prediction.
		alwaysBurnblow = true,
		moveCtrlSpeed = 5.3,
		moveCtrlAccel = 0.02,
		moveCtrlAccelAccel = 0.01,
		moveCtrlMaxSpeed = 30,
		groundFloat = 5,
		rangeSqr = 121,
		leadMult = 0.75,
		useOwnerWeapon = 2,
	},
}

local projectileLead = {
	[WeaponDefNames["cloakraid_emg"].id] = WeaponDefNames["cloakraid_emg"].projectilespeed,
	[WeaponDefNames["vehraid_heatray"].id] = WeaponDefNames["vehraid_heatray"].projectilespeed,
	[WeaponDefNames["hoverraid_gauss"].id] = WeaponDefNames["hoverraid_gauss"].projectilespeed,
	[WeaponDefNames["shieldraid_laser"].id] = WeaponDefNames["shieldraid_laser"].projectilespeed,
	[WeaponDefNames["jumpraid_flamethrower"].id] = WeaponDefNames["jumpraid_flamethrower"].projectilespeed,
}

local projectileLeadLimit = {
	[WeaponDefNames["cloakraid_emg"].id] = WeaponDefNames["cloakraid_emg"].leadLimit,
	[WeaponDefNames["vehraid_heatray"].id] = WeaponDefNames["vehraid_heatray"].leadLimit,
	[WeaponDefNames["hoverraid_gauss"].id] = WeaponDefNames["hoverraid_gauss"].leadLimit,
	[WeaponDefNames["shieldraid_laser"].id] = WeaponDefNames["shieldraid_laser"].leadLimit,
	[WeaponDefNames["jumpraid_flamethrower"].id] = WeaponDefNames["jumpraid_flamethrower"].leadLimit,
}

for key, value in pairs(projectileLeadLimit) do
	if value <= 0 then
		projectileLeadLimit[key] = nil
	end
end

local waterWeapon = {
	[WeaponDefNames["hoverraid_gauss"].id] = true,
}

return projectileDefs, projectileLead, projectileLeadLimit, waterWeapon
