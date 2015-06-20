--File: rockz.h.lua
--Description: Unit rocking script z-axis (roll) only.
--Author: Evil4Zerggin, rewritten in Lua by KingRaptor
--Date: 5 February 2008

--[[How to Use:
1. Copy the following to the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.
DECLARE AS GLOBALS, NOT AS LOCALS
ALL ANGLES ARE IN RADIANS

SIG_ROCK = 2		--Signal to prevent multiple rocking. REPLACE!

--rockz
ROCK_PIECE = 0		-- piece to rock. REPLACE!
ROCK_SPEED = 1		--Number of rock angles per second around z-axis.
ROCK_DECAY = -0.5		--Rocking around z-axis is reduced by this factor each time; should be between -1 and 0 to alternate rocking direction.
ROCK_MIN = math.rad(0.5)	--If around z-axis rock is not greater than this amount, rocking will stop after returning to center.
ROCK_MAX = math.rad(20)	--Caps maximum rocking in either direction

rockAngle[axis] = 0

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

local ROCK_PIECE = {}
local ROCK_SPEED = {}
local ROCK_DECAY = {}
local ROCK_MIN = {}
local ROCK_MAX = {}
local SIG_ROCK = {}
local rockAngle = {}

function InitializeRock(rockPiece, rockSpeed, rockDecay, rockMin, rockMax, sigRock, axis)
	ROCK_PIECE[axis] = rockPiece
	ROCK_SPEED[axis] = rockSpeed or 1
	ROCK_DECAY[axis] = rockDecay or -0.5
	ROCK_MIN[axis] = rockMin or math.rad(0.5)
	ROCK_MAX[axis] = rockMax or math.rad(20)
	SIG_ROCK[axis] = sigRock
	rockAngle[axis] = 0
end

function Rock(heading, rockAmount, axis)
	Signal(SIG_ROCK[axis])
	SetSignalMask(SIG_ROCK[axis])
	local magnitude = (heading and math.sin(heading)) or 1
	--Spring.Echo(magnitude)
	rockAngle[axis] = rockAngle[axis] + (rockAmount * magnitude)
	if rockAngle[axis] > ROCK_MAX[axis] then 
		rockAngle[axis] = ROCK_MAX[axis]
	elseif -rockAngle[axis] < -ROCK_MAX[axis] then 
		rockAngle[axis] = -ROCK_MAX[axis] 
	end
	--Spring.Echo(rockAngle[axis])
	
	while (rockAngle[axis] > ROCK_MIN[axis]) or (rockAngle[axis] < -ROCK_MIN[axis]) do
		Turn(ROCK_PIECE[axis], axis, rockAngle[axis], math.abs(rockAngle[axis]*ROCK_SPEED[axis]))
		--Spring.Echo("Turning to "..rockAngle[axis] .. " speed " .. rockAngle[axis]*ROCK_SPEED)
		WaitForTurn(ROCK_PIECE[axis], axis)
		Sleep(33)
		rockAngle[axis] = rockAngle[axis] * ROCK_DECAY[axis]
	end
	Turn(ROCK_PIECE[axis], axis, 0, (ROCK_MIN[axis] * ROCK_SPEED[axis]))
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
	Signal(SIG_ROCK)
	SetSignalMask(SIG_ROCK)
	result = ProjXPW(math.rad(60)/rock_z, math.rad(heading))
	rockAngle[axis] = rockAngle[axis] + result
	if rockAngle[axis] < 0 then rockAngle[axis] = -rockAngle[axis] end
	while (result > ROCK_MIN) or (result < - ROCK_MIN) do
		Spring.Echo("result: \t"..result.."\trockAngle[axis]: \t"..rockAngle[axis])
		Turn(ROCK_PIECE, z_axis, math.rad(rockAngle[axis]), math.rad(result * ROCK_SPEED))	
		WaitForTurn(ROCK_PIECE, z_axis)
		Sleep(100)
		rockAngle[axis] = rockAngle[axis] * ROCK_DECAY
		if rockAngle[axis] < 0 then rockAngle[axis] = -rockAngle[axis] end
	end
	Turn(ROCK_PIECE, z_axis, 0, math.rad(ROCK_MIN * ROCK_SPEED))
end
]]--