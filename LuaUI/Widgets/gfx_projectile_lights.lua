--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Projectile Lights",
		version   = 3,
		desc      = "Collects projectiles and sends them to the deferred renderer.",
		author    = "GoogleFrog (beherith orgional)",
		date      = "5 March 2016",
		license   = "GPL V2",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetProjectilesInRectangle = Spring.GetProjectilesInRectangle
local spGetVisibleProjectiles     = Spring.GetVisibleProjectiles
local spGetProjectilePosition     = Spring.GetProjectilePosition
local spGetProjectileType         = Spring.GetProjectileType
local spGetProjectileDefID        = Spring.GetProjectileDefID
local spGetPieceProjectileParams  = Spring.GetPieceProjectileParams 
local spGetProjectileVelocity     = Spring.GetProjectileVelocity 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lightsEnabled = true

local colorOverride = {1, 1, 1}
local colorBrightness = 1
local radiusOverride = 200
local overrideParam = {r = 1, g = 1, b = 1, radius = 200}
local doOverride = false

local wantLoadParams = false

local function Format(value)
	return string.format("%.2f", value)
end

local function ApplySetting()
	overrideParam.r = colorOverride[1] * colorBrightness
	overrideParam.g = colorOverride[2] * colorBrightness
	overrideParam.b = colorOverride[3] * colorBrightness
	overrideParam.radius = radiusOverride
	Spring.Utilities.TableEcho(overrideParam)
	Spring.Echo("light_color = [[" .. Format(overrideParam.r) .. " " .. Format(overrideParam.g) .. " " .. Format(overrideParam.b) .. "]]")
	Spring.Echo("light_radius = " .. Format(radiusOverride) .. ",")
end

local function LoadParams(param)
	options.light_radius.value = param.radius
	options.light_brightness.value = math.max(param.r, param.g, param.b)
	options.light_color.value = {
		param.r / options.light_brightness.value,
		param.g / options.light_brightness.value,
		param.b / options.light_brightness.value,
	}
	
	radiusOverride = options.light_radius.value
	colorBrightness = options.light_brightness.value
	colorOverride = options.light_color.value
	
	Spring.Echo("Loading Settings")
	ApplySetting()
	wantLoadParams = false
	WG.RemakeEpicMenu()
end

options_path = 'Settings/Graphics/Lighting'
options_order = {'light_projectile_enable', 'light_override', 'light_radius', 'light_brightness', 'light_color', 'light_reload'}
options = {
	light_projectile_enable = {
		name = "Enable Projectile Lights",
		type = 'bool',
		value = true,
		OnChange = function (self) 
			lightsEnabled = self.value
		end,
	},
	light_override = {
		name = "Override Parameters",
		desc = "Override lights with the following parameters.",
		type = 'bool',
		value = false,
		OnChange = function (self) 
			doOverride = self.value
		end,
		advanced = true
	},
	light_radius = {
		name = 'Light Radius',
		type = 'number',
		value = 3,
		min = 20, max = 1000, step = 10,
		OnChange = function (self)
			radiusOverride = self.value
			ApplySetting()
		end,
		advanced = true
	},
	light_brightness = {
		name = 'Light Brightness',
		type = 'number',
		value = 3,
		min = 0.05, max = 5, step = 0.05,
		OnChange = function (self) 
			colorBrightness = self.value
			ApplySetting()
		end,
		advanced = true
	},
	light_color = {
		name = 'Light Color',
		type = 'colors',
		value = { 0.8, 0.8, 0.8, 1},
		OnChange = function (self)
			colorOverride = self.value
			ApplySetting()
		end,
		advanced = true
	},
	light_reload = {
		name = 'Reload',
		type = 'button',
		desc = "Reload settings from the next projectile fired.",
		OnChange = function (self)
			wantLoadParams = true
		end,
		advanced = true
	},
}

local gibParams = {r = 0.5, g = 0.5, b = 0.25, radius = 100}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local projectileLightTypes = {}
	--[1] red
	--[2] green
	--[3] blue
	--[4] radius
	--[5] BEAMTYPE, true if BEAM

local function Split(s, separator)
	local results = {}
	for part in s:gmatch("[^"..separator.."]+") do
		results[#results + 1] = part
	end
	return results
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Light Defs

local function GetLightsFromUnitDefs()
	--Spring.Echo('GetLightsFromUnitDefs init')
	local plighttable = {}
	for weaponDefID = 1, #WeaponDefs do
		--These projectiles should have lights:
			--Cannon (projectile size: tempsize = 2.0f + std::min(wd.damages[0] * 0.0025f, wd.damageAreaOfEffect * 0.1f);)
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
			weaponData.radius = math.min(weaponDef.range, 150)
			weaponData.beam = true
			if weaponDef.beamTTL > 2 then
				weaponData.fadeTime = weaponDef.beamTTL
			end
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
		
		if customParams.light_color then
			local colorList = Split(customParams.light_color, " ")
			weaponData.r = colorList[1]
			weaponData.g = colorList[2]
			weaponData.b = colorList[3]
		end
		
		if weaponData.radius > 0 and not customParams.fake_weapon then
			plighttable[weaponDefID] = weaponData
		end
	end
	return plighttable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Projectile Collection

local function GetCameraHeight()
	local camX, camY, camZ = Spring.GetCameraPosition()
	return camY - math.max(Spring.GetGroundHeight(camX, camZ), 0)
end

local function ProjectileLevelOfDetailCheck(param, proID, fps, height)
	if param.cameraHeightLimit and param.cameraHeightLimit < height then
		if param.cameraHeightLimit*3 > height then
			local fraction = param.cameraHeightLimit/height
			if fps < 60 then
				fraction = fraction*fps/60
			end
			local ratio = 1/fraction
			return (proID%ratio < 1)
		else
			return false
		end
	end
	
	if param.beam then
		return true
	end
	
	if fps < 60 then
		local fraction = fps/60
		local ratio = 1/fraction
		return (proID%ratio < 1)
	end
	return true
end

local function GetProjectileLights(beamLights, beamLightCount, pointLights, pointLightCount)

	if not lightsEnabled then
		return beamLights, beamLightCount, pointLights, pointLightCount
	end

	local projectiles = spGetVisibleProjectiles()
	if #projectiles == 0 then
		return beamLights, beamLightCount, pointLights, pointLightCount
	end
	
	local fps = Spring.GetFPS()
	local cameraHeight = math.floor(GetCameraHeight()*0.01)*100
	--Spring.Echo("cameraHeight", cameraHeight, "fps", fps)
	

	local no_duplicate_projectileIDs_hackyfix = {}
	for i, pID in ipairs(projectiles) do
		if no_duplicate_projectileIDs_hackyfix[pID] == nil then -- hacky hotfix for https://springrts.com/mantis/view.php?id=4551
			--Spring.Echo(Spring.GetDrawFrame(), i, pID)
			no_duplicate_projectileIDs_hackyfix[pID] = true
			local x, y, z = spGetProjectilePosition(pID)
			--Spring.Echo("projectilepos = ", x, y, z, 'id', pID)
			local weapon, piece = spGetProjectileType(pID)
			if piece then
				local explosionflags = spGetPieceProjectileParams(pID)
				if explosionflags and (explosionflags%32) > 15  then --only stuff with the FIRE explode tag gets a light
					--Spring.Echo('explosionflag = ', explosionflags)
					pointLightCount = pointLightCount + 1
					pointLights[pointLightCount] = {px = x, py = y, pz = z, param = (doOverride and overrideParam) or gibParams, colMult = 1}
				end
			else
				lightParams = projectileLightTypes[spGetProjectileDefID(pID)]
				if wantLoadParams and lightParams then
					LoadParams(lightParams)
				end
				if lightParams and ProjectileLevelOfDetailCheck(lightParams, pID, fps, cameraHeight) then
					if lightParams.beam then --BEAM type
						local deltax, deltay, deltaz = spGetProjectileVelocity(pID) -- for beam types, this returns the endpoint of the beam]
						if lightParams.beamOffset then
							local m = lightParams.beamOffset
							x, y, z = x - deltax*m, y - deltay*m, z - deltaz*m
						end
						if lightParams.beamStartOffset then
							local m = lightParams.beamStartOffset
							x, y, z = x + deltax*m, y + deltay*m, z + deltaz*m
							deltax, deltay, deltaz = deltax*(1 - m), deltay*(1 - m), deltaz*(1 - m) 
						end
						beamLightCount = beamLightCount + 1
						beamLights[beamLightCount] = {px = x, py = y, pz = z, dx = deltax, dy = deltay, dz = deltaz, param = (doOverride and overrideParam) or lightParams}
						if lightParams.fadeTime then
							local timeToLive = Spring.GetProjectileTimeToLive(pID)
							beamLights[beamLightCount].colMult = timeToLive/lightParams.fadeTime
						else
							beamLights[beamLightCount].colMult = 1
						end
					else -- point type
						if not (lightParams.groundHeightLimit and lightParams.groundHeightLimit < (y - math.max(Spring.GetGroundHeight(y, y), 0))) then
							pointLightCount = pointLightCount + 1
							pointLights[pointLightCount] = {px = x, py = y, pz = z, param = (doOverride and overrideParam) or lightParams}
							-- Use the following to check heatray fadeout parameters.
							--local timeToLive = Spring.GetProjectileTimeToLive(pID)
							--Spring.MarkerAddPoint(x,y,z,timeToLive)
							if lightParams.fadeTime and lightParams.fadeOffset then
								local timeToLive = Spring.GetProjectileTimeToLive(pID)
								pointLights[pointLightCount].colMult = math.max(0, (timeToLive + lightParams.fadeOffset)/lightParams.fadeTime)
							else
								pointLights[pointLightCount].colMult = 1
							end
						end
					end
				end
			end
		end
	end 

	return beamLights, beamLightCount, pointLights, pointLightCount
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if WG.DeferredLighting_RegisterFunction then
		WG.DeferredLighting_RegisterFunction(GetProjectileLights)
		projectileLightTypes = GetLightsFromUnitDefs()
	end
end