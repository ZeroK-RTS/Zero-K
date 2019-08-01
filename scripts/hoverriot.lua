local base = piece 'base' 
local flare = piece 'flare' 
local ground1 = piece 'ground1' 
local barrel = piece 'barrel' 

local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ('wake' .. i)
end
include "constants.lua"

-- Signal definitions
local SIG_HIT = 2
local SIG_AIM = 4

local RESTORE_DELAY = 3000

local function WobbleUnit()
	while true do
		Move(base, y_axis, 0.8, 1.2)
		Sleep(750)
		Move(base, y_axis, -0.80, 1.2)
		Sleep(750)
	end
end

function HitByWeaponThread(x, z)
	Signal(SIG_HIT)
	SetSignalMask(SIG_HIT)
	Turn(base, z_axis, math.rad(-z), math.rad(105))
	Turn(base, x_axis, math.rad(x), math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn(base, z_axis, 0, math.rad(30))
	Turn(base, x_axis, 0, math.rad(30))
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
				EmitSfx(ground1, 1024)
			end
		end
		Sleep(150)
	end
end

function script.Create()
	Hide(flare)
	Hide(ground1)
	Move(ground1, x_axis, 24.2)
	Move(ground1, y_axis, -8)
	StartThread(GG.Script.SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(barrel, y_axis, heading, math.rad(750))
	Turn(barrel, x_axis, -pitch, math.rad(600))
	WaitForTurn(barrel, y_axis)
	WaitForTurn(barrel, x_axis)
	return true
end

function script.QueryWeapon()
	return flare
end

function script.AimFromWeapon()
	return barrel
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(base, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(base, SFX.NONE)
		return 1
	end
	Explode(base, SFX.SHATTER)
	return 2
end
