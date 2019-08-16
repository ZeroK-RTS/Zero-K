include 'constants.lua'

local base = piece 'base'
local body = piece 'body'
local head = piece 'head'
local tail = piece 'tail'
local lwing = piece 'lwing'
local rwing = piece 'rwing'
local rsack = piece 'rsack'
local lsack = piece 'lsack'
local dodobomb = piece 'dodobomb'

-- Signal definitions
--local SIG_AIM = 2
local SIG_MOVE = 4
local SIG_RESTORE = 8

local function Fly()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		Turn(lwing, z_axis, math.rad(40), math.rad(200))
		Turn(rwing , z_axis, math.rad(-40), math.rad(200))
		Turn(tail , x_axis, math.rad(20), math.rad(30))
		Move(base , y_axis, -20 , 8)
		WaitForTurn(lwing, z_axis)
		Turn(lwing , z_axis, math.rad(-40), math.rad(400))
		Turn(rwing , z_axis, math.rad(40), math.rad(400))
		Turn(tail , x_axis, math.rad(-20), math.rad(60))
		Move(base , y_axis, 0 , 16)
		WaitForTurn(lwing, z_axis)
	end
end

local function StopFly ()
	Turn(lwing, z_axis, 0, math.rad(200))
	Turn(rwing, z_axis, 0, math.rad(200))
end

function script.StartMoving()
	StartThread(Fly)
end

function script.StopMoving()
	Signal(SIG_MOVE)
	StartThread(StopFly)
end

function script.Create()
	EmitSfx(body, 1024+2)
	StartThread(Fly)
end

function script.AimFromWeapon(num)
	return dodobomb
end

function script.QueryWeapon(num)
	return dodobomb
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(15000)
	Show(dodobomb)
end

function script.AimWeapon(num, heading, pitch)
	return num == 2
end
	
function script.FireWeapon(num)
	if num == 2 then
		Hide(dodobomb)
		EmitSfx(dodobomb, 2050)
		StartThread(RestoreAfterDelay)
	end
end
	
function script.HitByWeapon(x, z, weaponID, damage)
	EmitSfx(body,  1024)
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	return 1
end
