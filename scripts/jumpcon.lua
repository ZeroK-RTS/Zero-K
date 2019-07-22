include "constants.lua"
include "JumpRetreat.lua"

local jump = piece 'jump' 
local torso = piece 'torso' 
local flare = piece 'flare' 
local pelvis = piece 'pelvis' 
local rcalf = piece 'rcalf' 
local lcalf = piece 'lcalf' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local larm = piece 'larm' 
local rarm = piece 'rarm' 
local rhand = piece 'rhand' 
local lhand = piece 'lhand' 
local head = piece 'head' 
local thrust = piece 'Thrust' 

local SIG_RESTORE = 16
local SIG_AIM = 8
local SIG_STOPBUILD = 4
local SIG_BUILD = 2
local SIG_WALK = 1
local RESTORE_DELAY = 1000

local smokePiece = {torso}
local nanoPiece = lhand

local usingNano = false
local usingGun = false

--------------------------
-- MOVEMENT

local function walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	while true do
	
		Move(pelvis, y_axis, -0.250000)
		Move(pelvis, z_axis, -0.600000)
		Move(rcalf, y_axis, 0.000000)
		Move(lcalf, y_axis, 0.639996)
		Turn(pelvis, x_axis, math.rad(10.890110))
		Turn(lthigh, x_axis, math.rad(-43.939560))
		Turn(rthigh, x_axis, math.rad(4.208791))
		Turn(rcalf, x_axis, math.rad(19.324176))
		Turn(lcalf, x_axis, math.rad(43.598901))
		if not usingNano and not usingGun then
			Turn(torso, x_axis, math.rad(5.269231))
			Turn(larm, x_axis, math.rad(-17.219780))
			Turn(rarm, x_axis, math.rad(-9.840659))
			Turn(rhand, x_axis, math.rad(-9.137363))
			Turn(lhand, x_axis, math.rad(-36.565934))
		end
		Sleep(82)

		Move(pelvis, y_axis, -0.119995)
		Move(pelvis, z_axis, -0.500000)
		Turn(lthigh, x_axis, math.rad(-57.302198))
		Turn(rthigh, x_axis, math.rad(10.708791))
		Turn(rcalf, x_axis, math.rad(21.093407))
		Turn(lcalf, x_axis, math.rad(43.598901))
		if not usingNano and not usingGun then
			Turn(torso, x_axis, math.rad(2.626374))
			Turn(larm, x_axis, math.rad(-8.598901))
			Turn(rarm, x_axis, math.rad(-11.769231))
			Turn(rhand, x_axis, math.rad(-14.230769))
			Turn(lhand, x_axis, math.rad(-24.774725))
		end
		Sleep(56)

		Move(pelvis, y_axis, 0.000000)
		Move(pelvis, z_axis, -0.400000)
		Turn(lthigh, x_axis, math.rad(-70.664835))
		Turn(rthigh, x_axis, math.rad(17.219780))
		Turn(rcalf, x_axis, math.rad(22.851648))
		Turn(lcalf, x_axis, math.rad(43.598901))
		if not usingNano and not usingGun then
			Turn(torso, x_axis, 0)
			Turn(larm, x_axis, 0)
			Turn(rarm, x_axis, math.rad(-13.708791))
			Turn(rhand, x_axis, math.rad(-19.324176))
			Turn(lhand, x_axis, math.rad(-13.000000))
		end
		Sleep(56)

		Move(pelvis, y_axis, 0.250000)
		Move(pelvis, z_axis, -0.200000)
		Move(lcalf, y_axis, 0.700000)
		Turn(lthigh, x_axis, math.rad(-76.296703))
		Turn(rthigh, x_axis, math.rad(18.983516))
		Turn(rcalf, x_axis, math.rad(25.313187))
		Turn(lcalf, x_axis, math.rad(37.263736))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-4.038462))
			Turn(torso, x_axis, math.rad(-2.626374))
			Turn(larm, x_axis, math.rad(10.890110))
			Turn(rarm, x_axis, math.rad(-14.928571))
			Turn(rhand, x_axis, math.rad(-28.994505))
			Turn(lhand, x_axis, math.rad(-12.818681))
		end
		Sleep(55)

		Move(pelvis, y_axis, 0.500000)
		Move(pelvis, z_axis, 0.000000)
		Move(lcalf, y_axis, -0.500000)
		Turn(lthigh, x_axis, math.rad(-81.917582))
		Turn(rthigh, x_axis, math.rad(20.741758))
		Turn(rcalf, x_axis, math.rad(27.774725))
		Turn(lcalf, x_axis, math.rad(30.934066))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-8.076923))
			Turn(torso, x_axis, math.rad(-5.269231))
			Turn(larm, x_axis, math.rad(21.791209))
			Turn(rarm, x_axis, math.rad(-16.170330))
			Turn(rhand, x_axis, math.rad(-38.675824))
			Turn(lhand, x_axis, math.rad(-12.648352))
		end
		Sleep(59)

		Move(pelvis, y_axis, 0.250000)
		Move(pelvis, z_axis, 0.869995)
		Move(lcalf, y_axis, -0.700000)
		Turn(lthigh, x_axis, math.rad(-68.384615))
		Turn(rthigh, x_axis, math.rad(29.357143))
		Turn(rcalf, x_axis, math.rad(25.483516))
		Turn(lcalf, x_axis, math.rad(26.010989))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-7.901099))
			Turn(torso, x_axis, math.rad(-2.626374))
			Turn(larm, x_axis, math.rad(34.456044))
			Turn(rarm, x_axis, math.rad(-22.851648))
			Turn(rhand, x_axis, math.rad(-54.489011))
			Turn(lhand, x_axis, math.rad(-20.912088))
		end
		Sleep(57)

		Move(pelvis, y_axis, 0.000000)
		Move(pelvis, z_axis, 1.739996)
		Move(lcalf, y_axis, -0.900000)
		Turn(lthigh, x_axis, math.rad(-54.851648))
		Turn(rthigh, x_axis, math.rad(37.967033))
		Turn(rcalf, x_axis, math.rad(23.203297))
		Turn(lcalf, x_axis, math.rad(21.093407))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-7.730769))
			Turn(torso, x_axis, 0)
			Turn(larm, x_axis, math.rad(47.109890))
			Turn(rarm, x_axis, math.rad(-29.532967))
			Turn(rhand, x_axis, math.rad(-70.324176))
			Turn(lhand, x_axis, math.rad(-29.175824))
		end
		Sleep(26)

		Move(pelvis, y_axis, -0.469995)
		Move(pelvis, z_axis, 2.059998)
		Move(rcalf, y_axis, 0.619995)
		Move(lcalf, y_axis, 0.000000 - 0.000031)
		Turn(pelvis, x_axis, math.rad(10.890110))
		Turn(lthigh, x_axis, math.rad(-43.598901))
		Turn(rthigh, x_axis, math.rad(18.104396))
		Turn(rcalf, x_axis, math.rad(48.170330))
		Turn(lcalf, x_axis, math.rad(21.263736))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-3.857143))
			Turn(torso, x_axis, math.rad(2.626374))
			Turn(larm, x_axis, math.rad(48.868132))
			Turn(rhand, x_axis, math.rad(-74.186813))
			Turn(lhand, x_axis, math.rad(-23.730769))
		end
		Sleep(27)

		Move(pelvis, y_axis, -0.939996)
		Move(pelvis, z_axis, 2.400000)
		Move(rcalf, y_axis, 1.239996)
		Move(lcalf, y_axis, 0.800000)
		Turn(lthigh, x_axis, math.rad(-32.346154))
		Turn(rthigh, x_axis, math.rad(-1.747253))
		Turn(rcalf, x_axis, math.rad(73.137363))
		Turn(lcalf, x_axis, math.rad(21.434066))
		if not usingNano and not usingGun then
			Turn(head, x_axis, 0)
			Turn(torso, x_axis, math.rad(5.269231))
			Turn(larm, x_axis, math.rad(50.631868))
			Turn(rhand, x_axis, math.rad(-78.054945))
			Turn(lhand, x_axis, math.rad(-18.280220))
		end
		Sleep(56)

		Move(pelvis, y_axis, -0.769995)
		Move(pelvis, z_axis, 1.619995)
		Move(rcalf, y_axis, 1.189996)
		Move(lcalf, y_axis, 0.700000)
		Turn(lthigh, x_axis, math.rad(-22.142857))
		Turn(rthigh, x_axis, math.rad(-5.087912))
		Turn(rcalf, x_axis, math.rad(58.362637))
		Turn(lcalf, x_axis, math.rad(11.252747))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(4.736264))
			Turn(torso, x_axis, math.rad(7.730769))
			Turn(larm, x_axis, math.rad(30.406593))
			Turn(rarm, x_axis, math.rad(-26.714286))
			Turn(rhand, x_axis, math.rad(-61.703297))
			Turn(lhand, x_axis, math.rad(-14.928571))
		end
		Sleep(55)

		Move(pelvis, y_axis, -0.589996)
		Move(pelvis, z_axis, 0.850000)
		Move(rcalf, y_axis, 1.129999)
		Move(lcalf, y_axis, 0.600000)
		Turn(lthigh, x_axis, math.rad(-11.950549))
		Turn(rthigh, x_axis, math.rad(-8.428571))
		Turn(rcalf, x_axis, math.rad(43.598901))
		Turn(lcalf, x_axis, math.rad(1.049451))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(9.489011))
			Turn(torso, x_axis, math.rad(10.192308))
			Turn(larm, x_axis, math.rad(10.192308))
			Turn(rarm, x_axis, math.rad(-23.901099))
			Turn(rhand, x_axis, math.rad(-45.357143))
			Turn(lhand, x_axis, math.rad(-11.598901))
		end
		Sleep(58)

		Move(pelvis, y_axis, -0.419995)
		Move(pelvis, z_axis, 0.119995)
		Move(rcalf, y_axis, 0.889996)
		Move(lcalf, y_axis, 0.300000)
		Turn(lthigh, x_axis, math.rad(-3.857143))
		Turn(rthigh, x_axis, math.rad(-26.181319))
		Turn(lcalf, x_axis, math.rad(10.192308))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(4.736264))
			Turn(torso, x_axis, math.rad(7.730769))
			Turn(larm, x_axis, math.rad(4.379121))
			Turn(rarm, x_axis, math.rad(-16.340659))
			Turn(rhand, x_axis, math.rad(-39.549451))
			Turn(lhand, x_axis, math.rad(-11.071429))
		end
		Sleep(57)

		Move(pelvis, y_axis, -0.250000)
		Move(pelvis, z_axis, -0.600000)
		Move(rcalf, y_axis, 0.639996)
		Move(lcalf, y_axis, 0.000000)
		Turn(pelvis, x_axis, math.rad(10.890110))
		Turn(lthigh, x_axis, math.rad(4.208791))
		Turn(rthigh, x_axis, math.rad(-43.950549))
		Turn(lcalf, x_axis, math.rad(19.324176))
		if not usingNano and not usingGun then
			Turn(head, x_axis, 0)
			Turn(torso, x_axis, math.rad(5.258242))
			Turn(larm, x_axis, math.rad(-1.395604))
			Turn(rarm, x_axis, math.rad(-8.769231))
			Turn(rhand, x_axis, math.rad(-33.758242))
			Turn(lhand, x_axis, math.rad(-10.538462))
		end
		Sleep(87)

		Move(pelvis, y_axis, -0.119995)
		Move(pelvis, z_axis, -0.500000)
		Move(rcalf, y_axis, 0.639996)
		Turn(lthigh, x_axis, math.rad(11.950549))
		Turn(rthigh, x_axis, math.rad(-57.302198))
		Turn(lcalf, x_axis, math.rad(21.093407))
		if not usingNano and not usingGun then
			Turn(torso, x_axis, math.rad(2.626374))
			Turn(larm, x_axis, math.rad(-4.208791))
			Turn(rarm, x_axis, math.rad(-4.379121))
			Turn(rhand, x_axis, math.rad(-23.203297))
			Turn(lhand, x_axis, math.rad(-16.873626))
		end
		Sleep(55)

		Move(pelvis, y_axis, 0.000000)
		Move(pelvis, z_axis, -0.400000)
		Move(rcalf, y_axis, 0.639996)
		Turn(lthigh, x_axis, math.rad(19.681319))
		Turn(rthigh, x_axis, math.rad(-70.664835))
		Turn(lcalf, x_axis, math.rad(22.851648))
		if not usingNano and not usingGun then
			Turn(torso, x_axis, 0)
			Turn(larm, x_axis, math.rad(-7.027473))
			Turn(rarm, x_axis, 0)
			Turn(rhand, x_axis, math.rad(-12.648352))
			Turn(lhand, x_axis, math.rad(-23.203297))
		end
		Sleep(56)

		Move(pelvis, y_axis, 0.250000)
		Move(pelvis, z_axis, -0.200000)
		Move(rcalf, y_axis, 0.700000)
		Move(lcalf, y_axis, 0.000000)
		Turn(lthigh, x_axis, math.rad(19.851648))
		Turn(rthigh, x_axis, math.rad(-76.296703))
		Turn(rcalf, x_axis, math.rad(37.263736))
		Turn(lcalf, x_axis, math.rad(25.313187))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-4.038462))
			Turn(torso, x_axis, math.rad(-2.626374))
			Turn(larm, x_axis, math.rad(-11.950549))
			Turn(rarm, x_axis, math.rad(7.901099))
			Turn(rhand, x_axis, math.rad(-12.478022))
			Turn(lhand, x_axis, math.rad(-24.252747))
		end
		Sleep(57)

		Move(pelvis, y_axis, 0.500000)
		Move(pelvis, z_axis, 0.000000)
		Move(rcalf, y_axis, -0.500000)
		Move(lcalf, y_axis, 0.000000)
		Turn(lthigh, x_axis, math.rad(20.032967))
		Turn(rthigh, x_axis, math.rad(-81.917582))
		Turn(rcalf, x_axis, math.rad(30.934066))
		Turn(lcalf, x_axis, math.rad(27.774725))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-8.076923))
			Turn(torso, x_axis, math.rad(-5.269231))
			Turn(larm, x_axis, math.rad(-16.873626))
			Turn(rarm, x_axis, math.rad(15.818681))
			Turn(rhand, x_axis, math.rad(-12.302198))
			Turn(lhand, x_axis, math.rad(-25.313187))
		end
		Sleep(59)

		Move(pelvis, y_axis, 0.250000)
		Move(pelvis, z_axis, 0.869995)
		Move(rcalf, y_axis, -0.700000)
		Move(lcalf, y_axis, 0.000000)
		Turn(pelvis, x_axis, math.rad(10.890110))
		Turn(lthigh, x_axis, math.rad(24.071429))
		Turn(rthigh, x_axis, math.rad(-68.384615))
		Turn(rcalf, x_axis, math.rad(26.010989))
		Turn(lcalf, x_axis, math.rad(25.483516))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-7.901099))
			Turn(torso, x_axis, math.rad(-2.626374))
			Turn(larm, x_axis, math.rad(-22.505495))
			Turn(rarm, x_axis, math.rad(31.642857))
			Turn(rhand, x_axis, math.rad(-20.741758))
			Turn(lhand, x_axis, math.rad(-45.527473))
		end
		Sleep(55)
		
		Move(pelvis, y_axis, 0.000000)
		Move(pelvis, z_axis, 1.750000)
		Move(rcalf, y_axis, -0.900000)
		Move(lcalf, y_axis, 0.000000)
		Turn(lthigh, x_axis, math.rad(28.126374))
		Turn(rthigh, x_axis, math.rad(-54.851648))
		Turn(rcalf, x_axis, math.rad(21.093407))
		Turn(lcalf, x_axis, math.rad(23.203297))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-7.730769))
			Turn(torso, x_axis, 0)
			Turn(larm, x_axis, math.rad(-28.126374))
			Turn(rarm, x_axis, math.rad(47.461538))
			Turn(rhand, x_axis, math.rad(-29.175824))
			Turn(lhand, x_axis, math.rad(-65.741758))
		end
		Sleep(28)

		Move(pelvis, y_axis, -0.469995)
		Move(pelvis, z_axis, 2.059998)
		Move(rcalf, y_axis, 0.000000 - 0.000031)
		Move(lcalf, y_axis, 0.600000)
		Turn(lthigh, x_axis, math.rad(13.181319))
		Turn(rthigh, x_axis, math.rad(-43.598901))
		Turn(rcalf, x_axis, math.rad(21.263736))
		Turn(lcalf, x_axis, math.rad(48.159341))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(-3.857143))
			Turn(torso, x_axis, math.rad(2.626374))
			Turn(larm, x_axis, math.rad(-27.774725))
			Turn(rarm, x_axis, math.rad(47.818681))
			Turn(rhand, x_axis, math.rad(-24.071429))
			Turn(lhand, x_axis, math.rad(-72.785714))
		end
		Sleep(27)

		Move(pelvis, y_axis, -0.939996)
		Move(pelvis, z_axis, 2.400000)
		Move(rcalf, y_axis, 0.789996)
		Move(lcalf, y_axis, 1.200000)
		Turn(lthigh, x_axis, math.rad(-1.747253))
		Turn(rthigh, x_axis, math.rad(-32.346154))
		Turn(rcalf, x_axis, math.rad(21.445055))
		Turn(lcalf, x_axis, math.rad(73.137363))
		if not usingNano and not usingGun then
			Turn(head, x_axis, 0)
			Turn(torso, x_axis, math.rad(5.269231))
			Turn(larm, x_axis, math.rad(-27.423077))
			Turn(rarm, x_axis, math.rad(48.159341))
			Turn(rhand, x_axis, math.rad(-18.983516))
			Turn(lhand, x_axis, math.rad(-79.807692))
		end
		Sleep(56)
		
		Move(pelvis, y_axis, -0.769995)
		Move(pelvis, z_axis, 1.619995)
		Move(rcalf, y_axis, 0.689996)
		Move(lcalf, y_axis, 1.350000)
		Turn(lthigh, x_axis, math.rad(-5.087912))
		Turn(rthigh, x_axis, math.rad(-22.142857))
		Turn(rcalf, x_axis, math.rad(11.252747))
		Turn(lcalf, x_axis, math.rad(58.362637))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(4.736264))
			Turn(torso, x_axis, math.rad(7.730769))
			Turn(larm, x_axis, math.rad(-24.961538))
			Turn(rarm, x_axis, math.rad(34.093407))
			Turn(rhand, x_axis, math.rad(-16.340659))
			Turn(lhand, x_axis, math.rad(-71.714286))
		end
		Sleep(55)
		
		Move(pelvis, y_axis, -0.589996)
		Move(pelvis, z_axis, 0.850000)
		Move(rcalf, y_axis, 0.589996)
		Move(lcalf, y_axis, 1.500000)
		Turn(lthigh, x_axis, math.rad(-8.428571))
		Turn(rthigh, x_axis, math.rad(-11.950549))
		Turn(rcalf, x_axis, math.rad(1.049451))
		Turn(lcalf, x_axis, math.rad(43.598901))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(9.489011))
			Turn(torso, x_axis, math.rad(10.192308))
			Turn(larm, x_axis, math.rad(-22.505495))
			Turn(rarm, x_axis, math.rad(20.032967))
			Turn(rhand, x_axis, math.rad(-13.708791))
			Turn(lhand, x_axis, math.rad(-63.642857))
		end
		Sleep(58)
		
		Move(pelvis, y_axis, -0.419995)
		Move(pelvis, z_axis, 0.119995)
		Move(rcalf, y_axis, 0.279999)
		Move(lcalf, y_axis, 1.069995)
		Turn(lthigh, x_axis, math.rad(-26.181319))
		Turn(rthigh, x_axis, math.rad(-3.857143))
		Turn(rcalf, x_axis, math.rad(10.192308))
		if not usingNano and not usingGun then
			Turn(head, x_axis, math.rad(4.736264))
			Turn(torso, x_axis, math.rad(7.730769))
			Turn(larm, x_axis, math.rad(-19.851648))
			Turn(rarm, x_axis, math.rad(5.087912))
			Turn(rhand, x_axis, math.rad(-11.417582))
			Turn(lhand, x_axis, math.rad(-50.098901))
		end
		Sleep(55)
	end
end

function script.StartMoving()
	StartThread(walk)
end


function script.StopMoving()
	Signal(SIG_WALK)
	
	Turn(pelvis, x_axis, 0, math.rad(200.000000))
	Turn(rthigh, x_axis, 0, math.rad(200.000000))
	Turn(rcalf, x_axis, 0, math.rad(200.000000))
	Turn(lthigh, x_axis, 0, math.rad(200.000000))
	Turn(lcalf, x_axis, 0, math.rad(200.000000))
	
	if not usingNano and not usingGun then
		Turn(torso, y_axis, 0, math.rad(90.000000))
		Turn(rhand, x_axis, 0, math.rad(200.000000))
		Turn(rarm, x_axis, 0, math.rad(200.000000))
		Turn(lhand, x_axis, 0, math.rad(200.000000))
		Turn(larm, x_axis, 0, math.rad(200.000000))
	end

end

--------------------------
-- NANO

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanoPiece)
	return nanoPiece
end

function script.StartBuilding(heading, pitch) 
	if GetUnitValue(COB.INBUILDSTANCE) == 0 then
		Signal(SIG_STOPBUILD)
		SetUnitValue(COB.INBUILDSTANCE, 1)
		SetSignalMask(SIG_BUILD)
		usingNano = true
		
		if not usingGun then
			Turn(torso, y_axis, heading, math.rad(250.000000))
		end
		Turn(larm, x_axis, -pitch-0.2, math.rad(150.000000))
		Turn(lhand, x_axis, math.rad(-45), math.rad(150.000000))
	end
end

function script.StopBuilding()
	if GetUnitValue(COB.INBUILDSTANCE) == 1 then
		Signal(SIG_BUILD)
		SetUnitValue(COB.INBUILDSTANCE, 0)
		SetSignalMask(SIG_STOPBUILD)
		
		usingNano = false
		Sleep(RESTORE_DELAY)
		
		if not usingGun then
			Turn(torso, y_axis, 0, math.rad(250.000000))
		end
		Turn(lhand, x_axis, 0, math.rad(150.000000))
		Turn(larm, x_axis, 0, math.rad(150.000000))
	end
end

--------------------------
-- WEAPON

function script.QueryWeapon(num) 
	return rhand 
end

function script.AimFromWeapon(num) 
	return torso 
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	usingGun = false
	Turn(torso, y_axis, 0, math.rad(250.000000))
	Turn(rhand, x_axis, 0, math.rad(150.000000))
	Turn(rarm, x_axis, 0, math.rad(150.000000))
end

function script.AimWeapon(num, heading, pitch)
	
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	usingGun = true
	
	Turn(torso, y_axis, heading, math.rad(250.000000))
	Turn(rarm, x_axis, -pitch-0.15, math.rad(150.000000))
	Turn(rhand, x_axis, math.rad(-45), math.rad(150.000000))
	
	WaitForTurn(torso, y_axis)
	WaitForTurn(rarm, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

--------------------------
-- JUMP

function preJump(turn,distance)
end

function beginJump()
	script.StopMoving()
	EmitSfx(jump, GG.Script.UNIT_SFX2)
end

function jumping()
	GG.PokeDecloakUnit(unitID, 50)
	EmitSfx(thrust, GG.Script.UNIT_SFX1)
end

function halfJump()
end

function endJump()
	script.StopMoving()
	EmitSfx(jump, GG.Script.UNIT_SFX2)
end

--------------------------
-- CREATE AND DESTROY

function script.Create()
	Hide(thrust)
	Hide(jump)
	Hide(flare)
	Turn(thrust, x_axis, math.rad(70), math.rad(2000))
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, {nanoPiece})
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	Hide(flare)
	if severity <= 0.25 then
	
		Explode(head, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lhand, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(larm, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rhand, SFX.NONE)
		Explode(rcalf, SFX.NONE)
		Explode(rarm, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(thrust, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	end
	if severity <= 0.5 then
	
		Explode(head, SFX.FALL)
		Explode(pelvis, SFX.FALL)
		Explode(lhand, SFX.FALL)
		Explode(lcalf, SFX.FALL)
		Explode(larm, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(rhand, SFX.FALL)
		Explode(rcalf, SFX.FALL)
		Explode(rarm, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(thrust, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	end
	
	Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lhand, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(larm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rhand, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(thrust, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(torso, SFX.SHATTER)
	return 2

end
