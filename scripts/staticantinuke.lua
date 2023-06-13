include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, door1, door2, brace, missile, aimpoint = piece('base', 'door1', 'door2', 'brace', 'missile', 'aimpoint')

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
	Turn(door1, z_axis, math.rad(-90), math.rad(45))
	Turn(door2, z_axis, math.rad(90), math.rad(45))
	WaitForTurn(door1, z_axis)
	
	Turn(brace, x_axis, math.rad(90), math.rad(45))
	WaitForTurn(brace, x_axis)
	open = true
end

local function Close()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Turn(brace, x_axis, 0, math.rad(45))
	WaitForTurn(brace, x_axis)
	Show(missile)
	open = false
	Turn(door1, z_axis, 0, math.rad(45))
	Turn(door2, z_axis, 0, math.rad(45))
	WaitForTurn(door1, z_axis)

end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {piece('smoke1', 'smoke2', 'smoke3', 'smoke4', 'smoke5', 'smoke6', 'smoke7')}, 4)
end

local function RestoreAfterDelay()
	Sleep(12000)
	if open then Close() end
end

function script.AimFromWeapon(weaponNum)	return aimpoint end
function script.QueryWeapon(weaponNum) return missile end

function script.AimWeapon(weaponNum, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	if not open then Open() end
	Sleep(100)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(weaponNum)
	Spring.AddUnitExperience(unitID, 1) -- nuke missiles aren't worth exactly 1 anti, but for simplicity
	Hide(missile)
	Sleep(500)
	if open then Close() end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(door1, SFX.NONE)
		Explode(door2, SFX.NONE)
		Explode(brace, SFX.SMOKE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(door1, SFX.SHATTER)
		Explode(door2, SFX.SHATTER)
		Explode(brace, SFX.SMOKE)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER)
		Explode(door1, SFX.SMOKE + SFX.FIRE)
		Explode(door2, SFX.SMOKE + SFX.FIRE)
		Explode(brace, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(door1, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(door2, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(brace, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
