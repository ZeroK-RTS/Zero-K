local base = piece 'base' 
local tube = piece 'tube' 
local tower = piece 'tower' 
local nuke = piece 'nuke' 
local hoses = piece 'hoses' 
local doorl = piece 'doorl' 
local doorr = piece 'doorr' 
local point = piece 'point' 

include "constants.lua"

local RESTORE_DELAY = 3000
local openingDoors = false
local doorsAreOpen = false
local closingDoors = false
local missileLoaded = true

-- Signal definitions
local SIG_AIM = 1
local SIG_RESTORE = 2

local function OpenDoors()
	SetSignalMask(0)
	
	if openingDoors or closingDoors then
		return
	end 
	openingDoors = true

	Move(doorl, x_axis, 0)
	Move(doorl, x_axis, -22, 14)
	Move(doorr, x_axis, 0)
	Move(doorr, x_axis, 22, 14)
	Move(tube, y_axis, 0)
	Move(nuke, x_axis, 0)	
	Move(tower, y_axis, 0)
	
	Show(tube)
	Show(tower)
	Show(nuke)
	
	Sleep(1000)

	Move(tube, y_axis, 15, 10)
	
	Move(tower, y_axis, 62, 22)
	Sleep(3000)
	doorsAreOpen = true
	openingDoors = false
end

local function CloseDoors()
	SetSignalMask(0)
	
	if openingDoors or closingDoors then
		return
	end
	doorsAreOpen = false
	closingDoors = true
	
	Sleep(500)
	
	Move(tower, y_axis, 0, 30)
	Sleep(1000)
	Move(tube, y_axis, 0, 15)
	Sleep(1000)

	Move(doorl, x_axis, 0, 14)
	Move(doorr, x_axis, 0, 14)
	Sleep(500)
	
	WaitForMove(doorr, x_axis)
	Hide(tube)	
	
	closingDoors = false
	missileLoaded = true
end

function script.Create()
	StartThread(SmokeUnit, {base})
	Hide(tube)
	Hide(tower)
	Hide(nuke)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	
	StartThread(CloseDoors)
end

function script.AimWeapon(num, heading, pitch)
	StartThread(RestoreAfterDelay)
	
	if not (missileLoaded or closingDoors) then
		StartThread(CloseDoors)
	elseif not (doorsAreOpen or openingDoors) then
		StartThread(OpenDoors)
	end
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	while not doorsAreOpen do
		Sleep(25)
	end
	return true
end

function script.FireWeapon()
	Hide(nuke)
	missileLoaded = false
	doorsAreOpen = false

	-- Intentionally non-positional
	Spring.PlaySoundFile("sounds/weapon/missile/heavymissile_launch.wav", 15)
end

function script.QueryWeapon()
	return point
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(tube, sfxNone)
		Explode(doorl, sfxNone)
		Explode(doorr, sfxNone)
		Explode(tower, sfxNone)
		Explode(nuke, sfxNone)
		return 1
	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(tube, sfxShatter)
		Explode(doorl, sfxFall)
		Explode(doorr, sfxFall)
		Explode(tower, sfxNone)
		Explode(nuke, sfxNone)
		return 1
	else
		Explode(base, sfxNone)
		Explode(tube, sfxShatter)
		Explode(doorl, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(doorr, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(tower, sfxNone)
		Explode(nuke, sfxNone)
		return 2
	end
	Explode(base, sfxNone)
	Explode(tube, sfxShatter + sfxExplodeOnHit)
	Explode(doorl, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(doorr, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(tower, sfxNone)
	Explode(nuke, sfxNone)
	return 3
end
