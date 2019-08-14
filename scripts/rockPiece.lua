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

if GG.ScriptRock then
	return
end
GG.ScriptRock = {}

function GG.ScriptRock.InitializeRock(rockInitData)
	local rockData = {}
	for key, data in pairs(rockInitData) do
		rockData[key] = {
			piece = data.piece,
			speed = data.speed or 1,
			minSpeed = data.minSpeed or 0.02,
			decay = data.decay or -0.5,
			minPos = data.minPos or math.rad(0.5),
			maxPos = data.maxPos or math.rad(20),
			signOverride = data.signOverride,
			signal = data.signal,
			axis = data.axis,
			position = 0,
			extraEffect = data.extraEffect,
		}
	end
	return rockData
end

function GG.ScriptRock.Oscillate(Func, rock, heading, rockAmount)
	Signal(rock.signal)
	SetSignalMask(rock.signal)
	local magnitude = (heading and math.sin(heading)) or 1
	--Spring.Echo(magnitude)
	rock.position = rock.position + (rockAmount * magnitude)
	if rock.position > rock.maxPos then
		rock.position = rock.maxPos
	elseif -rock.position < -rock.maxPos then
		rock.position = -rock.maxPos
	end
	
	while (rock.position > rock.minPos) or (rock.position < -rock.minPos) do
		local speed = math.abs(rock.position*rock.speed)
		if rock.minSpeed and (speed < rock.minSpeed) then
			speed = rock.minSpeed
		end
		local pos = rock.position
		if rock.signOverride then
			pos = rock.signOverride*math.abs(rock.position)
		end
		Func(rock.piece, rock.axis, pos, speed)
		if rock.extraEffect then
			rock.extraEffect(pos, speed)
		end
		WaitForTurn(rock.piece, rock.axis)
		Sleep(33)
		rock.position = rock.position * rock.decay
	end
	
	local speed = math.abs(rock.minPos*rock.speed)
	if rock.minSpeed and (speed < rock.minSpeed) then
		speed = rock.minSpeed
	end
	Func(rock.piece, rock.axis, 0, speed)
	if rock.extraEffect then
		rock.extraEffect(0, speed)
	end
	rock.position = 0
end

function GG.ScriptRock.Rock(rockData, heading, rockAmount)
	GG.ScriptRock.Oscillate(Turn, rockData, heading, rockAmount)
end

function GG.ScriptRock.Push(rockData, heading, rockAmount)
	GG.ScriptRock.Oscillate(Move, rockData, heading, rockAmount)
end
