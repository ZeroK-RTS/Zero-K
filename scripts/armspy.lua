include "constants.lua"

local base = piece 'base' 
local turret = piece 'turret' 
local barrel = piece 'barrel' 
local flare = piece 'flare' 

local lfrontleg = piece 'lfrontleg' 
local lfrontleg1 = piece 'lfrontleg_1' 

local rfrontleg = piece 'rfrontleg' 
local rfrontleg1 = piece 'rfrontleg_1' 

local laftleg = piece 'laftleg' 
local laftleg1 = piece 'laftleg_1' 

local raftleg = piece 'raftleg' 
local raftleg1 = piece 'raftleg_1' 

local PACE = 1.4

local SIG_Walk = 1
local SIG_Aim = 2
local SIG_Walk = 4

--constants
local PI = math.pi
local sa = math.rad(-10)
local ma = math.rad(40)
local la = math.rad(100)
local pause = 450

local forward = 2.5
local backward = 2.3
local up = 2

smokePiece = {base, barrel}

function script.Create()

Turn( lfrontleg, y_axis, math.rad(45) ) 
Turn( rfrontleg, y_axis, math.rad(-45) ) 
Turn( laftleg, y_axis, math.rad(-45) ) 
Turn( raftleg, y_axis, math.rad(45) ) 

	StartThread(SmokeUnit,smokePiece)
end


local function RestoreAfterDelay()
	Sleep( 2750)
	Turn( turret , y_axis, 0, math.rad(90) )
	Turn( barrel , x_axis, 0, math.rad(90) )
end

local function Walk()
	SetSignalMask( SIG_Walk )
	while ( true ) do


		Turn( lfrontleg, y_axis, 1.5*ma, forward )   	-- right front forward
		Turn( lfrontleg, z_axis, -ma, up )       	-- right front up
		Turn( lfrontleg1, z_axis, -ma/3, up )
				
		Turn( laftleg, y_axis, -1.5*ma, backward ) 	-- right back backward
		Turn( laftleg, z_axis, 0, 4*up )         	-- right back down
		Turn( laftleg1, z_axis, 0, up )
		
		Turn( rfrontleg, y_axis, sa, backward ) 	-- left front backward
    	Turn( rfrontleg, z_axis, 0, 4*up )         	-- left front down
		Turn( rfrontleg1, z_axis, 0, up )
		
		Turn( raftleg, y_axis, -sa, forward ) 	-- left back forward
		Turn( raftleg, z_axis, ma, up )       	-- left back up
		Turn( raftleg1, z_axis, ma/3, up )
		
		Sleep( pause )
		


		Turn( lfrontleg, y_axis, -sa, backward ) 	-- right front backward
		Turn( lfrontleg, z_axis, 0, 4*up )         	-- right front down
		Turn( lfrontleg1, z_axis, 0, up )
		
		Turn( laftleg, y_axis, sa, forward )   	-- right back forward
		Turn( laftleg, z_axis, -ma, up )       	-- right back up
		Turn( laftleg1, z_axis, -ma/3, up )
		
		Turn( rfrontleg, y_axis, -1.5*ma, forward ) 	-- left front forward
		Turn( rfrontleg, z_axis, ma, up )       	-- left front up
		Turn( rfrontleg1, z_axis, ma/3, up )
		
		Turn( raftleg, y_axis, 1.5*ma, backward ) 	-- left back backward
		Turn( raftleg, z_axis, 0, 4*up )         	-- left back down
		Turn( raftleg1, z_axis, 0, up )
		
		Sleep( pause )
	
	end
end

	local function StopWalk()
        Move( base, y_axis,  0, 4*up )	
     	Turn( lfrontleg, y_axis, 0 )   	-- right front forward
		Turn( lfrontleg, z_axis, 0, up )
		Turn( lfrontleg1, z_axis, 0, up )
		
		Turn( laftleg, y_axis, 0 ) 	-- right back backward
		Turn( laftleg, z_axis, 0, up )
		Turn( laftleg1, z_axis, 0, up )
		
		Turn( rfrontleg, y_axis, 0 ) 	-- left front backward
		Turn( rfrontleg, z_axis, 0, up ) 
		Turn( rfrontleg1, z_axis, 0, up )
		
		Turn( raftleg, y_axis, 0 ) 	-- left back forward
		Turn( raftleg, z_axis, 0, up ) 
		Turn( raftleg1, z_axis, 0, up )


		Turn( lfrontleg, y_axis, math.rad(45), forward ) 
		Turn( rfrontleg, y_axis, math.rad(-45), forward ) 
		Turn( laftleg, y_axis, math.rad(-45), forward ) 
		Turn( raftleg, y_axis, math.rad(45), forward ) 

		end

function script.StartMoving()
	--SetSignalMask( walk )
	StartThread( Walk )
end

function script.StopMoving()
	Signal( SIG_Walk )
	--SetSignalMask( SIG_Walk )
	StartThread( StopWalk )
end	
	
function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn( turret , y_axis, heading, math.rad(360) ) -- left-right
	Turn( barrel , x_axis, -pitch, math.rad(270) ) --up-down
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(barrel, sfxFall + sfxSmoke)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end