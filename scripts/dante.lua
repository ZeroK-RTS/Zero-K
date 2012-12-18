include 'constants.lua'

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base' 
local pelvis = piece 'pelvis' 
local torso = piece 'torso' 
local tail = piece 'tail' 
local flagellum = piece 'flagellum' 
local ruparm = piece 'ruparm' 
local rarm = piece 'rarm' 
local rshield = piece 'rshield' 
local lshield = piece 'lshield' 
local luparm = piece 'luparm' 
local larm = piece 'larm' 
local rupleg = piece 'rupleg' 
local lupleg = piece 'lupleg' 
local lleg = piece 'lleg' 
local rleg = piece 'rleg' 
local rfoot = piece 'rfoot' 
local lfoot = piece 'lfoot' 
local rtoef = piece 'rtoef' 
local rtoer = piece 'rtoer' 
local ltoef = piece 'ltoef' 
local ltoer = piece 'ltoer' 
local rf1 = piece 'rf1' 
local rf2 = piece 'rf2' 
local rf3 = piece 'rf3' 
local rbak1 = piece 'rbak1' 
local rbak2 = piece 'rbak2' 
local lbak1 = piece 'lbak1' 
local lbak2 = piece 'lbak2' 
local lf1 = piece 'lf1' 
local lf2 = piece 'lf2' 
local lf3 = piece 'lf3' 
local flame1 = piece 'flame1' 
local flame2 = piece 'flame2' 
local jet1 = piece 'jet1' 
local jet2 = piece 'jet2' 
local fix = piece 'fix'

smokePiece = {torso, pelvis, flagellum}

local weaponPieces = {
	{aimFrom = torso, query = {rf1, lf1, rf2, lf2, rf3, lf3}, index = 1},
	{aimFrom = torso, query = {flame1, flame2}, index = 1},
	{aimFrom = torso, query = {rf1, lf1, rf2, lf2, rf3, lf3}, index = 1},
	{aimFrom = flagellum, query = {flagellum}, index = 1},
}

local missileEmits = {{lbak1, lbak2}, {rbak1, rbak2}}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_AIM_3 = 8
local SIG_AIM_4 = 16
local SIG_RESTORE = 32
local SIG_RELOAD = 64
local RELOADTIME = 20000
local SALVO_TIME = 1000

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[3] and UnitDefs[unitDefID].weapons[3].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 20*30

local base_speed = 100
--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local dead = false
local armsFree = true
local dgunning = false

local targetHeading = 0
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function RestorePose()
	Turn( torso , x_axis, 0, math.rad(100) )
	
	Turn( lupleg , x_axis, 0, math.rad(100) )
	Turn( rupleg , x_axis, 0, math.rad(100) )		
	Turn( lfoot , x_axis, 0, math.rad(100) )
	Turn( rfoot , x_axis, 0, math.rad(100) )
	Turn( lleg , x_axis, 0, math.rad(100) )
	Turn( rleg , x_axis, 0, math.rad(100) )
	Turn( ltoef , x_axis, 0, math.rad(100) )
	Turn( ltoer , x_axis, 0, math.rad(100) )
	Turn( rtoef , x_axis, 0, math.rad(100) )
	Turn( rtoer , x_axis, 0, math.rad(100) )

	Move(pelvis, y_axis, 0, 5)
end

local function RestoreAfterDelay()
	Signal( SIG_RESTORE)
	SetSignalMask( SIG_RESTORE)
	Sleep(8000)
	--torso	
	if not dead then
		Turn( torso , y_axis, 0, math.rad(100) )
		
		Turn( ruparm , x_axis, 0, math.rad(250) ) 
		Turn( ruparm , y_axis, 0, math.rad(250) ) 
		Turn( ruparm , z_axis, math.rad(-(0)), math.rad(250) ) 
		Turn( rarm , x_axis, 0, math.rad(250) )      --up 2
		Turn( rarm , y_axis, 0, math.rad(250) )  
		Turn( rarm , z_axis, math.rad(-(0)), math.rad(250) )    --up -12
		Turn( flagellum , x_axis, 0, math.rad(90) )
	
		Turn( luparm , x_axis, 0, math.rad(250) )       --up -9
		Turn( luparm , y_axis, 0, math.rad(250) )  
		Turn( luparm , z_axis, math.rad(-(0)), math.rad(250) )  
		Turn( larm , x_axis, 0, math.rad(250) )       --up 5
		Turn( larm , y_axis, 0, math.rad(250) )       --up -3
		Turn( larm , z_axis, math.rad(-(0)), math.rad(250) )       --up 22
		RestorePose()
	end
	armsFree = true
end

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		Turn( lupleg , x_axis, math.rad(20), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-15.016484), math.rad(70.016484) )
		Turn( rfoot , x_axis, math.rad(5), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(-10), math.rad(70.016484) )
		Turn( torso , x_axis, math.rad(-1), math.rad(5) )
		if armsFree then
			Turn( ruparm , y_axis, math.rad(-2.50), math.rad(25) )
			Turn( luparm , y_axis, math.rad(-2.50), math.rad(25) )
		end
		Sleep(304)
		
		Turn( lfoot , x_axis, math.rad(20), math.rad(100) )
		Turn( rfoot , x_axis, math.rad(10), math.rad(50.010989) )
		Turn( rleg , x_axis, math.rad(20), math.rad(100) )
		Turn( ltoef , x_axis, math.rad(22), math.rad(100) )
		Turn( ltoer , x_axis, math.rad(-22), math.rad(100) )
		Turn( rtoef , x_axis, 0, math.rad(100) )
		Sleep(360)
		
		Turn( rtoer , x_axis, 0, math.rad(100) )
		Move( pelvis , y_axis, 0 , 5 )
		Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(3) )
		Turn( lupleg , x_axis, math.rad(-20), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(20), math.rad(50.010989) )
		Turn( rfoot , x_axis, math.rad(-20), math.rad(130.027473) )
		Turn( lleg , x_axis, math.rad(-20), math.rad(100) )
		Sleep(650)
	
		Turn( rfoot , x_axis, math.rad(20), math.rad(100) )
		Turn( lleg , x_axis, math.rad(20), math.rad(100) )
		Move( pelvis , y_axis, 0 , 5 )
		Turn( ltoef , x_axis, 0, math.rad(100) )
		Turn( rtoef , x_axis, math.rad(22), math.rad(100) )
		Turn( rtoer , x_axis, math.rad(-22), math.rad(100) )
		Sleep(360)

		Turn( ltoer , x_axis, 0, math.rad(100) )
		Move( pelvis , y_axis, 10 , 5 )
		Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
		Turn( lupleg , x_axis, math.rad(20), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(-20), math.rad(50.010989) )
		Turn( lfoot , x_axis, math.rad(-20), math.rad(130.027473) )
		Turn( rleg , x_axis, math.rad(-20), math.rad(100) )
		Turn( torso , y_axis, math.rad(2.5), math.rad(12) )
		Turn( torso , x_axis, math.rad(1), math.rad(6) )
		if armsFree then
			Turn( ruparm , y_axis, math.rad(2.5), math.rad(25) )
			Turn( luparm , y_axis, math.rad(2.5), math.rad(25) )
		end
		Sleep(650)
		
		Turn( lfoot , x_axis, math.rad(20), math.rad(100) )
		Turn( rfoot , x_axis, math.rad(20), math.rad(70.016484) )
		Turn( rleg , x_axis, math.rad(20), math.rad(100) )
		Move( pelvis , y_axis, 0 , 5 )
		Turn( ltoef , x_axis, math.rad(22), math.rad(100) )
		Turn( ltoer , x_axis, math.rad(-22), math.rad(100) )
		Turn( rtoef , x_axis, 0, math.rad(100) )
		Sleep(360)
			
		Turn( rtoer , x_axis, 0, math.rad(100) )
		Move( pelvis , y_axis, 10 , 5 )
		Turn( pelvis , z_axis, math.rad(-(-3.50)), math.rad(8) )
		Turn( lupleg , x_axis, math.rad(-20), math.rad(50.010989) )
		Turn( rupleg , x_axis, math.rad(20), math.rad(50.010989) )
		Turn( rfoot , x_axis, math.rad(-20), math.rad(130.027473) )
		Turn( lleg , x_axis, math.rad(-20), math.rad(100) )
		
		Turn( torso , y_axis, math.rad(-2.5), math.rad(12) )
		Turn( torso , x_axis, math.rad(-1), math.rad(6) )
		
		if armsFree then
			Turn( ruparm , y_axis, math.rad(5), math.rad(25) )
			Turn( luparm , y_axis, math.rad(5), math.rad(25) )
		end
		Sleep(650)

		Turn( rfoot , x_axis, math.rad(20), math.rad(100) )
		Turn( lleg , x_axis, math.rad(20), math.rad(100) )
		Move( pelvis , y_axis, 0 , 5 )
		Turn( ltoef , x_axis, 0, math.rad(100) )
		Turn( rtoef , x_axis, math.rad(22), math.rad(100) )
		Turn( rtoer , x_axis, math.rad(-22), math.rad(100) )
		Sleep(360)

		Turn( ltoer , x_axis, 0, math.rad(100) )
		Move( pelvis , y_axis, 10 , 5 )
		Turn( pelvis , z_axis, math.rad(-(3.5)), math.rad(8) )
		Sleep(2)
	end
end


function script.Create()
	base_speed = GetUnitValue(COB.MAX_SPEED)
	Hide( flame1)
	Hide( flame2)
	Hide( rf1)
	Hide( rf2)
	Hide( rf3)
	Hide( lf1)
	Hide( lf2)
	Hide( lf3)
	Hide( jet1)
	Hide( jet2)
	
	StartThread(SmokeUnit)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	RestorePose()
end

function script.AimFromWeapon(num)
	return weaponPieces[num].aimFrom
end

function script.QueryWeapon(num)
	local pieces = weaponPieces[num].query
	return pieces[weaponPieces[num].index]
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		if  dgunning  then return false end
		Signal( SIG_AIM)
		SetSignalMask( SIG_AIM)
		armsFree = false
		Turn( ruparm , x_axis, -pitch - math.rad(20), math.rad(250) )
		Turn( luparm , x_axis, -pitch - math.rad(20), math.rad(250) )
		Turn( torso , y_axis, heading, math.rad(250) )
		Turn( rarm , x_axis, math.rad(20), math.rad(250) )
		Turn( larm , x_axis, math.rad(20), math.rad(250) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)  --need to make surenot 
		return true
	elseif num == 2 then
		if dgunning  then return false end
		Signal( SIG_AIM_2)
		SetSignalMask( SIG_AIM_2)
		Turn( torso , y_axis, heading, math.rad(200) )
		WaitForTurn(torso, y_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 3 then
		--dgunning = true
		Signal( SIG_AIM)
		Signal( SIG_AIM_2)
		Signal( SIG_AIM_3)
		SetSignalMask( SIG_AIM_3)
		armsFree = false
		
		Turn( ruparm , x_axis, -pitch - math.rad(20), math.rad(250) )
		Turn( luparm , x_axis, -pitch - math.rad(20), math.rad(250) )
		Turn( torso , y_axis, heading, math.rad(250) )
		Turn( rarm , x_axis, math.rad(20), math.rad(250) )
		Turn( larm , x_axis, math.rad(20), math.rad(250) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
		targetHeading = heading + GetUnitValue(COB.HEADING)/32768
		StartThread(RestoreAfterDelay)
		Signal( SIG_AIM)
		Signal( SIG_AIM_2)
		--dgunning = false
		return true
	elseif num == 4 then
		if dgunning  then return false end
		Signal( SIG_AIM_4)
		SetSignalMask( SIG_AIM_4)
	
		Turn( flagellum , x_axis, -pitch, math.rad(90) )
		Turn( torso , y_axis, heading, math.rad(250) )
		WaitForTurn(ruparm, x_axis)
		WaitForTurn(flagellum, x_axis)
		WaitForTurn(torso, y_axis)
		StartThread(RestoreAfterDelay)
		return true	
	end
end

function script.Shot(num)
	local weapon = weaponPieces[num]
	local index = weapon.index
	if num == 1 or num == 3 then
		local side = index%2 + 1
		
		EmitSfx(weapon.query[index], 1024)
		EmitSfx(missileEmits[side][1], 1025)
		EmitSfx(missileEmits[side][2], 1025)
	elseif num == 4 then
		GG.LUPS.FlameShot(unitID, unitDefID, _, num)
	end
	weapon.index = index + 1
	if (index + 1) > #weapon.query then
		weapon.index = 1
	end
end

function script.FireWeapon(num)
	if num == 3 then
		local speedmult = 1/(Spring.GetUnitRulesParam(unitID,"slowState") or 1)
		Spring.SetUnitWeaponState(unitID, 0, "reloadFrame", Spring.GetGameFrame() + reloadTime*speedmult)
		dgunning = true
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 0)
		GG.attUnits[unitID] = true
		GG.UpdateUnitAttributes(unitID)
		Sleep(SALVO_TIME)
		dgunning = false
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
		GG.UpdateUnitAttributes(unitID)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = true
	Turn( torso , y_axis, 0, math.rad(200) )
	if  severity <= .50  then
		Turn( base , x_axis, math.rad(71), math.rad(70) )
		Turn( torso , x_axis, math.rad(-31), math.rad(50) )
		Turn( ruparm , x_axis, math.rad(-41), math.rad(50) )
		Turn( ruparm , y_axis, math.rad(-11), math.rad(50) )
		Turn( rarm , x_axis, math.rad(-6), math.rad(50) ) --was 0
		Turn( flagellum , x_axis, math.rad(49), math.rad(50) )
		Turn( flagellum , y_axis, math.rad(14), math.rad(50) )
		Turn( luparm , y_axis, math.rad(54), math.rad(50) )
		Turn( rupleg , x_axis, math.rad(-27), math.rad(50) )
		Turn( rupleg , y_axis, math.rad(-42), math.rad(50) )
		Turn( rupleg , z_axis, math.rad(-(-5)), math.rad(50) )		
		Turn( rleg , x_axis, math.rad(13), math.rad(50) )
		Turn( rleg , y_axis, math.rad(-36), math.rad(50) )
		Turn( rleg , z_axis, math.rad(-(24)), math.rad(50) )	
		Turn( lupleg , y_axis, math.rad(18), math.rad(50) )
		Turn( lleg , x_axis, math.rad(20), math.rad(50) )
		Turn( lleg , y_axis, math.rad(28), math.rad(50) )
		Turn( lfoot , x_axis, math.rad(23), math.rad(50) )
		Sleep(800)
		--EmitSfx( torso,  1027 ) --impact
		--StartThread(burn)
		--Sleep((1000 * rand (2 , 5)))

		Explode(pelvis, sfxNone)
		Explode(luparm, sfxNone)
		Explode(lleg, sfxNone)
		Explode(lupleg, sfxNone)
		Explode(rarm, sfxFall)
		Explode(rleg, sfxNone)
		Explode(ruparm, sfxNone)
		Explode(rupleg, sfxNone)
		Explode(torso, sfxNone)
		return 1
	else
		Explode(pelvis, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(luparm, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lupleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(rarm, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(rleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(ruparm, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(rupleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(torso, SFX.SHATTER + SFX.EXPLODE_ON_HIT )
		return 2
	end
end
