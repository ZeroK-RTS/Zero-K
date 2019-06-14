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

local smokePiece = {torso, pelvis, flagellum}

local weaponPieces = {
	{aimFrom = torso, query = {rf1, lf1, rf2, lf2, rf3, lf3}, index = 1},
	{aimFrom = torso, query = {flame1, flame2}, index = 1},
	{aimFrom = torso, query = {rf1, lf1, rf2, lf2, rf3, lf3}, index = 1},
	{aimFrom = torso, query = {fix}, index = 1},
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
local SIG_IDLE = 64
local RELOADTIME = wd and WeaponDefs[wd].reload*30 or 20*30
local SALVO_TIME = 1000

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[3] and UnitDefs[unitDefID].weapons[3].weaponDef

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local dead = false
local armsFree = true
local dgunning = false

local targetHeading = 0
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Arm Animation

local function RestorePose()
	Turn(torso, x_axis, 0, math.rad(100))
	
	Turn(lupleg, x_axis, 0, math.rad(100))
	Turn(rupleg, x_axis, 0, math.rad(100))		
	Turn(lfoot, x_axis, 0, math.rad(100))
	Turn(rfoot, x_axis, 0, math.rad(100))
	Turn(lleg, x_axis, 0, math.rad(100))
	Turn(rleg, x_axis, 0, math.rad(100))
	Turn(ltoef, x_axis, 0, math.rad(100))
	Turn(ltoer, x_axis, 0, math.rad(100))
	Turn(rtoef, x_axis, 0, math.rad(100))
	Turn(rtoer, x_axis, 0, math.rad(100))
	Turn(pelvis, z_axis, 0, math.rad(100))

	Move(pelvis, y_axis, 0, 25)
end

local function IdleAnim()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)
	Sleep(12000)
	while true do
		Turn(torso, y_axis, math.rad(15), math.rad(60))
		--Turn(larm, y_axis, math.rad(15), math.rad(60))
		--Turn(rarm, y_axis, math.rad(-10), math.rad(60))
		Turn(luparm, x_axis, math.rad(-40), math.rad(120))
		Turn(ruparm, x_axis, 0, math.rad(120))
		Sleep(1500)
		Turn(torso, y_axis, math.rad(-15), math.rad(90))
		--Turn(larm, y_axis, math.rad(10), math.rad(60))
		--Turn(rarm, y_axis, math.rad(-15), math.rad(60))
		Turn(luparm, x_axis, 0, math.rad(120))
		Turn(ruparm, x_axis, math.rad(-40), math.rad(120))
		Sleep(1500)
		Turn(torso, y_axis, 0, math.rad(60))
		--Turn(larm, y_axis, 0, math.rad(60))
		--Turn(rarm, y_axis, 0, math.rad(60))
		Turn(luparm, x_axis, 0, math.rad(120))
		Turn(ruparm, x_axis, 0, math.rad(120))
		Sleep(7000)
	end
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(8000)
	--torso	
	if not dead then
		Turn(torso, y_axis, 0, math.rad(100))
		
		Turn(ruparm, x_axis, 0, math.rad(250)) 
		Turn(ruparm, y_axis, 0, math.rad(250)) 
		Turn(ruparm, z_axis, math.rad(-(0)), math.rad(250)) 
		Turn(rarm, x_axis, 0, math.rad(250))	 --up 2
		Turn(rarm, y_axis, 0, math.rad(250)) 
		Turn(rarm, z_axis, math.rad(-(0)), math.rad(250))	--up -12
		Turn(flagellum, x_axis, 0, math.rad(90))
	
		Turn(luparm, x_axis, 0, math.rad(250))	 --up -9
		Turn(luparm, y_axis, 0, math.rad(250)) 
		Turn(luparm, z_axis, math.rad(-(0)), math.rad(250)) 
		Turn(larm, x_axis, 0, math.rad(250))	 --up 5
		Turn(larm, y_axis, 0, math.rad(250))	 --up -3
		Turn(larm, z_axis, math.rad(-(0)), math.rad(250))	 --up 22
		RestorePose()
	end
	StartThread(IdleAnim)
	armsFree = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Walking

local PACE = 3.9
local SLEEP_TIME = 1080/PACE

local walkCycle = 1 -- Alternate between 1 and 2

local tempSpeed = 40

local walkAngle = {
	{ -- Moving forwards
		{
			hip = {math.rad(0), math.rad(20) * PACE},
			leg = {math.rad(-20), math.rad(40) * PACE},
			foot = {math.rad(15), math.rad(54) * PACE},
			toeFront = {math.rad(22), math.rad(45) * PACE},
			toeRear = {math.rad(-22), math.rad(45) * PACE},
			arm = {math.rad(4), math.rad(12) * PACE},
		},
		{
			hip = {math.rad(-35), math.rad(35) * PACE},
			leg = {math.rad(0), math.rad(20) * PACE},
			foot = {math.rad(-5), math.rad(20) * PACE},
			toeFront = {math.rad(22), 0},
			toeRear = {math.rad(-6), 10},
		},
		{
			hip = {math.rad(-60), math.rad(25) * PACE},
			leg = {math.rad(30), math.rad(30) * PACE},
			foot = {math.rad(31), math.rad(36) * PACE},
			toeFront = {0, math.rad(45) * PACE},
			toeRear = {math.rad(10), math.rad(30) * PACE},
		},
	},
	{ -- Moving backwards
		{
			hip = {math.rad(-35), math.rad(25) * PACE},
			leg = {math.rad(20), math.rad(10) * PACE},
			foot = {math.rad(15), math.rad(16) * PACE},
			toeFront = {0, 0},
			toeRear = {0, math.rad(40) * PACE},
			arm = {math.rad(4), math.rad(12) * PACE},
		},
		{
			hip = {math.rad(-5), math.rad(30) * PACE},
			leg = {math.rad(10), math.rad(10) * PACE},
			foot = {math.rad(-3), math.rad(18) * PACE},
			toeFront = {0, 0},
			toeRear = {0, 0},
		},
		{
			hip = {math.rad(20), math.rad(25) * PACE},
			leg = {math.rad(20), math.rad(10) * PACE},
			foot = {math.rad(-39), math.rad(36) * PACE},
			toeFront = {0, 0},
			toeRear = {0, 0},
		},
	},
	{ -- Do each cycle
		{
			pelvisMove = {4.6, 2.9 * PACE},
			pelvisTurn = {math.rad(0.8), math.rad(1.6) * PACE},
		},
		{
			pelvisMove = {3.8, 0.9 * PACE},
			pelvisTurn = {math.rad(2), math.rad(1.2) * PACE},
		},
		{
			pelvisMove = {1.7, 2.1 * PACE},
			pelvisTurn = {math.rad(0.8), math.rad(1.6) * PACE},
		},
	}
}

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	local speedMult = 1
	if armsFree then
		Turn(torso, y_axis, 0, math.rad(90))
		Turn(larm, y_axis, 0, math.rad(120))
		Turn(rarm, y_axis, 0, math.rad(120))
		Turn(luparm, x_axis, 0, math.rad(240))
		Turn(ruparm, x_axis, 0, math.rad(240))
	end
	
	while true do
		walkCycle = 3 - walkCycle
		local speedMult = (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)
		
		local left = walkAngle[walkCycle] 
		local right = walkAngle[3 - walkCycle]
		local main = walkAngle[3]
		
		for i = 1, 3 do
			Turn(lupleg, x_axis,  left[i].hip[1],  left[i].hip[2] * speedMult)
			Turn(lleg, x_axis, left[i].leg[1],  left[i].leg[2] * speedMult)
			Turn(lfoot, x_axis, left[i].foot[1], left[i].foot[2] * speedMult)
			Turn(ltoef, x_axis, left[i].toeFront[1], left[i].toeFront[2] * speedMult)
			Turn(ltoer, x_axis, left[i].toeRear[1], left[i].toeRear[2] * speedMult)
			
			Turn(rupleg, x_axis,  right[i].hip[1],  right[i].hip[2] * speedMult)
			Turn(rleg, x_axis, right[i].leg[1],  right[i].leg[2] * speedMult)
			Turn(rfoot, x_axis,  right[i].foot[1], right[i].foot[2] * speedMult)
			Turn(rtoef, x_axis, right[i].toeFront[1], right[i].toeFront[2] * speedMult)
			Turn(rtoer, x_axis, right[i].toeRear[1], right[i].toeRear[2] * speedMult)
			
			if armsFree and left[i].arm then
				local parity = 3 - walkCycle*2
				Turn(larm, y_axis, left[i].arm[1] * parity, left[i].arm[2] * speedMult)
				Turn(rarm, y_axis, right[i].arm[1] * parity, right[i].arm[2] * speedMult)
				
				Turn(pelvis, z_axis, main[i].pelvisTurn[1] * parity, main[i].pelvisTurn[2] * speedMult)
			end
			
			Move(pelvis, y_axis, main[i].pelvisMove[1], main[i].pelvisMove[2] * speedMult)
			Sleep(SLEEP_TIME / speedMult)
		end
	end
end

function script.Create()
	Hide(flame1)
	Hide(flame2)
	Hide(rf1)
	Hide(rf2)
	Hide(rf3)
	Hide(lf1)
	Hide(lf2)
	Hide(lf3)
	Hide(jet1)
	Hide(jet2)
	
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	RestorePose()
	StartThread(IdleAnim)
end

function script.StartMoving()
	StartThread(Walk)
	Signal(SIG_IDLE)
end

function script.StopMoving()
	StartThread(Stopping)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weaponry

function script.AimFromWeapon(num)
	return weaponPieces[num].aimFrom
end

function script.QueryWeapon(num)
	local pieces = weaponPieces[num].query
	return pieces[weaponPieces[num].index]
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_IDLE)
	if num == 1 then
		if dgunning then return false end
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		armsFree = false
		Turn(ruparm, x_axis, -pitch - math.rad(20), math.rad(250))
		Turn(luparm, x_axis, -pitch - math.rad(20), math.rad(250))
		Turn(torso, y_axis, heading, math.rad(250))
		Turn(rarm, x_axis, math.rad(20), math.rad(250))
		Turn(larm, x_axis, math.rad(20), math.rad(250))
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis) --need to make surenot 
		return true
	elseif num == 2 then
		if dgunning then return false end
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
		Turn(torso, y_axis, heading, math.rad(200))
		WaitForTurn(torso, y_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 3 then
		dgunning = true
		Signal(SIG_AIM)
		Signal(SIG_AIM_2)
		Signal(SIG_AIM_3)
		SetSignalMask(SIG_AIM_3)
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 0)
		GG.UpdateUnitAttributes(unitID)
		armsFree = false
		
		Turn(ruparm, x_axis, -pitch - math.rad(20), math.rad(250))
		Turn(luparm, x_axis, -pitch - math.rad(20), math.rad(250))
		Turn(torso, y_axis, heading, math.rad(250))
		Turn(rarm, x_axis, math.rad(20), math.rad(250))
		Turn(larm, x_axis, math.rad(20), math.rad(250))
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
		targetHeading = heading + GetUnitValue(COB.HEADING)/32768
		StartThread(RestoreAfterDelay)
		Signal(SIG_AIM)
		Signal(SIG_AIM_2)
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
		GG.UpdateUnitAttributes(unitID)
		dgunning = false
		return true
	elseif num == 4 then
		if dgunning then return false end
		Signal(SIG_AIM_4)
		SetSignalMask(SIG_AIM_4)
	
		Turn(flagellum, x_axis, -pitch, math.rad(90))
		Turn(torso, y_axis, heading, math.rad(250))
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
		--GG.LUPS.FlameShot(unitID, unitDefID, _, num)
	end
	weapon.index = index + 1
	if (index + 1) > #weapon.query then
		weapon.index = 1
	end
end

function script.BlockShot(num, targetID)
	if num ~= 1 then
		return false
	end
	local reloadState = Spring.GetUnitWeaponState(unitID, 3, 'reloadState')
	return not (reloadState and (reloadState < 0 or reloadState < Spring.GetGameFrame()))
end

function script.FireWeapon(num)
	if num == 3 then
		dgunning = true
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 0)
		GG.UpdateUnitAttributes(unitID)
		Sleep(SALVO_TIME)
		dgunning = false
		Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
		GG.UpdateUnitAttributes(unitID)
	end
end

function OnLoadGame()
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = true
	Turn(torso, y_axis, 0, math.rad(200))
	if severity <= 0.5 then
		Turn(base, x_axis, math.rad(71), math.rad(70))
		Turn(torso, x_axis, math.rad(-31), math.rad(50))
		Turn(ruparm, x_axis, math.rad(-41), math.rad(50))
		Turn(ruparm, y_axis, math.rad(-11), math.rad(50))
		Turn(rarm, x_axis, math.rad(-6), math.rad(50)) --was 0
		Turn(flagellum, x_axis, math.rad(49), math.rad(50))
		Turn(flagellum, y_axis, math.rad(14), math.rad(50))
		Turn(luparm, y_axis, math.rad(54), math.rad(50))
		Turn(rupleg, x_axis, math.rad(-27), math.rad(50))
		Turn(rupleg, y_axis, math.rad(-42), math.rad(50))
		Turn(rupleg, z_axis, math.rad(-(-5)), math.rad(50))		
		Turn(rleg, x_axis, math.rad(13), math.rad(50))
		Turn(rleg, y_axis, math.rad(-36), math.rad(50))
		Turn(rleg, z_axis, math.rad(-(24)), math.rad(50))	
		Turn(lupleg, y_axis, math.rad(18), math.rad(50))
		Turn(lleg, x_axis, math.rad(20), math.rad(50))
		Turn(lleg, y_axis, math.rad(28), math.rad(50))
		Turn(lfoot, x_axis, math.rad(23), math.rad(50))
		
		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(800)
		--EmitSfx(torso, 1027) --impact
		--StartThread(burn)
		--Sleep((1000 * rand (2, 5)))

		Explode(pelvis, SFX.NONE)
		Explode(luparm, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(lupleg, SFX.NONE)
		Explode(rarm, SFX.FALL)
		Explode(rleg, SFX.NONE)
		Explode(ruparm, SFX.NONE)
		Explode(rupleg, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	else
		Explode(pelvis, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(luparm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lupleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rarm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(ruparm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rupleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
