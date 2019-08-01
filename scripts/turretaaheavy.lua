include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, turret, barrel, flare = piece('base', 'turret', 'barrel', 'flare')

local smokePiece = {turret, barrel}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SIG_Idle = 1
local SIG_Aim = 2
local lastHeading = 0

local function IdleAnim()
	Signal(SIG_Idle)
	SetSignalMask(SIG_Idle)
	while true do
		Turn(turret, y_axis, lastHeading - math.rad(30), math.rad(60))
		Sleep(math.random(3000, 6500))
		Turn(turret, y_axis, lastHeading + math.rad(30), math.rad(60))
		Sleep(math.random(3000, 6500))
	end
end

function script.Create()
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end
	StartThread(GG.Script.SmokeUnit, smokePiece)
	StartThread(IdleAnim)
end

function script.QueryWeapon() 
	return flare
end

function script.AimFromWeapon()
	return turret
end

local function RestoreAfterDelay()
	Sleep(6000)
	StartThread(IdleAnim)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Idle)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(turret, y_axis, heading, math.rad(360))
	Turn(barrel, x_axis, -pitch, math.rad(90))
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel, x_axis)
	lastHeading = heading
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 1600.1, 50)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .5) then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(barrel, SFX.NONE)
		return 1 -- corpsetype
	else		
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.SMOKE + SFX.FIRE)
		Explode(barrel, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
