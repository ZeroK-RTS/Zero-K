
local BASE_STR_MULT = 1/1.15

--Spring.Echo('GetLightsFromUnitDefs init')
local plighttable = {}
for weaponDefID = 1, #WeaponDefs do
	--These projectiles should have lights:
		--Cannon (projectile size: tempsize = 2.0f + std::min(wd.customParams.shield_damage * 0.0025f, wd.damageAreaOfEffect * 0.1f);)
		--Dgun
		--MissileLauncher
		--StarburstLauncher
		--LaserCannon
		--LightningCannon
		--BeamLaser
	--Shouldnt:
		--AircraftBomb
		--Shield
		--TorpedoLauncher
	
	local weaponDef = WeaponDefs[weaponDefID]
	local customParams = weaponDef.customParams or {}
	
	local r = weaponDef.visuals.colorR + 0.2
	local g = weaponDef.visuals.colorG + 0.2
	local b = weaponDef.visuals.colorB + 0.2
	
	local weaponData = {r = r, g = g, b = b, radius = 100}
	
	if (weaponDef.type == 'Cannon') then
		if customParams.single_hit then
			weaponData.beamOffset = 1
			weaponData.beam = true
			r = 1
			g = 2
			b = 2
		else
			weaponData.radius = 10 + 90 * weaponDef.size
		end
	elseif (weaponDef.type == 'LaserCannon') then
		weaponData.radius = 150 * weaponDef.size
	elseif (weaponDef.type == 'DGun') then
		weaponData.radius = 800
	elseif (weaponDef.type == 'MissileLauncher') then
		weaponData.radius = 150 * weaponDef.size
	elseif (weaponDef.type == 'StarburstLauncher') then
		weaponData.radius = 350
	elseif (weaponDef.type == 'LightningCannon') then
		weaponData.radius = math.min(weaponDef.range, 250)
		weaponData.beam = true
	elseif (weaponDef.type == 'BeamLaser') then
		weaponData.radius = math.min(weaponDef.range, 135)
		weaponData.beam = true
		if weaponDef.beamTTL > 2 then
			weaponData.fadeTime = weaponDef.beamTTL
			weaponData.fadeOffset = 0
		end
	end
	
	-- For long lasers or projectiles
	if customParams.light_beam_mult then
		-- Do not use this on projectiles with variable time to live (those with non-spherical ranges).
		weaponData.beamOffset = 1
		weaponData.beam = true
		weaponData.beamMult = tonumber(customParams.light_beam_mult)
		weaponData.beamMultFrames = tonumber(customParams.light_beam_mult_frames)
	end
	
	if customParams.light_fade_time and customParams.light_fade_offset then
		weaponData.fadeTime = tonumber(customParams.light_fade_time)
		weaponData.fadeOffset = tonumber(customParams.light_fade_offset)
	end
	
	if customParams.light_radius then
		weaponData.radius = tonumber(customParams.light_radius)
	end
	
	if customParams.light_ground_height then
		weaponData.groundHeightLimit = tonumber(customParams.light_ground_height)
	end
	
	if customParams.light_camera_height then
		weaponData.cameraHeightLimit = tonumber(customParams.light_camera_height)
	end
	
	if customParams.light_beam_start then
		weaponData.beamStartOffset = tonumber(customParams.light_beam_start)
	end
	
	if customParams.light_beam_offset then
		weaponData.beamOffset = tonumber(customParams.light_beam_offset)
	end
	
	if customParams.light_elevation then
		weaponData.elevation = tonumber(customParams.light_elevation)
	end
	
	if customParams.light_color then
		local colorList = string.split(customParams.light_color, " ")
		weaponData.r = colorList[1]
		weaponData.g = colorList[2]
		weaponData.b = colorList[3]
	end
	
	weaponData.r = weaponData.r * BASE_STR_MULT
	weaponData.g = weaponData.g * BASE_STR_MULT
	weaponData.b = weaponData.b * BASE_STR_MULT
	weaponData.a = tonumber(customParams.light_alpha) or 0.11
	
	if weaponData.radius > 0 and not customParams.fake_weapon then
		plighttable[weaponDefID] = weaponData
	end
end

return plighttable
