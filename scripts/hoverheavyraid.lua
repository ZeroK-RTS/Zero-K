include "constants.lua"

local base = piece 'base'
local turret = piece 'turret'

local fireNum = 1
local fire = {
	piece 'fire1',
	piece 'fire2',
	piece 'fire3',
}

local SIG_AIM = 1

local body = piece 'body'
local wakes_1 = piece 'jetl'
local wakes_2 = piece 'jetr'
local wakes_3 = piece 'jetb'

local function WobbleUnit()
	local wobble = true
	while true do
		if wobble == true then
			Move(base, y_axis, 2, 3)
		else
			Move(base, y_axis, -2, 3)
		end
		wobble = not wobble
		Sleep(750)
	end
end

local sfxNum = 0
function script.setSFXoccupy(num)
	sfxNum = num
end

local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			if (sfxNum == 1 or sfxNum == 2) and select(2, Spring.GetUnitPosition(unitID)) == 0 then
				EmitSfx(wakes_1, 3)
				EmitSfx(wakes_2, 3)
				EmitSfx(wakes_3, 3)
			else
				EmitSfx(body, 1024)
				EmitSfx(wakes_3, 1024)
			end
		end
		Sleep(150)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)
	Sleep(5000)
	Turn(turret, y_axis, 0, math.rad(20))
	Turn(turret, x_axis, 0, math.rad(20))
end

function script.AimFromWeapon()
	return turret
end

function script.EndBurst()
	fireNum = (fireNum%3) + 1
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(620))
	Turn(turret, x_axis, -pitch, math.rad(320))
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryWeapon(piecenum)
	return fire[fireNum]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity < 0.5 then
		Explode(turret, SFX.SHATTER)
		return 1
	else
		Explode(turret, SFX.FALL)
		Explode(body, SFX.SHATTER)
		return 2
	end
end
