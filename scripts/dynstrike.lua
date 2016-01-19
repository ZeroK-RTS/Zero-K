include "constants.lua"

dyncomm = include('dynamicCommander.lua')

local AntennaTip = piece('AntennaTip')
local ArmLeft = piece('ArmLeft')
local ArmRight = piece('ArmRight')
local AssLeft = piece('AssLeft')
local AssRight = piece('AssRight')
local Breast = piece('Breast')
local CalfLeft = piece('CalfLeft')
local CalfRight = piece('CalfRight')
local FingerA = piece('FingerA')
local FingerB = piece('FingerB')
local FingerC = piece('FingerC')
local FootLeft = piece('FootLeft')
local FootRight = piece('FootRight')
local Gun = piece('Gun')
local HandRight = piece('HandRight')
local Head = piece('Head')
local HipLeft = piece('HipLeft')
local HipRight = piece('HipRight')
local Muzzle = piece('Muzzle')
local Palm = piece('Palm')
local Stomach = piece('Stomach')
local Base = piece('Base')
local Nano = piece('Nano')
local UnderGun = piece('UnderGun')
local UnderMuzzle = piece('UnderMuzzle')
local Eye = piece('Eye')
local Shield = piece('Shield')
local FingerTipA = piece('FingerTipA')
local FingerTipB = piece('FingerTipB')
local FingerTipC = piece('FingerTipC')

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local nanoPieces = {Muzzle}

function script.Create()
	dyncomm.Create()
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	
	--Move(UnderGun, x_axis, 0)
	--Move(UnderGun, y_axis, -1)
	--Move(UnderGun, z_axis, 1)
end

local SIG_RIGHT = 1
local SIG_RESTORE_TORSO = 2
local SIG_RESTORE_RIGHT = 4
local RESTORE_DELAY = 2500

---------------------------

function script.AimFromWeapon(num)
	if dyncomm.IsManualFire(num) then
		if dyncomm.GetWeapon(num) == 1 then 
			return Palm
		elseif dyncomm.GetWeapon(num) == 2 then 
			return UnderMuzzle
		end
	end
	return Shield
end

function script.QueryWeapon(num)
	if dyncomm.GetWeapon(num) == 1 then 
		return Palm
	elseif dyncomm.GetWeapon(num) == 2 then 
		return UnderMuzzle
	end
	return Shield
end

local function RestoreTorsoAim()
	Signal(SIG_RESTORE_TORSO)
	SetSignalMask(SIG_RESTORE_TORSO)
	Sleep(RESTORE_DELAY)
end

local function RestoreRightAim()
	StartThread(RestoreTorsoAim)
	Signal(SIG_RESTORE_RIGHT)
	SetSignalMask(SIG_RESTORE_RIGHT)
	Sleep(RESTORE_DELAY)
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)
	
	if weaponNum == 1 then
		Signal(SIG_RIGHT)
		SetSignalMask(SIG_RIGHT)
		Turn(ArmRight, x_axis, -pitch/2 - 0.7, ARM_SPEED_PITCH)
		Turn(Stomach, z_axis, heading, TORSO_SPEED_YAW)
		Turn(HandRight, x_axis, -pitch/2 - 0.8, ARM_SPEED_PITCH)
		WaitForTurn(Stomach, y_axis)
		WaitForTurn(ArmRight, x_axis)
		StartThread(RestoreRightAim)
		return true
	end
	return (weaponNum and true) or false
end

function script.FireWeapon(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponFireSfx(UnderMuzzle, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponFireSfx(UnderMuzzle, num)
	end
end

function script.Shot(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponShotSfx(UnderMuzzle, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponShotSfx(UnderMuzzle, num)
	end
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.StartBuilding(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),Palm)
	return Palm
end
