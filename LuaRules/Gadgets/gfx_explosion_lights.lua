local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name = "Explosion and muzzle fire events",
		desc = "Exposes widget:Barrelfire and widget:VisibleExplosion",
		author = "Floris, GoogleFrog",
		date = "April 2017",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then
	local SendToUnsynced = SendToUnsynced
	local spGetProjectilePosition = Spring.GetProjectilePosition

	local muzzleProjectiles = {}
	local watchedExplosions = {}
	local watchedProjectiles = {}
	
	local function LoadConfig(path)
		local success, result = pcall(VFS.Include, path)
		return success and result
	end
	
	local function ProcessWeapon(wdid, weaponLightConfig, weaponDistortConfig)
		local watchProjectile = wdid and (
			weaponLightConfig and (weaponLightConfig.muzzleFlashLights[wdid] or weaponLightConfig.projectileDefLights[wdid]) or
			weaponDistortConfig and (weaponDistortConfig.muzzleFlashDistortions[wdid] or weaponDistortConfig.muzzleFlashDistortions[wdid])
		)
		local watchExplode = wdid and (
			weaponLightConfig and (weaponLightConfig.explosionLights[wdid] or weaponLightConfig.explosionLights[wdid]) or
			weaponDistortConfig and (weaponDistortConfig.explosionDistortions[wdid] or weaponDistortConfig.explosionDistortions[wdid])
		)
		if watchProjectile then
			muzzleProjectiles[wdid] = true
			Script.SetWatchProjectile(wdid, true)
			watchedProjectiles[wdid] = true
		end
		if watchExplode then
			Script.SetWatchExplosion(wdid, true)
			watchedExplosions[wdid] = true
		end
	end
	
	function gadget:Initialize()
		local weaponLightConfig = LoadConfig('luarules/configs/DeferredLightsGL4WeaponsConfig.lua')
		local weaponDistortConfig = LoadConfig('luarules/configs/DistortionGL4WeaponsConfig.lua')
		for wdid = 1, #WeaponDefs do
			ProcessWeapon(wdid, weaponLightConfig, weaponDistortConfig)
		end
	end

	function gadget:Shutdown()
		for wdid in pairs(watchedExplosions) do
			Script.SetWatchExplosion(wdid, false)
		end
		for wdid in pairs(watchedProjectiles) do
			Script.SetWatchProjectile(wdid, false)
		end
	end

	function gadget:Explosion(weaponID, px, py, pz, ownerID, projectileID)
		SendToUnsynced("explosion_light", px, py, pz, weaponID, ownerID)
	end

	function gadget:ProjectileCreated(projectileID, ownerID, weaponID)
		if muzzleProjectiles[weaponID] then
			local px, py, pz = spGetProjectilePosition(projectileID)
			SendToUnsynced("barrelfire_light", px, py, pz, weaponID, ownerID)
		end
	end
else -- Unsynced
	local myPlayerID = Spring.GetLocalPlayerID()
	local myAllyID = Spring.GetLocalAllyTeamID()
	local fullView = select(2, Spring.GetSpectatingState())
	local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
	local spIsPosInLos = Spring.IsPosInLos

	function gadget:PlayerChanged(playerID)
		if playerID == myPlayerID then
			myPlayerID = Spring.GetLocalPlayerID()
			myAllyID = Spring.GetLocalAllyTeamID()
			fullView = select(2, Spring.GetSpectatingState())
		end
	end

	local function SpawnExplosion(_, px, py, pz, weaponID, ownerID)
		if ownerID ~= nil and Script.LuaUI("VisibleExplosion") then
			if fullView or spGetUnitAllyTeam(ownerID) == myAllyID or spIsPosInLos(px, py, pz, myAllyID) then
				Script.LuaUI.VisibleExplosion(px, py, pz, weaponID, ownerID)
			end
		end
	end

	local function SpawnBarrelfire(_, px, py, pz, weaponID, ownerID)
		if ownerID ~= nil and Script.LuaUI("Barrelfire") then
			if fullView or spGetUnitAllyTeam(ownerID) == myAllyID or spIsPosInLos(px, py, pz, myAllyID) then
				Script.LuaUI.Barrelfire(px, py, pz, weaponID, ownerID)
			end
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("explosion_light", SpawnExplosion)
		gadgetHandler:AddSyncAction("barrelfire_light", SpawnBarrelfire)
	end

	function gadget:Shutdown()
		gadgetHandler.RemoveSyncAction("explosion_light")
		gadgetHandler.RemoveSyncAction("barrelfire_light")
	end
end
