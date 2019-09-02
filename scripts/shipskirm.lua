--Stupid dumb Bos converted to amazing awesome Lua (see http://packages.springrts.com/bos2lua/index.php)

include 'constants.lua'

--------------------------------------------------------------------
--pieces
--------------------------------------------------------------------
local hull = piece 'hull'
local neck = piece 'neck'
local turret = piece 'turret'
local arml = piece 'arml'
local armr = piece 'armr'
local flare1 = piece 'flare1'
local flare2 = piece 'flare2'
local flare3 = piece 'flare3'
local flare4 = piece 'flare4'
local missile1 = piece 'missile1'
local missile2 = piece 'missile2'
local missile3 = piece 'missile3'
local missile4 = piece 'missile4'
local exhaust1 = piece 'exhaust1'
local exhaust2 = piece 'exhaust2'
local exhaust3 = piece 'exhaust3'
local exhaust4 = piece 'exhaust4'
local wakel = piece 'wakel'
local waker = piece 'waker'
local exp1 = piece 'exp1'
local exp2 = piece 'exp2'
local exp3 = piece 'exp3'
local exp4 = piece 'exp4'

--------------------------------------------------------------------
--constants
--------------------------------------------------------------------
local smokePiece = {hull, turret}

-- Signal definitions
local SIG_MOVE = 8

--rockz
include "rockPiece.lua"
local dynamicRockData

local ROCK_PIECE = hull -- should be negative to alternate rocking direction
local ROCK_SPEED = 3 --number of quarter-cycles per second around z-axis
local ROCK_DECAY = -1/2	--rocking around z-axis is reduced by this factor each time'
local ROCK_MIN = math.rad(3) --if around z-axis rock is not greater than this amount rocking will stop after returning to center
local ROCK_MAX = math.rad(15)
local SIG_ROCK_Z = 16 --Signal to prevent multiple rocking
local ROCK_FORCE = 0.1

local rockData = {
	[z_axis] = {
		piece = ROCK_PIECE,
		speed = ROCK_SPEED,
		decay = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_Z,
		axis = z_axis,
	},
}

--------------------------------------------------------------------
--variables
--------------------------------------------------------------------
local gun1 = 0
local restore_delay = 3000
local gun_1_yaw = 0
local dead = false
function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
end

local function RestoreAfterDelay()
	Sleep( restore_delay)
	if dead then return false end
	Turn( turret , y_axis, 0, math.rad(35.000000) )
	Turn( arml , x_axis, 0, math.rad(20.000000) )
	Turn( armr , x_axis, 0, math.rad(20.000000) )
end

local function Wake()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			EmitSfx( wakel,  2 )
			EmitSfx( waker,  4 )
		end
		Sleep(300)
	end
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal( SIG_MOVE)
end

function script.AimWeapon(num, heading, pitch)
	Signal( 2)
	SetSignalMask( 2)
	Turn( turret , y_axis, heading, math.rad(70.000000) )
	Turn( arml , x_axis, -pitch, math.rad(40.000000) )
	Turn( armr , x_axis, -pitch, math.rad(40.000000) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(arml, x_axis)
	WaitForTurn(armr, x_axis)
	StartThread(RestoreAfterDelay)
	gun_1_yaw = heading
	return (1)
end

function script.Shot(num)
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gun_1_yaw, ROCK_FORCE)
	gun1 = gun1 + 1
	if gun1 == 4 then
		 gun1 = 0 end

	if  gun1 == 0  then
	
		Move( missile1 , z_axis, -4.000000  )
		--Sleep( 1500)
		Move( missile1 , z_axis, 0.000000 , 1.000000 )
	end
	if  gun1 == 1  then
	
		Move( missile2 , z_axis, -4.000000 )
		--Sleep( 1500)
		Move( missile2 , z_axis, 0.000000 , 1.000000 )
	end
	if  gun1 == 2  then
	
		Move( missile3 , z_axis, -4.000000  )
		--Sleep( 1500)
		Move( missile3 , z_axis, 0.000000 , 1.000000 )
	end
	if  gun1 == 3  then
	
		Move( missile4 , z_axis, -4.000000  )
		--Sleep( 1500)
		Move( missile4 , z_axis, 0.000000 , 1.000000 )
	end
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)

	if  gun1 == 0  then
		return flare1
	end
	if  gun1 == 1  then
		return flare2
	end
	if  gun1 == 2  then
		return flare3
	end
	if  gun1 == 3  then
		return flare4
	end
end

function script.BlockShot(num, targetID)
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 200, 105, false, false, true) then
		return true
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= 0.50  then
		Explode( turret, SFX.SHATTER)
		return 1
	end
	Explode( hull, SFX.SHATTER)
	Explode( neck, SFX.SHATTER)
	Explode( turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode( arml, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode( armr, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	return 2
end
