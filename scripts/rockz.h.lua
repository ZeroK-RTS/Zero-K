--File: rockz.h.lua
--Description: Unit rocking script z-axis (roll) only.
--Author: Evil4Zerggin, rewritten in Lua by KingRaptor
--Date: 5 February 2008

--[[How to Use:
1. Copy the following to  the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.
DECLARE AS GLOBALS, NOT AS LOCALS
ALL ANGLES ARE IN RADIANS

SIG_ROCK_Z = 2		--Signal to prevent multiple rocking. REPLACE!

--rockz
ROCK_PIECE = 0		-- piece to rock. REPLACE!
ROCK_Z_SPEED = 1		--Number of rock angles per second around z-axis.
ROCK_Z_DECAY = -0.5		--Rocking around z-axis is reduced by this factor each time; should be between -1 and 0 to alternate rocking direction.
ROCK_Z_MIN = math.rad(0.5)	--If around z-axis rock is not greater than this amount, rocking will stop after returning to center.
ROCK_Z_MAX = math.rad(20)	--Caps maximum rocking in either direction

rockZAngle = 0

include 'rockz.lua'

2. For each weapon that you want to cause rocking, do the following:
	2a. define a static variable gun_X_yaw.
	2b. In AimWeaponX, put the following line before the return(1) line:
		gun_X_yaw = heading
	2c. In FireWeaponX or ShotX, put the following line:
		StartThread(RockZ, heading, rock_z)
		It may be helpful to define ROCK_Z_FIRE_X for your weapons to use as the argument rock_z.
		
3. Remove any other x-axis rock-on-fire code (e.g., RockUnit()) otherwise rocking may not work as expected.

More details:
"heading" in the following functions refers to the direction that the weapon was fired in. Use the gun_X_yaw variables for this.
"rock_z" determines how far to rock the unit.
rock_z should be positive to rock away from the firing direction.
]]--

ROCK_Z_SPEED = ROCK_Z_SPEED or 1
ROCK_Z_DECAY = ROCK_Z_DECAY or -0.5
ROCK_Z_MIN = ROCK_Z_MIN or math.rad(0.5)
ROCK_Z_MAX = ROCK_Z_MAX or math.rad(20)

function RockZ(heading, rock_z)
	Signal(SIG_ROCK_Z)
	SetSignalMask(SIG_ROCK_Z)
	local magnitude = math.sin(heading)
	--Spring.Echo(magnitude)
	rockZAngle = rockZAngle + (rock_z * magnitude)
	if rockZAngle > ROCK_Z_MAX then rockZAngle = ROCK_Z_MAX
	elseif -rockZAngle < -ROCK_Z_MAX then rockZAngle = -ROCK_Z_MAX end
	--Spring.Echo(rockZAngle)
	
	while (rockZAngle > ROCK_Z_MIN) or (rockZAngle < -ROCK_Z_MIN) do
		Turn( ROCK_PIECE , z_axis, rockZAngle, math.abs(rockZAngle*ROCK_Z_SPEED) )
		--Spring.Echo("Turning to "..rockZAngle .. " speed " .. rockZAngle*ROCK_Z_SPEED)
		WaitForTurn( ROCK_PIECE, z_axis)
		Sleep(33)
		rockZAngle = rockZAngle * ROCK_Z_DECAY
	end
	Turn( ROCK_PIECE, z_axis, 0, (ROCK_Z_MIN * ROCK_Z_SPEED) )
end


--legacy code
--[[
--piece-wise projection on x-axis
local function ProjXPW(mag, angle) 
	if angle < math.rad(-120) then 
		return mag * math.rad(angle+180) / math.rad(60)
	elseif angle > math.rad(120) then 
		return mag * math.rad(180-angle) / math.rad(60)
	elseif angle < math.rad(-60) then 
		return 0 - mag
	elseif angle > math.rad(60) then 
		return mag
	else 
		return mag * math.rad(angle)/math.rad(60)
	end
end

--piece-wise projection on z-axis
local function ProjZPW(mag, angle) 
	if angle < math.rad(-150) or angle > math.rad(150) then 
		return 0 - mag
	elseif angle > math.rad(30) then 
		return mag * math.rad(90 - angle) / math.rad(60)
	elseif angle < math.rad(-30) then 
		return mag * math.rad(angle+90) / math.rad(60)
	else 
		return mag
	end
end

result = 0

function RockZ(heading, rock_z)
	Signal(SIG_ROCK_Z)
	SetSignalMask(SIG_ROCK_Z)
	result = ProjXPW(math.rad(60)/rock_z, math.rad(heading))
	rockZAngle = rockZAngle + result
	if rockZAngle < 0 then rockZAngle = -rockZAngle end
	while (result > ROCK_Z_MIN) or (result < - ROCK_Z_MIN) do
		Spring.Echo("result: \t"..result.."\trockZAngle: \t"..rockZAngle)
	    Turn( ROCK_PIECE , z_axis, math.rad(rockZAngle), math.rad(result * ROCK_Z_SPEED) )	
		WaitForTurn( ROCK_PIECE, z_axis)
		Sleep(100)
		rockZAngle = rockZAngle * ROCK_Z_DECAY
		if rockZAngle < 0 then rockZAngle = -rockZAngle end
	end
	Turn( ROCK_PIECE, z_axis, 0, math.rad(ROCK_Z_MIN * ROCK_Z_SPEED) )
end
]]--