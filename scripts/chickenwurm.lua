include "constants.lua"

--pieces
local mbody, fbody, bbody, head, tail = piece("mbody","fbody","bbody","head","tail")
local rsack, rblade, lsack, lblade, fire = piece("rsack","rblade","lsack","lblade","fire")

local smokePiece = {}

--constants
local digSpeed = 2
local digRotate = 0.6

--variables
local isMoving = false
local underwater = false
local uwheight = -23

--weapon variables
local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30

--signals
local SIG_Aim = 1
local SIG_Move = 16

--cob values

----------------------------------------------------------
local function RestoreAfterDelay()
	Sleep(1000)
end

local function WeaponUpdate()
	while true do
		local height = select(2, Spring.GetUnitPosition(unitID))
		if height <= uwheight then
			underwater = true
			Spring.SetUnitCloak(unitID, 0)
		elseif height > uwheight and underwater then 
			underwater = false
			Spring.SetUnitCloak(unitID, 2) -- free cloak restored.
		end
		Sleep(200)
	end
end

local function Dig()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		if (isMoving) then
			Turn(head, y_axis, -digRotate, digSpeed/2)
			Turn(fbody, y_axis, digRotate, digSpeed)
			Turn(mbody, y_axis, digRotate, digSpeed)
			Turn(bbody, y_axis, -digRotate, digSpeed)
			Turn(tail, y_axis, -digRotate, digSpeed)
			EmitSfx(head, 1026)
			WaitForTurn(tail, y_axis)
		else return end
		Sleep(33)
		if (isMoving) then
			Turn(head, y_axis, 0, digSpeed/2)
			Turn(fbody, y_axis, -digRotate, digSpeed)
			Turn(mbody, y_axis, digRotate, digSpeed)
			Turn(bbody, y_axis, digRotate, digSpeed)
			Turn(tail, y_axis, -digRotate, digSpeed)
			EmitSfx(fbody, 1026)
			WaitForTurn(fbody, y_axis)
		else return end
		Sleep(33)
		if (isMoving) then
			Turn(head, y_axis, digRotate, digSpeed/2)
			Turn(fbody, y_axis, -digRotate, digSpeed)
			Turn(mbody, y_axis, -digRotate, digSpeed)
			Turn(bbody, y_axis, digRotate, digSpeed)
			Turn(tail, y_axis, digRotate, digSpeed)
			EmitSfx(fbody, 1026)
			WaitForTurn(mbody, y_axis)
		else return end
		Sleep(33)
		if (isMoving) then	
			Turn(head, y_axis, 0, digSpeed/2)
			Turn(fbody, y_axis, digRotate, digSpeed)
			Turn(mbody, y_axis, -digRotate, digSpeed)
			Turn(bbody, y_axis, -digRotate, digSpeed)
			Turn(tail, y_axis, digRotate, digSpeed)
			WaitForTurn(bbody, y_axis)
			EmitSfx(fbody, 1026)
		else return end
		Sleep(33)
	end
end

local function StopDig()
	if not underwater then
		Spring.SetUnitCloak(unitID, 2)	--free cloak
	end
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
	StartThread(WeaponUpdate)
	Spring.SetUnitCloak(unitID, 2)	--free cloak
end

function script.AimFromWeapon(weaponNum) return fire end

function script.AimWeapon(weaponNum, heading, pitch)
	if weaponNum == 2 and not underwater then
		return false
	elseif weaponNum == 3 and underwater then
		return false
	else
		return true
	end
end

function script.QueryWeapon(weaponNum) return fire end

function script.FireWeapon(weaponNum)
	local frame = Spring.GetGameFrame()
	local reloadSpeedMult = Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
	if reloadSpeedMult <= 0 then
		-- Safety for div0. In theory a unit with reloadSpeedMult = 0 cannot fire because it never reloads.
		reloadSpeedMult = 1
	end
	local reloadTimeMult = 1/reloadSpeedMult
	if weaponNum == 1 then
		Spring.SetUnitWeaponState(unitID, 2, "reloadFrame", frame + reloadTime*reloadTimeMult) -- disallow UW stuff/force reload sync w/ napalm blob.
		Spring.SetUnitWeaponState(unitID, 3, "reloadFrame", frame + reloadTime*reloadTimeMult) -- above water -> UW synced
	elseif weaponNum == 2 then
		Spring.SetUnitWeaponState(unitID, 1, "reloadFrame", frame + reloadTime*reloadTimeMult)
		Spring.SetUnitWeaponState(unitID, 3, "reloadFrame", frame + reloadTime*reloadTimeMult)
	elseif weaponNum == 3 then
		Spring.SetUnitWeaponState(unitID, 2, "reloadFrame", frame + reloadTime*reloadTimeMult)
		Spring.SetUnitWeaponState(unitID, 1, "reloadFrame", frame + reloadTime*reloadTimeMult)
	end
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(mbody, 1025)
end

function script.HitByWeapon(x, z, weaponID, damage)
	EmitSfx(mbody, 1024)
end
