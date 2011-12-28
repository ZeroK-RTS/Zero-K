include "constants.lua"

local base, turret, sleeves = piece("base", "turret", "sleeves")
local wake1, wake2 = piece("wake1", "wake2")
local barrel1, barrel2, flare1, flare2 = piece("barrel1", "barrel2", "flare1", "flare2")

local gunPieces = {
	[0] = {barrel = barrel1, flare = flare1},
	[1] = {barrel = barrel2, flare = flare2},
}
local missiles = { piece("missile1", "missile2", "missile3", "missile4") }

smokePiece = {base, turret}
----------------------------------------------------------
----------------------------------------------------------

local gun_1 = 0
local missileNum = 1
local SIG_MOVE = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

----------------------------------------------------------
----------------------------------------------------------

local function Wake()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep( 200)
	end
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end

function script.Create()
	StartThread(SmokeUnit)
	for i=1,#missiles do
		Turn(missiles[i], x_axis, -math.rad(90))
	end
end

function script.QueryWeapon(num) 
	if num == 1 then return gunPieces[gun_1].flare
	else return	missiles[missileNum]
	end
end

function script.AimFromWeapon(num)
	if num == 1 then return sleeves end
	return base
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(6000)
	Turn(turret, y_axis, 0, math.rad(120))
	Turn(sleeves, x_axis, 0, math.rad(60))
end

function script.AimWeapon( num, heading, pitch )
	if num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		Turn(turret, y_axis, heading, math.rad(270))
		Turn(sleeves, x_axis, -pitch, math.rad(120))
		WaitForTurn(turret, y_axis)
		WaitForTurn(sleeves, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		return true
	end
end

local function Recoil(piece)
	Move(piece, z_axis, -8)
	Sleep(400)
	Move(piece, z_axis, 0, 6)
end

function script.Shot(num)
	if num == 1 then
		EmitSfx(gunPieces[gun_1].flare, 1024)
		StartThread(Recoil, gunPieces[gun_1].barrel)
		gun_1 = 1 - gun_1
	elseif num == 2 then
		missileNum = missileNum + 1	
		if missileNum > 4 then missileNum = 1 end		
		EmitSfx(missiles[missileNum], 1025)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(sleeves, sfxNone)
		Explode(barrel1, sfxFall)
		Explode(barrel2, sfxFall)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(sleeves, sfxShatter)
		Explode(barrel1, sfxSmoke)
		Explode(barrel2, sfxSmoke)
		return 1 -- corpsetype
	elseif (severity <= 1) then
		Explode(base, sfxShatter)
		Explode(turret, sfxShatter)
		Explode(sleeves, sfxShatter)
		Explode(barrel1, sfxSmoke + sfxFire)
		Explode(barrel2, sfxSmoke + sfxFire)
		return 2 -- corpsetype
	else
		Explode(base, sfxShatter)
		Explode(turret, sfxShatter)
		Explode(sleeves, sfxShatter)
		Explode(barrel1, sfxSmoke + sfxFire + sfxExplode)
		Explode(barrel2, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
