include "constants.lua"
include "strideremp_rig.lua"

-- Ungoliant: a deployable EMP strider. Detonate (D) or an attack order commits it to a
-- cycle that cannot be cancelled: lock in place, rear up the opisthosoma, unfold the
-- emitter, charge, pulse (stunning itself too), fold back once the stun wears off.
-- Stun pauses the cycle and slow stretches it. Death ends it.
--
-- One animation driver runs every frame: it samples the deploy choreography (keyed
-- in empcore.blend, see strideremp_rig.lua) and solves inverse kinematics for every
-- leg, so the feet stay planted while the body rises and pitches, and step along a
-- tripod gait while walking. Feet also follow the terrain under them.

local RIG = STRIDEREMP_RIG
local TR = RIG.tracks
local KEY_STEP = RIG.keyStep
local LEN = RIG.len

local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVectors = Spring.GetUnitVectors
local spGetGroundHeight = Spring.GetGroundHeight
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetGameFrame = Spring.GetGameFrame

local sin, cos, atan2, sqrt, acos = math.sin, math.cos, math.atan2, math.sqrt, math.acos
local min, max, abs, pi, floor = math.min, math.max, math.abs, math.pi, math.floor

local LOS_ACCESS = {inlos = true}

--------------------------------------------------------------------------------
-- pieces

local base, prosoma = piece("base", "prosoma")
local pedicel, yoke, opisthosoma = piece("pedicel", "pedicel_yoke", "opisthosoma")
local braceCoxa, braceFemur, braceTibia = piece("brace_coxa", "brace_femur", "brace_tibia")
local endcapInner, endcapMid, endcapTip = piece("endcap_inner", "endcap_mid", "endcap_tip")
local emitCore = piece("emit_core")

local petals = {}
for i = 1, 8 do
	local p = "petal" .. i .. "_"
	petals[i] = {
		link1 = piece(p .. "link1"), link2 = piece(p .. "link2"), shell = piece(p .. "shell"),
		knuckle = piece(p .. "knuckle"), prong = piece(p .. "prong"), spark = piece("spark" .. i),
	}
end

local LEG_NAMES = {"fl", "ml", "bl", "fr", "mr", "br"}
local GAIT_GROUP = {fl = 0, mr = 0, bl = 0, fr = 0.5, ml = 0.5, br = 0.5} -- tripods
local legs = {}
for i = 1, #LEG_NAMES do
	local k = LEG_NAMES[i]
	local p = "leg_" .. k .. "_"
	legs[i] = {
		name = k, rig = RIG.legs[k], group = GAIT_GROUP[k],
		coxa = piece(p .. "coxa"), femur = piece(p .. "femur"), tibia = piece(p .. "tibia"),
		tarsus = piece(p .. "tarsus"), foot = piece("foot_" .. k),
		groundOffset = 0, wasSwinging = false,
	}
end

local smokePiece = {prosoma, opisthosoma}

--------------------------------------------------------------------------------
-- tuning

local unitDef = UnitDefs[unitDefID]
local CHARGE_FRAMES = (tonumber(unitDef.customParams.emp_charge_time) or 6) * 30
local COOLDOWN_FRAMES = (tonumber(unitDef.customParams.emp_cooldown) or 30) * 30
local DEPLOY_SECONDS = 4
local DEPLOY_END = RIG.deployLength
local DEPLOY_RATE = DEPLOY_END / (DEPLOY_SECONDS * 30)

local STRIDE = 26           -- body travel per gait cycle
local LIFT = 7              -- foot lift at mid-swing
local GROUND_REACH = 20     -- how far a foot may reach up or down to meet the terrain
local SFX_SPARK, SFX_CHARGE, SFX_FOOTSTEP, SFX_GROUND_PULSE = 1024, 1025, 1026, 1027
local HUM_SOUND = "sounds/weapon/constant_electric.wav"
local CRACKLE_SOUND = "sounds/weapon/electrical_crackle.wav"

-- Spring's Turn/Move axis senses relative to the right-handed model axes the rig is
-- built in (x left, y up, z forward).
local TURN_SIGN = {1, 1, 1}
local MOVE_SIGN = {1, 1, 1}

local function SetTurn(p, axis, a)
	Turn(p, axis, TURN_SIGN[axis] * a)
end

local function SetMove(p, axis, d)
	Move(p, axis, MOVE_SIGN[axis] * d)
end

--------------------------------------------------------------------------------
-- math

local function RotX(x, y, z, a)
	local c, s = cos(a), sin(a)
	return x, c*y - s*z, s*y + c*z
end

local function RotY(x, y, z, a)
	local c, s = cos(a), sin(a)
	return c*x + s*z, y, -s*x + c*z
end

local function Ease(k)
	return 0.5 - 0.5*cos(pi*k)
end

-- the tracks are keyed densely off the Blender curves, so linear in between follows them
local function Sample(track, t)
	local i = t/KEY_STEP
	local i0 = floor(i)
	if i0 < 0 then
		return track[1]
	end
	if i0 >= #track - 1 then
		return track[#track]
	end
	return track[i0 + 1] + (track[i0 + 2] - track[i0 + 1])*(i - i0)
end

--------------------------------------------------------------------------------
-- legs

-- rest foot tip of each leg, in base (unit) space
for i = 1, #legs do
	local leg = legs[i]
	local r, h = leg.rig.rest, leg.rig.hip
	local u = LEN.coxa + LEN.femur*cos(r[1]) + LEN.tibia*cos(r[2]) + LEN.tarsus*cos(r[3])
	local v = LEN.femur*sin(r[1]) + LEN.tibia*sin(r[2]) + LEN.tarsus*sin(r[3])
	local x, y, z = RotY(u, v, 0, leg.rig.yaw)
	leg.restX, leg.restY, leg.restZ = RIG.prosoma[1] + h[1] + x, RIG.prosoma[2] + h[2] + y, RIG.prosoma[3] + h[3] + z
end

-- Put one leg's foot tip on (fx, fy, fz), in base space, for a body raised by `rise`,
-- shifted forward by `fwd` and pitched by `pitch` about x.
local function SolveLeg(leg, rise, fwd, pitch, fx, fy, fz)
	local rig, rest = leg.rig, leg.rig.rest
	local hx, hy, hz = RotX(rig.hip[1], rig.hip[2], rig.hip[3], pitch)
	hx, hy, hz = RIG.prosoma[1] + hx, RIG.prosoma[2] + rise + hy, RIG.prosoma[3] + fwd + hz

	-- target into the coxa's rest frame, then yaw the coxa to face it
	local dx, dy, dz = RotX(fx - hx, fy - hy, fz - hz, -pitch)
	dx, dy, dz = RotY(dx, dy, dz, -rig.yaw)
	local psi = atan2(-dz, dx)
	local u, v = RotY(dx, dy, dz, -psi)

	-- keep the tarsus as upright in the world as it is at rest
	local wx, wy, wz = RotX(0, -1, 0, -pitch)
	wx, wy, wz = RotY(wx, wy, wz, -rig.yaw)
	wx, wy = RotY(wx, wy, wz, -psi)
	local a3 = atan2(wy, wx) + rest[3] + pi/2

	-- two-bone solve for femur and tibia onto the ankle, knee up
	local ax, ay = u - LEN.tarsus*cos(a3) - LEN.coxa, v - LEN.tarsus*sin(a3)
	local dist = sqrt(ax*ax + ay*ay)
	dist = max(abs(LEN.femur - LEN.tibia) + 0.01, min(LEN.femur + LEN.tibia - 0.01, dist))
	local cb = (LEN.femur*LEN.femur + dist*dist - LEN.tibia*LEN.tibia) / (2*LEN.femur*dist)
	local a1 = atan2(ay, ax) + acos(max(-1, min(1, cb)))
	local kx, ky = LEN.femur*cos(a1), LEN.femur*sin(a1)
	local a2 = atan2(ay - ky, ax - kx)

	SetTurn(leg.coxa, y_axis, psi)
	SetTurn(leg.femur, z_axis, a1 - rest[1])
	SetTurn(leg.tibia, z_axis, (a2 - a1) - (rest[2] - rest[1]))
	SetTurn(leg.tarsus, z_axis, (a3 - a2) - (rest[3] - rest[2]))
end

--------------------------------------------------------------------------------
-- animation driver

local deployT, deployGoal = 0, 0
local lastPoseT = -1
local gaitPhase, gaitBlend = 0, 0
local locked = false

local function SpeedMult()
	if spGetUnitIsStunned(unitID) then
		return 0
	end
	return (GG.att_ReloadChange and GG.att_ReloadChange[unitID]) or 1 -- slow; 0 when disarmed
end

local function ApplyDeployPose(t)
	SetTurn(pedicel, x_axis, Sample(TR.pedicel_x, t))
	SetTurn(yoke, x_axis, Sample(TR.pedicel_yoke_x, t))
	SetTurn(opisthosoma, x_axis, Sample(TR.opisthosoma_x, t))
	SetTurn(braceCoxa, x_axis, Sample(TR.brace_coxa_x, t))
	SetTurn(braceFemur, x_axis, Sample(TR.brace_femur_x, t))
	SetTurn(braceTibia, x_axis, Sample(TR.brace_tibia_x, t))
	local l1, l2, sh = Sample(TR.petal_link1_x, t), Sample(TR.petal_link2_x, t), Sample(TR.petal_shell_x, t)
	local kn, pr = Sample(TR.petal_knuckle_x, t), Sample(TR.petal_prong_x, t)
	for i = 1, 8 do
		local p = petals[i]
		SetTurn(p.link1, x_axis, l1)
		SetTurn(p.link2, x_axis, l2)
		SetTurn(p.shell, x_axis, sh)
		SetTurn(p.knuckle, x_axis, kn)
		SetTurn(p.prong, x_axis, pr)
	end
	SetMove(endcapInner, z_axis, Sample(TR.endcap_inner_z, t))
	SetMove(endcapMid, z_axis, Sample(TR.endcap_mid_z, t))
	SetMove(endcapTip, z_axis, Sample(TR.endcap_tip_z, t))
end

local function FootOffset(leg)
	if gaitBlend <= 0 then
		return 0, 0, false
	end
	local p = (gaitPhase + leg.group) % 1
	if p < 0.5 then
		return STRIDE*(0.25 - p)*gaitBlend, 0, false
	end
	local s = (p - 0.5)*2
	return STRIDE*(Ease(s) - 0.5)*0.5*gaitBlend, LIFT*sin(pi*s)*gaitBlend, true
end

local function ApplyLegs(rise, fwd, pitch)
	local ux, uy, uz = spGetUnitPosition(unitID)
	local front, up, right = spGetUnitVectors(unitID)
	for i = 1, #legs do
		local leg = legs[i]
		local dz, lift, swinging = FootOffset(leg)
		local fx, fy, fz = leg.restX, leg.restY + lift, leg.restZ + dz

		-- meet the terrain: unit space x is the unit's left, i.e. -right
		local wx = ux - right[1]*fx + up[1]*fy + front[1]*fz
		local wy = uy - right[2]*fx + up[2]*fy + front[2]*fz
		local wz = uz - right[3]*fx + up[3]*fy + front[3]*fz
		local reach = (spGetGroundHeight(wx, wz) - (wy - lift)) / max(0.5, up[2])
		reach = max(-GROUND_REACH, min(GROUND_REACH, reach))
		leg.groundOffset = leg.groundOffset + (reach - leg.groundOffset)*0.5

		SolveLeg(leg, rise, fwd, pitch, fx, fy + leg.groundOffset, fz)

		if leg.wasSwinging and not swinging then
			EmitSfx(leg.foot, SFX_FOOTSTEP)
		end
		leg.wasSwinging = swinging
	end
end

local SIG_ANIM, SIG_DEPLOY = 1, 2

local function AnimThread()
	SetSignalMask(SIG_ANIM)
	while true do
		local mult = SpeedMult()
		if deployT ~= deployGoal and mult > 0 then
			local step = DEPLOY_RATE*mult
			if deployT < deployGoal then
				deployT = min(deployGoal, deployT + step)
			else
				deployT = max(deployGoal, deployT - step)
			end
		end

		local _, _, _, speed = spGetUnitVelocity(unitID)
		if (not locked) and speed and speed > 0.05 then
			gaitPhase = (gaitPhase + speed/STRIDE) % 1
			gaitBlend = min(1, gaitBlend + 0.1)
		else
			gaitBlend = max(0, gaitBlend - 0.05)
		end

		if deployT ~= lastPoseT then
			ApplyDeployPose(deployT)
			lastPoseT = deployT
		end
		local pitch = Sample(TR.prosoma_x, deployT)
		local rise = Sample(TR.prosoma_rise, deployT) + 0.8*sin(4*pi*gaitPhase)*gaitBlend
		local fwd = Sample(TR.prosoma_fwd, deployT)
		SetMove(prosoma, y_axis, rise)
		SetMove(prosoma, z_axis, fwd)
		SetTurn(prosoma, x_axis, pitch)
		ApplyLegs(rise, fwd, pitch)

		Sleep(33)
	end
end

--------------------------------------------------------------------------------
-- deploy cycle

local STATE_IDLE, STATE_DEPLOYING, STATE_CHARGING, STATE_RECOVERING = 0, 1, 2, 3
local state = STATE_IDLE
local readyFrame = 0

local function SetState(s)
	state = s
	spSetUnitRulesParam(unitID, "strideremp_state", s, LOS_ACCESS)
end

local function SetLocked(lock)
	locked = lock
	spSetUnitRulesParam(unitID, "selfMoveSpeedChange", lock and 0 or 1)
	spSetUnitRulesParam(unitID, "selfTurnSpeedChange", lock and 0 or 1)
	GG.UpdateUnitAttributes(unitID)
	if lock then
		GG.WaitWaitMoveUnit(unitID)
	end
end

local function Decloak(frame)
	if frame % 30 == 0 then
		GG.PokeDecloakUnit(unitID, unitDefID)
	end
end

local function DeployThread()
	SetSignalMask(SIG_DEPLOY)
	SetState(STATE_DEPLOYING)
	SetLocked(true)
	GG.PokeDecloakUnit(unitID, unitDefID)
	deployGoal = DEPLOY_END
	local frame = 0
	while deployT < DEPLOY_END do
		Sleep(33)
		frame = frame + 1
		Decloak(frame)
	end

	SetState(STATE_CHARGING)
	local x, y, z = spGetUnitPosition(unitID)
	Spring.PlaySoundFile(HUM_SOUND, 12, x, y, z)
	local progress = 0
	while progress < CHARGE_FRAMES do
		Sleep(33)
		frame = frame + 1
		Decloak(frame)
		progress = progress + SpeedMult()
		local charge = min(1, progress/CHARGE_FRAMES)
		spSetUnitRulesParam(unitID, "strideremp_charge", charge, LOS_ACCESS)
		spSetUnitRulesParam(unitID, "specialReloadRemaining", 1 - charge, LOS_ACCESS)
		-- crackle grows from the odd spark to a storm around the emitter
		if math.random() < 0.15 + 0.85*charge*charge then
			EmitSfx(petals[math.random(1, 8)].spark, SFX_SPARK)
		end
		if frame % 6 == 0 then
			EmitSfx(emitCore, SFX_CHARGE)
		end
		if frame % 45 == 0 then
			Spring.PlaySoundFile(frame % 90 == 0 and HUM_SOUND or CRACKLE_SOUND, 8 + 8*charge, x, y, z)
		end
	end

	EmitSfx(emitCore, GG.Script.DETO_W2)
	EmitSfx(base, SFX_GROUND_PULSE) -- ground flashes only draw near the terrain, not at the raised core
	spSetUnitRulesParam(unitID, "strideremp_charge", 0, LOS_ACCESS)
	SetState(STATE_RECOVERING)

	-- the pulse stuns us too; fold back up once it wears off
	Sleep(100)
	while spGetUnitIsStunned(unitID) do
		Sleep(33)
	end
	deployGoal = 0
	while deployT > 0 do
		Sleep(33)
	end
	SetLocked(false)
	readyFrame = spGetGameFrame() + COOLDOWN_FRAMES
	SetState(STATE_IDLE)

	while spGetGameFrame() < readyFrame do
		spSetUnitRulesParam(unitID, "specialReloadRemaining", (readyFrame - spGetGameFrame())/COOLDOWN_FRAMES, LOS_ACCESS)
		Sleep(500)
	end
	spSetUnitRulesParam(unitID, "specialReloadRemaining", 0, LOS_ACCESS)
end

local function TryDeploy()
	if state == STATE_IDLE and spGetGameFrame() >= readyFrame then
		StartThread(DeployThread)
		return true
	end
	return false
end

-- one-click Detonate (LuaRules/Configs/oneclick_weapon_defs.lua)
function Detonate()
	TryDeploy()
	return 0
end

--------------------------------------------------------------------------------
-- callins

function script.Create()
	SetState(STATE_IDLE)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(AnimThread)
end

-- called by the build icon generator (unit_icongenerator.lua): pose deployed, which tells
-- it apart from the other spiders
function BuildIconPose()
	deployT, deployGoal = DEPLOY_END, DEPLOY_END
end

-- The trigger measures range from the body: the folded emitter sits ~50 elmos behind
-- it, which would leave the unit stopping short of its own trigger range.
function script.AimFromWeapon(num)
	return (num == 1) and prosoma or emitCore
end

function script.QueryWeapon(num)
	return (num == 1) and prosoma or emitCore
end

-- Being given a target in range commits the unit; the trigger weapon itself never shoots.
function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		TryDeploy()
	end
	return false
end

--------------------------------------------------------------------------------
-- death: collapse into the wreck's pose (RIG.death, shared with strideremp_dead.dae)

local DEATH = RIG.death
local COLLAPSE_SECONDS = 1.1
local AXIS = {x = x_axis, y = y_axis, z = z_axis}

-- every channel the animation drives, so each one ends at its death value or back at rest
local function DeathChannels()
	local turns = {}
	local function turn(p, axis) turns[#turns + 1] = {p, axis} end
	for _, p in ipairs({prosoma, pedicel, yoke, opisthosoma, braceCoxa, braceFemur, braceTibia}) do
		turn(p, x_axis)
	end
	for i = 1, 8 do
		local pt = petals[i]
		for _, p in ipairs({pt.link1, pt.link2, pt.shell, pt.knuckle, pt.prong}) do
			turn(p, x_axis)
		end
	end
	for i = 1, #legs do
		local leg = legs[i]
		turn(leg.coxa, y_axis)
		turn(leg.femur, z_axis); turn(leg.tibia, z_axis); turn(leg.tarsus, z_axis)
	end
	for name, axes in pairs(DEATH.turn) do
		for axis in pairs(axes) do turn(piece(name), AXIS[axis]) end
	end
	local moves = {{prosoma, y_axis}, {prosoma, z_axis}, {endcapInner, z_axis}, {endcapMid, z_axis}, {endcapTip, z_axis}}
	return turns, moves
end

local function PieceName(p)
	for name, index in pairs(Spring.GetUnitPieceMap(unitID)) do
		if index == p then return name end
	end
end

local function Collapse()
	GG.Script.InitializeDeathAnimation(unitID)
	for _, name in ipairs(DEATH.lostRoots) do
		Explode(piece(name), SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
	end
	for _, name in ipairs(DEATH.lost) do
		Hide(piece(name))
	end
	local turns, moves = DeathChannels()
	for i = 1, #turns do
		local p, axis = turns[i][1], turns[i][2]
		local name = PieceName(p)
		local axisName = (axis == x_axis and "x") or (axis == y_axis and "y") or "z"
		local target = (DEATH.turn[name] and DEATH.turn[name][axisName]) or 0
		local current = select(axis, Spring.UnitScript.GetPieceRotation(p))
		Turn(p, axis, target, max(0.05, abs(target - current) / COLLAPSE_SECONDS))
	end
	for i = 1, #moves do
		local p, axis = moves[i][1], moves[i][2]
		local name = PieceName(p)
		local axisName = (axis == y_axis and "y") or "z"
		local target = (DEATH.move[name] and DEATH.move[name][axisName]) or 0
		local current = select(axis, Spring.UnitScript.GetPieceTranslation(p))
		Move(p, axis, target, max(0.5, abs(target - current) / COLLAPSE_SECONDS))
	end
	Sleep(COLLAPSE_SECONDS * 1000 + 150)
end

function script.Killed(recentDamage, maxHealth)
	Signal(SIG_ANIM)
	Signal(SIG_DEPLOY) -- death ends the cycle: no pulse from a corpse
	SetState(STATE_IDLE)
	spSetUnitRulesParam(unitID, "strideremp_charge", 0, LOS_ACCESS)
	local severity = recentDamage/maxHealth
	if severity <= 0.5 then
		Collapse()
		return 1
	end
	for i = 1, 8 do
		Explode(petals[i].shell, SFX.FALL + SFX.SMOKE + SFX.FIRE)
	end
	Explode(opisthosoma, SFX.SHATTER)
	Explode(prosoma, SFX.SHATTER)
	return 2
end
