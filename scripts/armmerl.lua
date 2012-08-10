include 'constants.lua'

local base, bay, gantry, clamp1, clamp2, missile, smoke, strobe = piece("base", "bay", "gantry", "clamp1", "clamp2", "missile", "smoke", "strobe")
local tracks1, tracks2, tracks3, tracks4 = piece("tracks1", "tracks2", "tracks3", "tracks4")

local wheels = { piece("wheels1", "wheels2", "wheels3", "wheels4", "wheels5", "wheels6") }

smokePiece = {bay, gantry}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_AIM = 2

local RESTORE_DELAY = 5000
local LOAD_DELAY = 500
local TRACK_PERIOD = 50

local BAY_DISTANCE = -10
local BAY_SPEED = 8
local GANTRY_SPEED = math.rad(90)
local CLAMP_SPEED = math.rad(180)

local WHEEL_SPIN_SPEED = math.rad(720)
local WHEEL_SPIN_ACCEL = math.rad(10)
local WHEEL_SPIN_DECEL = math.rad(30)

local isLoaded, isReady, isMoving, doStrobe = true, false, false, false
local tracks = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function TrackControl() 
	while isMoving do 
		tracks = tracks + 1
		if tracks == 2 then 
			Hide( tracks1)
			Show( tracks2)
		elseif tracks == 3 then 
			Hide( tracks2)
			Show( tracks3)
		elseif tracks == 4 then 
			Hide( tracks3)
			Show( tracks4)
		else 
			tracks = 1
			Hide( tracks4)
			Show( tracks1)
		end
		Sleep(TRACK_PERIOD)
	end
end

local function Prepare() 
	Move( bay , x_axis, 0 , BAY_SPEED )
	WaitForMove(bay, x_axis)
	doStrobe = true
	Turn( gantry , x_axis, math.rad(-90), GANTRY_SPEED )
	WaitForTurn(gantry, x_axis)
	Turn( clamp1 , z_axis, math.rad(-(90)), CLAMP_SPEED )
	Turn( clamp2 , z_axis, math.rad(-(-90)), CLAMP_SPEED )
	WaitForTurn(clamp1, y_axis)
	WaitForTurn(clamp2, y_axis)
	isReady = true
end

local function Reload() 
	isReady = false
	doStrobe = false
	Turn( clamp1 , z_axis, 0, CLAMP_SPEED )
	Turn( clamp2 , z_axis, 0, CLAMP_SPEED )
	WaitForTurn(clamp1, z_axis)
	WaitForTurn(clamp2, z_axis)
	Turn( gantry , x_axis, 0, GANTRY_SPEED )
	WaitForTurn(gantry, x_axis)
	Move( bay , x_axis, -BAY_DISTANCE , BAY_SPEED )
	WaitForMove(bay, x_axis)
	
	Sleep(LOAD_DELAY)
	isLoaded = 1
	Show( missile)
end

function script.StartMoving() 
	isMoving = true
	StartThread(TrackControl)
	for i=1,#wheels do
		Spin( wheels[i] , x_axis, WHEEL_SPIN_SPEED, WHEEL_SPIN_ACCEL )
	end
end

function script.StopMoving() 
	isMoving = false
	for i=1,#wheels do
		StopSpin( wheels[i], x_axis, WHEEL_SPIN_DECEL )
	end
end

local function RestoreAfterDelay() 
	Sleep(RESTORE_DELAY)
	StartThread(Reload)
end

function script.AimWeapon(num, heading, pitch) 
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	GG.DontFireRadar_CheckAim(unitID)
	
	if isLoaded then 
		StartThread(Prepare)
		if  doStrobe then
			EmitSfx(strobe, 1024)
		end
	end
	while (not isReady) do
		Sleep(250)
	end
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	return (targetID and GG.DontFireRadar_CheckBlock(unitID, targetID)) and true or false
end

function script.QueryWeapon(num) 
	return smoke
end

function script.Shot(num) 
	Hide( missile)
	isLoaded = false
	doStrobe = false
	StartThread(Reload)
end

function script.Create() 
	Hide( tracks2)
	Hide( tracks3)
	Hide( tracks4)
	Move( bay , x_axis, -BAY_DISTANCE  )
	StartThread(SmokeUnit)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then 
		Explode(base, sfxNone)
		Explode(bay, sfxNone)
		Explode(gantry, sfxNone)
		Explode(clamp1, sfxNone)
		Explode(clamp2, sfxNone)
		Explode(missile, sfxNone)
		return 1
	elseif  severity <= .50  then 
		Explode(base, sfxNone)
		Explode(bay, sfxNone)
		Explode(gantry, sfxFall)
		Explode(clamp1, sfxFall)
		Explode(clamp2, sfxFall)
		Explode(missile, sfxNone)
		return 1
	else 
		Explode(base, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(bay, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gantry, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(clamp1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(clamp2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(missile, sfxNone)
		return 2
	end
end
