
	Spring.Echo("GOGOGO")
-- by Chris Mackey

--pieces
local base = piece "base"
local body = piece "body"
local head = piece "head"
local flare = piece "flare" -- eyes?

local lshoulder = piece "lshoulder"
local lforearm = piece "lforearm"
local rshoulder = piece "rshoulder"
local rforearm = piece "rforearm"

local lthigh = piece "lthigh"
local lshin = piece "lshin"
local rthigh = piece "rthigh"
local rshin = piece "rshin"

--signals
local walk = 2
local aim = 4

--constants
langle = math.rad(30)
lspeed = 1.3
tiny = .1

local function Walk()
	SetSignalMask( walk )
	Turn( body, x_axis, .1, 1 )
	while( true ) do
		Move( body, x_axis, -2, 3 )
		Turn( body, y_axis, -.3, 1 ) -- right
		Turn( head, y_axis, .3, 1 )
		Turn( head, z_axis, tiny, .5 ) -- right
		
		Turn( lshoulder, x_axis, -langle/2, lspeed/3 )
		Turn( lforearm, x_axis, -langle, lspeed/2 )
		
		Turn( rshoulder, x_axis, langle/2, lspeed/3 )
		Turn( rforearm, x_axis, 0, lspeed/2 )
		
		Turn( lthigh, x_axis, langle, lspeed ) -- backward
		Turn( lthigh, y_axis, .3, 1 )
		Turn( lshin, x_axis, 0, lspeed )
		
		Turn( rthigh, x_axis, -langle, lspeed ) -- forward
		Turn( rthigh, y_axis, .3, 1 )
		Turn( rshin, x_axis, langle, lspeed )
		WaitForTurn( lthigh, x_axis )
		Sleep( 100 )
		--Part 2 ---------------------------------------------------------
		
		Move( body, x_axis, 2, 3 )
		Turn( body, y_axis, .3, 1 )
		Turn( head, y_axis, -.3, 1 )
		Turn( head, z_axis, -tiny, .5 )
		
		Turn( lshoulder, x_axis, langle/2, lspeed/3 )
		Turn( lforearm, x_axis, 0, lspeed/2 )
		
		Turn( rshoulder, x_axis, -langle/2, lspeed/3 )
		Turn( rforearm, x_axis, -langle, lspeed/2 )
		
		Turn( lthigh, x_axis, -langle, lspeed ) -- forward
		Turn( lthigh, y_axis, -.3, 1 )
		Turn( lshin, x_axis, langle, lspeed )
		
		Turn( rthigh, x_axis, langle, lspeed ) -- backward
		Turn( rthigh, y_axis, -.3, 1 )
		Turn( rshin, x_axis, 0, lspeed )
		WaitForTurn( lthigh, x_axis )
		Sleep( 100 )
	end
end

function script.Create()
	Turn( lshoulder, z_axis, math.rad(-20) )
	Turn( rshoulder, z_axis, math.rad(20) )
	Turn( lthigh, z_axis, math.rad(-10) )
	Turn( rthigh, z_axis, math.rad(10) )
end

function script.StartMoving()
	StartThread( Walk )
end

function script.StopMoving()
	Signal( walk )
	Move( body, x_axis, 0, 5 )
	Turn( body, x_axis, 0, lspeed )
	Turn( body, y_axis, 0, lspeed )
	Turn( body, z_axis, 0, lspeed )
	Turn( head, x_axis, 0, lspeed )
	Turn( head, y_axis, 0, lspeed )
	Turn( head, z_axis, 0, lspeed )
	Turn( lshoulder, x_axis, 0, lspeed )
	Turn( rshoulder, x_axis, 0, lspeed )
	Turn( lforearm, x_axis, 0, lspeed )
	Turn( rforearm, x_axis, 0, lspeed )
	Turn( lthigh, x_axis, 0, lspeed )
	Turn( rthigh, x_axis, 0, lspeed )
	Turn( lthigh, y_axis, 0, lspeed )
	Turn( rthigh, y_axis, 0, lspeed )
	Turn( lshin,  x_axis, 0, lspeed )
	Turn( rshin,  x_axis, 0, lspeed )
end
--attack
----[[
function script.QueryWeapon1() return flare end

function script.AimFromWeapon1() return flare end

function script.AimWeapon1( heading, pitch )
	Signal( aim )
	SetSignalMask( aim )
	Turn( head, y_axis, heading, 5 )
	Turn( head, x_axis, -pitch, 5 ) 
	WaitForTurn( head, y_axis )
	WaitForTurn( head, x_axis )
	return true
end

function script.FireWeapon1()
	--effects
end
--]]

--construction
----[[
function script.QueryNanoPiece ( ) return flare end

function script.StartBuilding(heading, pitch)
	Turn( head, y_axis, heading, 5 )
	Turn( head, x_axis, -pitch, 1 )
	WaitForTurn( head, y_axis )
	WaitForTurn( head, x_axis )
	SetUnitValue( COB.INBUILDSTANCE, 1 )
end

function script.StopBuilding()
	SetUnitValue( COB.INBUILDSTANCE, 0 )
end
--]]

function script.Killed(recentDamage, maxHealth)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1
	elseif (severity <= .5) then
		return 2
	else
		Explode( head, SFX.EXPLODE )
		return 3
	end
end
