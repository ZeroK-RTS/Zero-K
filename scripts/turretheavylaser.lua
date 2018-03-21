include "constants.lua"
include "pieceControl.lua"
include "aimPosTerraform.lua"

----------------------------------------------------------------------------------------------
-- Model Pieces

local basebottom, basemid, basetop, holder, housing, spindle, aim = piece('basebottom', 'basemid', 'basetop', 'holder', 'housing', 'spindle', 'aim')
local flare = piece('flare1')

local smokePiece = {basebottom, basemid, basetop}

----------------------------------------------------------------------------------------------
-- Local Constants

local BASETOP_TURN_SPEED = rad(200)
local BASEMID_TURN_SPEED = rad(230)
local HOUSING_TURN_SPEED = rad(200)
local SPINDLE_TURN_SPEED = rad(120 / 0.8)

local firing = false
local index = 1

local stuns = {false, false, false}
local disarmed = false

----------------------------------------------------------------------------------------------
-- Signal Definitions

local SIG_AIM = 2

----------------------------------------------------------------------------------------------
-- Local Animation Functions

local function RestoreAfterDelay()
	Sleep(5000)
	Turn(housing, x_axis, 0, math.rad(10)) 
	Turn(basetop, y_axis, 0, math.rad(10)) 
end

----------------------------------------------------------------------------------------------
-- Script Functions

function script.Create()
	local ud = UnitDefs[unitDefID]
	local midTable = ud
	if Spring.Utilities.IsCurrentVersionNewerThan(100, 0) then
		midTable = ud.model
	end
	
	local mid = {midTable.midx, midTable.midy, midTable.midz}
	local aim = {midTable.midx, midTable.midy + 15, midTable.midz}

	SetupAimPosTerraform(mid, aim, midTable.midy + 15, midTable.midy + 60, 15, 48)
	
	StartThread(SmokeUnit, smokePiece)
end

----------------------------------------------------------------------------------------------
-- Weapon Animations

function script.QueryWeapon(num) return flare end
function script.AimFromWeapon(num) return holder end

local function StunThread ()
	Signal (SIG_AIM)
	SetSignalMask(SIG_AIM)
	disarmed = true

	StopTurn (basetop, y_axis)
	StopTurn (housing, x_axis)
end

local function UnstunThread()
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

	while firing or disarmed do
		Sleep (34)
	end

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn(basetop, y_axis, heading, BASETOP_TURN_SPEED*slowMult)
	Turn(housing, x_axis, -pitch, HOUSING_TURN_SPEED*slowMult)
	WaitForTurn(basetop, y_axis)
	WaitForTurn(housing, x_axis)
	StartThread (RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	firing = true
	EmitSfx(flare, UNIT_SFX2)
	local rz = select(3, GetPieceRotation(spindle))
	Turn(spindle, z_axis, rz + rad(120),SPINDLE_TURN_SPEED)
	Sleep(800)
	firing = false
end

function script.BlockShot(num, targetID)
	-- Block for less than full damage and time because the target may dodge.
	return (targetID and (GG.DontFireRadar_CheckBlock(unitID, targetID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 680.1, 18))) or false
end


----------------------------------------------------------------------------------------------
-- Death Animation

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .50 then
		Explode(basebottom, sfxNone)
		Explode(housing, sfxNone)
		Explode(holder, sfxNone)
		Explode(spindle, sfxNone)
		Explode(basetop, sfxNone)
		Explode(basemid, sfxNone)
		return 1
	elseif severity <= .99 then
		Explode(basebottom, sfxNone)
		Explode(housing, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(holder, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(spindle, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(basetop, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(basemid, sfxShatter)
		return 2
	else
		Explode(basebottom, sfxNone)
		Explode(housing, sfxShatter)
		Explode(holder, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(spindle, sfxFall+ sfxSmoke+ sfxFire + sfxExplode)
		Explode(basetop, sfxShatter)
		Explode(basemid, sfxShatter)
		return 2
	end
end
