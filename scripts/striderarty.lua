include "constants.lua"

local torso = piece 'torso' 
local pelvis = piece 'pelvis' 
local rupleg = piece 'rupleg' 
local rleg = piece 'rleg' 
local rfoot = piece 'rfoot' 
local rtoer = piece 'rtoer' 
local rtoef1 = piece 'rtoef1' 
local rtoef2 = piece 'rtoef2' 
local lleg = piece 'lleg' 
local lupleg = piece 'lupleg' 
local lfoot = piece 'lfoot' 
local ltoer = piece 'ltoer' 
local ltoef1 = piece 'ltoef1' 
local ltoef2 = piece 'ltoef2' 
local launchers = piece 'launchers' 
local llauncher = piece 'llauncher' 
local lfire1 = piece 'lfire1' 
local lfire2 = piece 'lfire2' 
local lfire3 = piece 'lfire3' 
local lfire4 = piece 'lfire4' 
local lfire5 = piece 'lfire5' 
local lfire6 = piece 'lfire6' 
local lfire7 = piece 'lfire7' 
local lfire8 = piece 'lfire8' 
local lfire9 = piece 'lfire9' 
local lfire10 = piece 'lfire10' 
local lfire11 = piece 'lfire11' 
local lfire12 = piece 'lfire12' 
local lfire13 = piece 'lfire13' 
local lfire14 = piece 'lfire14' 
local lfire15 = piece 'lfire15' 
local lfire16 = piece 'lfire16' 
local lfire17 = piece 'lfire17' 
local lfire18 = piece 'lfire18' 
local lfire19 = piece 'lfire19' 
local lfire20 = piece 'lfire20' 
local rlauncher = piece 'rlauncher' 
local rfire1 = piece 'rfire1' 
local rfire2 = piece 'rfire2' 
local rfire3 = piece 'rfire3' 
local rfire4 = piece 'rfire4' 
local rfire5 = piece 'rfire5' 
local rfire6 = piece 'rfire6' 
local rfire7 = piece 'rfire7' 
local rfire8 = piece 'rfire8' 
local rfire9 = piece 'rfire9' 
local rfire10 = piece 'rfire10' 
local rfire11 = piece 'rfire11' 
local rfire12 = piece 'rfire12' 
local rfire13 = piece 'rfire13' 
local rfire14 = piece 'rfire14' 
local rfire15 = piece 'rfire15' 
local rfire16 = piece 'rfire16' 
local rfire17 = piece 'rfire17' 
local rfire18 = piece 'rfire18' 
local rfire19 = piece 'rfire19' 
local rfire20 = piece 'rfire20' 





--MAKE SURE FIRE POINTS REMAIN CONSECUTIVEnot 

local  bMoving, bAiming, isReady, gun_1, gun_1_side, Static_Var_3

-- Signal definitions
local SIG_AIM = 4


--SmokeUnit(healthpercent, Sleep(time, smoketype)
--
--	while  get BUILD_PERCENT_LEFT  do
--	
--		sleep 400)
--	end
--	while  true  do
--	
--		healthpercent = get HEALTH
--		if  healthpercent < 66  then
--		
--			smoketype = 256 + sfx2
--			if  1, 66 ) < healthpercent  then
--			
--				smoketype = 256 + sfx1
--			end
--			EmitSfx( torso,  smoketype )
--		end
--		Sleep(time = healthpercent * 50)
--		if  Sleep(time < 200  then
--		
--			sleeptime = 200)
--		end
--		Sleep( sleeptime)
--	end
--end

function walk()

	if  bMoving == true  then
		
		Turn( lupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-15.016484), math.rad(70.016484) )
		Turn( rfoot , x_axis, math.rad(5), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(-10), math.rad(70.016484) )

		Turn( torso , x_axis, math.rad(-1), math.rad(5) )
		Sleep( 304)
	end
		
	if  bMoving == true  then
		
		Turn( lfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( rfoot , x_axis, math.rad(10), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( ltoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Turn( rtoef1 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef2 , x_axis, 0, math.rad(100.021978) )
		Sleep( 360)
	end
		
	if  bMoving == true  then
			
		Turn( rtoer , x_axis, 0, math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(3) )
		Turn( lupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
		Turn( lleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
		Sleep( 650)
	end
		
	if  bMoving == true  then
		
		Turn( rfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( lleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( ltoef1 , x_axis, 0, math.rad(100.021978) )
	    Turn( ltoef2 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Sleep( 360)
	end
		
	if  bMoving == true  then
		
		Turn( ltoer , x_axis, 0, math.rad(100.021978) )
		Move( pelvis , y_axis, 4 , 2 )
		Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
		Turn( lupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
		Turn( rleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
	
		Turn( torso , y_axis, math.rad(2.5), math.rad(12) )
		Turn( torso , x_axis, math.rad(1), math.rad(6) )
		Sleep( 650)
	end
	
	if  bMoving == true  then
				
		Turn( lfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( rfoot , x_axis, math.rad(20.016484), math.rad(70.016484) )
		Turn( rleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( ltoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Turn( rtoef1 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef2 , x_axis, 0, math.rad(100.021978) )
		Sleep( 360)
	end
			
	if  bMoving == true  then
		
		Turn( rtoer , x_axis, 0, math.rad(100.021978) )
		Move( pelvis , y_axis, 4 , 2 )
		Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(8) )
		Turn( lupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
		Turn( lleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
		
		Turn( torso , y_axis, math.rad(-2.5), math.rad(12) )
		Turn( torso , x_axis, math.rad(-1), math.rad(6) )
		Sleep( 650)
	end

	if  bMoving == true  then
		
		Turn( rfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( lleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( ltoef1 , x_axis, 0, math.rad(100.021978) )
		Turn( ltoef2 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Sleep( 360)
	end
	Turn( ltoer , x_axis, 0, math.rad(100.021978) )
	Move( pelvis , y_axis, 4 , 2 )
	Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
	Sleep( 2)
end

function walklegs()

		if  bMoving == true  then
		
		Turn( lupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-15.016484), math.rad(70.016484) )
		Turn( rfoot , x_axis, math.rad(5), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(-10), math.rad(70.016484) )
		Sleep( 304)
		end
		
	if  bMoving == true  then
		
		Turn( lfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( rfoot , x_axis, math.rad(10), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( ltoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( ltoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Turn( rtoef1 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef2 , x_axis, 0, math.rad(100.021978) )		
		Sleep( 360)
	end
		
	if  bMoving == true  then
			
		Turn( rtoer , x_axis, 0, math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(3) )
		Turn( lupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
		Turn( lleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
		Sleep( 650)
	end
		
	if  bMoving == true  then
			
		Turn( rfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Turn( lleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
		Move( pelvis , y_axis, 0 , 2 )
		Turn( ltoef1 , x_axis, 0, math.rad(100.021978) )
		Turn( ltoef2 , x_axis, 0, math.rad(100.021978) )
		Turn( rtoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
		Turn( rtoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
		Sleep( 360)
	end
		
	if  bMoving == true  then
			
		Turn( ltoer , x_axis, 0, math.rad(100.021978) )
		Move( pelvis , y_axis, 2 , 2 )
		Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
		Turn( lupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
		Turn( rleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
		Sleep( 650)
	end
	
		if  bMoving == true  then
					
			Turn( lfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
			Turn( rfoot , x_axis, math.rad(20.016484), math.rad(70.016484) )
			Turn( rleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
			Move( pelvis , y_axis, 0 , 2 )
			Turn( ltoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
			Turn( ltoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
			Turn( ltoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
			Turn( rtoef1 , x_axis, 0, math.rad(100.021978) )
			Turn( rtoef2 , x_axis, 0, math.rad(100.021978) )
			Sleep( 360)
		end
			
		if  bMoving == true  then
			
			Turn( rtoer , x_axis, 0, math.rad(100.021978) )
			Move( pelvis , y_axis, 2 , 2 )
			Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(8) )
			Turn( lupleg , x_axis, math.rad(-20.016484), math.rad(50.010989) )
			Turn( rupleg , x_axis, math.rad(20.016484), math.rad(50.010989) )
			Turn( rfoot , x_axis, math.rad(-20.016484), math.rad(130.027473) )
			Turn( lleg , x_axis, math.rad(-20.016484), math.rad(100.021978) )
		    Sleep( 650)
		end

		if  bMoving == true  then
			
			Turn( rfoot , x_axis, math.rad(20.016484), math.rad(100.021978) )
			Turn( lleg , x_axis, math.rad(20.016484), math.rad(100.021978) )
			Move( pelvis , y_axis, 0 , 2 )
			Turn( ltoef1 , x_axis, 0, math.rad(100.021978) )
			Turn( ltoef2 , x_axis, 0, math.rad(100.021978) )
			Turn( rtoef1 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
			Turn( rtoef2 , x_axis, math.rad(22.5016484), math.rad(100.021978) )
			Turn( rtoer , x_axis, math.rad(-22.5016484), math.rad(100.021978) )
			Sleep( 360)
		end
			Turn( ltoer , x_axis, 0, math.rad(100.021978) )
			Move( pelvis , y_axis, 2 , 2 )
			Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
			Sleep( 2)
end


function MotionControl(moving, aiming, justmoved)
	justmoved = true
	while  true  do
	
		moving = bMoving
		aiming = bAiming
		if  moving  then
		
			if  aiming  then
			
				Static_Var_3 = 1
				 walklegs()
			end
			if  not aiming  then
			
				Static_Var_3 = 0
				 walk()
			end
			justmoved = true
		end
		if  not moving  then
		
			Static_Var_3 = 1
			if  justmoved  then
			
					Turn( lupleg , x_axis, 0, math.rad(50.010989) )
					Turn( rupleg , x_axis, 0, math.rad(50.010989) )
					Turn( lleg , x_axis, 0, math.rad(100.021978) )
					Turn( rleg , x_axis, 0, math.rad(100.021978) )
					Move( pelvis , y_axis, 0 , 20 )
					Turn( pelvis , z_axis, math.rad(-(0)), math.rad(20) )
					Turn( rtoef1 , x_axis, 0, math.rad(100.021978) )
					Turn( rtoef2 , x_axis, 0, math.rad(100.021978) )
					Turn( rtoer , x_axis, 0, math.rad(100.021978) )
					Turn( ltoef1 , x_axis, 0, math.rad(100.021978) )
                	Turn( ltoef2 , x_axis, 0, math.rad(100.021978) )
					Turn( ltoer , x_axis, 0, math.rad(100.021978) )
					Turn( rfoot , x_axis, 0, math.rad(100.021978) )
					Turn( lfoot , x_axis, 0, math.rad(100.021978) )
				if  not aiming  then
				
				Turn( torso , y_axis, 0, math.rad(100.021978) )
				Turn( torso , x_axis, 0, math.rad(20) )
				end
				justmoved = false
			end
			Sleep( 100)
		end
	end
end

function script.Create()

	Hide(rfire1)
	Hide(lfire1)
	bMoving = false
	bAiming = false
	isReady = 1
	gun_1 = 1
	gun_1_side = 0
	StartThread(MotionControl)
	StartThread(GG.Script.SmokeUnit, unitID, {torso})
    Turn( ltoef1 , y_axis, math.rad(45) )
    Turn( ltoef2 , y_axis, math.rad(-45) )
    Turn( rtoef1 , y_axis, math.rad(45) )
    Turn( rtoef2 , y_axis, math.rad(-45) )
end

function script.StartMoving()
    bMoving = true    
    --StartThread(walk)
end

function script.StopMoving()
    bMoving = false
	--StartThread(RestoreLegs)
end

local function SweetSpot(piecenum)

	piecenum = torso
end

function RestoreLegs()
    if bMoving == false then
        Turn(torso , y_axis, 0, math.rad(90.000000))
        Turn(launchers , x_axis, 0, math.rad(45.000000))
        --WaitForTurn(torso, y_axis)
        --WaitForTurn(launchers, x_axis)
    end
    bAiming = false
    Sleep(2)
end

function RestoreAfterDelay()
	Sleep(3000)
	Turn(torso , y_axis, 0, math.rad(90.000000))
	Turn(launchers , x_axis, 0, math.rad(45.000000))
	WaitForTurn(torso, y_axis)
	WaitForTurn(launchers, x_axis)
	bAiming = false
end

function script.AimFromWeapon1()
	return launchers
end

function script.FireWeapon1() 
	gun_1 = -1
	gun_1_side = 1
end

function script.Shot1() 
	if gun_1_side then
		gun_1 = gun_1 + 1
	end
	gun_1_side = not gun_1_side
end

function script.QueryWeapon1() 
    local piecenum
	if gun_1 >= 0 and gun_1 < 20 then 
		if gun_1_side then
			piecenum = (rfire1 + gun_1)
		else 
			piecenum = (lfire1 + gun_1)
		end
	else 
		piecenum = launchers
    end
    return piecenum
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	bAiming = true
	while not isReady do
		Sleep(100)
	end
	Turn(torso , y_axis, heading, math.rad(90.000000) )
	Turn(launchers , x_axis, 0 - pitch, math.rad(45.000000) )
	WaitForTurn(torso, y_axis)
	WaitForTurn(launchers, x_axis)
	StartThread(RestoreAfterDelay)
	return 1
end

function script.Killed(recentDamage, maxHealth)
    local severity = recentDamage/maxHealth
	Hide( rfire1)
	Hide( lfire1)
	if  severity <= 0.25  then
		Explode( lfoot, SFX.SMOKE + SFX.EXPLODE)
		Explode( lleg, SFX.SMOKE + SFX.EXPLODE)
		Explode( rfoot, SFX.SMOKE + SFX.EXPLODE)
		Explode( rleg, SFX.SMOKE + SFX.EXPLODE)
		Explode( torso, SFX.FIRE + SFX.EXPLODE)
		return 1
    elseif  severity <= 0.50  then
		Explode( lfoot, SFX.FALL + SFX.EXPLODE)
		Explode( lleg, SFX.FALL + SFX.EXPLODE)
		Explode( pelvis, SFX.FALL + SFX.EXPLODE)
		Explode( rfoot, SFX.FALL + SFX.EXPLODE)
		Explode( rleg, SFX.FALL + SFX.EXPLODE)
		Explode( torso, SFX.SHATTER + SFX.EXPLODE)
		return 1
	elseif  severity <= 0.99  then
		Explode( lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode( lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode( pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode( rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode( rleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode( torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	else
	    Explode( lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	    Explode( lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
        Explode( pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	    Explode( rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	    Explode( rleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	    Explode( torso, SFX.SHATTER + SFX.EXPLODE)
        return 2
    end
end