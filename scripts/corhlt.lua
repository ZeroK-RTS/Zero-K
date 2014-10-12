include "constants.lua"
include "pieceControl.lua"
----------------------------------------------------------------------------------------------
-- Model Pieces

local basebottom, basemid, basetop, holder, housing, spindle, aim = piece('basebottom', 'basemid', 'basetop', 'holder', 'housing', 'spindle', 'aim')
local flares = {piece('flare1', 'flare2', 'flare3')}

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
	Turn(housing, x_axis, 0, HOUSING_TURN_SPEED )   
end

----------------------------------------------------------------------------------------------
-- Script Functions


local spGetUnitRulesParam = Spring.GetUnitRulesParam

function script.HitByWeapon()
	if spGetUnitRulesParam(unitID,"disarmed") == 1 then
		StopTurn (basetop, y_axis)
		StopTurn (basemid, y_axis)
		StopTurn (housing, x_axis)
	end
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

----------------------------------------------------------------------------------------------
-- Weapon Animations

function script.QueryWeapon(num) return flares[index] end

function script.AimFromWeapon(num) return holder end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	while firing or spGetUnitRulesParam(unitID,"disarmed") == 1 do
		Sleep(10)
	end
	
	local slowMult = (1-(spGetUnitRulesParam(unitID,"slowState") or 0))
	
	Turn(basetop, y_axis, 2  * heading, BASETOP_TURN_SPEED*slowMult )
	Turn(basemid, y_axis, -1 * heading, BASEMID_TURN_SPEED*slowMult )
	Turn(housing, x_axis, -pitch, HOUSING_TURN_SPEED*slowMult )
	WaitForTurn(basetop, y_axis)
	WaitForTurn(basemid, y_axis)
	WaitForTurn(housing, x_axis)

	return (spGetUnitRulesParam(unitID,"disarmed") ~= 1)
end

function script.FireWeapon(num)
	firing = true
	EmitSfx(flares[index], UNIT_SFX2)
	Sleep(800) -- fixme: read beamtime from WeaponDefs instead of hardcoded

	local slowMult = (1-(spGetUnitRulesParam(unitID,"slowState") or 0))
	local rz = select(3, GetPieceRotation(spindle))
	Turn(spindle, z_axis, rz + rad(120),SPINDLE_TURN_SPEED*slowMult)
	-- WaitForTurn(spindle, z_axis)

	firing = false
	index = index - 1
	if index == 0 then index = 3 end
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
