local base = piece 'base'
local body = piece 'body'
local turret = piece 'turret'
local aim = piece 'aim'
local door1 = piece 'door1'
local door2 = piece 'door2'
local door3 = piece 'door3'
local door4 = piece 'door4'
local door5 = piece 'door5'
local door6 = piece 'door6'
local sleeve = piece 'sleeve'
local b1 = piece 'b1'
local barrel = piece 'barrel'
local flare = piece 'flare'
local p1 = piece 'p1'
local p2 = piece 'p2'
local p3 = piece 'p3'
local p4 = piece 'p4'

include "constants.lua"

local spGetUnitIsStunned = Spring.GetUnitIsStunned

local readyToFire = false
local RESTORE_DELAY = 3000
local position = 0

local tauOn12 = GG.Script.tau/12
local tauOn6 = GG.Script.tau/6

-- Signal definitions
local SIG_RESTORE = 1
local SIG_AIM = 2
local SIG_OPEN = 4
local SIG_CLOSE = 8

local smokePiece = { base, aim}

local function popUp()
	Spring.SetUnitArmored(unitID,false)
	
	Signal(SIG_CLOSE)
	SetSignalMask(SIG_OPEN)
	
	Turn(door1, z_axis, math.rad(0), math.rad(210))
	Turn(door2, z_axis, math.rad(0), math.rad(210))
	Turn(door3, z_axis, math.rad(0), math.rad(210))
	Turn(door4, z_axis, math.rad(0), math.rad(210))
	Turn(door5, x_axis, 0, math.rad(210))
	Turn(door6, x_axis, 0, math.rad(210))
	
	Sleep(100)
	Move(turret, y_axis, 0, 150)
	Sleep(100)
	Move(b1, z_axis, 0, 50)
	Move(barrel, z_axis, 0, 50)
	--WaitForMove(barrel, z_axis)
	readyToFire = true
end

local function popDown()
	
	Signal(SIG_OPEN)
	SetSignalMask(SIG_CLOSE)
	
	readyToFire = false
	
	Turn(turret, y_axis, tauOn6*position, math.rad(200))
	Turn(sleeve, x_axis,0, math.rad(100))
	
	Move(b1, z_axis, -4.4, 5)
	Move(barrel, z_axis, -7.4, 5)
	Sleep(500)
	
	Move(turret, y_axis, -34, 22)
	Sleep(700)
	
	Turn(door1, z_axis, math.rad(-120), math.rad(110))
	Turn(door2, z_axis, math.rad(-120), math.rad(110))
	Turn(door3, z_axis, math.rad(120), math.rad(110))
	Turn(door4, z_axis, math.rad(120), math.rad(110))
	Turn(door5, x_axis, math.rad(120), math.rad(110))
	Turn(door6, x_axis, math.rad(-120), math.rad(110))
	
	Spring.SetUnitArmored(unitID,true)
end


local function RestoreAfterDelay()

	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)

	Sleep(RESTORE_DELAY)
	while spGetUnitIsStunned(unitID) do
		Sleep(1000)
	end
	
	StartThread(popDown)
end

function script.Create()

	Hide(flare)
	
	position = 0
	
	Turn(p1, y_axis, math.rad(-33))
	Turn(p2, y_axis, math.rad(33))
	Turn(p3, y_axis, math.rad(33))
	Turn(p4, y_axis, math.rad(-33))

	while spGetUnitIsStunned(unitID) do
		Sleep(1000)
	end
	StartThread(RestoreAfterDelay)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	if not readyToFire then
		StartThread(popUp)
		Sleep(250)
	end

	--Spring.Echo(heading*GG.Script.toDegrees)
	
	position = math.floor((heading + tauOn12)/tauOn6)%6
	--Spring.Echo(position)
	
	
	Turn(turret, y_axis, heading, math.rad(600))
	Turn(sleeve, x_axis, -pitch, math.rad(300))
	WaitForTurn(sleeve, x_axis)
	WaitForTurn(turret, y_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	EmitSfx(flare, 1024 + 0)
	EmitSfx(flare, 1024 + 1)
end

function script.AimFromWeapon(num)
	return aim
end

function script.QueryWeapon(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(turret, SFX.SHATTER)
		Explode(door1, SFX.SMOKE)
		Explode(door2, SFX.SMOKE)
		Explode(door3, SFX.SMOKE)
		Explode(door4, SFX.SMOKE)
		Explode(door5, SFX.SMOKE)
		Explode(door6, SFX.SMOKE)
		return 1
	elseif severity <= 0.50 then
		Explode(body, SFX.SHATTER)
		Explode(turret, SFX.SHATTER)
		Explode(door1, SFX.FALL)
		Explode(door2, SFX.FALL)
		Explode(barrel, SFX.FALL + SFX.SMOKE)
		Explode(door4, SFX.FALL)
		Explode(door6, SFX.FALL + SFX.SMOKE)
		Explode(b1, SFX.FALL)
		Explode(sleeve, SFX.EXPLODE + SFX.SMOKE)
		return 1
	else
		Explode(body, SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.SHATTER)
		Explode(door1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)

		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(b1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(sleeve, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
