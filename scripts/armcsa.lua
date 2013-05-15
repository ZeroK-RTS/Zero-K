local fuselage = piece 'fuselage' 
local head = piece 'head' 
local wingl = piece 'wingl' 
local wingr = piece 'wingr' 
local enginel = piece 'enginel' 
local enginer = piece 'enginer' 
local arm = piece 'arm' 
local lathe = piece 'lathe' 
local jaw1 = piece 'jaw1' 
local jaw2 = piece 'jaw2' 
local nanopoint = piece 'nanopoint' 

include "constants.lua"

smokePiece = {fuselage}
local nanoPieces = {nanopoint}

-- Signal definitions
local SIG_MOVE = 1

function script.Create()
	StartThread(SmokeUnit)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.Activate()
	Turn( arm , x_axis, math.rad(-80), math.rad(200) )
	Turn( lathe , x_axis, math.rad(-80), math.rad(200) )
end

function script.Deactivate()
	Turn( arm , x_axis, 0, math.rad(200) )
	Turn( lathe , x_axis, 0, math.rad(200) )
end

local function StartMoving()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	Turn( enginel , x_axis, math.rad(10), math.rad(200) )
	Turn( enginer , x_axis, math.rad(10), math.rad(200) )
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	Signal( SIG_MOVE)
	Turn( enginel , x_axis, 0, math.rad(100) )
	Turn( enginer , x_axis, 0, math.rad(100) )
end

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
	Turn( jaw1 , x_axis, math.rad(-30), math.rad(150) )
	Turn( jaw2 , x_axis, math.rad(30), math.rad(150) )
	
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn( jaw1 , x_axis, 0, math.rad(100) )
	Turn( jaw2 , x_axis, 0, math.rad(100) )
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanopoint)
	return nanopoint
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		return 1
	elseif severity <= 0.50  then
		Explode(enginel, sfxFall + sfxFire )
		Explode(enginer, sfxFall + sfxFire )
		return 1
	else
		Explode(fuselage, sfxFall)
		Explode(head, sfxFall)
		Explode(wingl, sfxFall)
		Explode(wingr, sfxFall)
		Explode(enginel, sfxFall + sfxSmoke + sfxFire )
		Explode(enginer, sfxFall + sfxSmoke + sfxFire )
		Explode(lathe, sfxFall + sfxSmoke + sfxFire )
		return 2
	end
end
