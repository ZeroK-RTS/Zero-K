include "constants.lua"

local hips = piece 'hips'
local chest = piece 'chest'
local gun = piece 'gun'
local muzzle = piece 'muzzle'
local exhaust = piece 'exhaust'
local turner = piece 'turner'
local aimpoint = piece 'aimpoint'
local gunemit = piece 'gunemit'

local thigh = {piece 'lthigh', piece 'rthigh'}
local shin = {piece 'lshin', piece 'rshin'}
local foot = {piece 'lfoot', piece 'rfoot'}
local knee = {piece 'lknee', piece 'rknee'}
local heel = {piece 'lheel', piece 'rheel'}

local smokePiece = {chest, exhaust, muzzle}
local RELOAD_PENALTY = tonumber(UnitDefs[unitDefID].customParams.reload_move_penalty)

local SIG_Aim = 1
local SIG_Walk = 2

-- future-proof running animation against balance tweaks
local runspeed = 25 * (UnitDefs[unitDefID].speed / 69)

local aimBlocked = false

local function GetSpeedMod()
	-- disallow zero (instant turn instead -> infinite loop)
	return math.max(0.05, GG.att_MoveChange[unitID] or 1)
end

local function SetSelfSpeedMod(speedmod)
	if RELOAD_PENALTY == 1 then
		return
	end
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", speedmod)
	GG.UpdateUnitAttributes(unitID)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	for i = 1, 2 do
		Turn (thigh[i], y_axis, 0, runspeed*0.15)
		Turn (thigh[i], z_axis, 0, runspeed*0.15)
	end

	local side = 1
	while true do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod

		Turn (shin[side], x_axis, math.rad(85), truespeed*0.28)
		Turn (heel[side], x_axis, math.rad(0), truespeed*0.25)
		Turn (foot[side], x_axis, math.rad(0), truespeed*0.25)
		Turn (thigh[side], x_axis, math.rad(-36), truespeed*0.16)
		Turn (thigh[3-side], x_axis, math.rad(36), truespeed*0.16)

		Move (hips, y_axis, 0, truespeed*0.8)
		WaitForMove (hips, y_axis)

		Turn (shin[side], x_axis, math.rad(10), truespeed*0.32)
		Turn (heel[side], x_axis, math.rad(20), truespeed*0.35)
		Turn (foot[side], x_axis, math.rad(-20), truespeed*0.25)
		Move (hips, y_axis, -1, truespeed*0.35)
		WaitForMove (hips, y_axis)

		Move (hips, y_axis, -2, truespeed*0.8)

		WaitForTurn (thigh[side], x_axis)

		side = 3 - side
	end
end

local function StopWalk()
	Signal(SIG_Walk)

	Move (hips, y_axis, 0, runspeed*0.5)

	for i = 1, 2 do
		Turn (thigh[i], x_axis, 0, runspeed*0.2)
		Turn (shin[i],  x_axis, 0, runspeed*0.2)
		Turn (heel[i], x_axis, 0, runspeed*0.2)
		Turn (foot[i], x_axis, 0, runspeed*0.2)

		Turn (thigh[i], y_axis, math.rad(60 - i*40), runspeed*0.1)
		Turn (thigh[i], z_axis, math.rad(6*i - 9), runspeed*0.1)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Turn (chest, y_axis, math.rad(-20))
	Turn (gun, x_axis, math.rad(20), math.rad(40))
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_Aim)
	Sleep (2000)
	Turn (turner, y_axis, 0, math.rad(40))
	Turn (gun, x_axis, math.rad(20), math.rad(40))
end

local function ReloadPenaltyAndAnimation()
	aimBlocked = true
	SetSelfSpeedMod(RELOAD_PENALTY)

	Sleep(200)
	Turn (gun, x_axis, 1, math.rad(120))
	Turn (turner, y_axis, 0, math.rad(200))

	Sleep(2300) -- 3.5 second reload so no point checking earlier.
	local checkRate = 400
	while true do
		local state = Spring.GetUnitWeaponState(unitID, 1, "reloadState")
		local gameFrame = Spring.GetGameFrame()
		if state - 40 < gameFrame then
			checkRate = 100
		end
		if state - 10 < gameFrame then
			aimBlocked = false
			Sleep(250)
			Turn (gun, x_axis, 0, math.rad(100))
			SetSelfSpeedMod(1)
			RestoreAfterDelay()
			return
		end
		Sleep(checkRate)
	end
end

function OnLoadGame()
	SetSelfSpeedMod(1)
end

function script.AimFromWeapon(num)
	return gunemit
end

function script.QueryWeapon(num)
	return gunemit
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)

	if aimBlocked then
		return false
	end

	Turn (hips, x_axis, 0)
	Turn (chest, x_axis, 0)
	Turn (gun, x_axis, -pitch, math.rad(130))
	Turn (turner, y_axis, heading + math.rad(5), math.rad(220))

	WaitForTurn (turner, y_axis)
	WaitForTurn (gun, x_axis)

	StartThread(RestoreAfterDelay)

	return true
end

function script.FireWeapon(num)
	EmitSfx (exhaust, 1024)
	StartThread(ReloadPenaltyAndAnimation)
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/450
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 180.1, 75 * distMult, false, false, true)
	end
	return false
end

local explodables = {hips, thigh[2], foot[1], shin[2], knee[1], heel[2]}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		end
	end

	if (severity < 0.5) then
		return 1
	else
		Explode (chest, SFX.SHATTER)
		Explode (gun, SFX.SHATTER)
		return 2
	end
end
