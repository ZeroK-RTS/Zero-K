include "constants.lua"

local 		base, body, turret, sleeve, barrel, firepoint,
			rwheel1, rwheel2,
			lwheel1, lwheel2,
			lfender1, lfender2, rfender1, rfender2,
			gs1r, gs2r,
			gs1l, gs2l
			=     
			piece(
			'base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint',
			'rwheel1', 'rwheel2',
			'lwheel1', 'lwheel2',
			'lfender1', 'lfender2', 'rfender1', 'rfender2',
			'gs1r', 'gs2r',
			'gs1l', 'gs2l'
			);

local	moving,
			s1r, s2r,
			s1l, s2l,
			xtilt, xtiltv, xtilta, ztilt, ztilta, ztiltv, 
			ya, yv, yp, runsp, reloading, mainHead, WHEEL_TURN_SPEED
			
local smokePiece = {turret, body}

xtilt=0
xtiltv=0
xtilta=0
ztilt=0
ztilta=0
ztiltv=0;

ya=0;yv=0;yp=0;

-- Signal definitions
local SIG_AIM1 = 1
local ANIM_SPEED = 50
local RESTORE_DELAY = 2000

local TURRET_TURN_SPEED = 220
local SLEEVE_TURN_SPEED = 70

local spGetGroundHeight = Spring.GetGroundHeight;
local spGetPiecePosition = Spring.GetUnitPiecePosition;
local spGetUnitVelocity = Spring.GetUnitVelocity;

local lastFiredFrame = 0;
local SPINDOWN_TIME = 30;

function Suspension()
   while true do   
	   while runsp do
			local x, y, z;
			
			x,y,z = spGetPiecePosition(unitID,gs1r);
			s1r = spGetGroundHeight(x,z)-y;
			if s1r < -2 then
				s1r = -2
			end

			if s1r > 2 then
				s1r = 2
			end
			x,y,z = spGetPiecePosition(unitID,gs2r);
			s2r = spGetGroundHeight(x,z)-y;
			if s2r < -2 then
				s2r = -2
			end
			if s2r > 2 then
				s2r = 2
			end

			x,y,z = spGetPiecePosition(unitID,gs2r);
			s1l = spGetGroundHeight(x,z)-y;
			if s1l < -2 then
				s1l = -2
			end
			if s1l > 2 then
				s1l = 2
			end

			x,y,z = spGetPiecePosition(unitID,gs2l);
			s2l = spGetGroundHeight(x,z)-y;
			if s2l < -2 then
				s2l = -2
			end
			if s2l > 2 then
				s2l = 2
			end

			xtilta = 0 - (s1r - s2r + s1l - s2l)/58000 + xtiltv/7      
			xtiltv = xtiltv + xtilta
			xtilt = xtilt + xtiltv*4

			ztilta = 0 + (s1r - s2r + s1l - s2l)/58000 - ztiltv/7
			ztiltv = ztiltv + ztilta
			ztilt = ztilt + ztiltv*4

			ya = (s1r + s2r + s1l + s2l)/100 - yv/25
			yv = yv + ya
			yp = yp + yv/10

			--Move( base , y_axis, yp , 9000 )
			--Turn( base , x_axis, math.rad(xtilt ), math.rad(9000) )
			--Turn( base , z_axis, math.rad(-(ztilt )), math.rad(9000) )

			Move( rwheel1 , y_axis, s1r , 9000 )
			Move( rwheel2 , y_axis, s2r , 9000 )

			Move( lwheel1 , y_axis, s1l , 9000 )
			Move( lwheel2 , y_axis, s2l , 9000 )

			Move( rfender1 , y_axis, s1r , 9000 )
			Move( rfender2 , y_axis, s2r , 9000 )

			Move( lfender1 , y_axis, s1l , 9000 )
			Move( lfender2 , y_axis, s2l , 9000 )

			x,y,z = spGetUnitVelocity(unitID)
			WHEEL_TURN_SPEED = (math.sqrt(x*x+y*y+z*z)*10)

			Spin( rwheel1 , x_axis, WHEEL_TURN_SPEED)
			Spin( rwheel2 , x_axis, WHEEL_TURN_SPEED)
			Spin( lwheel1 , x_axis, WHEEL_TURN_SPEED)
			Spin( lwheel2 , x_axis, WHEEL_TURN_SPEED)

			Sleep(10)
		end
		Sleep(10)
   end 
end

function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn( turret , y_axis, 0, math.rad(90) )
end

function script.StopMoving()
	moving = false
	StartThread(Roll)
end

function Roll()
	Sleep(500)
	if not moving then
		StopSpin(rwheel1, x_axis)
		StopSpin(rwheel2, x_axis)
		StopSpin(lwheel1, x_axis)
		StopSpin(lwheel2, x_axis)
	
		runsp = false
	end
end

function script.StartMoving()
	moving = true
	runsp = true
	
	local x,y,z = spGetUnitVelocity(unitID)
	WHEEL_TURN_SPEED =  math.sqrt(x*x+y*y+z*z)*10
	
	Spin( rwheel1 , x_axis, WHEEL_TURN_SPEED)
	Spin( rwheel2 , x_axis, WHEEL_TURN_SPEED)
	Spin( lwheel1 , x_axis, WHEEL_TURN_SPEED)
	Spin( lwheel2 , x_axis, WHEEL_TURN_SPEED)
end

-- Weapons
function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoint
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM1)
	SetSignalMask( SIG_AIM1)
	
	Turn( turret , y_axis, heading, math.rad(TURRET_TURN_SPEED) )
	Turn( sleeve , x_axis, -pitch, math.rad(SLEEVE_TURN_SPEED) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, y_axis)
	StartThread(RestoreAfterDelay)

	return (true)
end

function script.Shot(num)
	local frame = Spring.GetGameFrame();

	if (frame >= lastFiredFrame+SPINDOWN_TIME) then
		local px, py, pz = Spring.GetUnitPosition(unitID)
		Spring.PlaySoundFile("sounds/weapon/heatray_fire.wav", 15, px, py, pz)
	end
	lastFiredFrame = frame;
	EmitSfx( firepoint,  UNIT_SFX1 )
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity >= 0 and severity < 0.25 then
		Explode(barrel, sfxNone)
		Explode(sleeve, sfxNone)
		Explode(body, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity < 0.50 then
		Explode(barrel, sfxFall)
		Explode(sleeve, sfxFall)
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		return 1
	elseif severity < 1 then
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(sleeve, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(sleeve, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(body, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		return 2
	end
end

function script.Create()
	moving = false
	StartThread(Suspension)
	StartThread(SmokeUnit, smokePiece)
end
