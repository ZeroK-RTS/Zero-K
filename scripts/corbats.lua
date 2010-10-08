include 'constants.lua'

--------------------------------------------------------------------
--pieces
--------------------------------------------------------------------
local hull, turret1, turret2, turret3, radar = piece('hull', 'turret1', 'turret2', 'turret3', 'radar')
local wake1, wake2, ground = piece('wake1', 'wake2', 'ground')

local turrets = { turret1, turret2, turret3 }

local barrels = {
	[1] = {piece 'barrel11', piece 'barrel12', piece 'barrel13'},
	[2] = {piece 'barrel21', piece 'barrel22', piece 'barrel23'},
	[3] = {piece 'barrel31', piece 'barrel32', piece 'barrel33'},
}
local flares = {
	[1] = {piece 'flare11', piece 'flare12', piece 'flare13'},
	[2] = {piece 'flare21', piece 'flare22', piece 'flare23'},
	[3] = {piece 'flare31', piece 'flare32', piece 'flare33'},
}

--------------------------------------------------------------------
--constants
--------------------------------------------------------------------
local smokePiece = {hull, turret1, turret2, turret3}

local SIG_Move = 1

local RESTORE_DELAY = 5000

local TURRET_PITCH_SPEED_1 = math.rad(30)
local TURRET_YAW_SPEED_1 = math.rad(60)
local RECOIL_DISTANCE =	-3
local RECOIL_RESTORE_SPEED = 2.5

--rockz
include 'rockz.lua'

local ROCK_PIECE = ground	--piece to rock
local ROCK_Z_SPEED = 3		--number of quarter-cycles per second around z-axis
local ROCK_Z_DECAY = -0.5	--rocking around z-axis is reduced by this factor each time; should be negative to alternate rocking direction
local ROCK_Z_MIN  = math.rad(0.5)	--if around z-axis rock is not greater than this amount rocking will stop after returning to center
local SIG_ROCK_Z = 1024		--signal to prevent multiple rocking

local ROCK_Z_FIRE = -0.2

--------------------------------------------------------------------
--variables
--------------------------------------------------------------------
local gun = {1, 1, 1}
local gunHeading = {0, 0, 0}
local rockZAngle = 0

function script.Create()
	Turn(turret2, y_axis, math.rad(180))
	Turn(turret3, y_axis, math.rad(180))
	Spin(radar, y_axis, math.rad(100))
	StartThread(SmokeUnit, smokePiece)
	--RockZInit()
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn( turret1 , y_axis, 0, math.rad(35) )
	Turn( turret2 , y_axis, math.rad(180), math.rad(35) )
	Turn( turret3 , y_axis, math.rad(180), math.rad(35) )
end

local function Wake()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep( 200)
	end
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal(SIG_Move)
end

function script.AimWeapon(num, heading, pitch)
	local SIG_Aim = 2^num
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn( turrets[num], y_axis, heading, math.rad(40) )
	for i=1,3 do
		Turn( barrels[num][i] , x_axis, -pitch, math.rad(40) )
	end
	WaitForTurn(barrels[num][1], x_axis)	
	WaitForTurn(turrets[num], y_axis)
	StartThread(RestoreAfterDelay)
	gunHeading[num] = heading
	return true
end

function script.FireWeapon(num)
	--StartThread(RockZ, gunHeading[num], ROCK_Z_FIRE)
end

function script.Shot(num)
	local barrel = barrels[num][(gun[num])]
	Move( barrel, z_axis, RECOIL_DISTANCE  )
	Move( barrel, z_axis, 0 , RECOIL_RESTORE_SPEED )	
	gun[num] = gun[num] + 1
	if gun[num] > 3 then gun[num] = 1 end
end

function script.AimFromWeapon(num)
	return turrets[num]
end

function script.QueryWeapon(num)
	return flares[num][(gun[num])]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local r = math.random
	if severity < 0.25 then
		Explode(barrels[1][r(1,3)], sfxNone)
		Explode(barrels[2][r(1,3)], sfxNone)
		Explode(barrels[3][r(1,3)], sfxNone)
		Explode(ground, sfxNone)
		Explode(turret1, sfxNone)
		Explode(turret2, sfxNone)
		Explode(turret3, sfxNone)
		return 1
	elseif severity < 0.5 then
		for i=1,3 do
			for v=1,3 do
				Explode(barrels[i][v], sfxFall + sfxSmoke + sfxExplode)
			end
		end
		Explode(ground, sfxNone)
		Explode(turret1, sfxShatter)
		Explode(turret2, sfxShatter)
		Explode(turret3, sfxShatter)
		return 1	
	end
	for i=1,3 do
		for v=1,3 do
			Explode(barrels[i][v], sfxFall + sfxSmoke + sfxExplode)
		end
	end
	Explode(hull, sfxNone)
	Explode(ground, sfxNone)
	Explode(turret1, sfxShatter)
	Explode(turret2, sfxShatter)
	Explode(turret3, sfxShatter)
	return 2	
end
