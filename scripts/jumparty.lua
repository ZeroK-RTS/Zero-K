include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base' 
local pelvis = piece 'pelvis' 
local torso = piece 'torso' 
local rgun = piece 'rgun' 
local lgun = piece 'lgun' 
local rbarrel = piece 'rbarrel' 
local lbarrel = piece 'lbarrel' 
local fp1 = piece 'fp1' 
local fp2 = piece 'fp2' 
local rflap1 = piece 'rflap1' 
local rflap2 = piece 'rflap2' 
local rflap3 = piece 'rflap3' 
local rflap4 = piece 'rflap4' 
local lflap1 = piece 'lflap1' 
local lflap2 = piece 'lflap2' 
local lflap3 = piece 'lflap3' 
local lflap4 = piece 'lflap4' 
local rupleg = piece 'rupleg' 
local rloleg = piece 'rloleg' 
local rfoot = piece 'rfoot' 
local lupleg = piece 'lupleg' 
local lloleg = piece 'lloleg' 
local lfoot = piece 'lfoot' 
local rftoe = piece 'rftoe' 
local rrtoe = piece 'rrtoe' 
local lftoe = piece 'lftoe' 
local lrtoe = piece 'lrtoe' 

local flares = {[0] = fp2, [1] = fp1}
local barrels = {[0] = lbarrel, [1] = rbarrel}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_MOVE = 16

local RESTORE_DELAY = 6000

local WALK_RATE = 38

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
local bAiming = false
local bMoving = false
local gun_1 = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	local pace = WALK_RATE
	while true do
		pace = WALK_RATE*(Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		
		Turn(rupleg 	, y_axis, 0, math.rad(pace))
		Turn(lupleg 	, y_axis, 0, math.rad(pace))
		
		Turn(rupleg 	, z_axis, math.rad(-(0)), math.rad(pace))
		Turn(lupleg 	, z_axis, math.rad(-(0)), math.rad(pace))
		Turn(lfoot 	, z_axis, math.rad(-(0)), math.rad(pace))
		Turn(rfoot 	, z_axis, math.rad(-(0)), math.rad(pace))
	
		Turn(rupleg, x_axis, math.rad(-70.000000), math.rad(pace*4)) --Forward
		Turn(rloleg, x_axis, math.rad(70.000000), math.rad(pace*9))
		Turn(rfoot, x_axis, 0, math.rad(pace*4))
		
		Turn(rftoe, x_axis, 0, math.rad(pace*6))
		Turn(rrtoe, x_axis, 0, math.rad(pace*6))
		
		Turn(lupleg, x_axis, math.rad(10.000000), math.rad(pace*4)) --Back
		Turn(lloleg, x_axis, 0, math.rad(pace*2))
		Turn(lfoot, x_axis, math.rad(-10.000000), math.rad(pace*2))
		
		Turn(lftoe, x_axis, math.rad(-20), math.rad(pace*6))
		
		Turn(torso, z_axis, math.rad(-(5)), math.rad(pace*0.4))
		Turn(torso, x_axis, math.rad(3), math.rad(pace*1))
	
		WaitForTurn(rloleg, x_axis)
		Sleep(0)
			
		Turn(rupleg, x_axis, math.rad(10.000000), math.rad(pace*4)) --Mid
		Turn(rloleg, x_axis, math.rad(20.000000), math.rad(pace*5))
		Turn(rfoot, x_axis, math.rad(10.000000), math.rad(pace*1))
		
		Turn(lupleg, x_axis, math.rad(-70.000000), math.rad(pace*4)) --Up
		Turn(lloleg, x_axis, math.rad(-20.000000), math.rad(pace*2))
		Turn(lfoot, x_axis, math.rad(40.000000), math.rad(pace*4))
		
		Turn(lftoe, x_axis, math.rad(30), math.rad(pace*3))
		Turn(lrtoe, x_axis, math.rad(-30), math.rad(pace*3))
		
		Turn(torso, x_axis, math.rad(-3), math.rad(pace*1))
		
		WaitForTurn(rloleg, x_axis)
		Sleep(0)
		
		Turn(rupleg, x_axis, math.rad(10.000000), math.rad(pace*4)) --Back
		Turn(rloleg, x_axis, 0, math.rad(pace*2))
		Turn(rfoot, x_axis, math.rad(-10.000000), math.rad(pace*2))
		
		Turn(rftoe, x_axis, math.rad(-20), math.rad(pace*6))
		
		Turn(lupleg, x_axis, math.rad(-70.000000), math.rad(pace*4)) --Forward
		Turn(lloleg, x_axis, math.rad(70.000000), math.rad(pace*9))
		Turn(lfoot, x_axis, 0, math.rad(pace*4))
		
		Turn(lftoe, x_axis, 0, math.rad(pace*6))
		Turn(lrtoe, x_axis, 0, math.rad(pace*6))
		
		Turn(torso, z_axis, math.rad(-(-5)), math.rad(pace*0.4))
		Turn(torso, x_axis, math.rad(3), math.rad(pace*1))
		
		WaitForTurn(rloleg, x_axis)
		Sleep(0)
		
		Turn(rupleg, x_axis, math.rad(-70.000000), math.rad(pace*4)) --Up
		Turn(rloleg, x_axis, math.rad(-20.000000), math.rad(pace*2))
		Turn(rfoot, x_axis, math.rad(40.000000), math.rad(pace*4))
		
		Turn(rftoe, x_axis, math.rad(30), math.rad(pace*3))
		Turn(rrtoe, x_axis, math.rad(-30), math.rad(pace*3))
		
		Turn(lupleg, x_axis, math.rad(10.000000), math.rad(pace*4)) --Mid
		Turn(lloleg, x_axis, math.rad(20.000000), math.rad(pace*5))
		Turn(lfoot, x_axis, math.rad(10.000000), math.rad(pace*1))
		
		Turn(torso, x_axis, math.rad(-3), math.rad(pace*1))
		
		WaitForTurn(rloleg, x_axis)
		Sleep(0)
	end
end

local function Stop()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	Turn(lupleg, x_axis, 0, math.rad(50))
	Turn(rupleg, x_axis, 0, math.rad(50))
	Turn(lloleg, x_axis, 0, math.rad(100))
	Turn(rloleg, x_axis, 0, math.rad(100))
	if not bAiming then
		Turn(torso, z_axis, math.rad(-(0.000000)), math.rad(100))
		Turn(torso, x_axis, 0, math.rad(20.000000))
	end
	Turn(rftoe, x_axis, 0, math.rad(100))
	Turn(rrtoe, x_axis, 0, math.rad(100))
	Turn(lftoe, x_axis, 0, math.rad(100))
	Turn(lrtoe, x_axis, 0, math.rad(100))
	Turn(rfoot, x_axis, 0, math.rad(100))
	Turn(lfoot, x_axis, 0, math.rad(100))
	WaitForTurn(torso, x_axis)
	if not bAiming then
	
		Turn(torso, x_axis, math.rad(10.000000), math.rad(48.010989))
	end
	WaitForTurn(torso, x_axis)
	if not bAiming then
	
		Turn(torso, x_axis, math.rad(-3.000000), math.rad(48.010989))
	end
	WaitForTurn(torso, x_axis)
	if not bAiming then
	
		Turn(torso, x_axis, 0, math.rad(48.010989))
	end
	WaitForTurn(torso, x_axis)
	Sleep(20)
	return (0)
end

function script.Create()
	bMoving = false
	bAiming = false
	StartThread(GG.Script.SmokeUnit, {torso})
end

function script.StartMoving()
	bMoving = true
	StartThread(Walk)
end

function script.StopMoving()
	bMoving = false
	StartThread(Stop)
end


local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	local speed = math.rad(50)
	Turn(rflap1, x_axis, 0, speed)
	Turn(rflap2, x_axis, 0, speed)
	Turn(rflap3, y_axis, 0, speed)
	Turn(rflap4, y_axis, 0, speed)
	Turn(lflap1, x_axis, 0, speed)
	Turn(lflap2, x_axis, 0, speed)
	Turn(lflap3, y_axis, 0, speed)
	Turn(lflap4, y_axis, 0, speed)
	Turn(torso, y_axis, 0, speed)
	Turn(torso, x_axis, 0, speed)
	Turn(lgun, x_axis, 0, speed)
	Turn(rgun, x_axis, 0, speed)
	WaitForTurn(torso, y_axis)
	WaitForTurn(torso, x_axis)
	WaitForTurn(lgun, x_axis)
	WaitForTurn(rgun, x_axis)
	bAiming = false
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	local aimMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	
	bAiming = true
	Turn(rflap1, x_axis, 0, math.rad(168)*aimMult)
	Turn(rflap2, x_axis, 0, math.rad(168)*aimMult)
	Turn(rflap3, y_axis, 0, math.rad(168)*aimMult)
	Turn(rflap4, y_axis, 0, math.rad(168)*aimMult)
	Turn(lflap1, x_axis, 0, math.rad(168)*aimMult)
	Turn(lflap2, x_axis, 0, math.rad(168)*aimMult)
	Turn(lflap3, y_axis, 0, math.rad(168)*aimMult)
	Turn(lflap4, y_axis, 0, math.rad(168)*aimMult)
	Turn(rgun, x_axis, - pitch + 0.15, math.rad(168)*aimMult)
	Turn(lgun, x_axis, - pitch + 0.15, math.rad(168)*aimMult)
	Turn(torso, y_axis, heading, math.rad(65)*aimMult)
	WaitForTurn(torso, y_axis)
	WaitForTurn(lgun, x_axis)
	StartThread(RestoreAfterDelay)	
	return true
end

function script.AimFromWeapon(num)
	return torso
end


local function Recoil()
	local barrel = barrels[gun_1]
	EmitSfx(flares[gun_1], 1024)
	Move(barrel, z_axis, -8)
	Sleep(150)
	Move(barrel, z_axis, 0, 10)
end

function script.Shot(num)
	StartThread(Recoil)
	gun_1 = 1 - gun_1
end

function script.QueryWeapon(num)
	return flares[gun_1]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(torso, SFX.NONE)
		Explode(lgun, SFX.FALL)
		Explode(rgun, SFX.FALL)
		Explode(rupleg, SFX.NONE)
		Explode(rloleg, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lupleg, SFX.NONE)
		Explode(lloleg, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	end
	Explode(base, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(torso, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rupleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rloleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lupleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lloleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	return 2
end
