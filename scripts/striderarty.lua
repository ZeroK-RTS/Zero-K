include "constants.lua"

local torso = piece 'torso'
local pelvis = piece 'pelvis'
local rupleg = piece 'rupleg'
local rleg = piece 'rleg'
local rfoot = piece 'rfoot'
local rtoer = piece 'rtoer'
local rtoef1 = piece 'rtoef1'
local rtoef2 = piece 'rtoef2'
local lleg = piece 'lleg'
local lupleg = piece 'lupleg'
local lfoot = piece 'lfoot'
local ltoer = piece 'ltoer'
local ltoef1 = piece 'ltoef1'
local ltoef2 = piece 'ltoef2'
local launchers = piece 'launchers'
local llauncher = piece 'llauncher'
local rlauncher = piece 'rlauncher'

local lfires = {}
local rfires = {}
for i = 1, 20 do
	lfires[i] = piece('lfire' .. i)
	rfires[i] = piece('rfire' .. i)
end

--Init variables
local bAiming = false
local gun_1 = 1
local gun_1_side = 0

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 4

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Turn(lupleg, x_axis, math.rad(20), math.rad(50))
	Turn(rupleg, x_axis, math.rad(-20), math.rad(50))
	Turn(lfoot, x_axis, math.rad(-15), math.rad(70))
	Turn(rfoot, x_axis, math.rad(5), math.rad(50))
	Turn(rleg, x_axis, math.rad(-10), math.rad(70))
	if not bAiming then
		Turn(torso, x_axis, math.rad(-1), math.rad(5))
	end
	Sleep(360)
	
	Turn(lfoot, x_axis, math.rad(20), math.rad(100))
	Turn(rfoot, x_axis, math.rad(10), math.rad(50))
	Turn(rleg, x_axis, math.rad(20), math.rad(100))
	Turn(ltoef1, x_axis, math.rad(22.5), math.rad(100))
	Turn(ltoef2, x_axis, math.rad(22.5), math.rad(100))
	Turn(ltoer, x_axis, math.rad(-22.5), math.rad(100))
	Turn(rtoef1, x_axis, 0, math.rad(100))
	Turn(rtoef2, x_axis, 0, math.rad(100))
	Sleep(360)
	
	Turn(rtoer, x_axis, 0, math.rad(100))
	Move(pelvis, y_axis, 4, 2)
	Turn(pelvis, z_axis, math.rad(-3.50), math.rad(3))
	Turn(lupleg, x_axis, math.rad(-20), math.rad(50))
	Turn(rupleg, x_axis, math.rad(20), math.rad(50))
	Turn(rfoot, x_axis, math.rad(-20), math.rad(130))
	Turn(lleg, x_axis, math.rad(-20), math.rad(100))
	Sleep(650)
	
	Turn(rfoot, x_axis, math.rad(20), math.rad(100))
	Turn(lleg, x_axis, math.rad(20), math.rad(100))
	Move(pelvis, y_axis, 0, 2)
	Turn(ltoef1, x_axis, 0, math.rad(100))
	Turn(ltoef2, x_axis, 0, math.rad(100))
	Turn(rtoef1, x_axis, math.rad(22.5), math.rad(100))
	Turn(rtoef2, x_axis, math.rad(22.5), math.rad(100))
	Turn(rtoer, x_axis, math.rad(-22.5), math.rad(100))
	Sleep(360)
	
	while true do
		Turn(ltoer, x_axis, 0, math.rad(100))
		Move(pelvis, y_axis, 4, 2)
		Turn(pelvis, z_axis, math.rad(3.5), math.rad(8))
		Turn(lupleg, x_axis, math.rad(20), math.rad(50))
		Turn(rupleg, x_axis, math.rad(-20), math.rad(50))
		Turn(lfoot, x_axis, math.rad(-20), math.rad(130))
		Turn(rleg, x_axis, math.rad(-20), math.rad(100))
		if not bAiming then
			Turn(torso, y_axis, math.rad(2.5), math.rad(12))
			Turn(torso, x_axis, math.rad(1), math.rad(6))
		end
		Sleep(650)
		
		Turn(lfoot, x_axis, math.rad(20), math.rad(100))
		Turn(rfoot, x_axis, math.rad(20), math.rad(70))
		Turn(rleg, x_axis, math.rad(20), math.rad(100))
		Move(pelvis, y_axis, 0, 2)
		Turn(ltoef1, x_axis, math.rad(22.5), math.rad(100))
		Turn(ltoef2, x_axis, math.rad(22.5), math.rad(100))
		Turn(ltoer, x_axis, math.rad(-22.5), math.rad(100))
		Turn(rtoef1, x_axis, 0, math.rad(100))
		Turn(rtoef2, x_axis, 0, math.rad(100))
		Sleep(360)
		
		Turn(rtoer, x_axis, 0, math.rad(100))
		Move(pelvis, y_axis, 4, 2)
		Turn(pelvis, z_axis, math.rad(-3.50), math.rad(8))
		Turn(lupleg, x_axis, math.rad(-20), math.rad(50))
		Turn(rupleg, x_axis, math.rad(20), math.rad(50))
		Turn(rfoot, x_axis, math.rad(-20), math.rad(130))
		Turn(lleg, x_axis, math.rad(-20), math.rad(100))
		if not bAiming then
			Turn(torso, y_axis, math.rad(-2.5), math.rad(12))
			Turn(torso, x_axis, math.rad(-1), math.rad(6))
		end
		Sleep(650)
		
		Turn(rfoot, x_axis, math.rad(20), math.rad(100))
		Turn(lleg, x_axis, math.rad(20), math.rad(100))
		Move(pelvis, y_axis, 0, 2)
		Turn(ltoef1, x_axis, 0, math.rad(100))
		Turn(ltoef2, x_axis, 0, math.rad(100))
		Turn(rtoef1, x_axis, math.rad(22.5), math.rad(100))
		Turn(rtoef2, x_axis, math.rad(22.5), math.rad(100))
		Turn(rtoer, x_axis, math.rad(-22.5), math.rad(100))
		Sleep(360)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Turn(lupleg, x_axis, 0, math.rad(50))
	Turn(rupleg, x_axis, 0, math.rad(50))
	Turn(lleg, x_axis, 0, math.rad(100))
	Turn(rleg, x_axis, 0, math.rad(100))
	Move(pelvis, y_axis, 0, 20)
	Turn(pelvis, z_axis, math.rad(-(0)), math.rad(20))
	Turn(rtoef1, x_axis, 0, math.rad(100))
	Turn(rtoef2, x_axis, 0, math.rad(100))
	Turn(rtoer, x_axis, 0, math.rad(100))
	Turn(ltoef1, x_axis, 0, math.rad(100))
	Turn(ltoef2, x_axis, 0, math.rad(100))
	Turn(ltoer, x_axis, 0, math.rad(100))
	Turn(rfoot, x_axis, 0, math.rad(100))
	Turn(lfoot, x_axis, 0, math.rad(100))

	if not bAiming then
		Turn(torso, y_axis, 0, math.rad(100))
		Turn(torso, x_axis, 0, math.rad(20))
	end
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)
	Sleep(3000)
	Turn(torso, y_axis, 0, math.rad(90.000000))
	Turn(launchers, x_axis, 0, math.rad(45.000000))
	WaitForTurn(torso, y_axis)
	WaitForTurn(launchers, x_axis)
	bAiming = false
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {torso, rlauncher, llauncher})
	Turn(ltoef1, y_axis, math.rad(45))
	Turn(ltoef2, y_axis, math.rad(-45))
	Turn(rtoef1, y_axis, math.rad(45))
	Turn(rtoef2, y_axis, math.rad(-45))
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

function script.AimFromWeapon(num)
	return launchers
end

function script.FireWeapon(num)
	gun_1 = 0
	gun_1_side = 1
end

function script.Shot(num)
	if gun_1_side then
		gun_1 = gun_1 + 1
	end
	gun_1_side = not gun_1_side
end

function script.QueryWeapon(num)
	if gun_1 > 0 and gun_1 < 21 then
		if gun_1_side then
			return rfires[gun_1]
		else
			return lfires[gun_1]
		end
	else
		return launchers
	end
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	bAiming = true
	Turn(torso, y_axis, heading, math.rad(90))
	Turn(launchers, x_axis, -pitch, math.rad(45))
	WaitForTurn(torso, y_axis)
	WaitForTurn(launchers, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	if num == 1 and GG.DisableAttack and GG.DisableAttack.IsAttackDisabled(unitID) then
		return true
	end

	local reloadTime = Spring.GetUnitWeaponState(unitID, 1, "reloadTime")*30 -- Takes slow into account
	local otherNum = 3 - num
	local gameFrame = Spring.GetGameFrame()
	Spring.SetUnitWeaponState(unitID, otherNum, "reloadFrame", gameFrame + reloadTime)
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.50 then
		Explode(lfoot, SFX.FALL + SFX.EXPLODE)
		Explode(lleg, SFX.FALL + SFX.EXPLODE)
		Explode(pelvis, SFX.EXPLODE)
		Explode(rfoot, SFX.EXPLODE)
		Explode(rleg, SFX.EXPLODE)
		return 1
	end
	
	Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(rleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(torso, SFX.SHATTER + SFX.EXPLODE)
	Explode(rlauncher, SFX.FALL + SFX.SHATTER + SFX.EXPLODE)
	Explode(llauncher, SFX.FALL + SFX.SHATTER + SFX.EXPLODE)
	return 2
end
