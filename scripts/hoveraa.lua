local base = piece 'base' 
local body = piece 'body' 
local turret = piece 'turret' 
local ground1 = piece 'ground1' 
local missile = piece 'missile' 
local firepoint = piece 'firepoint' 

local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ('wake' .. i)
end

include "constants.lua"

local SIG_MOVE = 1
local SIG_AIM = 2

local function WobbleUnit()
	local wobble = true
	while true do
		if wobble == true then
			Move(base, y_axis, 1.2, 1.6)
		end
		if wobble == false then
		
			Move(base, y_axis, -1.2, 1.6)
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
				EmitSfx(ground1, 1024)
			end
		end
		Sleep(150)
	end
end

function script.Create()
	Turn(firepoint, x_axis, math.rad(-90))
	StartThread(GG.Script.SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

function script.AimFromWeapon() 
	return turret
end

function script.AimWeapon()
	return true
end

function script.QueryWeapon()
	return firepoint
end

local function ReloadMissileThread()
	Hide(missile)
	Sleep(1000)
	Show(missile)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 374, 50)
end

function script.FireWeapon()
	StartThread(ReloadMissileThread)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity <= 0.25 then
		Explode(body, SFX.NONE)
		return 1
	end
	if severity <= 0.50 then
		Explode(body, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		return 1
	end
	if severity <= 0.99 then
		Explode(body, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		return 2
	end
	Explode(body, SFX.NONE)
	Explode(turret, SFX.SHATTER)
	return 2
end
