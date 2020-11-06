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
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_DEPLOY = 4
local SIG_FLOAT = 8
local SIG_BOB = 16

local GUN_DEPLOY_DIST = 6
local AIM_SPEED = 180

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local moving = false
local floating = false
local deployed = false
local gun = false

local PACE = 1.75

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	while true do
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Move(base, y_axis, math.rad(math.random(0,6)), math.rad(math.random(2,6)))
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Move(base, y_axis, math.rad(math.random(-6,0)), math.rad(math.random(2,6)))
		Sleep(2000)
	end
end

local function SinkBubbles()
	SetSignalMask(SIG_FLOAT)
	while true do
		EmitSfx(cthigh, SFX.BUBBLE)
		EmitSfx(lbarrel, SFX.BUBBLE)
		EmitSfx(rbarrel, SFX.BUBBLE)
		Sleep(66)
	end
end

local function dustBottom()
	local x1,y1,z1 = Spring.GetUnitPiecePosDir(unitID,rfoot)
	Spring.SpawnCEG("uw_amphlift", x1, y1+5, z1, 0, 0, 0, 0)
	local x2,y2,z2 = Spring.GetUnitPiecePosDir(unitID,lfoot)
	Spring.SpawnCEG("uw_amphlift", x2, y2+5, z2, 0, 0, 0, 0)
end

local function FloatThread(sign)
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)
	local speed = 0.7
	local cycle = 0
	
	Turn(rthigh, x_axis, math.rad(-100 + 9*sign), math.rad(80)*speed)
	Turn(rcalf, x_axis,  math.rad(115  + 9*sign), math.rad(100)*speed)
	Turn(rfoot, x_axis,  math.rad(-10  + 9*sign), math.rad(100)*speed)
	Turn(lthigh, x_axis, math.rad(-100 + 9*sign), math.rad(80)*speed)
	Turn(lcalf, x_axis,  math.rad(115  + 9*sign), math.rad(100)*speed)
	Turn(lfoot, x_axis,  math.rad(-10  + 9*sign), math.rad(100)*speed)
	Turn(cthigh, x_axis, math.rad(-90  - 9*sign), math.rad(80)*speed)
	Turn(ccalf, x_axis,  math.rad(-70  - 9*sign), math.rad(100)*speed)
	Turn(cfoot, x_axis,  math.rad(10   + 9*sign), math.rad(100)*speed)
	Sleep(150)
	
	while true do
		Turn(rthigh, x_axis, math.rad(-100 + ((cycle + 0)%3 - 1)*9), math.rad(80)*speed)
		Turn(rcalf, x_axis,  math.rad(115  + ((cycle + 0)%3 - 1)*9), math.rad(100)*speed)
		Turn(rfoot, x_axis,  math.rad(-10  + ((cycle + 0)%3 - 1)*9), math.rad(100)*speed)
		
		Turn(lthigh, x_axis, math.rad(-100 + ((cycle + 1)%3 - 1)*9), math.rad(80)*speed)
		Turn(lcalf, x_axis,  math.rad(115  + ((cycle + 1)%3 - 1)*9), math.rad(100)*speed)
		Turn(lfoot, x_axis,  math.rad(-10  + ((cycle + 1)%3 - 1)*9), math.rad(100)*speed)
		
		Turn(cthigh, x_axis, math.rad(-90  - ((cycle + 2)%3 - 1)*9), math.rad(80)*speed)
		Turn(ccalf, x_axis,  math.rad(-70  - ((cycle + 2)%3 - 1)*9), math.rad(100)*speed)
		Turn(cfoot, x_axis,  math.rad(10   + ((cycle + 2)%3 - 1)*9), math.rad(100)*speed)
	
		Sleep(900)
		speed = 0.1
		cycle = (cycle + 1)%3
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	dustBottom()
	Signal(SIG_WALK)
	Signal(SIG_FLOAT)
	StartThread(FloatThread, 1)
	StartThread(Bob)
end

function Float_stopOnFloor()
	dustBottom()
	Signal(SIG_BOB)
	Signal(SIG_FLOAT)
end

function Float_rising()
end

function Float_sinking()
	Signal(SIG_FLOAT)
	StartThread(SinkBubbles)
end

function Float_crossWaterline(speed)
	Signal(SIG_FLOAT)
	StartThread(FloatThread, -1)
end

function Float_stationaryOnSurface()
end

function unit_teleported(position)
	return GG.Floating_UnitTeleported(unitID, position)
end

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

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

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
	Signal(SIG_FLOAT)
	Signal(SIG_BOB)
	StartThread(Walk)
end

function StopMoving()
	moving = false
	StartThread(SetDeploy, true)
	if floating then
		Signal(SIG_FLOAT)
		StartThread(FloatThread, 1)
	end
	Signal(SIG_WALK)
end

function script.StopMoving()
	GG.Floating_StopMoving(unitID)
end

local prevSpeed = false
local function IsMoving()
	local speed = select(4, spGetUnitVelocity(unitID))
	floating = false
	if speed <= 0.1 then
		prevSpeed = false
		return false
	end
	if not prevSpeed then
		prevSpeed = true
		return false
	end
	local x, y, z = spGetUnitPosition(unitID)
	if (y > -2) then
		return true
	end
	-- Deploy if floating somewhere in the water.
	local height = spGetGroundHeight(x, z)
	floating = (y > height + 1) and (height < -20)
	return not floating
end

local function CheckMoving()
	while true do
		if moving then
			if not IsMoving() then
				StopMoving()
			end
		else
			if IsMoving()  then
				StartMoving()
			end
		end
		Sleep(33)
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local function WeaponRangeUpdate()
	while true do
		local height = select(2, Spring.GetUnitPosition(unitID))
		if height < -20 then
			Spring.SetUnitWeaponState(unitID, 2, {range = 550 - height})
			Spring.SetUnitMaxRange(unitID, 550 - height)
		else
			Spring.SetUnitWeaponState(unitID, 2, {range = 600})
			Spring.SetUnitMaxRange(unitID, 600)
		end
		Sleep(500)
	end
end

function script.Create()
	Turn(head_gimbal, x_axis, math.rad(10))
	Turn(raxel, x_axis, math.rad(-10))
	Turn(laxel, x_axis, math.rad(-10))
	moving = false
	
	StartThread(CheckMoving)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(WeaponRangeUpdate)
	
	local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID)
	if not stunned_or_inbuild then
		StartThread(SetDeploy, true)
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

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
		GG.Floating_AimWeapon(unitID)
		return false
	end
end

local function recoil()
	if gun then
		EmitSfx(lflare, 1024)
		EmitSfx(lflare, 1025)
		Move(lbarrel, z_axis, -2)
		Move(lbarrel, z_axis, GUN_DEPLOY_DIST, 4.2)
	else
		EmitSfx(rflare, 1024)
		EmitSfx(rflare, 1025)
		Move(rbarrel, z_axis, -2)
		Move(rbarrel, z_axis, GUN_DEPLOY_DIST, 4.2)
	end
end

function script.FireWeapon(num)
	StartThread(recoil)
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/600
		-- Reduced damage because it has a chance of missing.
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 145.1, 50 * distMult, false, false, true)
	end
	return false
end


function script.EndBurst()
	gun = not gun
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.5 then
		Explode(base, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(rthigh, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lthigh, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rcalf, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lcalf, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		return 1
	end
	
	Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(head, SFX.SHATTER + SFX.FIRE)
	Explode(rbarrel, SFX.SHATTER + SFX.FIRE)
	Explode(lbarrel, SFX.SHATTER + SFX.FIRE)

	Explode(rthigh, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(lthigh, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(rcalf, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(lcalf, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	Explode(lfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	return 2
end
