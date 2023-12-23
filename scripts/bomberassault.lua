local bomb = piece('bomb');
local bombEmit = piece('bombEmit');
local exhaustLeft = piece('exhaustLeft');
local exhaustRight = piece('exhaustRight');
local exhaustTop = piece('exhaustTop');
local hull = piece('hull');
local petalLeft = piece('petalLeft');
local petalRear = piece('petalRear');
local petalRight = piece('petalRight');
local turbineLeft = piece('turbineLeft');
local turbineRight = piece('turbineRight');
local turbineTop = piece('turbineTop');
local wingLeftFront = piece('wingLeftFront');
local wingLeftRear = piece('wingLeftRear');
local wingRightFront = piece('wingRightFront');
local wingRightRear = piece('wingRightRear');
local wingTopFront = piece('wingTopFront');
local wingTopRear = piece('wingTopRear');

local smokePiece = {exhaustTop, exhaustRight, exhaustLeft}

local CMD_AIR_MANUALFIRE = Spring.Utilities.CMD.AIR_MANUALFIRE
local manualfireWeapon = tonumber(UnitDefs[unitDefID].customParams.air_manual_fire_weapon)

include "bombers.lua"
include "constants.lua"

local manualTarget_p1 = false
local manualTarget_p2 = false
local manualTarget_p3 = false

function ReammoComplete()
	Show(bomb)
end

local function AirManualFireThread()
	local unitFollow = 0
	while true do
		local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
		if cmdID == CMD_AIR_MANUALFIRE then
			if cp_3 then
				Spring.SetUnitTarget(unitID, cp_1, cp_2, cp_3, false, false, manualfireWeapon)
				manualTarget_p1 = cp_1
				manualTarget_p2 = cp_2
				manualTarget_p3 = cp_3
			elseif unitFollow then
				if cp_1 and Spring.ValidUnitID(cp_1) then
					local tx, ty, tz = CallAsTeam(Spring.GetUnitTeam(unitID),
						function ()
							local _,_,_, _,_,_, tx, ty, tz = Spring.GetUnitPosition(cp_1, true, true)
							if tx then
								ty = math.max(0, Spring.GetGroundHeight(tx, tz))
								return tx, ty, tz
							end
						end)
					if tx then
						Spring.SetUnitTarget(unitID, tx, ty, tz, false, false, manualfireWeapon)
						manualTarget_p1 = tx
						manualTarget_p2 = ty
						manualTarget_p3 = tz
					end
				end
			end
		else
			manualTarget_p1 = false
			manualTarget_p2 = false
			manualTarget_p3 = false
		end
		--else
		--	
		--end
		unitFollow = (unitFollow + 1)%3
		Sleep(33)
	end
end

local function IsManualFireTargetValid()
	local targetType, isUser, targetParams = Spring.GetUnitWeaponTarget(unitID, manualfireWeapon)
	if targetType == 2 then
		if targetParams and targetParams[1] == manualTarget_p1 and
				targetParams[2] == manualTarget_p2 and targetParams[3] == manualTarget_p3 then
			return true
		end
	end
	return false
end

--function script.Deactivate()
--	StopSpin(turbineTop, z_axis, 0.5);
--	StopSpin(turbineLeft, z_axis, 0.5);
--	StopSpin(turbineRight, z_axis, 0.5);
--end

--function script.Activate()
--	Spin(turbineTop, z_axis, 8,2);
--	Spin(turbineLeft, z_axis, 8,2);
--	Spin(turbineRight, z_axis, -8,2);
--end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(AirManualFireThread)
	Move(bomb, y_axis, -8)
	Move(bombEmit, y_axis, -6)
end

function script.QueryWeapon(num)
	return bombEmit
end

function script.AimFromWeapon(num)
	return bombEmit
end

function script.AimWeapon(num, heading, pitch)
	if RearmBlockShot() then
		return false
	end
	if num == manualfireWeapon then
		return IsManualFireTargetValid()
	end
	return true
end

function script.FireWeapon(num)
	Hide(bomb)
	Sleep(66)
	Reload()
end

function script.BlockShot(num, targetID)
	if num == 1 or (num == manualfireWeapon and not IsManualFireTargetValid()) then
		return true
	end
	return (GetUnitValue(COB.CRASHING) == 1) or RearmBlockShot()
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(turbineLeft, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(turbineLeft, SFX.FIRE)
		Explode(wingLeftFront, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingLeftRear, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	elseif severity <= .50 then
		Explode(turbineLeft, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(turbineLeft, SFX.EXPLODE)
		Explode(wingLeftFront, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingLeftRear, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(hull, SFX.SHATTER)
		return 1
	elseif severity <= 0.75 then
		Explode(turbineLeft, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(turbineLeft, SFX.EXPLODE)
		Explode(wingLeftFront, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingLeftRear, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(hull, SFX.SHATTER)
		return 1
	else
		Explode(turbineLeft, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(turbineLeft, SFX.EXPLODE)
		Explode(wingLeftFront, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(wingLeftRear, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(turbineRight, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(turbineRight, SFX.EXPLODE)
		Explode(wingRightFront, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(wingRightRear, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(turbineTop, SFX.EXPLODE)
		Explode(wingTopFront, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		Explode(wingTopRear, SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
		
		Explode(hull, SFX.SHATTER)
		return 2
	end
end
