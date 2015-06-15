include "constants.lua"

local spGetUnitRulesParam   = Spring.GetUnitRulesParam

local base, shield, front, bottom, back = piece('base', 'shield', 'front', 'bottom', 'back')
local rim1, door1, rim2, door2 = piece('rim1', 'door1', 'rim2', 'door2')
local turretbase, turret, gun, pads, flare1, flare2 = piece('turretbase', 'turret', 'gun', 'pads', 'flare1', 'flare2')
local wake1, wake2, wake3, wake4, wake5, wake6, wake7, wake8 = piece('wake1', 'wake2', 'wake3', 'wake4', 'wake5', 'wake6', 'wake7', 'wake8')

local SIG_HIT = 2

local function WobbleUnit()
	while true do
		Move( base , y_axis, 0.8 , 1.2)
		Sleep(750)
		Move( base , y_axis, -0.80 , 1.2)
		Sleep(750)
	end
end

function HitByWeaponThread(x, z)
	Signal( SIG_HIT)
	SetSignalMask( SIG_HIT)
	Turn( base , z_axis, math.rad(-z), math.rad(105))
	Turn( base , x_axis, math.rad(x ), math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, 0, math.rad(30))
	Turn( base , x_axis, 0, math.rad(30))
end

local function MoveScript()
	while true do 
		if math.random() < 0.5  then
			EmitSfx(wake1, 5)
			EmitSfx(wake3, 5)
			EmitSfx(wake5, 5)
			EmitSfx(wake7, 5)
			EmitSfx(wake1, 3)
			EmitSfx(wake3, 3)
			EmitSfx(wake5, 3)
			EmitSfx(wake7, 3)
		else
			EmitSfx(wake2, 5)
			EmitSfx(wake4, 5)
			EmitSfx(wake6, 5)
			EmitSfx(wake8, 5)
			EmitSfx(wake2, 3)
			EmitSfx(wake4, 3)
			EmitSfx(wake6, 3)
			EmitSfx(wake8, 3)
		end
	
		EmitSfx( base,  1024+0 )
		Sleep( 150)
	end
end

function script.Create()
	Hide(flare1)
	Hide(flare2)
	Hide(turret)
	Hide(pads)
	Hide(door1)
	Hide(door2)
	Hide(bottom)
	
	Move(base, x_axis, -3)
	Move(base, z_axis, -6)
	
	Move(gun, y_axis, 2)
	Turn(base, y_axis, math.rad(180))

	Move(turretbase, y_axis, 12)
	Turn(turretbase, x_axis, math.rad(180))
	Turn(turretbase, y_axis, math.rad(180))
	
	Move(pads, z_axis, 10)
	Turn(pads, x_axis, math.rad(50))
	
	Move(back, y_axis, 5)
	Move(back, x_axis, 0)
	Move(back, z_axis, 33.5)
	
	
	Turn(rim1, y_axis, math.rad(-35))
	Turn(rim2, y_axis, math.rad(35))
	
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

function script.QueryWeapon(num)
	return pads
end

function script.AimFromWeapon(num)
	return pads
end

function script.AimWeapon(num)
	return num ~= 3
end

local function ShotThread()
	Move(gun, y_axis, -2, 40)
	Turn(turretbase, x_axis, math.rad(165), math.rad(200))
	Sleep(100)
	Turn(turretbase, x_axis, math.rad(180), math.rad(40))
	Move(gun, y_axis, 2, 2)
end

function script.Shot(num)
	StartThread(ShotThread)
end

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetGameFrame = Spring.GetGameFrame

local depthchargeWeaponDef = WeaponDefNames["hoverdepthcharge_depthcharge"]
local RELOAD = math.ceil( depthchargeWeaponDef.reload * Game.gameSpeed )

function ShootDepthcharge()
	EmitSfx(pads, FIRE_W3)
	StartThread(ShotThread)
end

local function FakeWeaponShoot()
	local reloaded = select(2, spGetUnitWeaponState(unitID,1))
	if reloaded then
		local x,y,z = Spring.GetUnitPosition(unitID)
		local h = Spring.GetGroundHeight(x,z)
		if h > -10 then
			local gameFrame   = spGetGameFrame()
			local reloadMult  = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1.0
			local reloadFrame = gameFrame + RELOAD / reloadMult
			spSetUnitWeaponState(unitID, 1, {reloadFrame = reloadFrame} )
			
			EmitSfx(pads, FIRE_W3)
			StartThread(ShotThread)
			Move(gun, y_axis, -2)
			Move(gun, y_axis, 2, 2)
	
			GG.PokeDecloakUnit(unitID,100)
		end
	end
end

function script.BlockShot(num)
	if num == 1 then
		return false
	end
	FakeWeaponShoot()
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		Explode(back, sfxNone)
		return 1
	elseif severity <= 0.50  then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		Explode(back, sfxNone)
		Explode(rim1, sfxShatter)
		Explode(rim2, sfxShatter)
		Explode(wake1, sfxFall)
		Explode(wake2, sfxFall)
		Explode(wake3, sfxFall)
		Explode(wake4, sfxFall)
		Explode(wake5, sfxFall)
		Explode(wake6, sfxFall)
		return 1
	end
	Explode(door1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(door2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(back, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(rim1, sfxShatter)
	Explode(rim2, sfxShatter)
	Explode(wake1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake3, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake4, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake5, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake6, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	return 2
end
