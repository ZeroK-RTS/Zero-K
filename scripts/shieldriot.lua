include 'constants.lua'

local base = piece 'base'
local pelvis = piece 'pelvis'
local torso = piece 'torso'
local emit = piece 'emit'
local fire = piece 'fire'
local lleg = piece 'lleg'
local rleg = piece 'rleg'
local lowerlleg = piece 'lowerlleg'
local lowerrleg = piece 'lowerrleg'
local lfoot = piece 'lfoot'
local rfoot = piece 'rfoot'

local l_gun = piece 'l_gun'
local r_gun = piece 'r_gun'

local smokePiece = {torso}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_ACTIVATE = 8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetGameFrame       = Spring.GetGameFrame

local waveWeaponDef = WeaponDefNames["shieldriot_blast"]
local WAVE_RELOAD = math.floor(waveWeaponDef.reload * Game.gameSpeed)
local WAVE_TIMEOUT = math.ceil(waveWeaponDef.damageAreaOfEffect / waveWeaponDef.explosionSpeed)* (1000 / Game.gameSpeed) + 200 -- empirically maximum delay of damage was (damageAreaOfEffect / explosionSpeed) - 4 frames

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- For G:\code\Zero-K-Artwork\blender_animations\outlaw.blend Created by https://github.com/Beherith/Skeletor_S3O V((0, 3, 7))
local ANIM_FRAMES = 4
local walking = false -- prevent script.StartMoving from spamming threads if already walking

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	local speedMult, sleepTime = GG.Script.GetSpeedParams(unitID, ANIM_FRAMES)

	-- Frame: 5 (first step)
	Turn(lfoot, x_axis, -1.005157, 36.441551 * speedMult) -- delta=69.60
	Turn(lfoot, z_axis, 0.000000, 0.269081 * speedMult) -- delta=0.51
	Turn(lfoot, y_axis, -0.000000, 0.305522 * speedMult) -- delta=0.58
	Turn(lleg, x_axis, 0.706633, 16.035916 * speedMult) -- delta=-30.63
	Turn(lleg, z_axis, -0.025628, 0.920972 * speedMult) -- delta=-1.76
	Turn(lleg, y_axis, 0.216548, 6.711383 * speedMult) -- delta=12.82
	Turn(lowerlleg, x_axis, 0.436177, 24.491338 * speedMult) -- delta=-46.78
	Turn(lowerlleg, z_axis, 0.000000, 1.131782 * speedMult) -- delta=-2.16
	Turn(lowerlleg, y_axis, -0.000000, 6.023916 * speedMult) -- delta=11.50
	Turn(lowerrleg, x_axis, 0.054725, 12.527276 * speedMult) -- delta=-23.93
	Turn(lowerrleg, z_axis, 0.000000, 0.067490 * speedMult) -- delta=0.13
	Turn(lowerrleg, y_axis, -0.000000, 0.312260 * speedMult) -- delta=-0.60
	Turn(pelvis, x_axis, 0.122507, 3.675203 * speedMult) -- delta=-7.02
	Turn(pelvis, z_axis, -0.014222, 0.426656 * speedMult) -- delta=-0.81
	Turn(pelvis, y_axis, -0.247694, 7.430825 * speedMult) -- delta=-14.19
	Turn(rfoot, x_axis, 0.666361, 14.462757 * speedMult) -- delta=-27.62
	Turn(rfoot, z_axis, 0.000000, 0.089851 * speedMult) -- delta=0.17
	Turn(rfoot, y_axis, -0.000000, 0.095897 * speedMult) -- delta=0.18
	Turn(rleg, x_axis, -0.843606, 30.666600 * speedMult) -- delta=58.57
	Turn(rleg, z_axis, -0.032587, 1.068274 * speedMult) -- delta=-2.04
	Turn(rleg, y_axis, 0.242480, 7.343706 * speedMult) -- delta=14.03
	Turn(torso, x_axis, 0.002425, 0.072750 * speedMult) -- delta=-0.14
	Turn(torso, z_axis, 0.000000, 1.047198 * speedMult) -- delta=2.00
	Turn(torso, y_axis, 0.226893, 6.806784 * speedMult) -- delta=13.00
	Sleep(sleepTime)

	while true do
		speedMult, sleepTime = GG.Script.GetSpeedParams(unitID, ANIM_FRAMES)
		-- Frame:9
		Turn(lfoot, x_axis, -0.251141, 22.620467 * speedMult) -- delta=-43.20
		Turn(lleg, x_axis, 1.005390, 8.962684 * speedMult) -- delta=-17.12
		Turn(lleg, z_axis, 0.188916, 6.436310 * speedMult) -- delta=12.29
		Turn(lleg, y_axis, 0.328514, 3.358976 * speedMult) -- delta=6.42
		Turn(lowerlleg, x_axis, -0.266738, 21.087460 * speedMult) -- delta=40.27
		Turn(lowerrleg, x_axis, -0.298917, 10.609255 * speedMult) -- delta=20.26
		Move(pelvis, y_axis, -0.500000, 38.099999 * speedMult) -- delta=1.27
		Turn(pelvis, x_axis, 0.070150, 1.570692 * speedMult) -- delta=3.00
		Turn(pelvis, z_axis, -0.115316, 3.032836 * speedMult) -- delta=-5.79
		Turn(pelvis, y_axis, -0.180727, 2.009007 * speedMult) -- delta=3.84
		Turn(rfoot, x_axis, 0.317229, 10.473948 * speedMult) -- delta=20.00
		Turn(rleg, x_axis, -0.107487, 22.083575 * speedMult) -- delta=-42.18
		Turn(rleg, z_axis, 0.107260, 4.195432 * speedMult) -- delta=8.01
		Turn(rleg, y_axis, 0.170010, 2.174100 * speedMult) -- delta=-4.15
		Turn(torso, x_axis, 0.012572, 0.304422 * speedMult) -- delta=-0.58
		Turn(torso, z_axis, 0.056303, 1.689084 * speedMult) -- delta=3.23
		Turn(torso, y_axis, 0.176278, 1.518438 * speedMult) -- delta=-2.90
		Sleep(sleepTime)
		-- Frame:13
		Turn(lfoot, x_axis, 0.786735, 31.136284 * speedMult) -- delta=-59.47
		Turn(lleg, x_axis, -0.646235, 49.548731 * speedMult) -- delta=94.63
		Turn(lleg, z_axis, 0.146929, 1.259611 * speedMult) -- delta=-2.41
		Turn(lleg, y_axis, -0.098604, 12.813533 * speedMult) -- delta=-24.47
		Turn(lowerlleg, x_axis, -0.065542, 6.035895 * speedMult) -- delta=-11.53
		Turn(lowerrleg, x_axis, 0.229709, 15.858770 * speedMult) -- delta=-30.29
		Move(pelvis, y_axis, 1.652101, 64.563024 * speedMult) -- delta=2.15
		Turn(pelvis, x_axis, -0.000000, 2.104511 * speedMult) -- delta=4.02
		Turn(pelvis, z_axis, -0.082305, 0.990339 * speedMult) -- delta=1.89
		Turn(pelvis, y_axis, -0.000000, 5.421818 * speedMult) -- delta=10.35
		Turn(rfoot, x_axis, -0.416225, 22.003623 * speedMult) -- delta=42.02
		Turn(rleg, x_axis, 0.185462, 8.788442 * speedMult) -- delta=-16.78
		Turn(rleg, z_axis, 0.094637, 0.378714 * speedMult) -- delta=-0.72
		Turn(rleg, y_axis, 0.020262, 4.492442 * speedMult) -- delta=-8.58
		Turn(torso, x_axis, 0.008382, 0.125724 * speedMult) -- delta=0.24
		Turn(torso, z_axis, 0.069813, 0.405311 * speedMult) -- delta=0.77
		Turn(torso, y_axis, 0.003491, 5.183626 * speedMult) -- delta=-9.90
		Sleep(sleepTime)
		-- Frame:17
		Turn(lfoot, x_axis, 0.409120, 11.328447 * speedMult) -- delta=21.64
		Turn(lleg, x_axis, -1.386774, 22.216178 * speedMult) -- delta=42.43
		Turn(lleg, z_axis, -0.037102, 5.520910 * speedMult) -- delta=-10.54
		Turn(lleg, y_axis, -0.133782, 1.055339 * speedMult) -- delta=-2.02
		Turn(lowerlleg, x_axis, 0.490075, 16.668494 * speedMult) -- delta=-31.83
		Turn(lowerrleg, x_axis, 0.574914, 10.356164 * speedMult) -- delta=-19.78
		Move(pelvis, y_axis, 0.261050, 41.731514 * speedMult) -- delta=-1.39
		Turn(pelvis, x_axis, 0.058467, 1.754012 * speedMult) -- delta=-3.35
		Turn(pelvis, z_axis, 0.019272, 3.047312 * speedMult) -- delta=5.82
		Turn(pelvis, y_axis, 0.182876, 5.486267 * speedMult) -- delta=10.48
		Turn(rfoot, x_axis, -0.989586, 17.200840 * speedMult) -- delta=32.85
		Turn(rleg, x_axis, 0.353818, 5.050702 * speedMult) -- delta=-9.65
		Turn(rleg, z_axis, -0.022840, 3.524285 * speedMult) -- delta=-6.73
		Turn(rleg, y_axis, -0.174735, 5.849882 * speedMult) -- delta=-11.17
		Turn(torso, x_axis, 0.004191, 0.125724 * speedMult) -- delta=0.24
		Turn(torso, z_axis, 0.033161, 1.099557 * speedMult) -- delta=-2.10
		Turn(torso, y_axis, -0.176278, 5.393067 * speedMult) -- delta=-10.30
		Sleep(sleepTime)
		-- Frame:21
		Turn(lfoot, x_axis, 0.655366, 7.387388 * speedMult) -- delta=-14.11
		Turn(lleg, x_axis, -0.808922, 17.335550 * speedMult) -- delta=-33.11
		Turn(lleg, z_axis, 0.022915, 1.800507 * speedMult) -- delta=3.44
		Turn(lleg, y_axis, -0.246012, 3.366888 * speedMult) -- delta=-6.43
		Turn(lowerlleg, x_axis, 0.031159, 13.767468 * speedMult) -- delta=26.29
		Turn(lowerrleg, x_axis, 0.492353, 2.476824 * speedMult) -- delta=4.73
		Move(pelvis, y_axis, -1.770000, 60.931510 * speedMult) -- delta=-2.03
		Turn(pelvis, x_axis, 0.122507, 1.921191 * speedMult) -- delta=-3.67
		Turn(pelvis, z_axis, 0.014222, 0.151504 * speedMult) -- delta=-0.29
		Turn(pelvis, y_axis, 0.247694, 1.944559 * speedMult) -- delta=3.71
		Turn(rfoot, x_axis, -1.028214, 1.158838 * speedMult) -- delta=2.21
		Turn(rleg, x_axis, 0.673646, 9.594827 * speedMult) -- delta=-18.32
		Turn(rleg, z_axis, 0.009465, 0.969130 * speedMult) -- delta=1.85
		Turn(rleg, y_axis, -0.220874, 1.384183 * speedMult) -- delta=-2.64
		Turn(torso, x_axis, 0.002425, 0.052974 * speedMult) -- delta=0.10
		Turn(torso, z_axis, 0.000000, 0.994838 * speedMult) -- delta=-1.90
		Turn(torso, y_axis, -0.227120, 1.525266 * speedMult) -- delta=-2.91
		Sleep(sleepTime)
		-- Frame:25
		Turn(lfoot, x_axis, 0.263757, 11.748286 * speedMult) -- delta=22.44
		Turn(lleg, x_axis, -0.100336, 21.257606 * speedMult) -- delta=-40.60
		Turn(lleg, z_axis, -0.099219, 3.664037 * speedMult) -- delta=-7.00
		Turn(lleg, y_axis, -0.163469, 2.476269 * speedMult) -- delta=4.73
		Turn(lowerlleg, x_axis, -0.251907, 8.491991 * speedMult) -- delta=16.22
		Turn(lowerrleg, x_axis, -0.247002, 22.180654 * speedMult) -- delta=42.36
		Move(pelvis, y_axis, -0.500000, 38.099999 * speedMult) -- delta=1.27
		Turn(pelvis, x_axis, 0.070150, 1.570692 * speedMult) -- delta=3.00
		Turn(pelvis, z_axis, 0.115316, 3.032836 * speedMult) -- delta=5.79
		Turn(pelvis, y_axis, 0.180727, 2.009007 * speedMult) -- delta=-3.84
		Turn(rfoot, x_axis, -0.254467, 23.212399 * speedMult) -- delta=-44.33
		Turn(rleg, x_axis, 0.987347, 9.411042 * speedMult) -- delta=-17.97
		Turn(rleg, z_axis, -0.209936, 6.582020 * speedMult) -- delta=-12.57
		Turn(rleg, y_axis, -0.341115, 3.607243 * speedMult) -- delta=-6.89
		Turn(torso, x_axis, 0.004219, 0.053822 * speedMult) -- delta=-0.10
		Turn(torso, z_axis, -0.103338, 3.100140 * speedMult) -- delta=-5.92
		Turn(torso, y_axis, -0.195477, 0.949308 * speedMult) -- delta=1.81
		Sleep(sleepTime)
		-- Frame:29
		Turn(lfoot, x_axis, -0.376806, 19.216895 * speedMult) -- delta=36.70
		Turn(lleg, x_axis, 0.064771, 4.953183 * speedMult) -- delta=-9.46
		Turn(lleg, z_axis, -0.110995, 0.353254 * speedMult) -- delta=-0.67
		Turn(lleg, y_axis, -0.027836, 4.069008 * speedMult) -- delta=7.77
		Turn(lowerlleg, x_axis, 0.150576, 12.074482 * speedMult) -- delta=-23.06
		Turn(lowerrleg, x_axis, -0.049790, 5.916367 * speedMult) -- delta=-11.30
		Move(pelvis, y_axis, 1.652101, 64.563024 * speedMult) -- delta=2.15
		Turn(pelvis, x_axis, 0.158951, 2.664019 * speedMult) -- delta=-5.09
		Turn(pelvis, z_axis, 0.106503, 0.264413 * speedMult) -- delta=-0.50
		Turn(pelvis, y_axis, 0.022281, 4.753387 * speedMult) -- delta=-9.08
		Turn(rfoot, x_axis, 0.753413, 30.236423 * speedMult) -- delta=-57.75
		Turn(rleg, x_axis, -0.793763, 53.433303 * speedMult) -- delta=102.05
		Turn(rleg, z_axis, -0.150095, 1.795224 * speedMult) -- delta=3.43
		Turn(rleg, y_axis, 0.055340, 11.893670 * speedMult) -- delta=22.72
		Turn(torso, x_axis, -0.000000, 0.126572 * speedMult) -- delta=0.24
		Turn(torso, z_axis, -0.083776, 0.586866 * speedMult) -- delta=1.12
		Turn(torso, y_axis, -0.017453, 5.340707 * speedMult) -- delta=10.20
		Sleep(sleepTime)
		-- Frame:33
		Turn(lfoot, x_axis, -0.986966, 18.304795 * speedMult) -- delta=34.96
		Turn(lleg, x_axis, 0.351070, 8.588974 * speedMult) -- delta=-16.40
		Turn(lleg, z_axis, -0.010896, 3.002964 * speedMult) -- delta=5.74
		Turn(lleg, y_axis, 0.158288, 5.583717 * speedMult) -- delta=10.66
		Turn(lowerlleg, x_axis, 0.578171, 12.827866 * speedMult) -- delta=-24.50
		Turn(lowerrleg, x_axis, 0.563778, 18.407012 * speedMult) -- delta=-35.15
		Move(pelvis, y_axis, 0.261050, 41.731514 * speedMult) -- delta=-1.39
		Turn(pelvis, x_axis, 0.058469, 3.014475 * speedMult) -- delta=5.76
		Turn(pelvis, z_axis, -0.000000, 3.195079 * speedMult) -- delta=-6.10
		Turn(pelvis, y_axis, -0.174533, 5.904419 * speedMult) -- delta=-11.28
		Turn(rfoot, x_axis, 0.389044, 10.931070 * speedMult) -- delta=20.88
		Turn(rleg, x_axis, -1.436901, 19.294136 * speedMult) -- delta=36.85
		Turn(rleg, z_axis, -0.096006, 1.622677 * speedMult) -- delta=3.10
		Turn(rleg, y_axis, 0.242815, 5.624240 * speedMult) -- delta=10.74
		Turn(torso, x_axis, 0.004191, 0.125724 * speedMult) -- delta=-0.24
		Turn(torso, z_axis, -0.033161, 1.518436 * speedMult) -- delta=2.90
		Turn(torso, y_axis, 0.175933, 5.801579 * speedMult) -- delta=11.08
		Sleep(sleepTime)
		-- Frame:37
		Turn(lfoot, x_axis, -1.005157, 0.545715 * speedMult) -- delta=1.04
		Turn(lleg, x_axis, 0.706633, 10.666913 * speedMult) -- delta=-20.37
		Turn(lleg, z_axis, -0.025628, 0.441968 * speedMult) -- delta=-0.84
		Turn(lleg, y_axis, 0.216548, 1.747790 * speedMult) -- delta=3.34
		Turn(lowerlleg, x_axis, 0.436177, 4.259818 * speedMult) -- delta=8.14
		Turn(lowerrleg, x_axis, 0.054725, 15.271580 * speedMult) -- delta=29.17
		Move(pelvis, y_axis, -1.770000, 60.931510 * speedMult) -- delta=-2.03
		Turn(pelvis, x_axis, 0.122507, 1.921147 * speedMult) -- delta=-3.67
		Turn(pelvis, z_axis, -0.014222, 0.426656 * speedMult) -- delta=-0.81
		Turn(pelvis, y_axis, -0.247694, 2.194837 * speedMult) -- delta=-4.19
		Turn(rfoot, x_axis, 0.666361, 8.319496 * speedMult) -- delta=-15.89
		Turn(rleg, x_axis, -0.843606, 17.798851 * speedMult) -- delta=-33.99
		Turn(rleg, z_axis, -0.032587, 1.902556 * speedMult) -- delta=3.63
		Turn(torso, x_axis, 0.002425, 0.052974 * speedMult) -- delta=0.10
		Turn(torso, z_axis, 0.000000, 0.994838 * speedMult) -- delta=1.90
		Turn(torso, y_axis, 0.226893, 1.528804 * speedMult) -- delta=2.92
		Sleep(sleepTime)
	end
end

local function StopWalking()
    Signal(SIG_WALK)
    SetSignalMask(SIG_WALK)

	local speedMult = 0.5 * GG.Script.GetSpeedParams(unitID, ANIM_FRAMES) -- slower restore speed for last step

	Move(pelvis, y_axis, -1.852628, 161.407560 * speedMult)
	Turn(lfoot, x_axis, 0.209562, 91.103878 * speedMult)
	Turn(lfoot, y_axis, -0.010184, 0.763806 * speedMult)
	Turn(lfoot, z_axis, -0.008969, 0.672702 * speedMult)
	Turn(lleg, x_axis, 0.172103, 123.871829 * speedMult)
	Turn(lleg, y_axis, -0.007165, 32.033832 * speedMult)
	Turn(lleg, z_axis, 0.005071, 16.090774 * speedMult)
	Turn(lowerlleg, x_axis, -0.380201, 61.228345 * speedMult)
	Turn(lowerlleg, y_axis, -0.200797, 15.059790 * speedMult)
	Turn(lowerlleg, z_axis, 0.037726, 2.829455 * speedMult)
	Turn(lowerrleg, x_axis, -0.362851, 55.451636 * speedMult)
	Turn(lowerrleg, y_axis, 0.010409, 0.780649 * speedMult)
	Turn(lowerrleg, z_axis, -0.002250, 0.168725 * speedMult)
	Turn(pelvis, x_axis, 0.000000, 9.188008 * speedMult)
	Turn(pelvis, y_axis, 0.000000, 18.577062 * speedMult)
	Turn(pelvis, z_axis, 0.000000, 7.987697 * speedMult)
	Turn(rfoot, x_axis, 0.184269, 75.591058 * speedMult)
	Turn(rfoot, y_axis, -0.003197, 0.239744 * speedMult)
	Turn(rfoot, z_axis, -0.002995, 0.224628 * speedMult)
	Turn(rleg, x_axis, 0.178614, 133.583258 * speedMult)
	Turn(rleg, y_axis, -0.002311, 29.734174 * speedMult)
	Turn(rleg, z_axis, 0.003022, 16.455050 * speedMult)
	Turn(torso, x_axis, 0.000000, 0.761055 * speedMult)
	Turn(torso, y_axis, 0.000000, 17.016960 * speedMult)
	Turn(torso, z_axis, -0.034907, 7.750349 * speedMult)
end

function script.StartMoving()
    if not walking then
        walking = true
        StartThread(Walk)
    end
end

function script.StopMoving()
    walking = false
    StartThread(StopWalking)
end

function AutoAttack_Thread()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	while true do
		Sleep(100)
		local reloaded = select(2, spGetUnitWeaponState(unitID,3))
		if reloaded then
			local height = select(5, Spring.GetUnitPosition(unitID, true))
			if height > -8 then -- Matches offset of AimFromWeapon position for FAKEGUN2
				local gameFrame = spGetGameFrame()
				local reloadMult = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1.0
				local reloadFrame = gameFrame + WAVE_RELOAD / reloadMult
				spSetUnitWeaponState(unitID, 3, {reloadFrame = reloadFrame})
				GG.PokeDecloakUnit(unitID, unitDefID)
				
				EmitSfx(emit, GG.Script.UNIT_SFX1)
				EmitSfx(emit, GG.Script.DETO_W2)
				FireAnim()
			end
		end
	end
end

function FireAnim()
	local mspeed = 4
	Move (l_gun, x_axis, 2, mspeed*3)
	Move (r_gun, x_axis, -2, mspeed*3)
	WaitForMove(l_gun, x_axis)
	WaitForMove(r_gun, x_axis)
	Sleep(1)
	Move (l_gun, x_axis, 0, mspeed)
	Move (r_gun, x_axis, 0, mspeed)
	Sleep(1)
end

function script.Activate()
 StartThread(AutoAttack_Thread)
end

function script.Deactivate()
 Signal(SIG_ACTIVATE)
end

function script.FireWeapon(num)
	if num == 3 then
		EmitSfx(emit, GG.Script.UNIT_SFX1)
		EmitSfx(emit, GG.Script.DETO_W2)
		FireAnim()
	end
end

function script.AimFromWeapon(num)
	return torso
end

function script.AimWeapon(num, heading, pitch)
	return num == 3
end

function script.QueryWeapon(num)
	return emit
end

local function Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(torso, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(torso, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, SFX.NONE)

		Explode(rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.NONE)
		return 2
	else
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, SFX.NONE)
	
		Explode(rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.NONE)
		return 2
	end
end

function script.Killed(recentDamage, maxHealth)
	Signal(SIG_ACTIVATE) -- prevent pulsing while undead

	-- keep the unit technically alive (but hidden) for some time so that any inbound
	-- pulses know who their owner is (so that they can do no damage to allies)
	return GG.Script.DelayTrueDeath(unitID, unitDefID, recentDamage, maxHealth, Killed, WAVE_TIMEOUT)
end
