include "constants.lua"

local base = piece 'base' 
local arm1 = piece 'arm1' 
local arm2 = piece 'arm2' 
local turret = piece 'turret' 
local firepoint = piece 'firepoint' 

smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2

local function Bob()
	while true do
		Turn(base, x_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Move(base, y_axis, math.rad(math.random(0,2)), math.rad(math.random(1,2)) )
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Turn(base, z_axis, math.rad(math.random(-5,5)), math.rad(math.random(1,2)) )
		Move(base, y_axis, math.rad(math.random(-2,0)), math.rad(math.random(1,2)) )
		Sleep(1000)
	end
end

function script.Create()
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
	    Sleep(400)
	end
	local x,y,z = Spring.GetUnitBasePosition(unitID)
	if y > 0 then
            Turn( arm1 , z_axis, math.rad(-70), math.rad(80) )
            Turn( arm2 , z_axis, math.rad(70), math.rad(80) )
            Move( base , y_axis, 20 , 25)
	else
            StartThread(Bob)
	end	
	StartThread(SmokeUnit)
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(120) )
	WaitForTurn(turret, y_axis)
	return true
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
