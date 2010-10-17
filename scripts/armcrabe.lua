--ARM CRABRE SCRIPT BY TA-FOREVER (Sephiroth) (http:--www.planetannihilation.com/taforever, http:--www.planetannihilation.com/taan)

include 'constants.lua'

local base = piece 'base' 
local ground = piece 'ground' 
local turret = piece 'turret' 
local blight = piece 'blight' 
local canon = piece 'canon' 
local barrel1 = piece 'barrel1' 
local barrel2 = piece 'barrel2' 
local flare1 = piece 'flare1' 
local flare2 = piece 'flare2' 
local flare3 = piece 'flare3' 
local flare4 = piece 'flare4' 
local flare5 = piece 'flare5' 
local flare6 = piece 'flare6' 
local flare7 = piece 'flare7' 
local rocket = piece 'rocket' 
local leg1 = piece 'leg1' 
local leg2 = piece 'leg2' 
local leg3 = piece 'leg3' 
local leg4 = piece 'leg4' 
local gflash = piece 'gflash' 

local restore_delay = 3000
local gun_0 = 0

local bMoving = false
local bCurled = false
local bCurling = false
local nocurl = false

local base_speed = 1	--gets reset in Create()
 

local SIG_MOVE = 1	
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_CURL = 8
local SIG_UNCURL = 16

smokePiece = {base, turret}

local function Walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while bCurling do Sleep(100) end
	while true do
		--Turn(leg1, y_axis, math.rad(43), math.rad(30)
		Turn(leg1, y_axis, math.rad(0), math.rad(30))
		Turn(leg1, z_axis, math.rad(0), math.rad(30))
		--Turn(leg2, z_axis, math.rad(0), math.rad(30))
		Turn(leg2, z_axis, math.rad(31), math.rad(30))
		Turn(leg3, y_axis, math.rad(34), math.rad(30))
		--Turn(leg3, z_axis, math.rad(31), math.rad(30))
		Turn(leg3, z_axis, math.rad(0), math.rad(30))
		Turn(leg4, y_axis, math.rad(-40), math.rad(30))
		--Turn(leg4, z_axis, math.rad(-31), math.rad(30))
		Turn(leg4, z_axis, math.rad(0), math.rad(30))
		Turn(base, z_axis, math.rad(2), math.rad(5))
		Sleep(300)
				
		Turn(leg1, z_axis, math.rad(39), math.rad(30))
		Turn(leg2, y_axis, math.rad(34), math.rad(30))
		Turn(leg2, z_axis, math.rad(31), math.rad(30))
		Turn(leg3, y_axis, math.rad(0), math.rad(30))
		Turn(leg3, z_axis, math.rad(0), math.rad(30))
		Turn(leg4, y_axis, math.rad(0), math.rad(30))
		Turn(base, z_axis, math.rad(-2), math.rad(5))
		Sleep(300)
				
		Turn(leg1, y_axis, math.rad(55), math.rad(30))
		Turn(leg1, z_axis, math.rad(31), math.rad(30))
		Turn(leg2, y_axis, math.rad(34), math.rad(30))
		Turn(leg2, z_axis, math.rad(0), math.rad(30))
		Turn(leg3, z_axis, math.rad(31), math.rad(30))
		Turn(leg4, y_axis, math.rad(0), math.rad(30))
		Turn(leg4, z_axis, math.rad(-31), math.rad(30))
		Turn(base, z_axis, math.rad(2), math.rad(5))
		Sleep(300)
		
		Turn(leg1, y_axis, math.rad(46), math.rad(30))
		Turn(leg1, z_axis, math.rad(0), math.rad(30))
		Turn(leg2, y_axis, math.rad(0), math.rad(30))
		Turn(leg2, z_axis, math.rad(0), math.rad(30))
		Turn(leg3, y_axis, math.rad(37), math.rad(30))
		Turn(leg3, z_axis, math.rad(34), math.rad(30))
		Turn(leg4, y_axis, math.rad(-40), math.rad(30))
		Turn(leg4, z_axis, math.rad(-31), math.rad(30))
		--Turn(base, z_axis, math.rad(-2), math.rad(5)
		Sleep(300)
	end
end

local function Curl()
	if nocurl then return end
	--Spring.Echo("Initiating curl")
	Signal( SIG_UNCURL)
	SetSignalMask( SIG_CURL)
	
	SetUnitValue(COB.MAX_SPEED, 0.1)
	bCurling = true
	
	Turn( leg1 , y_axis, math.rad(45), math.rad(35) )
	Turn( leg4 , y_axis, math.rad(-45), math.rad(35) )
	Turn( leg2 , y_axis, math.rad(-45), math.rad(35) )
	Turn( leg3 , y_axis, math.rad(45), math.rad(35) )
	
	
	Turn( leg1 , z_axis, math.rad(-(-45)), math.rad(35) )
	Turn( leg4 , z_axis, math.rad(-(45)), math.rad(35) )
	-- raise legs (back)
	Turn( leg2 , z_axis, math.rad(-(-40)), math.rad(35) )
	Turn( leg3 , z_axis, math.rad(-(40)), math.rad(35) )

	
	Turn(leg2 , x_axis, math.rad(-180), math.rad(105))
	Turn(leg3 , x_axis, math.rad(-180), math.rad(105))
	
	Turn(leg1 , x_axis, math.rad(-180), math.rad(95))
	Turn(leg4 , x_axis, math.rad(-180), math.rad(95))

	Move( canon , y_axis, 4 , 1 )
	Move( base , y_axis, -2 , 1 )
	Move( base , z_axis, -2 , 1 )

    WaitForTurn(leg1, x_axis)
    WaitForTurn(leg2, x_axis)
    WaitForTurn(leg3, x_axis)
    WaitForTurn(leg4, x_axis)
        
    WaitForTurn(leg1, y_axis)
    WaitForTurn(leg2, y_axis)
    WaitForTurn(leg3, y_axis)
    WaitForTurn(leg4, y_axis)
        
    WaitForTurn(leg1, z_axis)
    WaitForTurn(leg2, z_axis)
    WaitForTurn(leg3, z_axis)
    WaitForTurn(leg4, z_axis)    
	
   	bCurled = true
   	bCurling = false
	SetUnitValue(COB.ARMORED,1)
end

local function ResetLegs()
	--Spring.Echo("Resetting legs")
	Turn( leg1 , x_axis, 0, math.rad(95) )
	Turn( leg2 , x_axis, 0, math.rad(95) )
	Turn( leg3 , x_axis, 0, math.rad(95) )
	Turn( leg4 , x_axis, 0, math.rad(95) )
	
	Turn( leg1 , y_axis, 0, math.rad(35) )
	Turn( leg2 , y_axis, 0, math.rad(35) )
	Turn( leg3 , y_axis, 0, math.rad(35) )
	Turn( leg4 , y_axis, 0, math.rad(35) )
	
	Turn( leg1 , z_axis, 0, math.rad(25) )
	Turn( leg2 , z_axis, 0, math.rad(25) )
	Turn( leg3 , z_axis, 0, math.rad(25) )
	Turn( leg4 , z_axis, 0, math.rad(25) )
end

local function Uncurl()
	--Spring.Echo("Initiating uncurl")
	Signal( SIG_CURL) 
	SetSignalMask( SIG_UNCURL)
	bCurled = false
	bCurling = true
	SetUnitValue(COB.ARMORED,0)
	
	ResetLegs()
	
	Move( canon , y_axis, 0 , 1 )
	Move( base , y_axis, 0 , 1 )
	Move( base , z_axis, 0 , 1 )
    
    WaitForTurn(leg1, x_axis)
    WaitForTurn(leg2, x_axis)
    WaitForTurn(leg3, x_axis)
    WaitForTurn(leg4, x_axis)
        
    WaitForTurn(leg1, y_axis)
    WaitForTurn(leg2, y_axis)
    WaitForTurn(leg3, y_axis)
    WaitForTurn(leg4, y_axis)
        
    WaitForTurn(leg1, z_axis)
    WaitForTurn(leg2, z_axis)
    WaitForTurn(leg3, z_axis)
    WaitForTurn(leg4, z_axis)    
	
    SetUnitValue(COB.MAX_SPEED, base_speed)
    bCurling = false
end

local function BlinkingLight()
	while GetUnitValue(COB.BUILD_PERCENT_LEFT) do
		Sleep( 3000)
	end
	while true do
		EmitSfx( blight,  1024+2 )
		Sleep( 2100)
	end
end

local function CurlDelay()	--workaround for crabe getting stuck in fac
	while GetUnitValue(COB.BUILD_PERCENT_LEFT) do
		Sleep( 1000)
	end
	Sleep( 3000)
	nocurl = false
end

function script.Create()
	base_speed = GetUnitValue(COB.MAX_SPEED)
	--set ARMORED to false
	Hide( flare1)
	Hide( flare2)
	Hide( flare3)
	Hide( flare4)
	Hide( flare5)
	Hide( flare6)
	Hide( flare7)
	
	--StartThread(MotionControl)
	StartThread(SmokeUnit)
	StartThread(BlinkingLight)
	--StartThread(CurlDelay)
end

local function CurlControl()
	if GetUnitValue(COB.BUILD_PERCENT_LEFT) == 0 then
		ResetLegs()
		Sleep(1000)
		if not (bMoving or bCurled) then StartThread(Curl) end
	end
end

function script.StartMoving()
	--Spring.Echo("Unit started moving")
	bMoving = true
	StartThread(Walk)
	if bCurled and not bCurling then StartThread(Uncurl) end
end

function script.StopMoving()
	--Spring.Echo("Unit stopped moving")
	bMoving = false
	Signal(SIG_MOVE)
	StartThread(CurlControl)
end

local function Rock(anglex, anglez)	
	Turn( base , z_axis, -anglex, math.rad(50) )
	Turn( base , x_axis, anglez, math.rad(50) )
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, 0, math.rad(20) )
	Turn( base , x_axis, 0, math.rad(20) )
end
	
function script.RockUnit(anglex, anglez)
	StartThread(Rock, math.rad(anglex), math.rad(anglez))
end

local function RestoreAfterDelay1()
	Sleep( 3000)
	Turn( turret , y_axis, 0, math.rad(70) )
	Turn( canon , x_axis, 0, math.rad(50) )
end

local function RestoreAfterDelay2()
	Sleep( 3000)
	Turn( rocket , y_axis, 0, math.rad(70) )
	Turn( rocket , x_axis, 0, math.rad(50) )
end

function script.AimWeapon1(heading,pitch)
	Signal( SIG_AIM1)
	SetSignalMask( SIG_AIM1)
	Turn( turret , y_axis, heading, math.rad(70) )
	Turn( canon , x_axis, -pitch, math.rad(50) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(canon, x_axis)
	StartThread(RestoreAfterDelay1)
	return (not bCurling)
end

function script.AimWeapon2(heading,pitch)
	Signal( SIG_AIM2)
	SetSignalMask( SIG_AIM2)
	Turn( rocket , y_axis, math.rad(heading ), math.rad(190) )
	Turn( rocket , x_axis, 0, math.rad(150) )
	WaitForTurn(rocket, y_axis)
	WaitForTurn(rocket, x_axis)
	StartThread(RestoreAfterDelay2)
	return(true)
end

function script.FireWeapon1()
	Move( barrel1 , z_axis, -1  )
	EmitSfx( flare1,  1024+0 )	
	EmitSfx( gflash,  1024+1 )
	--Show( flare1)
	--Sleep( 150)
	--Hide( flare1)
	Move( barrel2 , z_axis, -1  )
	WaitForMove(barrel2, z_axis)
	Move( barrel1 , z_axis, 0 , 3 )
	Move( barrel2 , z_axis, 0 , 3 )
end

function script.FireWeapon2()
	if gun_0 == 0  then
		Show( flare2)
		Show( flare5)
		Sleep( 150)
		Hide( flare2)
		Hide( flare5)
	elseif gun_0 == 1  then
		Show( flare3)
		Show( flare6)
		Sleep( 150)
		Hide( flare3)
		Hide( flare6)
	else
		Show( flare4)
		Show( flare7)
		Sleep( 150)
		Hide( flare4)
		Hide( flare7)
		end
	gun_0 = gun_0 + 1
	if gun_0 == 3 then
		gun_0 = 0
	end
end

function script.AimFromWeapon(num)
	if num == 1 then return turret
	else return rocket end
end

function script.QueryWeapon(num)
	if num == 1 then return flare1
	else
		if gun_0==0 then piecenum=flare2 
		elseif gun_0==1 then piecenum=flare3 
		else piecenum=flare4 end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		return 1
	elseif (severity <= .50 ) then
		Explode(base, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(leg3, sfxNone)
		Explode(leg4, sfxNone)
		return 1
	elseif (severity <= .99 ) then
		Explode(base, sfxShatter)
		Explode(leg1, sfxShatter)
		Explode(leg2, sfxShatter)
		Explode(leg3, sfxShatter)
		Explode(leg4, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(leg1, sfxShatter)
		Explode(leg2, sfxShatter)
		Explode(leg3, sfxShatter)
		Explode(leg4, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(barrel, sfxFall + sfxSmoke + sfxFire)
		return 3
	end
end
