include "constants.lua"

local spGetUnitVelocity = Spring.GetUnitVelocity
--local math = math

--pieces
local fuselage = piece "fuselage"
local rotor1 = piece "rotor1"
local rotor2 = piece "rotor2"
local engineL = piece "enginel"
local engineR = piece "enginer"
local tailL = piece "taill"
local tailR = piece "tailr"
local wingL = piece "wingl"
local wingR = piece "wingr"
local podL = piece "podl"
local podR = piece "podr"

local gunpod = piece "gunpod"
local pivot = piece "pivot"
local barrel = piece "barrel"
local flare = piece "flare"

local smokePiece = {fuselage, engineL, engineR}

--constants
local tiltAngle = math.rad(10)
local tiltSpeed = math.rad(30)
local rotorSpeed = math.rad(1080)
local rotorAccel = math.rad(240)
local rotorDecel = math.rad(120)
local pivotSpeed = math.rad(180)

--variables
local tilt = 0

--signals
local SIG_Aim = 1

--cob values


----------------------------------------------------------

local function Tilt()
	while true do
		local vx, vy, vz = spGetUnitVelocity(unitID)
		local vel = (vx^2 + vz^2)^0.5	--horizontal speed
		vel = math.max(vel - 1.5, 0)	--counteract jerking
		--Spring.Echo(vel)
		tilt = math.min(tiltAngle * vel, math.rad(20))	--cap at 20 degree tilt
		Turn(fuselage, x_axis, tilt, tiltSpeed)
		WaitForTurn(fuselage, x_axis)
		Sleep(330)
	end
end

function script.MoveRate(n)
	--Turn(fuselage, x_axis, math.rad(10)*n, tiltSpeed)
end

local function RotorStart()
	Spin(rotor1, y_axis, rotorSpeed, rotorAccel)
	Spin(rotor2, y_axis, -rotorSpeed, rotorAccel)
end

local function RotorStop()
	StopSpin(rotor1, y_axis, rotorDecel)
	StopSpin(rotor2, y_axis, rotorDecel)
end

function script.Create()
	StartThread(Tilt)
	StartThread(RotorStart)
end

function script.StartMoving()

end

function script.StopMoving()

end

function script.QueryWeapon1() return flare end

function script.AimFromWeapon1() return gunpod end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(pivot, y_axis, heading, pivotSpeed)
	Turn(pivot, x_axis, -pitch - tilt, pivotSpeed)
	WaitForTurn(pivot, y_axis)
	WaitForTurn(pivot, x_axis)
	return true
end

function script.Shot1()
	EmitSfx (gunpod, 1025)
	EmitSfx (flare, 1024)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		Explode(rotor1, SFX.FALL)
		Explode(rotor2, SFX.FALL)
		Explode(fuselage, SFX.NONE)
		Explode(engineL, SFX.SMOKE)
		Explode(engineR, SFX.SMOKE)
		Explode(wingL, SFX.NONE)
		Explode(wingR, SFX.NONE)
		Explode(podL, SFX.NONE)
		Explode(podR, SFX.NONE)
		Explode(tailL, SFX.NONE)
		Explode(tailR, SFX.NONE)
	elseif severity < 100 then
		Explode(rotor1, SFX.SMOKE)
		Explode(rotor2, SFX.SMOKE)
		Explode(fuselage, SFX.SHATTER)
		Explode(engineL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(engineR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wingL, SFX.FALL)
		Explode(wingR, SFX.FALL)
		Explode(podL, SFX.SMOKE + SFX.EXPLODE)
		Explode(podR, SFX.SMOKE + SFX.EXPLODE)
		Explode(tailL, SFX.FALL)
		Explode(tailR, SFX.FALL)
	else
		Explode(rotor1, SFX.SMOKE + SFX.FIRE)
		Explode(rotor2, SFX.SMOKE + SFX.FIRE)
		Explode(fuselage, SFX.SHATTER)
		Explode(engineL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(engineR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wingL, SFX.SMOKE)
		Explode(wingR, SFX.SMOKE)
		Explode(podL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(podR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(tailL, SFX.SMOKE)
		Explode(tailR, SFX.SMOKE)
	end
end
