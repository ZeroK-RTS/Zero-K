include 'constants.lua'

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local anteny = piece 'anteny'
local cervena = piece 'cervena'
local modra = piece 'modra'
local zelena = piece 'zelena'
local ozdoba = piece 'ozdoba'
local spodni_zebra = piece 'spodni_zebra'
local vrchni_zebra = piece 'vrchni_zebra'
local trubky = piece 'trubky'

local solid_ground = piece 'solid_ground' 
local gear = piece 'gear'
local plovak = piece 'plovak'
local gear001 = piece 'gear001'
local gear002 = piece 'gear002'
local rotating_bas = piece 'rotating_bas'
local mc_rocket_ho = piece 'mc_rocket_ho'
local raketa = piece 'raketa'
local raketa_l = piece 'raketa_l'
local raketa002 = piece 'raketa002'
local raketa002_l = piece 'raketa002_l'
local raketa004 = piece 'raketa004'
local raketa004_l = piece 'raketa004_l'
local raketa006 = piece 'raketa006'
local raketa006_l = piece 'raketa006_l'
local raketa007 = piece 'raketa007'
local raketa007_l = piece 'raketa007_l'
local raketa008 = piece 'raketa008'
local raketa008_l = piece 'raketa008_l'
local raketa009 = piece 'raketa009'
local raketa009_l = piece 'raketa009_l'
local raketa010 = piece 'raketa010'
local raketa010_l = piece 'raketa010_l'
local raketa011 = piece 'raketa011'
local raketa011_l = piece 'raketa011_l'
local raketa012 = piece 'raketa012'
local raketa012_l = piece 'raketa012_l'
local raketa013 = piece 'raketa013'
local raketa013_l = piece 'raketa013_l'
local raketa014 = piece 'raketa014'
local raketa014_l = piece 'raketa014_l'
local raketa026 = piece 'raketa026'
local raketa026_l = piece 'raketa026_l'
local raketa027 = piece 'raketa027'
local raketa027_l = piece 'raketa027_l'
local flare = piece 'flare_r'
local flare2 = piece 'flare_l'
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--local flares = { flare_l, flare_r }

--------------------------------------------------------------------------------
-- constants and variables
--------------------------------------------------------------------------------
smokePiece = {rotating_bas, mc_rocket_ho}

local TURN_SPEED = 1.5
local TILT_SPEED = 1.2
local RELOAD_SPEED = 20
local MOV_DEL = 50

--local inMove = false
local gun = true
local loaded = true
local lastHeading = 0
local rotateWise = 1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- signals
--------------------------------------------------------------------------------
local SIG_AIM = 1
local SIG_Idle = 2
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Methods and functions
--------------------------------------------------------------------------------
local function IdleAnim()
	Signal(SIG_Idle)
	SetSignalMask(SIG_Idle)
	while true do
		EmitSfx(zelena, 1025)	
		
		heading = math.rad(math.random(-90, 90))
		if(lastHeading > heading) then
			rotateWise = 1
		else
			rotateWise = -1
		end
		lastHeading = heading

		if(gun and not loaded) then
			rotate()
			loaded = true
		end
		
		Spin(gear, y_axis, TURN_SPEED * 5 * rotateWise)
		Spin(gear001, y_axis, TURN_SPEED * 5 * rotateWise)
		Spin(gear002, y_axis, TURN_SPEED * 5 * rotateWise)
	
		Turn(rotating_bas, y_axis, heading, math.rad(60))
		Turn(mc_rocket_ho, x_axis, math.rad(math.random(-25, 0)), math.rad(60))
		
		WaitForTurn(rotating_bas, y_axis)
		EmitSfx(modra, 1026)
		StopSpin(gear, y_axis)
		StopSpin(gear001, y_axis)
		StopSpin(gear002, y_axis)
		
		
		Sleep(math.random(100, 6500))
	end
end

local function RestoreAfterDelay()
	--Sleep(2000)
	--StartThread(IdleAnim)
end

function script.Create()	
	--Spring.Echo("Vytvořeno")
	--Hide(flare_l)
	--Hide(flare_r)
	
	if onWater() then
		Hide(solid_ground)
	else
		Hide(plovak)
	end
	
	StartThread(SmokeUnit)
	
	--Spin(rotating_bas, y_axis, 0.5)
	
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end	
	StartThread(IdleAnim)
	
	--while true do
	--	if not(inMove) then
	--		rotate()
	--	end
	--end
	

	--Turn(rotating_bas, y_axis, rad(-90), 0.5)
end

function rotate()	
	resetRockets()	
	
	Show(raketa014_l)
	Show(raketa014)
	
	--inMove = true	
		
	--1
	Move(raketa014, y_axis, -3.9, RELOAD_SPEED)
	Move(raketa014, x_axis, -2.5, RELOAD_SPEED)
	Move(raketa014, z_axis, 4, RELOAD_SPEED)
	Move(raketa014_l, y_axis, -3.9, RELOAD_SPEED)
	Move(raketa014_l, x_axis, 2.5, RELOAD_SPEED)
	Move(raketa014_l, z_axis, 4, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--2
	Move(raketa013, y_axis, -3.6, RELOAD_SPEED)
	Move(raketa013, x_axis, -1.5, RELOAD_SPEED)
	Move(raketa013, z_axis, 3.3, RELOAD_SPEED)
	Move(raketa013_l, y_axis, -3.6, RELOAD_SPEED)
	Move(raketa013_l, x_axis, 1.5, RELOAD_SPEED)
	Move(raketa013_l, z_axis, 3.3, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--3
	Move(raketa012, y_axis, -4.1, RELOAD_SPEED)
	Move(raketa012, x_axis, -0.3, RELOAD_SPEED)
	Move(raketa012, z_axis, 2.5, RELOAD_SPEED)
	Move(raketa012_l, y_axis, -4.1, RELOAD_SPEED)
	Move(raketa012_l, x_axis, 0.3, RELOAD_SPEED)
	Move(raketa012_l, z_axis, 2.5, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--4
	Move(raketa011, y_axis, -4.6, RELOAD_SPEED)
	Move(raketa011, x_axis, 1.6, RELOAD_SPEED)
	Move(raketa011, z_axis, 1.9, RELOAD_SPEED)
	Move(raketa011_l, y_axis, -4.6, RELOAD_SPEED)
	Move(raketa011_l, x_axis, -1.6, RELOAD_SPEED)
	Move(raketa011_l, z_axis, 1.9, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--5
	Move(raketa010, y_axis, -4.2, RELOAD_SPEED)
	Move(raketa010, x_axis, 2.2, RELOAD_SPEED)
	Move(raketa010, z_axis, 0.2, RELOAD_SPEED)
	Move(raketa010_l, y_axis, -4.2, RELOAD_SPEED)
	Move(raketa010_l, x_axis, -2.2, RELOAD_SPEED)
	Move(raketa010_l, z_axis, 0.2, RELOAD_SPEED)
	
	
	Sleep(MOV_DEL)
	
	--6
	Move(raketa009, y_axis, -2.8, RELOAD_SPEED)
	Move(raketa009, x_axis, 4.2, RELOAD_SPEED)
	Move(raketa009, z_axis, 0.4, RELOAD_SPEED)
	Move(raketa009_l, y_axis, -2.8, RELOAD_SPEED)
	Move(raketa009_l, x_axis, -4.2, RELOAD_SPEED)	
	Move(raketa009_l, z_axis, 0.4, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--7
	Move(raketa008, y_axis, -1, RELOAD_SPEED)
	Move(raketa008, x_axis, 5.2, RELOAD_SPEED)
	Move(raketa008, z_axis, -0.4, RELOAD_SPEED)
	Move(raketa008_l, y_axis, -1, RELOAD_SPEED)
	Move(raketa008_l, x_axis, -5.2, RELOAD_SPEED)
	Move(raketa008_l, z_axis, -0.4, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--8
	Move(raketa007, y_axis, 1.6, RELOAD_SPEED)
	Move(raketa007, x_axis, 4.6, RELOAD_SPEED)
	Move(raketa007, z_axis, -1.8, RELOAD_SPEED)
	Move(raketa007_l, y_axis, 1.6, RELOAD_SPEED)
	Move(raketa007_l, x_axis, -4.6, RELOAD_SPEED)
	Move(raketa007_l, z_axis, -1.8, RELOAD_SPEED)
	
	Sleep(MOV_DEL)

	--9
	Move(raketa006, y_axis, 3, RELOAD_SPEED)
	Move(raketa006, x_axis, 3.6, RELOAD_SPEED)
	Move(raketa006, z_axis, 0, RELOAD_SPEED)
	Move(raketa006_l, y_axis, 3, RELOAD_SPEED)
	Move(raketa006_l, x_axis, -3.6, RELOAD_SPEED)
	Move(raketa006_l, z_axis, 0, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--10
	Move(raketa027, y_axis, 4, RELOAD_SPEED)
	Move(raketa027, x_axis, 1.2, RELOAD_SPEED)
	Move(raketa027, z_axis, 0, RELOAD_SPEED)
	Move(raketa027_l, y_axis, 4.1, RELOAD_SPEED)
	Move(raketa027_l, x_axis, -1.6, RELOAD_SPEED)
	Move(raketa027_l, z_axis, 0, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--11 !!!switched l&r (again, so its right)
	Move(raketa004, y_axis, 5.2, RELOAD_SPEED)
	Move(raketa004, x_axis, 0.2, RELOAD_SPEED)
	Move(raketa004, z_axis, 0, RELOAD_SPEED)
	Move(raketa004_l, y_axis, 4.2, RELOAD_SPEED)
	Move(raketa004_l, x_axis, -0.8, RELOAD_SPEED)
	Move(raketa004_l, z_axis, 0, RELOAD_SPEED)
	
	Sleep(MOV_DEL)
	
	--12
	Move(raketa002, y_axis, 5, RELOAD_SPEED)
	Move(raketa002, x_axis, 0.2, RELOAD_SPEED)
	Move(raketa002, z_axis, 0, RELOAD_SPEED)
	Move(raketa002_l, y_axis, 4.9, RELOAD_SPEED)
	Move(raketa002_l, x_axis, -0.2, RELOAD_SPEED)
	Move(raketa002_l, z_axis, 0, RELOAD_SPEED)
	
	Sleep(MOV_DEL)	
	
	--14
	Move(raketa, y_axis, 4.8, RELOAD_SPEED)
	Move(raketa, x_axis, 0, RELOAD_SPEED)
	Move(raketa, z_axis, 0, RELOAD_SPEED)
	Move(raketa_l, y_axis, 4.5, RELOAD_SPEED)
	Move(raketa_l, x_axis, 0.2, RELOAD_SPEED)
	Move(raketa_l, z_axis, 0, RELOAD_SPEED)
	
	--inMove = false

end

function resetRockets()
	Move(raketa, z_axis, -5)
	Move(raketa_l, z_axis, -3)
	Move(raketa, y_axis, -5)
	Move(raketa_l, y_axis, -3)
	setZero(raketa002)
	setZero(raketa004)
	setZero(raketa006)
	setZero(raketa007)
	setZero(raketa008)
	setZero(raketa009)
	setZero(raketa010)
	setZero(raketa011)
	setZero(raketa012)
	setZero(raketa013)
	--setZero(raketa014)
	setZero(raketa002_l)
	setZero(raketa004_l)
	setZero(raketa006_l)
	setZero(raketa007_l)
	setZero(raketa008_l)
	setZero(raketa009_l)
	setZero(raketa010_l)
	setZero(raketa011_l)
	setZero(raketa012_l)
	setZero(raketa013_l)
	--setZero(raketa014_l)
	--setZero(raketa026)
	setZero(raketa027)
	--setZero(raketa026_l)
	setZero(raketa027_l)	
end

function setZero(piece) 
	Move(piece, x_axis, 0)
	Move(piece, y_axis, 0)
	Move(piece, z_axis, 0)
end



function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	EmitSfx(cervena, 1024 )
	if(lastHeading > heading) then
		rotateWise = 1
	else
		rotateWise = -1
	end
	lastHeading = heading

	if(gun and not loaded) then
		rotate()
		loaded = true
	end
	
	Turn( rotating_bas , y_axis, heading,  TURN_SPEED )
	
	Spin(gear, y_axis, TURN_SPEED * rotateWise * 5)
	Spin(gear001, y_axis, TURN_SPEED * rotateWise * 5)
	Spin(gear002, y_axis, TURN_SPEED * rotateWise * 5)	
	
	Turn( mc_rocket_ho , x_axis, -pitch,  TILT_SPEED )
	WaitForTurn(rotating_bas, y_axis)
	WaitForTurn(mc_rocket_ho, x_axis)	
	
	StopSpin(gear, y_axis)
	StopSpin(gear001, y_axis)
	StopSpin(gear002, y_axis)
	
	StartThread(RestoreAfterDelay)
	return true
end

function script.Shot(num)	
	StartThread(Bum)
end

function Bum()
	temp = flare
	flare = flare2
	flare2 = temp
	
	if(gun) then
		Hide(raketa026)
				
		Hide(raketa014)	
		setZero(raketa014)
		gun = false		
	else		
		Hide(raketa026_l)
		
		gun = true
		loaded = false	
		Hide(raketa014_l)
		setZero(raketa014_l)
	end
end

function script.QueryWeapon()
	return flare
end

function script.AimFromWeapon() 
	return mc_rocket_ho
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		return 1
	elseif severity <= 0.50  then
		Explode(trubky, sfxFall)
		Explode(raketa027, sfxFall)
		Explode(raketa004, sfxFall)
		Explode(raketa011_l, sfxFall)
		Explode(raketa008_l, sfxFall)
		Explode(raketa009, sfxFall)
		Explode(cervena, sfxFall)
		Explode(modra, sfxFall)
		Explode(zelena, sfxFall)
		Explode(spodni_zebra, sfxFall)
		Explode(vrchni_zebra, sfxFall)
		Explode(mc_rocket_ho, sfxFall)
		Explode(rotating_bas, sfxShatter)
		return 1
	else
		Explode(trubky, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(raketa027, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(raketa004, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(raketa011_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(raketa008_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(raketa009, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(cervena, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(modra, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(zelena, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(spodni_zebra, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(vrchni_zebra, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(mc_rocket_ho, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit)
		Explode(rotating_bas, sfxShatter)
		return 2
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
