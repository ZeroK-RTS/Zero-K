local body = piece 'body'

local LUpperClaw1 	= piece 'LUpperClaw1'
local LMidClaw1 	= piece 'LMidClaw1'
local LLowClaw1 	= piece 'LLowClaw1'
local LUpperClaw2 	= piece 'LUpperClaw2'
local LMidClaw2 	= piece 'LMidClaw2'
local LLowClaw2 	= piece 'LLowClaw2'
local LUpperClaw3 	= piece 'LUpperClaw3'
local LMidClaw3 	= piece 'LMidClaw3'
local LLowClaw3 	= piece 'LLowClaw3'
local LUpperClaw4 	= piece 'LUpperClaw4'
local LMidClaw4 	= piece 'LMidClaw4'
local LLowClaw4 	= piece 'LLowClaw4'

local RUpperClaw1 	= piece 'RUpperClaw1'
local RMidClaw1 	= piece 'RMidClaw1'
local RLowClaw1 	= piece 'RLowClaw1'
local RUpperClaw2 	= piece 'RUpperClaw2'
local RMidClaw2 	= piece 'RMidClaw2'
local RLowClaw2 	= piece 'RLowClaw2'
local RUpperClaw3 	= piece 'RUpperClaw3'
local RMidClaw3 	= piece 'RMidClaw3'
local RLowClaw3 	= piece 'RLowClaw3'
local RUpperClaw4 	= piece 'RUpperClaw4'
local RMidClaw4 	= piece 'RMidClaw4'
local RLowClaw4 	= piece 'RLowClaw4'

local FrontTurret	= piece 'FrontTurret'
local FrontGun1		= piece 'FrontGun1'
local FrontGun2		= piece 'FrontGun2'
local fflare1		= piece 'fflare1'
local fflare2		= piece 'fflare2'
local fflare3		= piece 'fflare3'
local fflare4		= piece 'fflare4'


local RTurretDoor	= piece 'RTurretDoor'
local RTurretBase	= piece 'RTurretBase'
local RTurretHinge	= piece 'RTurretHinge'
local RTurretVHinge	= piece 'RTurretVHinge'
local RTurretGun1	= piece 'RTurretGun1'
local RTurretGun2	= piece 'RTurretGun2'
local RTurretBarrel1= piece 'RTurretBarrel1'
local RTurretBarrel2= piece 'RTurretBarrel2'
local Rflare1		= piece 'Rflare1'
local Rflare2		= piece 'Rflare2'


local LTurretDoor	= piece 'LTurretDoor'
local LTurretBase 	= piece 'LTurretBase'
local LTurretHinge	= piece 'LTurretHinge'
local LTurretVHinge	= piece 'LTurretVHinge'
local LTurretGun1	= piece 'LTurretGun1'
local LTurretGun2	= piece 'LTurretGun2'
local LTurretBarrel1= piece 'LTurretBarrel1'
local LTurretBarrel2= piece 'LTurretBarrel2'
local Lflare1		= piece 'Lflare1'
local Lflare2		= piece 'Lflare2'

local engineEmit 	= piece 'engineEmit'
local link 			= piece 'link'

local dust1, dust2	= piece('dust1', 'dust2')

local AttachUnit = Spring.UnitScript.AttachUnit
local DropUnit = Spring.UnitScript.DropUnit

local loaded = false
local unitLoaded = nil
local doorOpen = false
local takeoffOrLanding = false

local SIG_OPENDOORS = 1
local SIG_CLOSEDOORS = 2
local SIG_AIM = 4
local SIG_AIM2 = 8
local SIG_AIM3 = 16
local SIG_TOL = 64

local doorSpeed = 3

local weaponPieces = {
	{aimFrom = RTurretBase, query = {Rflare1, Rflare2}, index = 1},
	{aimFrom = LTurretBase, query = {Lflare1, Lflare2}, index = 1},
	{aimFrom = FrontTurret, query = {fflare1,fflare2,fflare3,fflare4}, index = 1},
}

local smokePiece = {body, engineEmit}

include "constants.lua"
include "transports.lua"

local function openDoors()

	Signal(SIG_OPENDOORS)
	SetSignalMask(SIG_OPENDOORS)
	
	Turn(LUpperClaw1,z_axis, math.rad(40),doorSpeed)
	Turn(RUpperClaw1,z_axis, math.rad(-40),doorSpeed)
	Turn(LMidClaw1,z_axis, math.rad(40),doorSpeed)
	Turn(RMidClaw1,z_axis, math.rad(-40),doorSpeed)
	Turn(LLowClaw1,z_axis, math.rad(40),doorSpeed)
	Turn(RLowClaw1,z_axis, math.rad(-40),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw2,z_axis, math.rad(40),doorSpeed)
	Turn(RUpperClaw2,z_axis, math.rad(-40),doorSpeed)
	Turn(LMidClaw2,z_axis, math.rad(40),doorSpeed)
	Turn(RMidClaw2,z_axis, math.rad(-40),doorSpeed)
	Turn(LLowClaw2,z_axis, math.rad(40),doorSpeed)
	Turn(RLowClaw2,z_axis, math.rad(-40),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw3,z_axis, math.rad(40),doorSpeed)
	Turn(RUpperClaw3,z_axis, math.rad(-40),doorSpeed)
	Turn(LMidClaw3,z_axis, math.rad(40),doorSpeed)
	Turn(RMidClaw3,z_axis, math.rad(-40),doorSpeed)
	Turn(LLowClaw3,z_axis, math.rad(40),doorSpeed)
	Turn(RLowClaw3,z_axis, math.rad(-40),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw4,z_axis, math.rad(40),doorSpeed)
	Turn(RUpperClaw4,z_axis, math.rad(-40),doorSpeed)
	Turn(LMidClaw4,z_axis, math.rad(40),doorSpeed)
	Turn(RMidClaw4,z_axis, math.rad(-40),doorSpeed)
	Turn(LLowClaw4,z_axis, math.rad(40),doorSpeed)
	Turn(RLowClaw4,z_axis, math.rad(-40),doorSpeed)
	Sleep(200)
	doorOpen = true
	--[[
	WaitForTurn(LUpperClaw1, z_axis)
	WaitForTurn(RUpperClaw1, z_axis)
	WaitForTurn(LMidClaw1,z_axis)
	WaitForTurn(RMidClaw1,z_axis)
	WaitForTurn(LLowClaw1,z_axis)
	WaitForTurn(RLowClaw1,z_axis)
	
	WaitForTurn(LUpperClaw2, z_axis)
	WaitForTurn(RUpperClaw2, z_axis)
	WaitForTurn(LMidClaw2,z_axis)
	WaitForTurn(RMidClaw2,z_axis)
	WaitForTurn(LLowClaw2,z_axis)
	WaitForTurn(RLowClaw2,z_axis)
	
	WaitForTurn(LUpperClaw3, z_axis)
	WaitForTurn(RUpperClaw3, z_axis)
	WaitForTurn(LMidClaw3,z_axis)
	WaitForTurn(RMidClaw3,z_axis)
	WaitForTurn(LLowClaw3,z_axis)
	WaitForTurn(RLowClaw3,z_axis)
	
	WaitForTurn(LUpperClaw4, z_axis)
	WaitForTurn(RUpperClaw4, z_axis)
	WaitForTurn(LMidClaw4,z_axis)
	WaitForTurn(RMidClaw4,z_axis)
	WaitForTurn(LLowClaw4,z_axis)
	WaitForTurn(RLowClaw4,z_axis)
	]]
end


function closeDoors()
	Signal(SIG_CLOSEDOORS)
	SetSignalMask(SIG_CLOSEDOORS)

	Turn(LUpperClaw1,z_axis, math.rad(0),doorSpeed)
	Turn(RUpperClaw1,z_axis, math.rad(0),doorSpeed)
	Turn(LMidClaw1,z_axis, math.rad(0),doorSpeed)
	Turn(RMidClaw1,z_axis, math.rad(0),doorSpeed)
	Turn(LLowClaw1,z_axis, math.rad(0),doorSpeed)
	Turn(RLowClaw1,z_axis, math.rad(0),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw2,z_axis, math.rad(0),doorSpeed)
	Turn(RUpperClaw2,z_axis, math.rad(0),doorSpeed)
	Turn(LMidClaw2,z_axis, math.rad(0),doorSpeed)
	Turn(RMidClaw2,z_axis, math.rad(0),doorSpeed)
	Turn(LLowClaw2,z_axis, math.rad(0),doorSpeed)
	Turn(RLowClaw2,z_axis, math.rad(0),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw3,z_axis, math.rad(0),doorSpeed)
	Turn(RUpperClaw3,z_axis, math.rad(0),doorSpeed)
	Turn(LMidClaw3,z_axis, math.rad(0),doorSpeed)
	Turn(RMidClaw3,z_axis, math.rad(0),doorSpeed)
	Turn(LLowClaw3,z_axis, math.rad(0),doorSpeed)
	Turn(RLowClaw3,z_axis, math.rad(0),doorSpeed)
	Sleep(200)
	Turn(LUpperClaw4,z_axis, math.rad(0),doorSpeed)
	Turn(RUpperClaw4,z_axis, math.rad(0),doorSpeed)
	Turn(LMidClaw4,z_axis, math.rad(0),doorSpeed)
	Turn(RMidClaw4,z_axis, math.rad(0),doorSpeed)
	Turn(LLowClaw4,z_axis, math.rad(0),doorSpeed)
	Turn(RLowClaw4,z_axis, math.rad(0),doorSpeed)
	Sleep(200)
	doorOpen = false
	--[[
	WaitForTurn(LUpperClaw1, z_axis)
	WaitForTurn(RUpperClaw1, z_axis)
	WaitForTurn(LMidClaw1,z_axis)
	WaitForTurn(RMidClaw1,z_axis)
	WaitForTurn(LLowClaw1,z_axis)
	WaitForTurn(RLowClaw1,z_axis)
	
	
	WaitForTurn(LUpperClaw2, z_axis)
	WaitForTurn(RUpperClaw2, z_axis)
	WaitForTurn(LMidClaw2,z_axis)
	WaitForTurn(RMidClaw2,z_axis)
	WaitForTurn(LLowClaw2,z_axis)
	WaitForTurn(RLowClaw2,z_axis)
	
	WaitForTurn(LUpperClaw3, z_axis)
	WaitForTurn(RUpperClaw3, z_axis)
	WaitForTurn(LMidClaw3,z_axis)
	WaitForTurn(RMidClaw3,z_axis)
	WaitForTurn(LLowClaw3,z_axis)
	WaitForTurn(RLowClaw3,z_axis)
	
	WaitForTurn(LUpperClaw4, z_axis)
	WaitForTurn(RUpperClaw4, z_axis)
	WaitForTurn(LMidClaw4,z_axis)
	WaitForTurn(RMidClaw4,z_axis)
	WaitForTurn(LLowClaw4,z_axis)
	WaitForTurn(RLowClaw4,z_axis)
	]]
end

local function DustLoop()
	while true do
		if (takeoffOrLanding) then
			EmitSfx(dust1, 1025)
			EmitSfx(dust2, 1025)
		end
		Sleep(66)
	end
end


local function TakeOffOrLand()
	Signal(SIG_TOL)
	SetSignalMask(SIG_TOL)
	takeoffOrLanding = true
	Sleep(1200)
	takeoffOrLanding = false
end

--Special ability: drop unit midair
function ForceDropUnit()
	if (unitLoaded ~= nil) and Spring.ValidUnitID(unitLoaded) then
		local x,y,z = Spring.GetUnitPosition(unitLoaded) --cargo position
		local _,ty = Spring.GetUnitPosition(unitID) --transport position
		local vx,vy,vz = Spring.GetUnitVelocity(unitID) --transport speed
		DropUnit(unitLoaded) --detach cargo
		local transRadius = Spring.GetUnitRadius(unitID)
		Spring.SetUnitPosition(unitLoaded, x,math.min(y, ty-transRadius),z) --set cargo position below transport
		Spring.AddUnitImpulse(unitLoaded,0,4,0) --hax to prevent teleport to ground
		Spring.AddUnitImpulse(unitLoaded,0,-4,0) --hax to prevent teleport to ground
		Spring.SetUnitVelocity(unitLoaded,0,0,0) --remove any random velocity caused by collision with transport (especially Spring 91)
		Spring.AddUnitImpulse(unitLoaded,vx,vy,vz) --readd transport momentum
	end
	unitLoaded = nil
	StartThread(script.EndTransport) --formalize unit drop (finish animation, clear tag, ect)
end

function OnStartingCrash()
	ForceDropUnit()
end

--fetch unit id of passenger (from the load command)
function getPassengerId()
	local cmd=Spring.GetCommandQueue(unitID, 1)
	local unitId = nil
	
	if cmd and cmd[1] then
		if cmd[1]['id'] == 75 then -- CMDTYPE.LOAD_UNITS = 75
			unitId = cmd[1]['params'][1]
		end
	end
	
	return unitId
end

--fetch id of command
function getCommandId()
	local cmd=Spring.GetCommandQueue(unitID, 1)
	if cmd and cmd[1] then
		return cmd[1]['id']
	end
	
	return nil
end

function getDropPoint()
	local cmd = Spring.GetCommandQueue(unitID, 1)
	if cmd and cmd[1] and cmd[1].id == 81 then -- CMDTYPE.LOAD_UNITS = 75
		return cmd[1]['params'][1], cmd[1]['params'][2], cmd[1]['params'][3]
	end
	return false
end

function isNearPickupPoint(passengerId, requiredDist)
	if passengerId == nil then
		return false
	end

	local px, py, pz = Spring.GetUnitBasePosition(passengerId)
	if not px then
		return
	end
	
	local px2, py2, pz2 = Spring.GetUnitBasePosition(unitID)
	if not px2 then
		return
	end
	
	local dx = px2 - px
	local dz = pz2 - pz
	local dist = (dx^2 + dz^2)
	
	if dist < requiredDist^2 then
		return true
	else
		return false
	end
end

function isNearDropPoint(transportUnitId, requiredDist)
	if transportUnitId == nil then
		return false
	end

	local px, py, pz = Spring.GetUnitBasePosition(transportUnitId)
	if not px then
		return false
	end
	local px2, py2, pz2 = getDropPoint()
	if not px2 then
		return false
	end
	
	local dx = px - px2
	local dz = pz - pz2
	local dist = (dx^2 + dz^2)
	
	if dist < requiredDist^2 then
		return true
	else
		return false
	end
end

function isValidCargo(soonPassenger, passenger)
	return ((soonPassenger and Spring.ValidUnitID(soonPassenger)) or
	(passenger and Spring.ValidUnitID(passenger)))
end

local function PickupAndDropFixer()
	while true do
		local passengerId = getPassengerId()
		if passengerId and (getCommandId() == 75) and isValidCargo(passengerId) and isNearPickupPoint(passengerId, 120) then
			Sleep(1500)
			local passengerId = getPassengerId()
			if passengerId and (getCommandId() == 75) and isValidCargo(passengerId) and isNearPickupPoint(passengerId, 120) then
				Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
				Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
			end
		end
		
		if unitLoaded and (getCommandId() == 81) and isNearDropPoint(unitLoaded, 80) then
			Sleep(1500)
			if unitLoaded and (getCommandId() == 81) and isNearDropPoint(unitLoaded, 80) then
				Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
				Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
			end
		end
		
		Sleep(500)
	end
end

function script.MoveRate(curRate)
	local passengerId = getPassengerId()
	
	if doorOpen and not isValidCargo(passengerId,unitLoaded) then
		unitLoaded = nil
		StartThread(script.EndTransport) --formalize unit drop (finish animation, clear tag, ect)
	elseif getCommandId() == 75 and isNearPickupPoint(passengerId, 1000) then
		StartThread(openDoors)
	elseif getCommandId() == 81 and isNearDropPoint(unitLoaded, 1000) then
		StartThread(openDoors)
	end
end

function script.BeginTransport(passengerID)
	if loaded then
		return
	end
	Move(link, y_axis, -Spring.GetUnitHeight(passengerID) - 15, nil, true)
	
	if not GG.TransportAllowed(unitID, passengerID) then
		Sleep(10)
		unitLoaded = passengerID
		ForceDropUnit()
		return
	end
	
	--local px, py, pz = Spring.GetUnitBasePosition(passengerID)
	SetUnitValue(COB.BUSY, 1)

	AttachUnit(link, passengerID)
	unitLoaded = passengerID
	loaded = true
	
	
	Sleep(500)
	
	--StartThread(closeDoors)
end

function script.EndTransport()
	getDropPoint()
	--StartThread(openDoors)
	if (unitLoaded ~= nil) then
		DropUnit(unitLoaded)
		unitLoaded = nil
	end
	loaded = false
	SetUnitValue(COB.BUSY, 0)
	Sleep(1000)
	StartThread(closeDoors)
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM2)
		SetSignalMask(SIG_AIM2)
		
		Turn(LTurretHinge, y_axis, heading - math.rad(90), 10)
		Turn(LTurretVHinge, z_axis, pitch, 10)
		WaitForTurn(LTurretHinge, y_axis)
		WaitForTurn(LTurretVHinge, z_axis)
		return true
	elseif num == 2 then
		Signal(SIG_AIM3)
		SetSignalMask(SIG_AIM3)
		
		Turn(RTurretHinge, y_axis, math.rad(90) + heading, 10)
		Turn(RTurretVHinge, z_axis, -pitch, 10)
		WaitForTurn(RTurretHinge, y_axis)
		WaitForTurn(RTurretVHinge, z_axis)
		return true
	elseif num == 3 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		Turn(FrontGun1,x_axis, -pitch,6)
		Turn(FrontGun2,x_axis, -pitch,6)
		WaitForTurn(FrontGun1, x_axis)
		return true
	end
	
end

function script.Create()
	Turn(dust1, x_axis, math.rad(90))
	Turn(dust2, x_axis, math.rad(90))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(PickupAndDropFixer)
	--StartThread(DustLoop)	-- looks stupid
	
	Spring.MoveCtrl.SetGunshipMoveTypeData(unitID,"bankingAllowed",false)
	--Spring.MoveCtrl.SetGunshipMoveTypeData(unitID,"turnRate",0)
	
	Move(LTurretDoor, y_axis, 3)
	Move(LTurretBase, x_axis, 10)
	Move(RTurretDoor, y_axis, 3, 10)
	Move(RTurretBase, x_axis, -10, 14) --11
end

function script.Activate()
	StartThread(TakeOffOrLand)
end

function script.Deactivate()
	StartThread(TakeOffOrLand)
	StartThread(closeDoors)
end


function script.QueryTransport(passengerID)
	return link
end

function script.AimFromWeapon(num)
	return weaponPieces[num].aimFrom
end

function script.QueryWeapon(num)
	local pieces = weaponPieces[num].query
	return pieces[weaponPieces[num].index]
end


function script.Shot(num)
	local index = weaponPieces[num].index
	index = index + 1
	if index > #(weaponPieces[num].query) then
		index = 1
	end
	weaponPieces[num].index = index
	if num < 3 then
		EmitSfx(weaponPieces[num].query[index], 1026)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	StartThread(ForceDropUnit)
	if severity <= 0.25 then
		Explode(body, SFX.NONE)
		Explode(RUpperClaw1, SFX.SHATTER	)
		Explode(RMidClaw1 	, SFX.SHATTER	)
		Explode(RLowClaw1 	, SFX.SHATTER	)
		Explode(RUpperClaw2, SFX.SHATTER	)
		Explode(RMidClaw2 	, SFX.SHATTER	)
		Explode(RLowClaw2 	, SFX.SHATTER	)
		Explode(RUpperClaw3, SFX.SHATTER	)
		Explode(RMidClaw3 	, SFX.SHATTER	)
		Explode(RLowClaw3 	, SFX.SHATTER	)
		Explode(RUpperClaw4, SFX.SHATTER	)
		Explode(RMidClaw4 	, SFX.SHATTER	)
		return 1
	elseif severity <= 0.50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(body, SFX.SHATTER)
		Explode(RUpperClaw1, SFX.SHATTER	)
		Explode(RMidClaw1 	, SFX.SHATTER	)
		Explode(RLowClaw1 	, SFX.SHATTER	)
		Explode(RUpperClaw2, SFX.SHATTER	)
		Explode(RMidClaw2 	, SFX.SHATTER	)
		Explode(RLowClaw2 	, SFX.SHATTER	)
		Explode(RUpperClaw3, SFX.SHATTER	)
		Explode(RMidClaw3 	, SFX.SHATTER	)
		Explode(RLowClaw3 	, SFX.SHATTER	)
		Explode(RUpperClaw4, SFX.SHATTER	)
		Explode(RMidClaw4 	, SFX.SHATTER	)
		return 1
	else
		Explode(body, SFX.SHATTER)
		Explode(RUpperClaw1, SFX.SHATTER	)
		Explode(RMidClaw1 	, SFX.SHATTER	)
		Explode(RLowClaw1 	, SFX.SHATTER	)
		Explode(RUpperClaw2, SFX.SHATTER	)
		Explode(RMidClaw2 	, SFX.SHATTER	)
		Explode(RLowClaw2 	, SFX.SHATTER	)
		Explode(RUpperClaw3, SFX.SHATTER	)
		Explode(RMidClaw3 	, SFX.SHATTER	)
		Explode(RLowClaw3 	, SFX.SHATTER	)
		Explode(RUpperClaw4, SFX.SHATTER	)
		Explode(RMidClaw4 	, SFX.SHATTER	)
		return 2
	end
end
