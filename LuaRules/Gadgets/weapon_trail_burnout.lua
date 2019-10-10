if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name = "Trail Burnout",
		desc = "Provide ability to changes weapon trail CEG after a customParam-specified time, or change specific weapon into customParam-specified weapon when underwater",
		author = "Anarchid",
		date = "14.01.2013",
		license = "Public domain",
		layer = -1, --before lups_shockwaves.lua (so that there's no shockwave after we block explosion effect)
		enabled = false
	}
end

local defaultCeg = ''
local burnoutWeapon = {}
local burnoutProjectile = {}
local underwaterWeapon = {}
local underwaterProjectile = {}
local noExplosionVFX = {}

local spGetGameFrame     = Spring.GetGameFrame
local spSetProjectileCeg = Spring.SetProjectileCEG
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spGetProjectileTarget = Spring.GetProjectileTarget
local spSetProjectileCollision = Spring.SetProjectileCollision
local spSetProjectileVelocity = Spring.SetProjectileVelocity
local spSetProjectileGravity  = Spring.SetProjectileGravity
local spSpawnProjectile = Spring.SpawnProjectile
local spSetProjectileTarget = Spring.SetProjectileTarget
local spSetPieceProjectileParams = Spring.SetPieceProjectileParams
local spGetUnitTeam = Spring.GetUnitTeam

function gadget:Initialize()
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]
		if wd.customParams then
			if wd.customParams.trail_burnout then
				burnoutWeapon[wd.id] = {
					burnout = wd.customParams.trail_burnout,
					burnoutCeg = wd.customParams.trail_burnout_ceg or defaultCeg
				}
				Script.SetWatchProjectile(wd.id, true)
			end
			if wd.customParams.torp_underwater then
				underwaterWeapon[wd.id] = {
					torpName = wd.customParams.torp_underwater,
				}
				Script.SetWatchProjectile(wd.id, true)
				Script.SetWatchExplosion(wd.id, true)
			end
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if burnoutWeapon[weaponID] then
		burnoutProjectile[proID] = {
			startFrame = spGetGameFrame(),
			burnout = burnoutWeapon[weaponID].burnout,
			burnoutCeg = burnoutWeapon[weaponID].burnoutCeg or defaultCeg
		}
	end
	if underwaterWeapon[weaponID] then
		underwaterProjectile[proID] = {
			owner = proOwnerID,
			weaponID = weaponID,
			torpName = underwaterWeapon[weaponID].torpName,
		}
	end
end

function gadget:ProjectileDestroyed(proID, proOwnerID, weaponID)
	burnoutProjectile[proID] = nil
	underwaterProjectile[proID] = nil
end

function gadget:Explosion(weaponDefID, px, py, pz, ownerID)
	if noExplosionVFX[weaponDefID] then
		px = math.modf(px+0.5)
		pz = math.modf(pz+0.5)
		if noExplosionVFX[weaponDefID][px..pz]==ownerID then
			noExplosionVFX[weaponDefID][px..pz] = nil
			return true --noVFX
		end
	end
end

-------------------------------------------
-------------------------------------------

local function StartBurnoutTrail(frame)
	for id, proj in pairs(burnoutProjectile) do
		if proj.startFrame+proj.burnout <= frame then
			spSetProjectileCeg(id, proj.burnoutCeg)
			burnoutProjectile[id] = nil
		end
	end
end

local function ConvertWeaponUnderwater()
	for id,proj in pairs(underwaterProjectile) do
		if spSpawnProjectile and proj.torpName and WeaponDefNames[proj.torpName] then
			local px,py,pz = Spring.GetProjectilePosition(id)
			if py <= -9 then -- projectile is underwater. Set to submarine waterline (bottom = -20, top = 0) to let it hit submarine first rather than doing a conversion to torpedo
				local defID = WeaponDefNames[proj.torpName].id
				local ownerTeamID = spGetUnitTeam(proj.owner)
				local pvx, pvy, pvz = spGetProjectileVelocity(id)
				local projectileParams = {
					pos = {px, py, pz},
					speed = {pvx, pvy, pvz},
					owner = proj.owner,
					team = ownerTeamID,
				}
				local a, b = spGetProjectileTarget(id)
				
				spSetPieceProjectileParams(id,0) --not sure what this do, it set piece explosion tag to 0 (disable)
				px = math.modf(px+0.5) --round the number to nearest integer
				pz = math.modf(pz+0.5)
				noExplosionVFX[proj.weaponID] = noExplosionVFX[proj.weaponID] or {}
				noExplosionVFX[proj.weaponID][px..pz] = proj.owner
				spSetProjectileVelocity(id,0,0,0) --stop projectile for more accurate
				spSetProjectileGravity(id,0)
				
				spSetProjectileCollision(id) --explosion to destroy projectile. It also trigger wave in Dynamic water
				local newID = spSpawnProjectile(defID, projectileParams)
				if type(b)=='number' then
					spSetProjectileTarget(newID,b)
				elseif type(b)=='table' then
					spSetProjectileTarget(newID,b[1],b[2],b[3])
				elseif type(a)=='number' then
					spSetProjectileTarget(newID,b,a)
				end
				underwaterProjectile[id]=nil
			end
		else
			if spSpawnProjectile then
				Spring.Echo("weapon_trail_burnout.lua ERROR:non existent torpedo name :".. (proj.torpName or "nil"))
			end
			underwaterProjectile[id]=nil
		end
	end
end

function gadget:GameFrame(f)
	StartBurnoutTrail(f)
	if f % 7 == 0 then
		ConvertWeaponUnderwater()
	end
end
