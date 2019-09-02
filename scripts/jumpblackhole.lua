
include "constants.lua"

-- pieces
local hips = piece "hips"
local chest = piece "chest"

-- left arm
local lshoulder = piece "lshoulder"
local lforearm = piece "lforearm"
local flare = piece "flare"

-- right arm
local rshoulder = piece "rshoulder"
local rforearm = piece "rforearm"

-- left leg
local lthigh = piece "lthigh"
local lshin = piece "lshin"
local lfoot = piece "lfoot"

-- right leg
local rthigh = piece "rthigh"
local rshin = piece "rshin"
local rfoot = piece "rfoot"

local smokePiece = {hips, chest}


--constants
local runspeed = 3.5
local steptime = 20

-- variables
local firing = false
local walkCycle = 0

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim = 4

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Turn(flare, x_axis, 1.6, 5)
	Turn(lshoulder, x_axis, -0.9, 5)
	Turn(lforearm, z_axis, -0.2, 5)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	while (true) do
		if walkCycle == 0 then
			local speedmult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
			local speed = runspeed*speedmult
			
			if not firing then
				Turn(lshoulder, x_axis, -1.2, speed*0.2)
				Turn(rshoulder, x_axis, 0.5, speed*0.3)
			end
			
			Turn(hips, z_axis, 0.1, speed*0.05)
			
			Turn(rthigh, x_axis, -1, speed*1)
			Turn(rshin, x_axis, 1, speed*1)
	--		Turn(rfoot, x_axis, 0.5, speed*1)
			
			Turn(lshin, x_axis, 0.2, speed*1)
			Turn(lthigh, x_axis, 0.5, speed*1)

			walkCycle = 1
			WaitForTurn(rthigh, x_axis)
			
			Sleep(steptime)
		end
		
		if walkCycle == 1 then
			local speedmult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
			local speed = runspeed*speedmult
			
			if not firing then
				Turn(lshoulder, x_axis, -0.6, speed*0.2)
				Turn(rshoulder, x_axis, -0.5, speed*0.3)
			end
			
			Turn(hips, z_axis, -0.1, speed*0.05)
			
			Turn(lthigh, x_axis, -1, speed*1)
			Turn(lshin, x_axis, 1, speed*1)
	--		Turn(lfoot, x_axis, 0.5, speed*1)
			
			Turn(rshin, x_axis, 0.2, speed*1)
			Turn(rthigh, x_axis, 0.5, speed*1)
			
			walkCycle = 0
			WaitForTurn(lthigh, x_axis)
			Sleep(steptime)
		end
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	Turn(hips, z_axis, 0, 0.5)
	
	Turn(lthigh, x_axis, 0, 2)
	Turn(lshin, x_axis, 0, 2)
	Turn(lfoot, x_axis, 0, 2)
	
	Turn(rthigh, x_axis, 0, 2)
	Turn(rshin, x_axis, 0, 2)
	Turn(rfoot, x_axis, 0, 2)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(2000)
	firing = false
	Turn(chest, y_axis, 0, 3)
	Turn(lshoulder, x_axis, -0.9, 5)
	Turn(rshoulder, x_axis, 0, 3)
	
	Turn(lforearm, z_axis, -0.2, 5)
	Turn(lshoulder, z_axis, 0, 3)
	Turn(rshoulder, z_axis, 0, 3)
end

function script.QueryWeapon1() return flare end

function script.AimFromWeapon1() return chest end

function script.AimWeapon1(heading, pitch)
	
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	--[[ Gun Hugger
	Turn(chest, y_axis, 1.1 + heading, 12)
	Turn(lshoulder, x_axis, -1 -pitch, 12)
	Turn(rshoulder, x_axis, -0.9 -pitch, 12)
	
	Turn(rshoulder, z_axis, 0.3, 9)
	Turn(lshoulder, z_axis, -0.3, 9)
	--]]
	
	-- Outstreched Arm
	firing = true
	Turn(chest, y_axis, heading, 4)
	Turn(lforearm, z_axis, 0, 5)
	Turn(lshoulder, x_axis, -pitch - 1.5, 4)
	
	
	WaitForTurn(chest, y_axis)
	WaitForTurn(lshoulder, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	EmitSfx(flare, 1025)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPreventionPlaceholder_CheckBlock(unitID, targetID, Spring.GetUnitAllyTeam(unitID))
end

function preJump(turn, distance)
end

function beginJump()
	StartThread(StopWalk)
end

function jumping()
	EmitSfx(lfoot, GG.Script.UNIT_SFX4)
	EmitSfx(rfoot, GG.Script.UNIT_SFX4)
	EmitSfx(lfoot, GG.Script.UNIT_SFX1)
	EmitSfx(rfoot, GG.Script.UNIT_SFX2)
	EmitSfx(lshoulder, GG.Script.UNIT_SFX3)
	EmitSfx(rshoulder, GG.Script.UNIT_SFX3)
end

function halfJump()
end

function endJump()
	EmitSfx(lfoot, GG.Script.UNIT_SFX4)
	EmitSfx(rfoot, GG.Script.UNIT_SFX4)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(hips, SFX.NONE)
		Explode(chest, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(hips, SFX.NONE)
		Explode(chest, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
