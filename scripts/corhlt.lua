include "constants.lua"
include "pieceControl.lua"

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
local SPINDLE_TURN_SPEED = rad(240)

local firing = false
local index = 1

----------------------------------------------------------------------------------------------
-- Signal Definitions

local SIG_AIM = 2
local SIG_RESTORE = 4

----------------------------------------------------------------------------------------------
-- Local Animation Functions

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(6000)
	Turn(housing, x_axis, 0, HOUSING_TURN_SPEED) 
end

----------------------------------------------------------------------------------------------
-- Script Functions

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

----------------------------------------------------------------------------------------------
-- Weapon Animations

function script.QueryWeapon(num) return flare end

function script.AimFromWeapon(num) return holder end

function Stunned ()
	StopTurn (basetop, y_axis)
	StopTurn (housing, x_axis)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	while firing or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) do
		Sleep (100)
	end
	
	local slowMult = (1-(Spring.GetUnitRulesParam(unitID,"slowState") or 0))
	Turn(basetop, y_axis, heading, BASETOP_TURN_SPEED*slowMult)
	Turn(housing, x_axis, -pitch, HOUSING_TURN_SPEED*slowMult)
	WaitForTurn(basetop, y_axis)
	WaitForTurn(housing, x_axis)

	return true
end

function script.FireWeapon(num)
	firing = true
	EmitSfx(flare, UNIT_SFX2)
	Sleep(800)
	local rz = select(3, GetPieceRotation(spindle))
	Turn(spindle, z_axis, rz + rad(120),SPINDLE_TURN_SPEED)
	firing = false
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
