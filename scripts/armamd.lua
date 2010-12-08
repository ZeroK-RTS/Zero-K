include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, door1, door2, brace, missile, aimpoint = piece('base', 'door1', 'door2', 'brace', 'missile', 'aimpoint') 

local smokePiece = {base}

--------------------------------------------------------------------------------
-- signals
--------------------------------------------------------------------------------
local SIG_AIM = 2
local SIG_OPEN = 1

-------------------------------------------------------------------------------
-- main code
--------------------------------------------------------------------------------
local open = false

local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Turn(door1, z_axis, math.rad(-90), math.rad(30))
	Turn(door2, z_axis, math.rad(90), math.rad(30))
	WaitForTurn(door1, z_axis)
	
	Turn(brace, x_axis, math.rad(90), math.rad(20))
	WaitForTurn(brace, x_axis)
	open = true
end

local function Close()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Turn(brace, x_axis, 0, math.rad(20))
	WaitForTurn(brace, x_axis)
	Turn(door1, z_axis, 0, math.rad(30))
	Turn(door2, z_axis, 0, math.rad(30))
	WaitForTurn(door1, z_axis)
	open = false
end

function script.Create()
	StartThread(SmokeUnit)
end

local function RestoreAfterDelay()
	Sleep(6000)
	if open then Close() end
end

function script.AimFromWeapon(weaponNum)	return aimpoint end
function script.QueryWeapon(weaponNum) return missile end

function script.AimWeapon(weaponNum, heading, pitch)
	Show(missile)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	if not open then Open() end
	Sleep(100)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(weaponNum)
	Hide(missile)
	Sleep(1500)
	if open then Close() end
	Show(missile)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		Explode(brace, sfxSmoke)
		return 1
	elseif severity <= .50  then
		Explode(base, sfxNone)
		Explode(door1, sfxShatter)
		Explode(door2, sfxShatter)
		Explode(brace, sfxSmoke)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxShatter)
		Explode(door1, sfxSmoke + sfxFire)
		Explode(door2, sfxSmoke + sfxFire)
		Explode(brace, sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(door1, sfxSmoke + sfxFire + sfxExplode)
		Explode(door2, sfxSmoke + sfxFire + sfxExplode)
		Explode(brace, sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
