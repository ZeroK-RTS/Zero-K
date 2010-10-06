include "constants.lua"

local spGetUnitVelocity = Spring.GetUnitVelocity
local math = math

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
local tiltAngle = math.rad(3)
local tiltSpeed = math.rad(5)
local rotorSpeed = math.rad(1080)
local rotorAccel = math.rad(240)
local rotorDecel = math.rad(120)
local pivotSpeed = math.rad(180)

--variables


--signals
local SIG_Aim = 1

--cob values


----------------------------------------------------------

local function Tilt()
	while true do
		Sleep(100)
		local vel = GetUnitValue(CURRENT_SPEED)/60
		Turn(fuselage, x_axis, tiltAngle * vel, tiltSpeed)
	end
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
	--StartThread(Tilt)
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
	Turn(pivot, x_axis, -pitch, pivotSpeed)
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
		Explode(rotor1, sfxFall)
		Explode(rotor2, sfxFall)
		Explode(fuselage, sfxNone)
		Explode(engineL, sfxSmoke)
		Explode(engineR, sfxSmoke)
		Explode(wingL, sfxNone)
		Explode(wingR, sfxNone)
		Explode(podL, sfxNone)
		Explode(podR, sfxNone)
		Explode(tailL, sfxNone)
		Explode(tailR, sfxNone)
	elseif severity < 100 then
		Explode(rotor1, sfxSmoke)
		Explode(rotor2, sfxSmoke)
		Explode(fuselage, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxFall)
		Explode(wingR, sfxFall)
		Explode(podL, sfxSmoke + sfxExplode)
		Explode(podR, sfxSmoke + sfxExplode)
		Explode(tailL, sfxFall)
		Explode(tailR, sfxFall)
	else
		Explode(rotor1, sfxSmoke + sfxFire)
		Explode(rotor2, sfxSmoke + sfxFire)
		Explode(fuselage, sfxShatter)
		Explode(engineL, sfxSmoke + sfxFire + sfxExplode)
		Explode(engineR, sfxSmoke + sfxFire + sfxExplode)
		Explode(wingL, sfxSmoke)
		Explode(wingR, sfxSmoke)
		Explode(podL, sfxSmoke + sfxFire + sfxExplode)
		Explode(podR, sfxSmoke + sfxFire + sfxExplode)
		Explode(tailL, sfxSmoke)
		Explode(tailR, sfxSmoke)
	end
end
