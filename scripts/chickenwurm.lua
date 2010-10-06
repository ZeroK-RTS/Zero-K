include "constants.lua"

--pieces
local mbody, fbody, bbody, head, tail = piece("mbody","fbody","bbody","head","tail")
local rsack, rblade, lsack, lblade, fire = piece("rsack","rblade","lsack","lblade","fire")

local smokePiece = {}

local turretIndex = {
}

--constants
local digSpeed = 1
local digRotate = 0.6

--variables
local isMoving = false

--signals
local SIG_Aim = 1
local SIG_Aim2 = 2
local SIG_Move = 16

--cob values


----------------------------------------------------------
local function RestoreAfterDelay()
	Sleep(1000)
end

local function Dig()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	if (isMoving) then
		Turn(head, y_axis, -digRotate, digSpeed/2)
		Turn(fbody, y_axis, digRotate, digSpeed)
		Turn(mbody, y_axis, digRotate, digSpeed)
		Turn(bbody, y_axis, -digRotate, digSpeed)
		Turn(tail, y_axis, -digRotate, digSpeed)
		EmitSfx(head, 1026)
		WaitForTurn(tail, y_axis)
	else return end
	Sleep(50)
	if (isMoving) then
		Turn(head, y_axis, 0, digSpeed/2)
		Turn(fbody, y_axis, -digRotate, digSpeed)
		Turn(mbody, y_axis, digRotate, digSpeed)
		Turn(bbody, y_axis, digRotate, digSpeed)
		Turn(tail, y_axis, -digRotate, digSpeed)
		EmitSfx(fbody, 1026)
		WaitForTurn(fbody, y_axis)
	else return end
	Sleep(50)
	if (isMoving) then
		Turn(head, y_axis, digRotate, digSpeed/2)
		Turn(fbody, y_axis, -digRotate, digSpeed)
		Turn(mbody, y_axis, -digRotate, digSpeed)
		Turn(bbody, y_axis, digRotate, digSpeed)
		Turn(tail, y_axis, digRotate, digSpeed)
		EmitSfx(fbody, 1026)
		WaitForTurn(mbody, y_axis)
	else return end
	Sleep(50)
	if (isMoving) then	
		Turn(head, y_axis, 0, digSpeed/2)
		Turn(fbody, y_axis, digRotate, digSpeed)
		Turn(mbody, y_axis, -digRotate, digSpeed)
		Turn(bbody, y_axis, -digRotate, digSpeed)
		Turn(tail, y_axis, digRotate, digSpeed)
		WaitForTurn(bbody, y_axis)
		EmitSfx(fbody, 1026)
	else return end
	Sleep(50)
	StartThread(Dig)
end

local function StopDig()
end

function script.StartMoving()
	isMoving = true
	StartThread(Dig)
end

function script.StopMoving()
	isMoving = false
	StartThread(StopDig)
end

function script.Create()
	EmitSfx(mbody, 1026)
	EmitSfx(head, 1026)
	EmitSfx(tail, 1026)
	Spring.SetUnitCloak(unitID, 2)	--free cloak
end

function script.AimFromWeapon(weaponNum) return fire end

function script.AimWeapon(weaponNum, heading, pitch) return true end

function script.QueryWeapon(weaponNum) return fire end

function script.FireWeapon(weaponNum) return true end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(mbody, 1025)
end

function script.HitByWeaponId()
	EmitSfx(body, 1024)
end
