include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base = piece "base"
local flare = piece "flare"
local firept = piece "firept"

local SOURCE_RANGE = 4000	-- size of the box which the emit point can be randomly placed in
local SOURCE_HEIGHT = 9001

local HOVER_RANGE = 1600
local HOVER_HEIGHT = 2600

local AIM_RADIUS = 160

local smokePiece = {base}

local Vector = Spring.Utilities.Vector

local projectiles = {}
local projectileCount = 0

local floatWeaponDefID      = WeaponDefNames["zenith_meteor_float"].id
local aimWeaponDefID        = WeaponDefNames["zenith_meteor_aim"].id
local fireWeaponDefID       = WeaponDefNames["zenith_meteor"].id
local uncontrolWeaponDefID  = WeaponDefNames["zenith_meteor_uncontrolled"].id

local uncontrolGravity = -0.05
local meteorGravity = -0.2
local fireGravity = 0.2

local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local launchInProgress = false
local currentlyStunned

local INLOS_ACCESS = {inlos = true}

local function IsDisabled()
	local state = Spring.GetUnitStates(unitID)
	if not (state and state.active) then
		return true
	end
	return spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
end

local function TransformMeteor(weaponDefID, proID, ttl, x, y, z, gravity)
	
	-- Get old projectile attributes
	local px, py, pz = Spring.GetProjectilePosition(proID)
	local vx, vy, vz = Spring.GetProjectileVelocity(proID)
	
	-- Destroy old projectile
	Spring.SetProjectilePosition(proID, -1000000, 10000, -1000000)
	Spring.SetProjectileCollision(proID)
	
	-- Send new one in the right direction
	local newProID = Spring.SpawnProjectile(weaponDefID, {
		pos = {px, py, pz},
		["end"] = {x, y, z},
		tracking = true, 
		speed = {vx, vy, vz}, 
		ttl = ttl,
		gravity = gravity,
	})
	if x then
		Spring.SetProjectileTarget(newProID, x, y, z)
	end
	
	return newProID
end

local function LoseControlOfMeteors()
	for i = 1, projectileCount do
		local proID = projectiles[i]
		-- Check that the projectile ID is still valid
		if Spring.GetProjectileDefID(proID) == floatWeaponDefID then
			local ttl = Spring.GetProjectileTimeToLive(projectiles[i])
			if ttl > 0 then
				projectiles[i] = TransformMeteor(uncontrolWeaponDefID, proID, ttl, nil, nil, nil, uncontrolGravity)
			end
		end
	end
end

local function RegainControlOfMeteors()
	local ux,_, uz = Spring.GetUnitPosition(unitID)
	local uy = Spring.GetGroundHeight(ux, uz)
	
	for i = 1, projectileCount do
		local proID = projectiles[i]
		-- Check that the projectile ID is still valid
		if Spring.GetProjectileDefID(proID) == uncontrolWeaponDefID then
			local ttl = Spring.GetProjectileTimeToLive(projectiles[i])
			if ttl > 0 then
				local hoverPos = Vector.PolarToCart(HOVER_RANGE*math.random()^2, 2*math.pi*math.random())
				projectiles[i] = TransformMeteor(floatWeaponDefID, proID, ttl, ux + hoverPos[1], uy + HOVER_HEIGHT, uz + hoverPos[2], meteorGravity)
			end
		end
	end
end

local function SpawnProjectileThread()
	local ux,_, uz = Spring.GetUnitPosition(unitID)
	local uy = Spring.GetGroundHeight(ux, uz)
	
	local reloadMult = 1
	
	while true do		
		reloadMult = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
		
		-- reloadMult should be 0 only when disabled.
		Sleep(700/((reloadMult > 0 and reloadMult) or 1))
		while IsDisabled() do			
			if not currentlyStunned then
				LoseControlOfMeteors()
				currentlyStunned = true
			end
			Sleep(700)
		end
		EmitSfx(flare, 2049)
		
		if currentlyStunned then
			RegainControlOfMeteors()
			currentlyStunned = false
		end
		
		local sourcePos = Vector.PolarToCart(SOURCE_RANGE*(1 - math.random()^2), 2*math.pi*math.random())
		local hoverPos = Vector.PolarToCart(HOVER_RANGE*math.random()^2, 2*math.pi*math.random())
		local proID = Spring.SpawnProjectile(floatWeaponDefID, {
			pos = {ux + sourcePos[1], uy + SOURCE_HEIGHT, uz + sourcePos[2]}, 
			tracking = true, 
			speed = {0, -1, 0}, 
			ttl = 9000, -- 9000 = 5 minutes
			gravity = meteorGravity,
		})
		Spring.SetProjectileTarget(proID, ux + hoverPos[1], uy + HOVER_HEIGHT, uz + hoverPos[2])
		
		projectileCount = projectileCount + 1
		projectiles[projectileCount] = proID
		Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
		

	end
end

local function LaunchAll(x, z)
	launchInProgress = true
	
	-- Sanitize input
	x, z = Spring.Utilities.ClampPosition(x, z)
	local y = Spring.GetGroundHeight(x,z)
	
	-- Make the aiming projectiles. These projectiles have high turnRate
	-- so are able to rotate the wobbly float projectiles in the right
	-- direction.
	local aim = {}
	local aimCount = 0
	
	for i = 1, projectileCount do
		local proID = projectiles[i]
		-- Check that the projectile ID is still valid
		if Spring.GetProjectileDefID(proID) == floatWeaponDefID then
			-- Projectile is valid, launch!
			aimCount = aimCount + 1
			aim[aimCount] = TransformMeteor(aimWeaponDefID, proID, 300, x, y, z)
		end
	end
	
	-- All projectiles were launched so there are none left.
	projectiles = {}
	projectileCount = 0
	Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
	
	-- Sleep to give time for the aim projectiles to turn
	Sleep(1500)
	
	-- Destroy the aim projectiles and create the speedy, low turnRate
	-- projectiles.
	for i = 1, aimCount do
		local proID = aim[i]
		-- Check that the projectile ID is still valid
		if Spring.GetProjectileDefID(proID) == aimWeaponDefID then
			-- Projectile is valid, launch!
			local aimOff = Vector.PolarToCart(AIM_RADIUS*math.random()^2, 2*math.pi*math.random())
			
			TransformMeteor(fireWeaponDefID, proID, 900, x + aimOff[1], y, z + aimOff[2], fireGravity)
		end
	end
	
	launchInProgress = false
end

function script.Create()
	currentlyStunned = IsDisabled()
	
	Move(firept, y_axis, 9001)
	Move(flare, y_axis, -110)
	Turn(flare, x_axis, math.rad(-90))
	StartThread(SmokeUnit, smokePiece)
	StartThread(SpawnProjectileThread)
	
	-- Helpful for devving
	--local proj = Spring.GetProjectilesInRectangle(0,0, 10000, 10000)
	--for i = 1, #proj do
	--	Spring.SetProjectileCollision(proj[i])
	--end
end

function script.QueryWeapon(num) 
	return firept
end

function script.AimFromWeapon(num)
	return firept
end

function script.AimWeapon(num, heading, pitch)
	return (num ~= 2) --and (spGetUnitRulesParam(unitID, "lowpower") == 0)
end

function script.BlockShot(num, target)
	if launchInProgress then
		return true
	end
	
	if IsDisabled() then
		return true
	end
	
	local cQueue = Spring.GetCommandQueue(unitID, 1)
	if not (cQueue and cQueue[1] and cQueue[1].id == CMD.ATTACK) then
		return true
	end
	
	if cQueue[1].params[3] then
		StartThread(LaunchAll, cQueue[1].params[1], cQueue[1].params[3])
	elseif #cQueue[1].params == 1 then
		local x,y,z = Spring.GetUnitPosition(cQueue[1].params[1])
		if x then
			StartThread(LaunchAll, x, z)
		end
	end
	return true
end

function script.Killed(recentDamage, maxHealth)
	LoseControlOfMeteors();
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, sfxNone)
		return 1
	else
		Explode(base, sfxShatter)
		return 2
	end
end
