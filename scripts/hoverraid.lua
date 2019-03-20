include "constants.lua"

local base = piece 'base'
local turret = piece 'turret'
local gun = piece 'gun'
local flare = piece 'flare'
local ground = piece 'ground01'
local wakes = {}
for i = 1, 8 do
	wakes[i] = piece('wake0' .. i)
end

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
				for i = 1, 8 do
					EmitSfx(wakes[i], 3)
				end
			else
				EmitSfx(ground, 1024)
			end
		end
		Sleep(150)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)
	Sleep(5000)
	Turn(turret, y_axis, 0, math.rad(20))
	Turn(gun, x_axis, 0, math.rad(20))
end

function script.AimFromWeapon() 
	return turret
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(320))
	Turn(gun, x_axis, -pitch, math.rad(320))
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return (1)
end

function script.QueryWeapon(piecenum)
	return flare
end

local pieces = {turret, gun}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #pieces do
		if math.random() < severity then
			Explode(pieces[i], SFX.SHATTER)
		end
		if math.random() < (severity*2) then
			Explode(pieces[i], SFX.FALL + ((math.random() > severity) and (SFX.SMOKE + SFX.FIRE) or 0))
		end
	end

	if severity < 0.5 then
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
