include "constants.lua"
include "pieceControl.lua"

local base, turret, sleeve, barrel, flare, muzzle, ejector = piece('base', 'turret', 'sleeve', 'barrel', 'flare', 'muzzle', 'ejector')

local explodables = {barrel, flare, sleeve, turret}
local smokePiece = { base, turret }

local stuns = {false, false, false}
local disarmed = false

local LOS_ACCESS = {inlos = true}
local SigAim = 1

local function SetupHeat()
	local ud = UnitDefs[unitDefID]
	local cp = ud.customParams
	return tonumber(cp.heat_per_shot), (tonumber(cp.heat_decay) or 0)/30, tonumber(cp.heat_max_slow), tonumber(cp.heat_initial) or 0
end
local heatPerShot, heatDecay, heatMaxSlow, currentHeat = SetupHeat()

local function UpdateReloadTime()
	local reloadMult = 1 - currentHeat * heatMaxSlow
	Spring.SetUnitRulesParam(unitID, "selfReloadSpeedChange", reloadMult, LOS_ACCESS)
	Spring.SetUnitRulesParam(unitID, "heat_bar", currentHeat, LOS_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end

local function HeatUpdateThread()
	while currentHeat > 0 do
		UpdateReloadTime()
		Sleep(33)
		local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID)
		if not stunned_or_inbuild then
			local decayMult = (GG.att_EconomyChange[unitID] or 1)
			if decayMult > 0 then
				currentHeat = currentHeat - heatDecay*decayMult
				if currentHeat <= 0 then
					currentHeat = 0
					UpdateReloadTime()
					return
				end
			end
		end
	end
end

local function AddHeat(newHeat)
	local newThread = (currentHeat == 0)

	currentHeat = currentHeat + newHeat
	if currentHeat > 1 then
		currentHeat = 1
	end

	if newThread then
		StartThread(HeatUpdateThread)
	end
end

local function RestoreAfterDelay()
	Sleep (5000)
	Turn (turret, y_axis, 0, math.rad(10))
	Turn (sleeve, x_axis, 0, math.rad(10))
end

local function StunThread()
	Signal (SigAim)
	SetSignalMask(SigAim)
	disarmed = true

	GG.PieceControl.StopTurn (turret, y_axis)
	GG.PieceControl.StopTurn (sleeve, x_axis)
end

local function UnstunThread()
	disarmed = false
	SetSignalMask(SigAim)
	RestoreAfterDelay()
end

function Stunned(stun_type)
	stuns[stun_type] = true
	StartThread(StunThread)
end

function Unstunned(stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread(UnstunThread)
	end
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	Turn (ejector, y_axis, math.rad(-90))
	Spring.Echo("currentHeat", currentHeat)
	if currentHeat > 0 then
		StartThread(HeatUpdateThread)
	end
end

function script.QueryWeapon()
	return muzzle
end

function script.AimFromWeapon()
	return turret
end

function script.AimWeapon (num, heading, pitch)

	Signal (SigAim)
	SetSignalMask (SigAim)

	while disarmed do
		Sleep (34)
	end

	StartThread (RestoreAfterDelay)
	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (turret, y_axis, heading, math.rad(360)*slowMult)
	Turn (sleeve, x_axis, -pitch, math.rad(360)*slowMult)
	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)

	return true
end

--local lastFrameFired = Spring.GetGameFrame()
function script.FireWeapon ()
	--Spring.Echo("fire", Spring.GetGameFrame() - lastFrameFired, Spring.GetGameFrame())
	--lastFrameFired = Spring.GetGameFrame()

	EmitSfx (muzzle, 1024)
	EmitSfx (ejector, 1025)
	Spin (barrel, z_axis, math.rad(720))
	StopSpin (barrel, z_axis, math.rad(18))
	AddHeat(heatPerShot)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], SFX.SMOKE + SFX.FIRE)
		end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (base, SFX.SHATTER)
		return 2
	end
end
