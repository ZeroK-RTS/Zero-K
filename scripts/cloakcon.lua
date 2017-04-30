include "constants.lua"

local head = piece 'head' 
local hips = piece 'hips' 
local chest = piece 'chest' 
local rthigh = piece 'rthigh' 
local lthigh = piece 'lthigh' 
local lshin = piece 'lshin' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lfoot = piece 'lfoot' 
local larm = piece 'larm' 
local rupperarm = piece 'rupperarm' 
local claw1 = piece 'claw1' 
local claw2 = piece 'claw2' 
local rshoulder = piece 'rshoulder' 
local rforearm = piece 'rforearm' 

-- Signal definitions
local SIG_WALK = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	while true do
		Turn(lshin, x_axis, math.rad(10), math.rad(315))				
		Turn(rshin, x_axis, math.rad(85), math.rad(260))
		Turn(rthigh, x_axis, math.rad(-100), math.rad(135))
		Turn(lthigh, x_axis, math.rad(30), math.rad(135))
		if GetUnitValue(COB.INBUILDSTANCE) == 0 then
			Turn(larm, x_axis, math.rad(-30), math.rad(60))
			Turn(rshoulder, x_axis, math.rad(30), math.rad(60))
		end
		WaitForTurn(lthigh, x_axis)
		
		Turn(rshin, x_axis, math.rad(10), math.rad(315))
		Turn(lshin, x_axis, math.rad(85), math.rad(260))
		Turn(lthigh, x_axis, math.rad(-100), math.rad(135))
		Turn(rthigh, x_axis, math.rad(30), math.rad(135))
		if GetUnitValue(COB.INBUILDSTANCE) == 0 then
			Turn(larm, x_axis, math.rad(30), math.rad(60))
			Turn(rshoulder, x_axis, math.rad(-30), math.rad(60))
		end
		WaitForTurn(rthigh, x_axis)
	end
end

local function StopWalk ()
	Signal(SIG_WALK)
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
	
	if GetUnitValue(COB.INBUILDSTANCE) == 0 then
		Turn(larm, x_axis, 0, math.rad(30))
		Turn(rshoulder, x_axis, 0, math.rad(30))
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.StartBuilding(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	Turn(chest, y_axis, heading, math.rad(150))
	Turn(rshoulder, x_axis, -math.rad(90) - pitch, math.rad(150))
	Turn(rforearm, x_axis, 0, math.rad(150))
	Turn(claw1, x_axis, math.rad(-30), math.rad(150))
	Turn(claw2, x_axis, math.rad(30), math.rad(150))
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn(rshoulder, x_axis, 0, math.rad(150))
	Turn(rforearm, x_axis, 0, math.rad(150))
	Turn(chest, y_axis, 0, math.rad(150))
	Turn(rshoulder, x_axis, 0, math.rad(100))
	Turn(claw1, x_axis, 0, math.rad(100))
	Turn(claw2, x_axis, 0, math.rad(100))
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID), claw1)
	return claw1
end

function script.Create()
	StartThread(SmokeUnit, {chest})
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local corpseType = 1
	if severity <= .25 then
		Explode(hips, sfxShatter)
		Explode(chest, sfxShatter)
		Explode(head, sfxFall + sfxFire)
	elseif severity <= .50 then
		Explode(hips, sfxShatter)
		Explode(chest, sfxShatter)
		Explode(head, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	else
		corpseType = 2
		Explode(hips, sfxShatter)
		Explode(chest, sfxShatter)
		Explode(head, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	end
	return corpseType
end