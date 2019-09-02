local body = piece 'body'
local turret = piece 'turret'
local flare = piece 'flare'
local barrel = piece 'barrel'
local lfupleg = piece 'lfupleg'
local lrupleg = piece 'lrupleg'
local rrupleg = piece 'rrupleg'
local head = piece 'head'
local rfupleg = piece 'rfupleg'
local rrleg = piece 'rrleg'
local rfleg = piece 'rfleg'
local lrleg = piece 'lrleg'
local lfleg = piece 'lfleg'
local digger = piece 'digger'

include "constants.lua"
include 'reliableStartMoving.lua'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local TURRET_TURN_RATE = math.rad(450)
local RESTORE_DELAY = 600

local burrowed = false
local aiming = false
local dirtfling = 1024+2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Signal definitions

local SIG_BURROW = 1
local SIG_AIM = 2
local SIG_WALK = 4
local SIG_RESTORE = 8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	while true do
		Move( lfupleg , y_axis, 0  )
		Move( lfupleg , y_axis, 0.25 , 2 )
		Move( lrupleg , y_axis, 0  )
		Move( lrupleg , y_axis, 0.9 , 8 )
		Move( rrupleg , y_axis, 0  )
		Move( rrupleg , y_axis, 0.8 , 7 )
		Turn( body , x_axis, math.rad(11.829670) )
		Turn( body , x_axis, math.rad(22), math.rad(94) )
		Turn( head , x_axis, math.rad(8.521978) )
		Turn( head , x_axis, math.rad(20), math.rad(107) )
		Turn( lfupleg , x_axis, math.rad(-50.208791) )
		Turn( lfupleg , x_axis, math.rad(-22), math.rad(254) )
		Turn( lrupleg , x_axis, math.rad(23.203297) )
		Turn( lrupleg , x_axis, math.rad(-28.005495), math.rad(473) )
		Turn( rfupleg , x_axis, math.rad(-49.269231) )
		Turn( rfupleg , x_axis, math.rad(-32.005495), math.rad(150) )
		Turn( rrupleg , x_axis, math.rad(27.472527) )
		Turn( rrupleg , x_axis, math.rad(-20), math.rad(439) )
		Turn( rrleg , x_axis, math.rad(45.010989) )
		Turn( rrleg , x_axis, math.rad(-24.005495), math.rad(633) )
		Turn( rfleg , x_axis, 0 )
		Turn( rfleg , x_axis, math.rad(12), math.rad(111) )
		Turn( lrleg , x_axis, math.rad(44.527473) )
		Turn( lrleg , x_axis, math.rad(-9), math.rad(495) )
		Sleep( 80)

		Move( lfupleg , y_axis, 0.75 , 4 )
		Move( lrupleg , y_axis, 1.6 , 6 )
		Move( rfupleg , y_axis, 0.85 , 7 )
		Move( rrupleg , y_axis, 1.45 , 5 )
		Turn( body , x_axis, 0, math.rad(188) )
		Turn( lfupleg , x_axis, math.rad(53.010989), math.rad(670) )
		Turn( lrupleg , x_axis, math.rad(-39.005495), math.rad(96) )
		Turn( rfupleg , x_axis, math.rad(51.010989), math.rad(742) )
		Turn( rrupleg , x_axis, math.rad(-32.005495), math.rad(100) )
		Turn( rrleg , x_axis, math.rad(14), math.rad(348) )
		Turn( rfleg , x_axis, math.rad(-52.010989), math.rad(570) )
		Turn( lrleg , x_axis, math.rad(25.005495), math.rad(314) )
		Turn( lfleg , x_axis, math.rad(-52.010989), math.rad(465) )
		Sleep( 80)

		Move( lrupleg , y_axis, 1.819995 , 4 )
		Move( rrupleg , y_axis, 1.719995 , 4 )
		Turn( body , x_axis, math.rad(-12), math.rad(241) )
		Turn( lfupleg , x_axis, math.rad(87.016484), math.rad(604) )
		Turn( lrupleg , x_axis, math.rad(-61.010989), math.rad(380) )
		Turn( rfupleg , x_axis, math.rad(82.016484), math.rad(562) )
		Turn( rrupleg , x_axis, math.rad(-61.010989), math.rad(528) )
		Turn( rrleg , x_axis, math.rad(72.016484), math.rad(1036) )
		Turn( rfleg , x_axis, math.rad(-58.010989), math.rad(105) )
		Turn( lrleg , x_axis, math.rad(71.016484), math.rad(820) )
		Sleep( 40)

		Move( lrupleg , y_axis, 1.65 , 3 )
		Move( rrupleg , y_axis, 1.7 , 0 )
		Turn( body , x_axis, math.rad(-26.005495), math.rad(232) )
		Turn( lfupleg , x_axis, math.rad(121.027473), math.rad(584) )
		Turn( lrupleg , x_axis, math.rad(-32.005495), math.rad(498) )
		Turn( rfupleg , x_axis, math.rad(114.027473), math.rad(543) )
		Turn( rrupleg , x_axis, math.rad(-31.005495), math.rad(526) )
		Turn( rrleg , x_axis, math.rad(54.010989), math.rad(306) )
		Turn( rfleg , x_axis, math.rad(-63.010989), math.rad(102) )
		Turn( lrleg , x_axis, math.rad(57.010989), math.rad(245) )
		Sleep( 40)

		Move( lrupleg , y_axis, 0.95 , 6 )
		Move( rrupleg , y_axis, 1.1 , 5 )
		Turn( body , x_axis, 0, math.rad(232) )
		Turn( head , x_axis, 0, math.rad(181) )
		Turn( lfupleg , x_axis, math.rad(60.010989), math.rad(545) )
		Turn( lrupleg , x_axis, math.rad(3), math.rad(321) )
		Turn( rfupleg , x_axis, math.rad(53.010989), math.rad(545) )
		Turn( rrupleg , x_axis, math.rad(-3), math.rad(249) )
		Turn( rrleg , x_axis, math.rad(30.005495), math.rad(219) )
		Turn( rfleg , x_axis, math.rad(26.005495), math.rad(807) )
		Turn( lrleg , x_axis, math.rad(22), math.rad(308) )
		Turn( lfleg , x_axis, math.rad(13), math.rad(588) )
		Sleep( 80)
		
		Sleep(113)
	end
end

local function WalkLegs()
	while true do
		Move( lrupleg , y_axis, 1.1  )
		Move( lrupleg , y_axis, 0.7 , 2 )
		Move( rfupleg , y_axis, 0.75  )
		Move( rfupleg , y_axis, 1.35 , 4 )
		Move( rrupleg , y_axis, 0.9  )
		Move( rrupleg , y_axis, 1.2 , 2 )
		Turn( head , x_axis, math.rad(1.406593) )
		Turn( head , x_axis, math.rad(8), math.rad(52) )
		Turn( lfupleg , x_axis, math.rad(-12.307692) )
		Turn( lfupleg , x_axis, 0, math.rad(91) )
		Turn( lrupleg , x_axis, math.rad(-56.373626) )
		Turn( lrupleg , x_axis, math.rad(-44.005495), math.rad(87) )
		Turn( rfupleg , x_axis, math.rad(56.373626) )
		Turn( rfupleg , x_axis, math.rad(87.016484), math.rad(231) )
		Turn( rrupleg , x_axis, math.rad(-47.368132) )
		Turn( rrupleg , x_axis, math.rad(-66.010989), math.rad(140) )
		Turn( rrleg , x_axis, math.rad(12.780220) )
		Turn( rrleg , x_axis, math.rad(39.005495), math.rad(200) )
		Turn( rfleg , x_axis, math.rad(-38.835165) )
		Turn( lrleg , x_axis, math.rad(75.796703) )
		Turn( lrleg , x_axis, math.rad(70.016484), math.rad(42) )
		Turn( lfleg , x_axis, math.rad(0.467033) )
		Sleep( 135)

		Move( lfupleg , y_axis, 0.75 , 5 )
		Move( lrupleg , y_axis, 0.45 , 1 )
		Turn( head , x_axis, math.rad(-6), math.rad(111) )
		Turn( lfupleg , x_axis, math.rad(49.010989), math.rad(365) )
		Turn( lrupleg , x_axis, math.rad(-8), math.rad(261) )
		Turn( rfupleg , x_axis, math.rad(29.005495), math.rad(428) )
		Turn( rrupleg , x_axis, math.rad(-49.010989), math.rad(121) )
		Turn( rrleg , x_axis, math.rad(48.010989), math.rad(62) )
		Turn( rfleg , x_axis, math.rad(22), math.rad(449) )
		Turn( lrleg , x_axis, math.rad(70.016484), math.rad(3) )
		Turn( lfleg , x_axis, math.rad(-46.010989), math.rad(348) )
		Sleep( 136)

		Move( lrupleg , y_axis, 1.3 , 6 )
		Move( rfupleg , y_axis, 0.45 , 6 )
		Move( rrupleg , y_axis, 0.8 , 2 )
		Turn( head , x_axis, math.rad(1), math.rad(58) )
		Turn( lfupleg , x_axis, math.rad(56.010989), math.rad(51) )
		Turn( lrupleg , x_axis, math.rad(-45.010989), math.rad(264) )
		Turn( rfupleg , x_axis, math.rad(-21), math.rad(370) )
		Turn( rrupleg , x_axis, math.rad(-40.005495), math.rad(68) )
		Turn( rrleg , x_axis, math.rad(45.010989), math.rad(17) )
		Turn( rfleg , x_axis, math.rad(4), math.rad(127) )
		Turn( lrleg , x_axis, math.rad(51.010989), math.rad(140) )
		Turn( lfleg , x_axis, math.rad(-49.010989), math.rad(20) )
		Sleep( 138)

		Move( lfupleg , y_axis, 0.9 , 1 )
		Move( rrupleg , y_axis, 0.7 , 0 )
		Turn( head , x_axis, math.rad(4), math.rad(20) )
		Turn( lfupleg , x_axis, math.rad(81.016484), math.rad(181) )
		Turn( lrupleg , x_axis, math.rad(-61.010989), math.rad(114) )
		Turn( rfupleg , x_axis, math.rad(15), math.rad(271) )
		Turn( rrupleg , x_axis, math.rad(-38.005495), math.rad(13) )
		Turn( rrleg , x_axis, math.rad(49.010989), math.rad(24) )
		Turn( rfleg , x_axis, math.rad(-33.005495), math.rad(278) )
		Turn( lrleg , x_axis, math.rad(26.005495), math.rad(184) )
		Turn( lfleg , x_axis, math.rad(-80.016484), math.rad(222) )
		Sleep( 136)

		Move( lrupleg , y_axis, 1.55 , 1 )
		Move( rrupleg , y_axis, 0.5 , 1 )
		Turn( head , x_axis, math.rad(7), math.rad(24) )
		Turn( lfupleg , x_axis, math.rad(87.016484), math.rad(41) )
		Turn( lrupleg , x_axis, math.rad(-78.016484), math.rad(125) )
		Turn( rfupleg , x_axis, math.rad(31.005495), math.rad(121) )
		Turn( rrupleg , x_axis, math.rad(-31.005495), math.rad(48) )
		Turn( rrleg , x_axis, math.rad(55.010989), math.rad(48) )
		Turn( lrleg , x_axis, math.rad(78.016484), math.rad(383) )
		Turn( lfleg , x_axis, math.rad(-28.005495), math.rad(376) )
		Sleep( 136)

		Move( lfupleg , y_axis, 1.1 , 1 )
		Move( lrupleg , y_axis, 1.25 , 2 )
		Move( rfupleg , y_axis, 0.8 , 2 )
		Move( rrupleg , y_axis, 0.85 , 2 )
		Turn( head , x_axis, math.rad(5), math.rad(17) )
		Turn( lfupleg , x_axis, math.rad(43.005495), math.rad(318) )
		Turn( lrupleg , x_axis, math.rad(-70.016484), math.rad(55) )
		Turn( rfupleg , x_axis, math.rad(51.010989), math.rad(145) )
		Turn( rrupleg , x_axis, math.rad(-23.005495), math.rad(58) )
		Turn( rrleg , x_axis, math.rad(59.010989), math.rad(24) )
		Turn( rfleg , x_axis, math.rad(-51.010989), math.rad(134) )
		Turn( lfleg , x_axis, math.rad(1), math.rad(221) )
		Sleep( 137)

		Move( lfupleg , y_axis, 0.55 , 4 )
		Move( lrupleg , y_axis, 1.05 , 1 )
		Turn( head , x_axis, 0, math.rad(38) )
		Turn( lfupleg , x_axis, math.rad(16), math.rad(202) )
		Turn( lrupleg , x_axis, math.rad(-65.010989), math.rad(34) )
		Turn( rfupleg , x_axis, math.rad(78.016484), math.rad(195) )
		Turn( rrupleg , x_axis, math.rad(-4), math.rad(142) )
		Turn( rrleg , x_axis, math.rad(-20), math.rad(585) )
		Turn( rfleg , x_axis, math.rad(-73.016484), math.rad(163) )
		Turn( lrleg , x_axis, math.rad(75.016484), math.rad(20) )
		Turn( lfleg , x_axis, math.rad(-41.005495), math.rad(317) )
		Sleep( 136)
		
		Sleep(136)
	end
end

local function WalkControl()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	while true do
		if aiming then
			WalkLegs()
		else
			Walk()
		end
		Sleep(100)
	end
end

local function Burrow()
	Signal(SIG_WALK)
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	burrowed = true
	EmitSfx(digger, dirtfling)
	burrowed = true
	
	Turn( rrleg   , x_axis, 0, 1 )
	Turn( rrupleg , x_axis, 0, 2 )
	Move( rrupleg , y_axis, 0, 2 )
	
	Turn( rfleg   , x_axis, 0, 1 )
	Turn( rfupleg , x_axis, 0, 2 )
	Move( rfupleg , y_axis, 0, 2 )
	
	Turn( lrleg   , x_axis, 0, 1 )
	Turn( lrupleg , x_axis, 0, 2 )
	Move( lrupleg , y_axis, 0, 2 )
	
	Turn( lfleg   , x_axis, 0, 1 )
	Turn( lfupleg , x_axis, 0, 2 )
	Move( lfupleg , y_axis, 0, 2 )
	
	Turn( head , x_axis, 0, math.rad(52) )
	Move(body, y_axis, 0, 9)
	Turn(body, x_axis, 0, 9)
	
	GG.SetWantedCloaked(unitID, 1)
	local down = false
	while true do
		local cloaked = Spring.GetUnitIsCloaked(unitID)
		if down ~= cloaked then
			if cloaked then
				Move( body , y_axis, -7.5, 7.5 )
				Turn( body , x_axis, math.rad(-20), math.rad(20) )
			else
				Move(body, y_axis, 0, 9)
				Turn(body, x_axis, 0, 9)
			end
			down = cloaked
		end
		Sleep(500)
	end
end

local function UnBurrow()
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	burrowed = false
	GG.SetWantedCloaked(unitID, 0)
	--Spring.SetUnitStealth(false)
	Move(body, y_axis, 0, 9)
	Turn(body, x_axis, 0, 9)

	--[[
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 0.2)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 5)
	GG.UpdateUnitAttributes(unitID)
	
	Sleep(600)
	
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
	]]
	EmitSfx(digger, dirtfling)
	StartThread(WalkControl)
end

function script.StartMoving()
	Signal(SIG_BURROW)
	if burrowed then
		StartThread(UnBurrow)
	else
		StartThread(WalkControl)
	end
end

function script.StopMoving()
	StartThread(Burrow)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {body})
	StartThread(GG.StartStopMovingControl, unitID, script.StartMoving, script.StopMoving, nil, true)
	if not Spring.GetUnitIsStunned(unitID) then
		Burrow()
	end
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep( RESTORE_DELAY)
	Turn( turret , y_axis, 0, math.rad(300) )
	WaitForTurn(turret, y_axis)
	aiming = false
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return flare
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	aiming = true
	Turn(turret, y_axis, heading, TURRET_TURN_RATE)
	WaitForTurn(turret, y_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local corpseType = 1
	if severity > .50 then
		corpseType = 2
	end

	local rand = math.random(1, 10)
	if rand == 1 then
		Explode( body, SFX.SHATTER)
		Explode( head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 2 then
		Explode( body, SFX.SHATTER)
		Explode( turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 3 then
		Explode( body, SFX.SHATTER)
	elseif rand == 4 then
		Explode( head, SFX.SHATTER)
		Explode( turret, SFX.SHATTER)
		Explode( body, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 5 then
		Explode( lfleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( rfleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( lrleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( rrleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 6 then
		Explode( body, SFX.SHATTER)
		Explode( head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( lfleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 7 then
		Explode( body, SFX.SHATTER)
		Explode( head, SFX.SHATTER)
		Explode( turret, SFX.SHATTER)
	elseif rand == 8 then
		Explode( body, SFX.SHATTER)
		Explode( head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	elseif rand == 9 then
		Explode( body, SFX.SHATTER)
	elseif rand == 10 then
		Explode( body, SFX.SHATTER)
		Explode( turret, SFX.SHATTER)
		Explode( head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( lfleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( rfleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( lrleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode( rrleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	end
	
	return corpseType
end
