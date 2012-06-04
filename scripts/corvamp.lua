include "constants.lua"

--pieces
local base = piece "base"
local wingR, wingL, wingtipR, wingtipL = piece("wingr", "wingl", "wingtip1", "wingtip2")
local engineR, engineL, thrust1, thrust2, thrust3 = piece("jetr", "jetl", "thrust1", "thrust2", "thrust3")
local missR, missL = piece("m1", "m2")

smokePiece = {base, engineL, engineR}

--constants

--variables
local gun = false

local RESTORE_DELAY = 500
local FIRE_SLOWDOWN = 0.5

--signals
local SIG_Aim = 1
local SIG_RESTORE = 2

----------------------------------------------------------

local function getState()
	local state = Spring.GetUnitStates(unitID)
	return state and state.active
end

function script.Create()
	Turn(thrust1, x_axis, -math.rad(90), 1)
	Turn(thrust2, x_axis, -math.rad(90), 1)
end

function script.StartMoving()
	Turn(engineL, z_axis, -1.57, 1)
	Turn(engineR, z_axis, 1.57, 1)
	Turn(engineL, y_axis, -1.57, 1)
	Turn(engineR, y_axis, 1.57, 1)
	Turn(engineL, x_axis, 0, 1)
	Turn(engineR, x_axis, 0, 1)
end

function script.StopMoving()
	Turn(engineL, z_axis, 0, 1)
	Turn(engineR, z_axis, 0, 1)
	Turn(engineL, y_axis, 0, 1)
	Turn(engineR, y_axis, 0, 1)
	Turn(engineL, x_axis, 0, 1)
	Turn(engineR, x_axis, 0, 1)
end

function script.QueryWeapon1()
	if gun then return missR
	else return missL end
end

function script.AimFromWeapon1() 
	return base 
end

function script.AimWeapon1(heading, pitch)
	return not (GetUnitValue(COB.CRASHING) == 1) 
end

function script.Shot1()
	gun = not gun
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	
	if getState() then
		Turn(engineL, z_axis, -1.2, 1)
		Turn(engineR, z_axis, 1.2, 1)
		Turn(engineL, y_axis, -1.2, 1)
		Turn(engineR, y_axis, 1.2, 1)
		Turn(engineL, x_axis, 0.6, 1)
		Turn(engineR, x_axis, 0.6, 1)
	end
	
	Sleep(RESTORE_DELAY)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)

	-- Don't ask me why this must be called twice for planes, Spring is crazy
	GG.UpdateUnitAttributes(unitID)
	GG.UpdateUnitAttributes(unitID)
	
	
	if getState() then
		script.StartMoving()
	else
		script.StopMoving()
	end
end

function script.BlockShot1()
	if GetUnitValue(CRASHING) == 1 then
		return true
	else
		if Spring.GetUnitRulesParam(unitID, "selfMoveSpeedChange") ~= FIRE_SLOWDOWN then
			Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", FIRE_SLOWDOWN)
			GG.attUnits[unitID] = true
			GG.UpdateUnitAttributes(unitID)
		end
		StartThread(RestoreAfterDelay)
		return false
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		Explode(base, sfxNone)
		Explode(engineL, sfxSmoke)
		Explode(engineR, sfxSmoke)
		Explode(wingL, sfxNone)
		Explode(wingR, sfxNone)
		return 1
	elseif severity < 100 then
		Explode(base, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxFall + sfxSmoke)
		Explode(wingR, sfxFall + sfxSmoke)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxSmoke + sfxExplode)
		Explode(wingR, sfxSmoke + sfxExplode)
		return 2
	end
end
