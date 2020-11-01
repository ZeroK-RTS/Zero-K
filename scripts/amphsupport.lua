include 'constants.lua'

local base = piece 'base'
local aimfrom = piece 'aimfrom'
local pelvis = piece 'pelvis'
local head_gimbal = piece 'head_gimbal'
local head = piece 'head'

local rthigh = piece 'rthigh'
local rcalf = piece 'rcalf'
local rfoot = piece 'rfoot'

local lthigh = piece 'lthigh'
local lcalf = piece 'lcalf'
local lfoot = piece 'lfoot'

local cthigh = piece 'cthigh'
local ccalf = piece 'ccalf'
local cfoot = piece 'cfoot'

local raxel = piece 'raxel'
local rbarrel = piece 'rbarrel'
local rflare = piece 'rflare'

local laxel = piece 'laxel'
local lbarrel = piece 'lbarrel'
local lflare = piece 'lflare'

local smokePiece = {head}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitVelocity = Spring.GetUnitVelocity

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_DEPLOY = 4

local GUN_DEPLOY_DIST = 6
local AIM_SPEED = 180

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local moving = false
local deployed = false
local gun = false

local PACE = 1.8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Move(pelvis, y_axis, 0, 8)
	
	Move(base, y_axis, 2, PACE*2)
	Turn(lthigh, x_axis, math.rad(20),  PACE*math.rad(50))
	Turn(rthigh, x_axis, math.rad(-20), PACE*math.rad(50))
	Turn(lfoot,  x_axis, math.rad(-15), PACE*math.rad(70))
	Turn(rfoot,  x_axis, math.rad(5),   PACE*math.rad(50))
	Turn(rcalf,  x_axis, math.rad(-15), PACE*math.rad(70))
	Sleep(360/PACE)
	
	Turn(lfoot,  x_axis, math.rad(20),  PACE*math.rad(100))
	Turn(rfoot,  x_axis, math.rad(10),  PACE*math.rad(50))
	Turn(rcalf,  x_axis, math.rad(20),  PACE*math.rad(100))
	Sleep(360/PACE)
	
	Move(base, y_axis, 3, PACE*2)
	Turn(pelvis, z_axis, math.rad(-3.5), PACE*math.rad(3))
	Turn(lthigh, x_axis, math.rad(-20),  PACE*math.rad(50))
	Turn(rthigh, x_axis, math.rad(20),   PACE*math.rad(50))
	Turn(rfoot,  x_axis, math.rad(-20),  PACE*math.rad(130))
	Turn(lcalf,  x_axis, math.rad(-25),  PACE*math.rad(100))
	Sleep(650/PACE)
	
	Turn(rfoot,  x_axis, math.rad(20),   PACE*math.rad(100))
	Turn(lcalf,  x_axis, math.rad(20),   PACE*math.rad(100))
	Move(base, y_axis, 0, 2)
	Sleep(360/PACE)
	
	while true do
		Move(base, y_axis, 3.5, PACE*2)
		Turn(pelvis, z_axis, math.rad(3.5), PACE*math.rad(8))
		
		Turn(rthigh, x_axis, math.rad(-24), PACE*math.rad(70))
		Turn(rcalf,  x_axis, math.rad(-20), PACE*math.rad(100))
		Turn(lthigh, x_axis, math.rad(20),  PACE*math.rad(70))
		Turn(lfoot,  x_axis, math.rad(-40), PACE*math.rad(50))
		
		Sleep(650/PACE)
		
		Turn(lfoot,  x_axis, math.rad(20),  PACE*math.rad(80))
		Turn(rcalf,  x_axis, math.rad(30),  PACE*math.rad(100))
		Turn(rfoot,  x_axis, math.rad(-5),  PACE*math.rad(80))
		Move(base, y_axis, 0, PACE*2)
		Sleep(360/PACE)
		
		Move(base, y_axis, 3.5, PACE*2)
		Turn(pelvis, z_axis, math.rad(-3.50), PACE*math.rad(8))
		
		Turn(lthigh, x_axis, math.rad(-24),   PACE*math.rad(70))
		Turn(lcalf,  x_axis, math.rad(-20),   PACE*math.rad(100))
		Turn(rthigh, x_axis, math.rad(20),    PACE*math.rad(70))
		Turn(rfoot,  x_axis, math.rad(-40),   PACE*math.rad(50))
		
		Sleep(650/PACE)
		
		Turn(rfoot, x_axis, math.rad(20), PACE*math.rad(80))
		Turn(lcalf, x_axis, math.rad(30), PACE*math.rad(100))
		Turn(lfoot,  x_axis, math.rad(-5),  PACE*math.rad(80))
		Move(pelvis, y_axis, 0, PACE*2)
		Sleep(360/PACE)
	end
end

local function AnimateDeployment(distance, speed, wait)
	Move(base, y_axis, 0, 16*speed)
	Turn(pelvis, z_axis, 0, math.rad(30))
	
	if wait then
		Move(pelvis, z_axis, 0, 4*speed)
		Move(pelvis, y_axis, 0, 3*speed)
		
		Turn(rthigh, x_axis, 0, math.rad(120)*speed)
		Turn(rcalf, x_axis, 0, math.rad(120)*speed)
		Turn(rfoot, x_axis, 0, math.rad(120)*speed)
		
		Turn(lthigh, x_axis, 0, math.rad(120)*speed)
		Turn(lcalf, x_axis, 0, math.rad(120)*speed)
		Turn(lfoot, x_axis, 0, math.rad(120)*speed)
		
		Turn(cthigh, x_axis, math.rad(-110)*distance, math.rad(220)*speed)
		Turn(ccalf, x_axis, math.rad(-40)*distance, math.rad(120)*speed)
		Turn(cfoot, x_axis, math.rad(10)*distance, math.rad(120)*speed)
		
		Sleep(400)
	end
	
	Move(raxel, x_axis, -3*distance, 6*speed)
	Move(laxel, x_axis, 3*distance, 6*speed)
	
	Move(pelvis, z_axis, -4*distance, 4*speed)
	Move(pelvis, y_axis, -3*distance, 3*speed)
	Turn(pelvis, x_axis,  math.rad(-10)*distance, math.rad(-10)*speed)
	
	Turn(rthigh, x_axis, math.rad(-48)*distance, math.rad(48)*speed)
	Turn(rcalf, x_axis, math.rad(-7)*distance, math.rad(14)*speed)
	Turn(rfoot, x_axis, math.rad(60)*distance, math.rad(90)*speed)
	
	Turn(lthigh, x_axis, math.rad(-48)*distance, math.rad(48)*speed)
	Turn(lcalf, x_axis, math.rad(-7)*distance, math.rad(14)*speed)
	Turn(lfoot, x_axis, math.rad(60)*distance, math.rad(90)*speed)
	
	if wait then
		Sleep(300)
		Turn(cthigh, x_axis, math.rad(-118)*distance, math.rad(30)*speed)
		Turn(ccalf, x_axis, math.rad(0)*distance, math.rad(55)*speed)
		Turn(cfoot, x_axis, math.rad(-25)*distance, math.rad(70)*speed)
	
		WaitForTurn(lcalf, x_axis)
	end
	
	Move(lbarrel, z_axis, GUN_DEPLOY_DIST*distance, 12*speed)
	Move(rbarrel, z_axis, GUN_DEPLOY_DIST*distance, 12*speed)
	
	Turn(rthigh, y_axis, math.rad(-35)*distance, math.rad(65)*speed)
	Turn(rcalf, x_axis, math.rad(12)*distance, math.rad(40)*speed)
	Turn(rfoot, x_axis, math.rad(40)*distance, math.rad(80)*speed)
	Turn(rfoot, z_axis, math.rad(-5)*distance, math.rad(10)*speed)
	
	Turn(lthigh, y_axis, math.rad(35)*distance, math.rad(65)*speed)
	Turn(lcalf, x_axis, math.rad(12)*distance, math.rad(40)*speed)
	Turn(lfoot, x_axis, math.rad(40)*distance, math.rad(80)*speed)
	Turn(lfoot, z_axis, math.rad(5)*distance, math.rad(10)*speed)
	
	if not wait then
		Turn(cthigh, x_axis, math.rad(-118)*distance, math.rad(80)*speed)
		Turn(ccalf, x_axis, math.rad(0)*distance, math.rad(80)*speed)
		Turn(cfoot, x_axis, math.rad(-25)*distance, math.rad(50)*speed)
	end
	
	if wait then
		WaitForMove(pelvis, z_axis)
	end
end

local function SetDeploy(wantDeploy)
	Signal(SIG_DEPLOY)
	SetSignalMask(SIG_DEPLOY)
	if wantDeploy then
		AnimateDeployment(1, 1, true)
		deployed = true
	else
		deployed = false
		Turn(head, y_axis, 0, math.rad(AIM_SPEED))
		Turn(laxel, x_axis, math.rad(-10), math.rad(AIM_SPEED*1.5))
		Turn(raxel, x_axis, math.rad(-10), math.rad(AIM_SPEED*1.5))
		--WaitForTurn(head, y_axis)
		--WaitForTurn(head, laxel)

		AnimateDeployment(0, 1.2, false)
	end
end

function StartMoving()
	moving = true
	StartThread(SetDeploy, false)
	StartThread(Walk)
end

function StopMoving()
	moving = false
	StartThread(SetDeploy, true)
	Signal(SIG_WALK)
end

local function CheckMoving()
	while true do
		local speed = select(4,spGetUnitVelocity(unitID))
		if moving then
			if speed <= 0.05 then
				StopMoving()
			end
		else
			if speed > 0.05 then
				StartMoving()
			end
		end
		Sleep(33)
	end
end

function script.Create()
	Turn(head_gimbal, x_axis, math.rad(10))
	Turn(raxel, x_axis, math.rad(-10))
	Turn(laxel, x_axis, math.rad(-10))
	moving = false
	StartThread(SetDeploy, true)
	StartThread(CheckMoving)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

local function RestoreAfterDelay()
	Sleep(2750)
	Turn(head, y_axis, 0, math.rad(AIM_SPEED*0.25))
	WaitForTurn(head, y_axis)
	Turn(laxel, x_axis, math.rad(-10), math.rad(AIM_SPEED*0.37))
	Turn(raxel, x_axis, math.rad(-10), math.rad(AIM_SPEED*0.37))
end

function script.QueryWeapon(num)
	if gun then
		return lflare
	else
		return rflare
	end
end

function script.AimFromWeapon(num)
	return aimfrom
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		
		if moving or not deployed then
			return false
		else
			Turn(head, y_axis, heading, math.rad(AIM_SPEED)) -- left-right
			Turn(laxel, x_axis, -pitch, math.rad(AIM_SPEED*1.5)) --up-down
			Turn(raxel, x_axis, -pitch, math.rad(AIM_SPEED*1.5)) --up-down
			WaitForTurn(head, y_axis)
			WaitForTurn(laxel, x_axis)
			StartThread(RestoreAfterDelay)
			return true
		end
	elseif num == 2 then
		--GG.Floating_AimWeapon(unitID)
		return false
	end
end

local function recoil()
	if gun then
		EmitSfx(lflare, 1024)
		EmitSfx(lflare, 1025)
		Move(lbarrel, z_axis, -2)
		Move(lbarrel, z_axis, GUN_DEPLOY_DIST, 3)
	else
		EmitSfx(rflare, 1024)
		EmitSfx(rflare, 1025)
		Move(rbarrel, z_axis, -2)
		Move(rbarrel, z_axis, GUN_DEPLOY_DIST, 3)
	end
end

function script.FireWeapon(num)
	StartThread(recoil)
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/350
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 141.1, 30 * distMult, false, false, true)
	end
	return false
end

function script.EndBurst()
	gun = not gun
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rcalf, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rcalf, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(head, SFX.NONE)

		Explode(rthigh, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lthigh, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rcalf, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.NONE)
		return 2
	end
	
	Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(head, SFX.NONE)

	Explode(rthigh, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(lthigh, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(rcalf, SFX.NONE)
	Explode(lcalf, SFX.NONE)
	Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(lfoot, SFX.NONE)
	return 2
end
