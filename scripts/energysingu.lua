
-- by Chris Mackey
include "constants.lua"

--pieces
local base = piece "base"
local toroid = piece "toroid"
local energyball = piece "energyball"
local nexus = piece "nexus"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local arm3 = piece "arm3"

local smokePiece = { piece "base", piece "arm1", piece "arm2", piece "arm3" }

local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitHealth = Spring.GetUnitHealth
local sin = math.sin
local max = math.max
local min = math.min
local abs = math.abs
local rand = math.random

local SPRING = 0.18    -- Pull toward center
local DAMPING_BASE = 0.4    -- Removes oscillation
local DAMPING_MIN = 0.03
local RATTLE_THRESHOLD = 26  -- elmo range threshold
local ballSize = 0
local ImpulseUpdate = 0
local pendingImpulseX, pendingImpulseY, pendingImpulseZ = 0, 0, 0
local velX, velY, velZ = 0, 0, 0
local ax, ay, az = 0, 0, 0
local offsetX, offsetY, offsetZ = 0, 0, 0
local is_stunned = true

local function clamp(val, c)
	-- c expected to be positive
	if val > c then
		val = c
	elseif val < -c then
		val = -c
	end
	return val
end

local function SizeControl()
	local mag = rand() + 1
	local period = rand()*20 + 15
	local t = 0

	while true do
		-- damage rattle
		local deltadistance = (offsetX^2 + offsetY^2 + offsetZ^2)^0.5 -- ignore fake Y
		if ImpulseUpdate > 0 then
			-- cap velocity, 2*distance*acceleration
			-- just ignore the dampening effect the illusion holds
			local maxv = 2*(RATTLE_THRESHOLD-deltadistance)*SPRING
			velX = clamp(velX + pendingImpulseX, maxv)
			velY = clamp(velY + pendingImpulseY, maxv)
			velZ = clamp(velZ + pendingImpulseZ, maxv)
			ImpulseUpdate, pendingImpulseX, pendingImpulseY, pendingImpulseZ = 0, 0, 0, 0
		end
		if abs(velX) + abs(velY) + abs(velZ) > 0.1 or abs(offsetX) + abs(offsetY) + abs(offsetZ) > 0.1 then
			local health, maxhealth = spGetUnitHealth(unitID)
			local rel_hp = health / maxhealth
			local DAMPING = max((1.22*rel_hp - 0.22) * DAMPING_BASE, DAMPING_MIN)
			ax = -SPRING * offsetX - DAMPING * velX
			ay = -SPRING * offsetY - DAMPING * velY
			az = -SPRING * offsetZ - DAMPING * velZ

			velX = velX + ax
			velY = velY + ay
			velZ = velZ + az

			offsetX = offsetX + velX
			offsetY = offsetY + velY
			offsetZ = offsetZ + velZ

			MultiMove(	energyball, x_axis, offsetX, ax*30,
						energyball, y_axis, offsetY, ay*30,
						energyball, z_axis, offsetZ, az*30)
		end

		-- shrink ball to fit arms. Considering ballSwellFactor function and size of unit.
		ballSize = min(ballSize, 1/14*(deltadistance - 2*RATTLE_THRESHOLD)^2)

		-- grow ball
		if is_stunned then
			if ballSize > 3 then
				ballSize = ballSize - 3
			else
				ballSize = 1
				Hide(energyball)
			end
		else
			if ballSize == 1 then
				Show(energyball)
			end
			if ballSize < 100 then
				ballSize = ballSize + 1
			end
		end

		-- periodic swell
		local ballSwellFactor = 1.13^(sin(t/period)*mag) * (ballSize^2 / 11000)
		spSetUnitRulesParam(unitID, "ballSwell", 1.15*ballSwellFactor - 0.1, INLOS)
		Scale(energyball, ballSwellFactor)

		t = t + 1
		Sleep(33)
	end
end

local function StartAnim()
	Spin(toroid, y_axis, 1, 0.25 / Game.gameSpeed)
	Spin(arm1, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(arm2, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(arm3, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(nexus, y_axis, -2, 0.5 / Game.gameSpeed)
end

local function StopAnim()
	StopSpin(toroid, y_axis, 1 / Game.gameSpeed)
	StopSpin(arm1, y_axis, 2 / Game.gameSpeed)
	StopSpin(arm2, y_axis, 2 / Game.gameSpeed)
	StopSpin(arm3, y_axis, 2 / Game.gameSpeed)
	StopSpin(nexus, y_axis, 2 / Game.gameSpeed)
end

local function Anim()
	local spGetUnitIsStunned = Spring.GetUnitIsStunned
	local spGetUnitRulesParam = Spring.GetUnitRulesParam
	local was_stunned = true
	while true do
		is_stunned = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
		if is_stunned ~= was_stunned then
			was_stunned = is_stunned
			if is_stunned then
				StopAnim()
			else
				StartAnim()
			end
		end
		Sleep(1000)
	end
end

function script.HitByWeapon(hitDirx, hitDirz, weaponDefId, inoutDamage)
	ImpulseUpdate = inoutDamage
    local impulse = inoutDamage^0.6  - 1
    pendingImpulseX = pendingImpulseX + hitDirx * impulse
	pendingImpulseY = pendingImpulseY + (1.4* rand() - 0.7) * impulse -- fake y impusle
    pendingImpulseZ = pendingImpulseZ - hitDirz * impulse
    return inoutDamage
end

function script.Create()
	Hide(energyball)
	spSetUnitRulesParam(unitID, "ballSwell", 0, INLOS) -- halo size

	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(Anim)
	StartThread(SizeControl)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.EXPLODE)
	Explode(toroid, SFX.EXPLODE)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
