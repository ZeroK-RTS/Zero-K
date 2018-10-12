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

local tauOn12 = tau/12
local tauOn6 = tau/6

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
	StartThread(SmokeUnit, smokePiece)
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	if not readyToFire then
		StartThread(popUp)
		Sleep(250)
	end

	--Spring.Echo(heading*toDegrees)
	
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

function script.BlockShot(num, targetID)
	-- This call is a form of evil hackery, because EMP weapon is hitting target instantly.
	-- This forces OKP to release target block when target is 15 frame away from to reach 100% EMP damage.
	return GG.OverkillPrevention_CheckBlockEMP(unitID, targetID, 1200, 60, 45)
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
		Explode(turret, sfxShatter)
		Explode(door1, sfxSmoke)
		Explode(door2, sfxSmoke)
		Explode(door3, sfxSmoke)
		Explode(door4, sfxSmoke)
		Explode(door5, sfxSmoke)
		Explode(door6, sfxSmoke)
		return 1
	elseif severity <= 0.50 then
		Explode(body, sfxShatter)
		Explode(turret, sfxShatter)
		Explode(door1, sfxFall)
		Explode(door2, sfxFall)
		Explode(barrel, sfxFall + sfxSmoke)
		Explode(door4, sfxFall)
		Explode(door6, sfxFall + sfxSmoke)
		Explode(b1, sfxFall)
		Explode(sleeve, sfxExplode + sfxSmoke)
		return 1
	else
		Explode(body, sfxShatter + sfxExplodeOnHit)
		Explode(turret, sfxShatter)
		Explode(door1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(door2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(door3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(door4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(door5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(door6, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)

		Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(b1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)		
		return 2
	end
end
