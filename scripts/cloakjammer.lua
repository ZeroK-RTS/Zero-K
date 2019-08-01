local head = piece 'head' 
local hips = piece 'hips' 
local chest = piece 'chest' 
local rthigh = piece 'rthigh' 
local lthigh = piece 'lthigh' 
local lshin = piece 'lshin' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lfoot = piece 'lfoot' 
local disc = piece 'disc' 
local cloaker = piece 'cloaker' 

local SIG_MOVE = 1

include "constants.lua"

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	while true do
		Turn(rthigh, y_axis, 0, math.rad(135))
		Turn(lthigh, y_axis, 0, math.rad(130))
		
		Turn(rthigh, z_axis, math.rad(0), math.rad(135))
		Turn(lthigh, z_axis, math.rad(0), math.rad(130))
		Turn(lfoot, z_axis, math.rad(0), math.rad(130))
		Turn(rfoot, z_axis, math.rad(0), math.rad(130))
	
		Turn(rshin, x_axis, math.rad(85), math.rad(260))	
		Turn(rthigh, x_axis, math.rad(-100), math.rad(135))
		Turn(lthigh, x_axis, math.rad(30), math.rad(135))
		Turn(chest, y_axis, math.rad(10), math.rad(60))
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, 1.2, 4.2)
		WaitForMove(hips, y_axis)
		
		Turn(rshin, x_axis, math.rad(10), math.rad(315))
		Move(hips, y_axis, 0, 4.2)
		Turn(lshin, x_axis, math.rad(85), math.rad(260))
		Turn(lthigh, x_axis, math.rad(-100), math.rad(135))
		Turn(rthigh, x_axis, math.rad(30), math.rad(135))
		Turn(chest, y_axis, math.rad(-10), math.rad(60))
		WaitForMove(hips, y_axis)
		
		Move(hips, y_axis, 1.2, 4.2)	
		WaitForMove(hips, y_axis)
		
		Turn(lshin, x_axis, math.rad(10), math.rad(315))
		Move(hips, y_axis, 0, 4.2)
	end
end


local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	Turn(lfoot, x_axis, 0, math.rad(395))
	Turn(rfoot, x_axis, 0, math.rad(395))
	Turn(rthigh, x_axis, 0, math.rad(235))
	Turn(lthigh, x_axis, 0, math.rad(230))
	Turn(lshin, x_axis, 0, math.rad(235))
	Turn(rshin, x_axis, 0, math.rad(230))
	
	Turn(rthigh, y_axis, math.rad(-20), math.rad(135))
	Turn(lthigh, y_axis, math.rad(20), math.rad(130))
	
	Turn(rthigh, z_axis, math.rad(-3), math.rad(135))
	Turn(lthigh, z_axis, math.rad(3), math.rad(130))
	Turn(lfoot, z_axis, math.rad(-3), math.rad(130))
	Turn(rfoot, z_axis, math.rad(3), math.rad(130))
end


function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.Activate()
	Spin(disc, z_axis, math.rad(90))
end

function script.Deactivate()
	Spin(disc, z_axis, 0)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, {head, hips, chest})
	Turn(hips, x_axis, math.rad(45))
end
	
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		Explode(hips, SFX.NONE)
		Explode(chest, SFX.NONE)
		Explode(head, SFX.FALL + SFX.FIRE)
		return 1
	elseif (severity <= 0.5) then
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SHATTER)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 1
	end

	Explode(hips, SFX.SHATTER)
	Explode(chest, SFX.SHATTER)
	Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	
	return 2
end