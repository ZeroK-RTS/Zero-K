local base = piece 'base' 
local body = piece 'body' 
local barrel = piece 'barrel' 
local turret = piece 'turret' 
local flare = piece 'flare' 
--linear constant 163840

include "constants.lua"
include "pieceControl.lua"
include "aimPosTerraform.lua"

-- Signal definitions
local SIG_AIM = 2

local function RestoreAfterDelay()
	Sleep(5000)
	Turn(barrel, x_axis, 0, math.rad(10)) 
	Turn(turret, y_axis, 0, math.rad(10)) 
end

local stuns = {false, false, false}
local disarmed = false

function script.Create()
	local ud = UnitDefs[unitDefID]
	local midTable = ud
	if Spring.Utilities.IsCurrentVersionNewerThan(100, 0) then
		midTable = ud.model
	end
	
	local mid = {midTable.midx, midTable.midy, midTable.midz}
	local aim = {midTable.midx, midTable.midy + 22, midTable.midz}
    
	SetupAimPosTerraform(mid, aim, midTable.midy + 22, midTable.midy + 40, 15, 40)
	
	StartThread(SmokeUnit, {base})
end

local function StunThread ()
	Signal (SIG_AIM)
	SetSignalMask(SIG_AIM)
	disarmed = true

	StopTurn (turret, y_axis)
	StopTurn (barrel, x_axis)
end

local function UnstunThread ()
	disarmed = false
	SetSignalMask(SIG_AIM)
	RestoreAfterDelay()
end

function Stunned (stun_type)
	stuns[stun_type] = true
	StartThread (StunThread)
end
function Unstunned (stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread (UnstunThread)
	end
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	while disarmed do
		Sleep(34)
	end

	local slowMult = (1-(Spring.GetUnitRulesParam(unitID,"slowState") or 0))
	Turn(turret, y_axis, heading, math.rad(300)*slowMult)
	Turn(barrel, x_axis, -pitch, math.rad(200)*slowMult)
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel, x_axis)
	StartThread (RestoreAfterDelay)
	return true
end

function script.AimFromWeapon()
	return barrel
end

function script.QueryWeapon()
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	Hide(flare)
	if severity <= 0.25 then
		Explode(base, sfxNone)
		Explode(flare, sfxNone)
		Explode(turret, sfxNone)
		Explode(barrel, sfxNone)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxNone)
		Explode(flare, sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(turret, sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(barrel, sfxNone)
		return 1
	end
	Explode(base, sfxNone)
	Explode(flare, sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret, sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(barrel, sfxShatter)
	return 2
end