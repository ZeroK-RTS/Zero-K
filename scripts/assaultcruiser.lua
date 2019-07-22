include 'constants.lua'

--------------------------------------------------------------------
--pieces
--------------------------------------------------------------------
local base, lowerhull, upperhull, antenna, radarbase, radardish = piece('base', 'lowerhull', 'upperhull', 'antenna', 'radarbase', 'radardish')
local wake1, wake2 = piece('wake1', 'wake2')

local turretPrefixes = {"fl", "fr", "sl", "sr", "ml", "mr"}
local turretPieces = {}
local gunStates = {}

-- generate turretPieces table
for i=2,7 do
	turretPieces[i] = {}
	local array = turretPieces[i]
	array.turret = piece(turretPrefixes[i-1].."turret")
	array.pivot = piece(turretPrefixes[i-1].."pivot")
	array.barrel = {}
	array.barrel[0] = piece(turretPrefixes[i-1].."barrel1")
	array.barrel[1] = piece(turretPrefixes[i-1].."barrel2")
	array.flare = {}
	array.flare[0] = piece(turretPrefixes[i-1].."flare1")
	array.flare[1] = piece(turretPrefixes[i-1].."flare2")
	
	gunStates[i] = 0
end

--------------------------------------------------------------------
--constants
--------------------------------------------------------------------
local smokePiece = {lowerhull, radarbase, upperhull}

local SIG_RESTORE = 1
local SIG_MOVE = 2
local SIG_Aim = 4

local RESTORE_DELAY = 5000

local TURRET_PITCH_SPEED = math.rad(90)
local TURRET_YAW_SPEED = math.rad(180)
local RECOIL_DISTANCE =	-3
local RECOIL_RESTORE_SPEED = 2.5


--------------------------------------------------------------------
--variables
--------------------------------------------------------------------
local gun = {1, 1, 1}
local gunHeading = {0, 0, 0}

local dead = false

function script.Create()
	Turn(turretPieces[4].turret, y_axis, math.rad(180))
	Turn(turretPieces[5].turret, y_axis, math.rad(180))
	Spin(radardish, y_axis, math.rad(100))
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	if dead then return false end
	for i=2,7 do
		if i == 4 or i == 5 then Turn(turretPieces[i].turret, y_axis, math.pi, math.rad(35))
		else Turn(turretPieces[i].turret, y_axis, 0, math.rad(35)) end
		Turn(turretPieces[i].pivot, x_axis, 0, math.rad(15))
	end
end

local function Wake()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		EmitSfx(wake1, 2)
		EmitSfx(wake2, 2)
		Sleep(200)
	end
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end

function script.AimWeapon(num, heading, pitch)
	if dead or (num == 1) then return false end
	local SIG_Aim = 2^num
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(turretPieces[num].turret, y_axis, heading, TURRET_YAW_SPEED)
	Turn(turretPieces[num].pivot, x_axis, -pitch, TURRET_PITCH_SPEED)
	WaitForTurn(turretPieces[num].turret, y_axis)
	WaitForTurn(turretPieces[num].pivot, x_axis)	
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
end

function script.Shot(num)
	local gun_num = gunStates[num]
	local barrel = turretPieces[num].barrel[gun_num]
	local flare = turretPieces[num].flare[gun_num]
	local toEmit = (num <= 5) and 1024 or 1025 
	EmitSfx(flare, toEmit)
	if (num <= 5) then
		Move(barrel, z_axis, RECOIL_DISTANCE)
		Move(barrel, z_axis, 0, RECOIL_RESTORE_SPEED)
	end
	gunStates[num] = 1 - gunStates[num]
end

function script.AimFromWeapon(num)
	if num == 1 then return base end
	return turretPieces[num].turret
end

function script.QueryWeapon(num)
	if num == 1 then return base end
	return turretPieces[num].flare[gunStates[num]]
end

local function ExplodeTurret(num, severity)
end

--not actually called; copypasta into Killed()
local function DeathAnim()
	dead = true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.25 then
		DeathAnim()
		Explode(lowerhull, SFX.NONE)
		Explode(upperhull, SFX.NONE)
		return 1
	elseif severity < 0.5 then
		DeathAnim()
		Explode(lowerhull, SFX.NONE)
		Explode(upperhull, SFX.NONE)
		return 1	
	else
		Explode(lowerhull, SFX.SHATTER)
		Explode(upperhull, SFX.SHATTER)
		return 2
	end
end
