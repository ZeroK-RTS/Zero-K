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

local function Walk()
	for i = 1, 2 do
		Turn (thigh[i], y_axis, 0, math.rad(135))
		Turn (thigh[i], z_axis, 0, math.rad(135))
		Turn (foot[i], z_axis, 0, math.rad(135))
	end

	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	local side = 1
	local speedMult = 1
	while true do
		speedMult = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
		Turn (shin[side], x_axis, math.rad(85), speedMult*math.rad(260))
		Turn (thigh[side], x_axis, math.rad(-100), speedMult*math.rad(135))
		Turn (thigh[3-side], x_axis, math.rad(30), speedMult*math.rad(135))

		WaitForMove (hips, y_axis)
		Move (hips, y_axis, 3, speedMult*9)
		WaitForMove (hips, y_axis)
		Turn (shin[side], x_axis, math.rad(10), speedMult*math.rad(315))
		Move (hips, y_axis, 0, speedMult*9)

		side = 3 - side
	end
end

local function StopWalk()
	Signal(SIG_Walk)

	for i = 1, 2 do
		Turn (foot[i],  x_axis, 0, math.rad(400))
		Turn (thigh[i], x_axis, 0, math.rad(225))
		Turn (shin[i],  x_axis, 0, math.rad(225))

		Turn (thigh[i], y_axis, math.rad(60 - i*40), math.rad(135))
		Turn (thigh[i], z_axis, math.rad(6*i - 9), math.rad(135))
		Turn (foot[i], z_axis, math.rad(9 - 6*i), math.rad(135))
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Turn (chest, y_axis, math.rad(-20))
end

local function ReloadPenaltyAndAnimation()
	aimBlocked = true
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", RELOAD_PENALTY)
	GG.UpdateUnitAttributes(unitID)

	Sleep(200)
	Turn (gun, x_axis, 1, math.rad(120))
	Turn (turner, y_axis, 0, math.rad(200))
	
	Sleep(2300) -- 3.5 second reload so no point checking earlier.
	while true do
		local state = Spring.GetUnitWeaponState(unitID, 1, "reloadState")
		local gameFrame = Spring.GetGameFrame()
		if state - 32 < gameFrame then
			aimBlocked = false
			
			Sleep(500)
			Turn (gun, x_axis, 0, math.rad(100))
			Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
			GG.UpdateUnitAttributes(unitID)
			return
		end
		Sleep(340)
	end
end

function OnLoadGame()
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function script.AimFromWeapon(num)
	return gunemit
end

function script.QueryWeapon(num)
	return gunemit
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_Aim)
	Sleep (2000)
	Turn (turner, y_axis, 0, math.rad(40))
	Turn (gun, x_axis, math.rad(20), math.rad(40))
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	if aimBlocked then
		return false
	end
	
	Turn (hips, x_axis, 0)
	Turn (chest, x_axis, 0)
	Turn (gun, x_axis, -pitch, math.rad(100))
	Turn (turner, y_axis, heading + math.rad(5), math.rad(200))

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
			Explode (explodables[i], sfxFall + sfxSmoke + sfxFire)
		end
	end

	if (severity < 0.5) then
		return 1
	else
		Explode (chest, sfxShatter)
		Explode (gun, sfxShatter)
		return 2
	end
end
