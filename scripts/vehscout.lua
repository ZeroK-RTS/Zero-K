include "constants.lua"

local base, body, turret, gun, barrel, bwheel, fwheel, firepoint = piece('base', 'body', 'turret', 'gun', 'barrel', 'bwheel', 'fwheel', 'firepoint')

-- tweakables
local AIM_SPEED = math.rad(200)

local LEAN_SPEED = math.rad(100)
local LEAN_MAX = math.rad(50)
local LEAN_UPDATE_RATE = 2 -- frames

-- derivatives
local WHEEL_SPIN_SPEED, WHEEL_SPIN_ACCEL, WHEEL_SPIN_DECEL, LEAN_PER_HEADING_UNIT, SLEEP_TIME
do
	local ud = UnitDefs[unitDefID]
	local speedInFrames = ud.speed / Game.gameSpeed
	local WHEEL_DIAMETER = 12.4 -- measured

	WHEEL_SPIN_SPEED = ud.speed / (WHEEL_DIAMETER * math.pi)
	WHEEL_SPIN_ACCEL = WHEEL_SPIN_SPEED * ud.maxAcc / speedInFrames
	WHEEL_SPIN_DECEL = WHEEL_SPIN_SPEED * ud.maxDec / speedInFrames
	LEAN_PER_HEADING_UNIT = LEAN_MAX / (ud.turnRate * LEAN_UPDATE_RATE)
	SLEEP_TIME = (1000 * LEAN_UPDATE_RATE) / Game.gameSpeed
end


local SIG_MOVE = 1
local SIG_AIM = 2

local spGetUnitHeading = Spring.GetUnitHeading
function Lean()
	SetSignalMask (SIG_MOVE)
	local lastHeading = spGetUnitHeading (unitID)
	while true do
		local currHeading = spGetUnitHeading (unitID)

		local diffHeading = lastHeading - currHeading
		if diffHeading >= 32768 then diffHeading = diffHeading - 65536 end
		if diffHeading < -32768 then diffHeading = diffHeading + 65536 end

		lastHeading = currHeading
		local leanAngle = diffHeading * LEAN_PER_HEADING_UNIT

		Turn (body, z_axis, leanAngle, LEAN_SPEED)
		Sleep (SLEEP_TIME)
	end
end

function script.StartMoving()
	Signal (SIG_MOVE)

	Spin (fwheel, x_axis, WHEEL_SPIN_SPEED, WHEEL_SPIN_ACCEL)
	Spin (bwheel, x_axis, WHEEL_SPIN_SPEED, WHEEL_SPIN_ACCEL)
	StartThread (Lean)
end

function script.StopMoving()
	Signal (SIG_MOVE)

	StopSpin (fwheel, x_axis, WHEEL_SPIN_DECEL)
	StopSpin (bwheel, x_axis, WHEEL_SPIN_DECEL)
	Turn (body, z_axis, 0, LEAN_SPEED)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, {bwheel, fwheel})
end

local function RestoreAfterDelay()
	Sleep (5000)
	Turn (turret, y_axis, 0, math.rad(10))
	Turn (gun,    x_axis, 0, math.rad(10))
end

function script.AimWeapon(num, heading, pitch)
	Signal (SIG_AIM)
	SetSignalMask (SIG_AIM)
	Turn (turret, y_axis, heading, AIM_SPEED)
	Turn (gun,    x_axis,  -pitch, AIM_SPEED)
	WaitForTurn (turret, y_axis)
	WaitForTurn (gun,    x_axis)
	StartThread (RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoint
end

local explodables = {barrel, bwheel, fwheel, turret, gun}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], SFX.FALL + (brutal and (SFX.SMOKE + SFX.FIRE) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, SFX.SHATTER)
		return 2
	end
end
