function gadget:GetInfo()
  return {
    name      = "Projectile Retarget",
    desc      = "Retargets newly created projectiles and implements burnblow.",
    author    = "Google Frog",
    date      = "10 June 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------

local FEATURE = 102
local GROUND = 103
local UNIT = 117

local projectiles = {}
local thereAreProjectiles = false

local spGetProjectileTarget   = Spring.GetProjectileTarget
local spGetUnitVelocity       = Spring.GetUnitVelocity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileTeamID   = Spring.GetProjectileTeamID
local spValidUnitID           = Spring.ValidUnitID
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spSetProjectileVelocity = Spring.SetProjectileVelocity

local dist3D = Spring.Utilities.Vector.Dist3D

-- In elmos/frame
local projectileDefs = {
	[WeaponDefNames["bomberheavy_arm_pidr"].id] = {
		speed = 19,
		rangeSqr = 121,
		leadMult = 0.4,
	},
	[WeaponDefNames["hoverdepthcharge_depthcharge"].id] = {
		speed = 3,
		track = true,
		alwaysBurnblow = true,
		rangeSqr = 121,
		underwaterTrack = true,
		leadMult = 0.5,
	},
	[WeaponDefNames["hoverdepthcharge_fake_depthcharge"].id] = {
		speed = 6,
		alwaysBurnblow = true,
		moveCtrlSpeed = 6,
		groundFloat = 5,
		rangeSqr = 121,
		leadMult = 0.5,
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

-- Recluse projectile speed at different distances formula is a result of the least squares linear fit
-- of the following data set of {distance, averageSpeed} data.
-- {{290.8, 7.458}, {125.0, 6.252}, {451.9,8.369}, {31.436, 5.238}, {207.89, 6.929}, {371.8, 7.911}, {474.12, 8.466}}
-- speed = 0.00701024*distance + 5.27606

function gadget:Initialize()
	for id, _ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
	for id, _ in pairs(projectileLead) do
		Script.SetWatchProjectile(id, true)
	end
end
local function Dist3Dsqr(x,y,z)
	return x*x + y*y + z*z
end

local function Dist3D(x,y,z)
	return math.sqrt(x*x + y*y + z*z)
end

local function Dist2D(x,y)
	return math.sqrt(x*x + y*y)
end

function gadget:GameFrame(n)
	if thereAreProjectiles then
		thereAreProjectiles = false
		for proID, data in pairs(projectiles) do
			thereAreProjectiles = true
			local def = data[4]
			if data[5] then
				local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(data[5], true, true)
				if tx then
					if def.underwaterTrack and ty > -1 then
						ty = -1
					end
					data[1], data[2], data[3] = tx, ty, tz
					Spring.SetProjectileTarget(proID, tx, ty, tz)
				else
					data[5] = nil
				end
			end
			local px, py, pz = Spring.GetProjectilePosition(proID)
			
			if def.moveCtrlSpeed then
				local dx, dz = data[1] - px, data[3] - pz
				if px and dx ~= 0 and dz ~= 0 then
					local horDist = Dist2D(dx, dz)
					dx, dz = def.speed*dx/horDist, def.speed*dz/horDist
					
					local height = Spring.GetGroundHeight(px + dx, pz + dz) + def.groundFloat
					local dy = height - py
					local dist = Dist3D(dx, dy, dz)
					dx, dz = def.speed*dx/dist, def.speed*dz/dist
					
					height = Spring.GetGroundHeight(px + dx, pz + dz) + def.groundFloat
					Spring.SetProjectilePosition(proID, px + dx, height, pz + dz)
					Spring.SetProjectileVelocity(proID, dx, height - py, dz)
					if dist*horDist < def.rangeSqr then
						Spring.SetProjectileCollision(proID)
					end
				end
			elseif px and Dist3Dsqr(data[1] - px, data[2] - py, data[3] - pz) < def.rangeSqr then
				Spring.SetProjectileCollision(proID)
			end
		end
	end
end

local function GetAimPosition(proID, targetID, def)
	if def.track then
		local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(targetID, true, true)
		return {tx, ty, tz, def, targetID}
	end
	-- Replace prediction for mobile targets
	local bx,by,bz,ux,uy,uz = Spring.GetUnitPosition(targetID, true)
	local px,py,pz = Spring.GetProjectilePosition(proID)
	local vx, vy, vz = Spring.GetUnitVelocity(targetID)
	local hitTime = Dist3D(px - ux, py - uy, pz - uz)/def.speed
	
	-- Check whether the target is on the ground
	local h = Spring.GetGroundHeight(bx, bz)
	if by < h + 1 then
		-- Target is on the ground so snap target position to the ground.
		-- Reduce the effect of hit time because fast jinking units can cause the shot to go wide.
		-- Units fast enough to jink will be killed by the AoE of imperfect prediction.
		hitTime = hitTime*def.leadMult
		
		local x,z = bx + hitTime*vx, bz + hitTime*vz
		local y = Spring.GetGroundHeight(x,z)
		Spring.SetProjectileTarget(proID, x, y, z)
		if def.alwaysBurnblow then
			return {x, y, z, def}
		end
	else
		-- Target is in the air so predict perfectly and implement burnblow
		local x,y,z = ux + hitTime*vx, uy + hitTime*vy, uz + hitTime*vz
		Spring.SetProjectileTarget(proID, x, y, z)
		return {x, y, z, def}
	end
end

local function GetTarget(proID, proOwnerID, useOwnerWeapon)
	if not useOwnerWeapon then
		return Spring.GetProjectileTarget(proID)
	end
	local targetType, isUser, params = Spring.GetUnitWeaponTarget(proOwnerID, useOwnerWeapon)
	if targetType == 1 then
		return UNIT, params
	end
	if targetType == 2 then
		return GROUND, params
	end
	return Spring.GetProjectileTarget(proID)
end

local function AddProjectile(proID, def, proOwnerID)
	local targetType, targetID = GetTarget(proID, proOwnerID, def.useOwnerWeapon)
	if targetType == UNIT and Spring.ValidUnitID(targetID) then
		local unitDefID = Spring.GetUnitDefID(targetID)
		-- May as well home perfectly onto immobile targets, they are not going anywhere.
		if not (unitDefID and UnitDefs[unitDefID].isImmobile) then
			local targetData = GetAimPosition(proID, targetID, def)
			if targetData then
				projectiles[proID] = targetData
				thereAreProjectiles = true
			end
		else
			-- Targets may die, so always implement retargeting and burnblow.
			local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(targetID, true, true)
			Spring.SetProjectileTarget(proID, tx, ty, tz)
			projectiles[proID] = {tx, ty, tz, def, def.track and targetID}
			thereAreProjectiles = true
		end
	elseif targetType == FEATURE and Spring.ValidFeatureID(targetID) then
		local x,y,z = Spring.GetFeaturePosition(targetID)
		Spring.SetProjectileTarget(proID, x, y, z)
		if def.alwaysBurnblow then
			projectiles[proID] = {x, y, z, def}
			thereAreProjectiles = true
		end
	elseif targetType ~= GROUND then
		-- If the target type is not ground then the target was an invalid unit or feature
		-- Target straight
		local px,py,pz = Spring.GetProjectilePosition(proID)
		local vx, vy, vz = Spring.GetProjectileVelocity(proID)
		local x, y, z = px + 30*vx, py + 30*vy, pz + 30*vz
		Spring.SetProjectileTarget(proID, x, y, z)
		if def.alwaysBurnblow then
			projectiles[proID] = {x, y, z, def}
			thereAreProjectiles = true
		end
	else
		if def.alwaysBurnblow and type(targetID) == "table" then
			projectiles[proID] = {targetID[1], targetID[2], targetID[3], def}
			thereAreProjectiles = true
		end
	end
	
	if def.moveCtrlSpeed and projectiles[proID] then
		Spring.SetProjectileMoveControl(proID, true)
		Spring.SetPieceProjectileParams(proID, 1000)
	end
end

local function GetTargetPosition(targetID)
	local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(targetID, true, true)
	return tx, ty, tz
end

local function ApplyProjectileLead(proID, speed, weaponID)
	local targetType, targetID = spGetProjectileTarget(proID)
	if not (targetType == UNIT and spValidUnitID(targetID)) then
		return
	end

	local tx, ty, tz = CallAsTeam(spGetProjectileTeamID(proID), GetTargetPosition, targetID)
	if not tx then
		return
	end
	if ty < 4 and not waterWeapon[weaponID] then
		ty = 4
	end

	local vx, vy, vz, uSpeed = spGetUnitVelocity(targetID)
	local px, py, pz = spGetProjectilePosition(proID)
	local pvx, pvy, pvz = spGetProjectileVelocity(proID)
	if not (vx  and px) then
		return
	end

	-- Approximate flight time for direct flight
	local flyTime = dist3D(tx, ty, tz, px, py, pz)/speed
	
	-- Reduce additional lead amount by the leadLimit of the weapon
	if projectileLeadLimit[weaponID] then
		if flyTime*uSpeed <= projectileLeadLimit[weaponID] then
			-- already leading
			return
		end
		flyTime = (flyTime*speed - projectileLeadLimit[weaponID])/speed
	end
	
	-- First order approximation of where we're currently going
	local pdx, pdy, pdz = pvx*flyTime, pvy*flyTime, pvz*flyTime
	-- First order approximation of where our lead point should be
	local lx, ly, lz = pdx + vx*flyTime, pdy + vy*flyTime, pdz + vz*flyTime

	-- Normalize it all back down to what the speed should be
	local leadSpeed = dist3D(lx, ly, lz, 0, 0, 0)
	local normFactor = speed/leadSpeed

	--Spring.Utilities.UnitEcho(targetID, dist3D(ax*normFactor, ay*normFactor, az*normFactor, 0, 0, 0))

	spSetProjectileVelocity(proID, lx*normFactor, ly*normFactor, lz*normFactor)
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if projectileDefs[weaponID] then
		AddProjectile(proID, projectileDefs[weaponID], proOwnerID)
	end
	if projectileLead[weaponID] then
		ApplyProjectileLead(proID, projectileLead[weaponID], weaponID)
	end
end

GG.ProjectileRetarget_AddProjectile = AddProjectile

function gadget:ProjectileDestroyed(proID)
	if projectiles and projectiles[proID] then
		projectiles[proID] = nil
	end
end
