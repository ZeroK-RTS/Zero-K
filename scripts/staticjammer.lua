include "constants.lua"

local base, cylinder, turret, jammersturret, jam1, jam2, deploy = piece ('base', 'cylinder', 'turret', 'jammersturret', 'jam1', 'jam2', 'deploy')
local smokePiece = {base}

local cloakOffsetRange = tonumber(UnitDefs[unitDefID].customParams.area_cloak_shift_range)
local currentX, currentY, currentZ = 0, 0, 0
local moveSpeed = 3
local UPDATE_RATE = 3
local lastAim = false
local currentlyFollowingCommandTag = false

local SIG_MOVE = 1

function script.Create()
	local _, _, _, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	currentX, currentY, currentZ = mx, my, mz
	if Spring.GetUnitRulesParam(unitID, "cloaker_pos_x") then
		currentX = Spring.GetUnitRulesParam(unitID, "cloaker_pos_x")
		currentY = Spring.GetUnitRulesParam(unitID, "cloaker_pos_y")
		currentZ = Spring.GetUnitRulesParam(unitID, "cloaker_pos_z")
	end
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate()
	Spin(jammersturret, y_axis, math.rad(120), math.rad(30))
	Move(deploy, y_axis, 25, 10)
	Turn(jam1, z_axis, 0.2, 0.1)
	Turn(jam2, z_axis, -0.2, 0.1)
	
	Spin(turret, y_axis, -0.5, 0.01)
	Spin(cylinder, y_axis, 1.2, 0.05)
end

function script.Deactivate()
	Move(deploy, y_axis, 0, 10)
	Turn(jam1, z_axis, 0, 0.1)
	Turn(jam2, z_axis, 0, 0.1)
	StopSpin(jammersturret, y_axis, math.rad(30))
	
	StopSpin(turret, y_axis, 0.01)
	StopSpin(cylinder, y_axis, 0.01)
end

local function FindPlacementPosition(tx, ty, tz)
	local _, _, _, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	
	local maxRange = cloakOffsetRange
	for i = 1, 5 do
		ty = Spring.GetGroundHeight(tx, tz) + 20
		local mag = Spring.Utilities.Vector.AbsVal(mx - tx, my - ty, mz - tz)
		if mag > maxRange then
			tx, ty, tz = mx + maxRange*(tx - mx)/mag, my + maxRange*(ty - my)/mag, mz + maxRange*(tz - mz)/mag
		else
			break
		end
	end
	return tx, ty, tz
end

local function MoveCloaker(tx, ty, tz, toRemoveCmdTag)
	SetSignalMask(SIG_MOVE)
	Signal(SIG_MOVE)
	
	while true do
		local mag = Spring.Utilities.Vector.AbsVal(currentX - tx, currentY - ty, currentZ - tz)
		if mag > moveSpeed then
			currentX = currentX + moveSpeed*(tx - currentX)/mag
			currentY = currentY + moveSpeed*(ty - currentY)/mag
			currentZ = currentZ + moveSpeed*(tz - currentZ)/mag
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_x", currentX)
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_y", currentY)
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_z", currentZ)
		else
			currentX, currentY, currentZ = tx, ty, tz
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_x", currentX)
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_y", currentY)
			Spring.SetUnitRulesParam(unitID, "cloaker_pos_z", currentZ)
			if (Spring.GetUnitStates(unitID) or {})["repeat"] then
				local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3 = Spring.GetUnitCurrentCommand(unitID)
				if cmdTag == toRemoveCmdTag then
					params = (cmdParam3 and {cmdParam1, cmdParam2, cmdParam3}) or {cmdParam1}
					Spring.GiveOrderToUnit(unitID, CMD.MANUALFIRE, params, CMD.OPT_SHIFT)
					Spring.GiveOrderToUnit(unitID, CMD.MANUALFIRE, params, CMD.OPT_SHIFT)
				end
			else
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, toRemoveCmdTag, 0)
			end
			currentlyFollowingCommandTag = false
			return
		end
		Sleep(33)
	end
end

local function AimCloaker()
	local frame = Spring.GetGameFrame()
	if lastAim and lastAim + UPDATE_RATE > frame then
		return
	end
	lastAim = frame
	
	local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3 = Spring.GetUnitCurrentCommand(unitID)
	if cmdTag == currentlyFollowingCommandTag then
		return
	end
	local tx, ty, tz
	if cmdID == CMD.MANUALFIRE then
		if cmdParam3 then
			tx, ty, tz = cmdParam1, cmdParam2, cmdParam3
			currentlyFollowingCommandTag = cmdTag
		elseif not cmdParam2 then
			targetID = cmdParam1
			tx, ty, tz = Spring.GetUnitPosition(targetID)
			currentlyFollowingCommandTag = false -- Units can move
		end
	end
	if not tx then
		return
	end
	
	tx, ty, tz = FindPlacementPosition(tx, ty, tz)
	StartThread(MoveCloaker, tx, ty, tz, cmdTag)
end

function script.QueryWeapon(num)
	return turret
end

function script.AimWeapon(num, heading, pitch)
	AimCloaker()
	return true
end

function script.BlockShot(num, targetID)
	AimCloaker()
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(cylinder, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		Explode(cylinder, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(cylinder, SFX.FALL + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		return 2
	end
	Explode(base, SFX.SHATTER)
	Explode(turret, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(cylinder, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	return 2
end
