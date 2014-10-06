include "constants.lua"
include "pieceControl.lua"

local base = piece 'base' 
local arm1 = piece 'arm1' 
local arm2 = piece 'arm2' 
local turret = piece 'turret' 
local firepoint = piece 'firepoint' 

local waterFire = false

local smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2


local spGetUnitRulesParam = Spring.GetUnitRulesParam

function script.HitByWeapon()
	if spGetUnitRulesParam(unitID,"disarmed") == 1 then
		StopTurn (turret, y_axis)
	end
end

local function Bob(rot)
	while true do
		Turn(base, x_axis, math.rad(rot + math.random(-5,5)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Move(base, y_axis, 48 + math.rad(math.random(0,2)), math.rad(math.random(1,2)) )
		Sleep(2000)
		Turn(base, x_axis, math.rad(rot + math.random(-5,5)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Move(base, y_axis, 48 + math.rad(math.random(-2,0)), math.rad(math.random(1,2)) )
		Sleep(1000)
	end
end

function script.Create()
	--while select(5, Spring.GetUnitHealth(unitID)) < 1  do
	--    Sleep(400)
	--end
	local x,_,z = Spring.GetUnitBasePosition(unitID)
	local y = Spring.GetGroundHeight(x,z)
	if y > 0 then
		Turn( arm1 , z_axis, math.rad(-70), math.rad(80) )
		Turn( arm2 , z_axis, math.rad(70), math.rad(80) )
		Move( base , y_axis, 20 , 25)
	elseif y > -19 then
		StartThread(Bob, 0)
	else
		waterFire = true
		StartThread(Bob, 180)
		Turn( base , x_axis, math.rad(180))
		Move( base , y_axis, 48)
		Turn( arm1 , x_axis, math.rad(180))
		Turn( arm2 , x_axis, math.rad(180))
		--Turn( turret , x_axis, math.rad(0))
	end	
	StartThread(SmokeUnit, smokePiece)
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)

	while spGetUnitRulesParam(unitID,"disarmed") == 1 do
		Sleep(10)
	end

	local slowMult = (1-(spGetUnitRulesParam(unitID,"slowState") or 0))

	if waterFire then
		Turn( turret , y_axis, -heading + math.pi, math.rad(120)*slowMult )
	else
		Turn( turret , y_axis, heading, math.rad(120)*slowMult )
	end

	WaitForTurn(turret, y_axis)
	return spGetUnitRulesParam(unitID,"disarmed") ~= 1
end

function script.FireWeapon(num)
	local px, py, pz = Spring.GetUnitPosition(unitID)
	if waterFire then
		Spring.PlaySoundFile("sounds/weapon/torpedo.wav", 10, px, py, pz)
	else
		Spring.PlaySoundFile("sounds/weapon/torp_land.wav", 10, px, py, pz)
	end
end

function script.AimFromWeapon(num)
	return base
end

function script.QueryWeapon(num)
	return firepoint
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(firepoint, sfxNone)
		Explode(arm1, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(base, sfxNone)
		Explode(firepoint, sfxFall)
		Explode(arm2, sfxShatter)
		Explode(turret, sfxFall)
		return 1
	elseif  severity <= .99  then
		Explode(base, sfxNone)
		Explode(firepoint, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(arm1, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	else
		Explode(base, sfxNone)
		Explode(firepoint, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(arm2, sfxShatter + sfxExplode )
		Explode(turret, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	end
end
