--linear constant 65536

include "constants.lua"

local base, pelvis, body = piece('base', 'pelvis', 'body')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local holder, sphere = piece('holder', 'sphere') 

smokePiece = {pelvis}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 1

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(45)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(10)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local SIG_WALK = 1

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local gun_1 = 0
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--Spring.Echo("Left foot up, right foot down")
		Turn( lthigh , x_axis, math.rad(20), math.rad(20)*PACE )
		Turn( lshin , x_axis, math.rad(-60), math.rad(20)*PACE  )
		Turn( lfoot , x_axis, math.rad(40), math.rad(40)*PACE  )
		Turn( rthigh , x_axis, math.rad(0), math.rad(25)*PACE  )
		Turn( rshin , x_axis, math.rad(25), math.rad(20)*PACE  )
		Turn( rfoot , x_axis, math.rad(-20), math.rad(40)*PACE  )
		Turn( pelvis , z_axis, math.rad(-5), math.rad(5)*PACE  )
		Turn( lthigh , z_axis, math.rad(5), math.rad(5)*PACE  )
		Turn( rthigh , z_axis, math.rad(5), math.rad(5)*PACE  )
		Move( pelvis , y_axis, 5 , 2*PACE)
		WaitForMove(pelvis, y_axis)
		Sleep(0)	-- needed to prevent anim breaking, DO NOT REMOVE
		
		--Spring.Echo("Right foot middle, left foot middle")
		Turn( lthigh , x_axis, math.rad(-25), math.rad(45)*PACE  )
		Turn( lshin , x_axis, math.rad(5), math.rad(65)*PACE  )
		Turn( lfoot , x_axis, math.rad(20), math.rad(20)*PACE  )		
		Turn( rthigh , x_axis, math.rad(40), math.rad(40)*PACE  )
		Turn( rshin , x_axis, math.rad(-40), math.rad(60)*PACE  )
		Turn( rfoot , x_axis, math.rad(0), math.rad(20)*PACE  )	
		Move( pelvis , y_axis, 2.5, 2*PACE )
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--Spring.Echo("Right foot up, Left foot down")		
		Turn( rthigh , x_axis, math.rad(20), math.rad(20)*PACE  )
		Turn( rshin , x_axis, math.rad(-60), math.rad(20)*PACE  )
		Turn( rfoot , x_axis, math.rad(40), math.rad(40)*PACE  )
		Turn( lthigh , x_axis, math.rad(0), math.rad(25)*PACE  )
		Turn( lshin , x_axis, math.rad(25), math.rad(20)*PACE  )
		Turn( lfoot , x_axis, math.rad(-20), math.rad(40)*PACE  )
		Turn( pelvis , z_axis, math.rad(5), math.rad(5)*PACE  )
		Turn( lthigh , z_axis, math.rad(-5), math.rad(5)*PACE  )
		Turn( rthigh , z_axis, math.rad(-5), math.rad(5)*PACE  )
		Move( pelvis , y_axis, 5 , 2*PACE )
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--Spring.Echo("Left foot middle, right foot middle")
		Turn( rthigh , x_axis, math.rad(-25), math.rad(40)*PACE  )
		Turn( rshin , x_axis, math.rad(5), math.rad(65)*PACE  )
		Turn( rfoot , x_axis, math.rad(20), math.rad(20)*PACE  )
		Turn( lthigh , x_axis, math.rad(40), math.rad(40)*PACE  )
		Turn( lshin , x_axis, math.rad(-40), math.rad(60)*PACE  )
		Turn( lfoot , x_axis, math.rad(0), math.rad(20)*PACE  )
		Move( pelvis , y_axis, 2.5, 2*PACE )
		WaitForMove(pelvis, y_axis)
		Sleep(0)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( rshin , x_axis, 0, math.rad(120)*PACE  )
	Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( lshin , x_axis, 0, math.rad(80)*PACE  )
	Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
end

function script.Create()
	StartThread(SmokeUnit)	
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
    if severity <= 50 then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif severity <= 99 then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(body, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxShatter + sfxExplode )
		return 2
	end
end