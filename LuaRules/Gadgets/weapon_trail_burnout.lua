function gadget:GetInfo()
	return {
		name = "Trail Burnout",
		desc = "Provide ability to changes weapon trail CEG after a customParam-specified time, or change specific weapon into customParam-specified weapon when underwater",
		author = "Anarchid",
		date = "14.01.2013",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

------ SYNCED -------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then

local defaultCeg = ''
local burnoutWeapon = {}
local burnoutProjectile = {}
local underwaterWeapon = {}
local underwaterProjectile = {}

local spGetGameFrame     = Spring.GetGameFrame
local spSetProjectileCeg = Spring.SetProjectileCEG
local scSetWatchWeapon   = Script.SetWatchWeapon
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spGetProjectileTarget = Spring.GetProjectileTarget
local spSetProjectileCollision = Spring.SetProjectileCollision
local spSpawnProjectile = Spring.SpawnProjectile
local spSetProjectileTarget = Spring.SetProjectileTarget
local spGetUnitTeam = Spring.GetUnitTeam
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
				scSetWatchWeapon(wd.id, true)
			end
			if wd.customParams.torp_underwater then
				underwaterWeapon[wd.id] = {
					torpName = wd.customParams.torp_underwater,
					tracking = wd.customParams.tracking,
					model = wd.customParams.model,
				}
				scSetWatchWeapon(wd.id, true)
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
			torpName = underwaterWeapon[weaponID].torpName,
			tracking = underwaterWeapon[weaponID].tracking,
			model = underwaterWeapon[weaponID].model,
		}
	end	
end

function gadget:ProjectileDestroyed(proID, proOwnerID, weaponID)
	burnoutProjectile[proID] = nil
	underwaterProjectile[proID] = nil
end

function gadget:GameFrame(f)
	StartBurnoutTrail(f)
	if f % 7 == 0 then
		ConvertWeaponUnderwater()
	end
end
-------------------------------------------
-------------------------------------------
function StartBurnoutTrail(frame)
	for id, proj in pairs(burnoutProjectile) do
		if proj.startFrame+proj.burnout <= frame then
			spSetProjectileCeg(id, proj.burnoutCeg)
			burnoutProjectile[id] = nil
		end
	end
end

function ConvertWeaponUnderwater()
	for id,proj in pairs(underwaterProjectile) do
		if spSpawnProjectile and proj.torpName and WeaponDefNames[proj.torpName] then
			local px,py,pz = Spring.GetProjectilePosition(id)
			if py <= 0 then
				local defID = WeaponDefNames[proj.torpName].id
				local pvx, pvy, pvz = spGetProjectileVelocity(id)
				local projectileParams = {
					pos = {px, py, pz},
					speed = {pvx, pvy, pvz},
					owner = proj.owner,
					tracking = (proj.tracking=="true"),
					model = proj.model,
					team = spGetUnitTeam(proj.owner),
				}
				local a, b = spGetProjectileTarget(id)
				spSetPieceProjectileParams(id,0) --should disable explosion but may not work
				spSetProjectileCollision(id)
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
end
----- END SYNCED ---------------------------------------------------
