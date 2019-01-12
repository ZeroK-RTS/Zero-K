include 'constants.lua'

local head = piece 'head' 
local hips = piece 'hips' 
local lshoulder = piece 'lshoulder' 
local lbcover = piece 'lbcover' 
local ltcover = piece 'ltcover' 
local rshoulder = piece 'rshoulder' 
local rbcover = piece 'rbcover' 
local rtcover = piece 'rtcover' 
local chest = piece 'chest' 
local rthigh = piece 'rthigh' 
local lthigh = piece 'lthigh' 
local lshin = piece 'lshin' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lfoot = piece 'lfoot' 
local lmissile = piece 'lmissile' 
local rmissile = piece 'rmissile' 
local rmuzzle = piece 'rmuzzle' 
local rexhaust = piece 'rexhaust' 
local lmuzzle = piece 'lmuzzle' 
local lexhaust = piece 'lexhaust' 

local RESTORE_SPEED = math.rad(100)
local COVER_UNFOLD_ANGLE = math.rad(100)
local COVER_UNFOLD_SPEED = math.rad(400)

local gun = false
local aiming = false

-- Signal definitions
local SIG_AIM = 2
local SIG_WALK = 1
local SIG_RESTORE = 4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	local speedmod = 1.0
	while true do
		speedmod = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1.0)
		if not aiming then
			Turn(chest, x_axis, math.rad(20), speedmod*math.rad(40))
			Turn(chest, y_axis, math.rad(10), speedmod*math.rad(40))
		end
		Turn(lshin, x_axis, math.rad(10), speedmod*math.rad(630))
		Turn(rshin, x_axis, math.rad(85), speedmod*math.rad(540))
		Turn(rthigh, x_axis, math.rad(-100), speedmod*math.rad(445))
		Turn(lthigh, x_axis, math.rad(30), speedmod*math.rad(445))
		Turn(hips, z_axis, 0.1, speedmod*math.rad(45))
		WaitForTurn(lthigh, x_axis)

		if not aiming then
			Turn(chest, y_axis, math.rad(-10), speedmod*math.rad(40))
		end
		Turn(rshin, x_axis, math.rad(10), speedmod*math.rad(630))
		Turn(lshin, x_axis, math.rad(85), speedmod*math.rad(540))
		Turn(lthigh, x_axis, math.rad(-100), speedmod*math.rad(445))
		Turn(rthigh, x_axis, math.rad(30), speedmod*math.rad(445))
		Turn(hips, z_axis, -0.1, speedmod*math.rad(45))
		WaitForTurn(rthigh, x_axis)
	end
end

local function StopWalk()
	Signal(SIG_WALK)
	Turn(chest, x_axis, 0, math.rad(180))
	Turn(chest, y_axis, 0, math.rad(180))
	Turn(hips, z_axis, 0, math.rad(90))
	Turn(lfoot, x_axis, 0, math.rad(395))
	Turn(rfoot, x_axis, 0, math.rad(395))
	Turn(rthigh, x_axis, 0, math.rad(235))
	Turn(lthigh, x_axis, 0, math.rad(230))
	Turn(lshin, x_axis, 0, math.rad(235))
	Turn(rshin, x_axis, 0, math.rad(230))

	Turn(rthigh, y_axis, math.rad(-20), math.rad(135))
	Turn(lthigh, y_axis, math.rad(20), math.rad(130))

	Turn(hips, x_axis, 0, math.rad(125))

	Turn(rthigh, z_axis, math.rad(-(3)), math.rad(135))
	Turn(lthigh, z_axis, math.rad(-(-3)), math.rad(130))
	Turn(lfoot, z_axis, math.rad(-(3)), math.rad(130))
	Turn(rfoot, z_axis, math.rad(-(-3)), math.rad(130))
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.Create()
	StartThread(SmokeUnit, {chest})
end

-----------------------------------------------------------------------
--gun functions
-----------------------------------------------------------------------
function script.QueryWeapon(num)
	return gun and rmissile or lmissile
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(2000)
	Turn(chest, y_axis, 0, RESTORE_SPEED)
	Turn(rtcover, x_axis, 0, RESTORE_SPEED)
	Turn(rbcover, x_axis, 0, RESTORE_SPEED)
	Turn(ltcover, x_axis, 0, RESTORE_SPEED)
	Turn(lbcover, x_axis, 0, RESTORE_SPEED)
	aiming = false
end

function script.AimFromWeapon(num)
	return head
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	aiming = true
	Turn(chest, x_axis, 0) 
	Turn(chest, y_axis, heading, math.rad(450))
	Turn(lshoulder, x_axis, -pitch, math.rad(500))
	Turn(rshoulder, x_axis, -pitch, math.rad(500))
	Turn(rtcover, x_axis, -COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(rbcover, x_axis, COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(ltcover, x_axis, -COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(lbcover, x_axis, COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	WaitForTurn(chest, y_axis)
	WaitForTurn(lshoulder, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end
	
function script.Shot(num)
	if gun then
		EmitSfx(lmuzzle,  1024)
		EmitSfx(lexhaust,  1025)
		Move(lmissile, z_axis, -1 )	
		Move(lmissile, z_axis, 0, 500)
	else
		EmitSfx(rmuzzle,  1024)
		EmitSfx(rexhaust,  1025)
		Move(rmissile, z_axis, -1 )
		Move(rmissile, z_axis, 0, 500)
	end
	gun = not gun
end
	

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local corpseType = 1
	if severity <= .25 then
		Explode(hips, sfxNone)
		Explode(chest, sfxNone)
		Explode(lshoulder, sfxNone)
		Explode(rshoulder, sfxNone)
		Explode(head, sfxFall + sfxFire)
	elseif severity <= .50 then
		Explode(hips, sfxNone)
		Explode(chest, sfxNone)
		Explode(lshoulder, sfxFall + sfxFire)
		Explode(rshoulder, sfxFall + sfxFire)
		Explode(head, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	else
		corpseType = 2
		Explode(hips, sfxShatter)
		Explode(chest, sfxShatter)
		Explode(lshoulder, sfxShatter)
		Explode(rshoulder, sfxShatter)
		Explode(head, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	end
	
	return corpseType
end
