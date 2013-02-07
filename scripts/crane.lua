local base = piece 'base' 
local body = piece 'body' 
local engine1 = piece 'engine1' 
local engine2 = piece 'engine2' 
local nozzle = piece 'nozzle' 
local nano = piece 'nano' 

--New bits
local centreClaw 		= piece 'CentreClaw'
local centreClawBit 	= piece 'CentreClawBit'
local CentreNano 		= piece 'CentreNano'
local leftClaw 			= piece 'LeftClaw'
local leftClawBit 		= piece 'LeftClawBit'
local leftNano 			= piece 'LeftNano'
local rightClaw 		= piece 'RightClaw'
local rightClawBit 		= piece 'RightClawBit'
local rightClawBit 		= piece 'RightClawBit'
local engShield1 		= piece 'EngShield1'
local engShield2 		= piece 'EngShield2'


smokePiece = {base, engine1, engine2}

include "constants.lua"

function script.Create()
	Move( engShield1, y_axis, 0, 0.5 ) 
	Move( engShield2, y_axis, 0, 0.5 ) 
	StartThread(SmokeUnit)
end

function script.Activate()
	Move( engShield1, y_axis, 0.8, 0.5 ) 
	Move( engShield2, y_axis, -0.8, 0.5 ) 
end

function script.Deactivate()
	Move( engShield1, y_axis, 0, 0.5 ) 
	Move( engShield2, y_axis, 0, 0.5 ) 	
end

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
	
	Turn(base,x_axis, rad(30),0.5)
	
	Turn(centreClaw,x_axis, rad(-35),1)
	Turn(centreClawBit,x_axis, rad(-135),2.5)
	Turn(leftClaw,y_axis, rad(40),1)
	Turn(leftClawBit,y_axis, rad(135),2.5)
	Turn(rightClaw,y_axis, rad(-40),1)
	Turn(rightClawBit,y_axis, rad(-135),2.5)
	
	WaitForTurn( centreClaw, x_axis )
	WaitForTurn( centreClawBit, x_axis )
	WaitForTurn( leftClaw, y_axis )
	WaitForTurn( leftClawBit, y_axis )
	WaitForTurn( rightClaw, y_axis )
	WaitForTurn( rightClawBit, y_axis )	
	
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	
	Turn(base,x_axis, rad(0),0.5)
	Turn(centreClaw,x_axis, rad(0),0.5)
	Turn(centreClawBit,x_axis, rad(0),2)
	Turn(leftClaw,y_axis, rad(0),0.5)
	Turn(leftClawBit,y_axis, rad(0),2)
	Turn(rightClaw,y_axis, rad(0),0.5)
	Turn(rightClawBit,y_axis, rad(0),2)
	
	WaitForTurn( centreClaw, x_axis )
	WaitForTurn( centreClawBit, x_axis )
	WaitForTurn( leftClaw, y_axis )
	WaitForTurn( leftClawBit, y_axis )
	WaitForTurn( rightClaw, y_axis )
	WaitForTurn( rightClawBit, y_axis )	

end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),CentreNano)
	return nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(engine2, sfxFall)
		Explode(engine1, sfxFall)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxShatter)
		Explode(engine2, sfxFall)
		Explode(engine1, sfxFall)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(engine2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(engine1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		return 2
	end
end