local support = piece 'support' 
local flare = piece 'flare' 
local thigh1 = piece 'thigh1' 
local thigh2 = piece 'thigh2' 
local torso = piece 'torso' 
local barrel = piece 'barrel' 
local foot2 = piece 'foot2' 
local foot1 = piece 'foot1' 
local leg2 = piece 'leg2' 
local leg1 = piece 'leg1' 

include "constants.lua"

local aiming = false

local RESTORE_DELAY = 2000

-- Signal definitions
local SIG_MOVE = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

local function walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)

	while true do
		if not aiming then
			Move( torso , y_axis, -0.050000  )
			Turn( torso , x_axis, math.rad(1.758242) )
			Turn( torso , z_axis, math.rad(-0.703297) )
		end
		
		Turn( thigh1 , x_axis, math.rad(16.879121) )
		Turn( thigh2 , x_axis, math.rad(-45.714286) )
		Turn( leg2 , x_axis, math.rad(50.983516) )
		Turn( foot1 , x_axis, math.rad(-16.527473) )
		Sleep( 100)
	
		if not aiming then
			Move( torso , y_axis, 0.000000  )
			Turn( torso , x_axis, math.rad(0.351648) )
			Turn( torso , z_axis, math.rad(-0.351648) )
		end
		
		Turn( thigh1 , x_axis, math.rad(24.263736) )
		Turn( thigh2 , x_axis, math.rad(-41.137363) )
		Turn( leg2 , x_axis, math.rad(43.247253) )
		Turn( foot1 , x_axis, math.rad(-11.956044) )
		Sleep( 102)
	
		if not aiming then
			Turn( torso , x_axis, 0 )
			Turn( torso , z_axis, 0 )
		end
		
		Turn( thigh1 , x_axis, math.rad(37.620879) )
		Turn( thigh2 , x_axis, math.rad(-26.368132) )
		Turn( leg2 , x_axis, math.rad(26.368132) )
		Turn( leg1 , x_axis, math.rad(8.439560) )
		Sleep( 104)
	
		if not aiming then
			Move( torso , y_axis, -0.300000  )
			Turn( torso , x_axis, 0 )
		end
		
		Turn( thigh1 , x_axis, math.rad(22.148352) )
		Turn( thigh2 , x_axis, math.rad(-11.956044) )
		Turn( leg2 , x_axis, math.rad(11.598901) )
		Turn( leg1 , x_axis, math.rad(27.428571) )
		Sleep( 102)
	
		if not aiming then
			Move( torso , y_axis, -0.250000  )
			Turn( torso , x_axis, math.rad(1.758242) )
			Turn( torso , z_axis, math.rad(1.406593) )
		end
		
		Turn( thigh1 , x_axis, math.rad(3.159341) )
		Turn( thigh2 , x_axis, math.rad(7.032967) )
		Turn( leg2 , x_axis, math.rad(-1.054945) )
		Turn( foot2 , x_axis, math.rad(-6.329670) )
		Turn( leg1 , x_axis, math.rad(53.450549) )
		Sleep( 102)
	
		if not aiming then
			Move( torso , y_axis, -0.100000  )
			Turn( torso , x_axis, math.rad(2.461538) )
			Turn( torso , z_axis, math.rad(0.703297) )
		end
		
		Turn( thigh1 , x_axis, math.rad(-20.747253) )
		Turn( thigh2 , x_axis, math.rad(20.747253) )
		Turn( foot2 , x_axis, math.rad(-19.692308) )
		Turn( leg1 , x_axis, math.rad(60.829670) )
		Sleep( 103)

		if not aiming then
			Move( torso , y_axis, -0.050000  )
			Turn( torso , x_axis, math.rad(0.703297) )
		end
		
		Turn( thigh1 , x_axis, math.rad(-39.384615) )
		Turn( thigh2 , x_axis, math.rad(28.483516) )
		Turn( foot2 , x_axis, math.rad(-27.076923) )
		Sleep( 103)
	
		if not aiming then
			Move( torso , y_axis, 0.000000  )
			Turn( torso , x_axis, math.rad(0.351648) )
			Turn( torso , z_axis, math.rad(0.351648) )
		end
		
		Turn( thigh1 , x_axis, math.rad(-43.956044) )
		Turn( thigh2 , x_axis, math.rad(34.813187) )
		Turn( foot2 , x_axis, math.rad(-20.395604) )
		Turn( leg1 , x_axis, math.rad(43.956044) )
		Turn( foot1 , x_axis, 0 )
		Sleep( 103)
		
		if not aiming then
			Turn( torso , x_axis, 0 )
			Turn( torso , z_axis, 0 )
		end
		
		Turn( thigh1 , x_axis, math.rad(-31.994505) )
		Turn( thigh2 , x_axis, math.rad(35.868132) )
		Turn( leg2 , x_axis, math.rad(16.175824) )
		Turn( foot2 , x_axis, math.rad(-13.714286) )
		Turn( leg1 , x_axis, math.rad(32.351648) )
		Sleep( 103)
	
		if not aiming then
			Move( torso , y_axis, -0.250000  )
		end
		
		Turn( thigh1 , x_axis, math.rad(-23.554945) )
		Turn( thigh2 , x_axis, math.rad(23.560440) )
		Turn( leg2 , x_axis, math.rad(40.434066) )
		Turn( leg1 , x_axis, math.rad(24.263736) )
		Sleep( 103)
	
		if not aiming then
			Move( torso , y_axis, -0.200000  )
			Turn( torso , x_axis, math.rad(2.109890) )
			Turn( torso , z_axis, math.rad(-2.109890) )
		end
		
		Turn( thigh1 , x_axis, math.rad(-1.406593) )
		Turn( thigh2 , x_axis, math.rad(-14.412088) )
		Turn( leg2 , x_axis, math.rad(69.269231) )
		Turn( leg1 , x_axis, math.rad(2.461538) )
		Sleep( 103)
	
		if not aiming then
			Move( torso , y_axis, -0.150000  )
			Turn( torso , z_axis, math.rad(-1.054945) )
		end
		
		Turn( thigh1 , x_axis, math.rad(11.604396) )
		Turn( thigh2 , x_axis, math.rad(-35.164835) )
		Turn( leg2 , x_axis, math.rad(76.659341) )
		Turn( foot1 , x_axis, math.rad(-14.065934) )
		Sleep( 103)
	end
end

function script.Create()
	Hide(flare)
	StartThread(SmokeUnit, {torso})
end

function script.StartMoving()
	StartThread(walk)
end

function script.StopMoving()
	Signal(SIG_MOVE)
	
	Turn( thigh1 , x_axis, 0 )
	Turn( thigh2 , x_axis, 0 )
	Turn( leg2 , x_axis, 0 )
	Turn( foot1 , x_axis, 0 )
end


local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep( RESTORE_DELAY)
	Turn( torso , y_axis, 0, math.rad(90) )
	Turn( support , x_axis, 0, math.rad(45) )
	aiming = false
end

function script.AimWeapon(num, heading, pitch)

	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	StartThread(RestoreAfterDelay)
	aiming = true
	
	Turn( torso , y_axis, heading, math.rad(300) )
	Turn( support , x_axis, -pitch, math.rad(150) )
	WaitForTurn(torso, y_axis)
	WaitForTurn(support, x_axis)
	return true
end

function script.FireWeapon()

	Move( barrel , z_axis, -5  )
	EmitSfx( flare,  1024 )
	Sleep( 150)
	--Turn( torso , x_axis, math.rad(-10.000000), math.rad(500.120879) )
	Sleep( 150)
	--Turn( torso , x_axis, 0, math.rad(20.000000) )
	Move( barrel , z_axis, 0 , 6 )
end

function script.QueryWeapon()
	return flare
end

function script.AimFromWeapon()
	return support
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25  then
		Explode(barrel, sfxNone)
		Explode(foot1, sfxNone)
		Explode(foot2, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(support, sfxNone)
		Explode(thigh1, sfxNone)
		Explode(thigh2, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif  severity <= 0.50  then
		Explode(barrel, sfxNone)
		Explode(foot1, sfxNone)
		Explode(foot2, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(support, sfxNone)
		Explode(thigh1, sfxNone)
		Explode(thigh2, sfxNone)
		Explode(torso, sfxShatter)
		return 1
	end

	
	Explode(barrel, sfxSmoke + sfxFire)
	Explode(foot1, sfxSmoke + sfxFire)
	Explode(foot2, sfxSmoke + sfxFire)
	Explode(leg1, sfxSmoke + sfxFire)
	Explode(leg2, sfxSmoke + sfxFire)
	Explode(support, sfxSmoke + sfxFire)
	Explode(thigh1, sfxSmoke + sfxFire)
	Explode(thigh2, sfxSmoke + sfxFire)
	Explode(torso, sfxShatter)
	return 2
end