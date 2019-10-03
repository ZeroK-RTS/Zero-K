include "constants.lua"
include "pieceControl.lua"
include "aimPosTerraform.lua"
----------------------------------------------------------------------------------------------
-- Model Pieces

local basebottom, basemid, basetop, holder, housing, spindle, aim = piece('basebottom', 'basemid', 'basetop', 'holder', 'housing', 'spindle', 'aim')
local flares = {piece('flare1', 'flare2', 'flare3')}

local smokePiece = {basebottom, basemid, basetop}

----------------------------------------------------------------------------------------------
-- Local Constants

local BASETOP_TURN_SPEED = math.rad(200)
local BASEMID_TURN_SPEED = math.rad(230)
local HOUSING_TURN_SPEED = math.rad(200)
local SPINDLE_TURN_SPEED = math.rad(120 / 0.8)

local firing = false
local index = 2

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
	local midTable = ud.model
	
	local midpos = {midTable.midx, midTable.midy,      midTable.midz}
	local aimpos = {midTable.midx, midTable.midy + 15, midTable.midz}

	GG.SetupAimPosTerraform(unitID, unitDefID, midpos, aimpos, midTable.midy + 15, midTable.midy + 60, 15, 48)
	
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

----------------------------------------------------------------------------------------------
-- Weapon Animations

function script.QueryWeapon(num) return flares[index] end
function script.AimFromWeapon(num) return holder end

local function StunThread ()
	Signal (SIG_AIM)
	SetSignalMask(SIG_AIM)
	disarmed = true

	GG.PieceControl.StopTurn (basetop, y_axis)
	GG.PieceControl.StopTurn (housing, x_axis)
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
	index = index - 1
	if index == 0 then
		index = #flares
	end
	firing = true
	EmitSfx(flares[index], GG.Script.UNIT_SFX2)
	Sleep(800)
	local rz = select(3, Spring.UnitScript.GetPieceRotation(spindle))
	Turn(spindle, z_axis, rz + math.rad(120),SPINDLE_TURN_SPEED)
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
		Explode(basebottom, SFX.NONE)
		Explode(housing, SFX.NONE)
		Explode(holder, SFX.NONE)
		Explode(spindle, SFX.NONE)
		Explode(basetop, SFX.NONE)
		Explode(basemid, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(basebottom, SFX.NONE)
		Explode(housing, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(holder, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(spindle, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(basetop, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(basemid, SFX.SHATTER)
		return 2
	else
		Explode(basebottom, SFX.NONE)
		Explode(housing, SFX.SHATTER)
		Explode(holder, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(spindle, SFX.FALL+ SFX.SMOKE+ SFX.FIRE + SFX.EXPLODE)
		Explode(basetop, SFX.SHATTER)
		Explode(basemid, SFX.SHATTER)
		return 2
	end
end
