include "constants.lua"

local base = piece 'base' 
--local imma_chargin = piece 'imma_chargin' 
local firepoint_test = piece 'firepoint' 
local firepoint = piece 'firepoint' 
local button  = piece 'button' 

local on = false

local built = false

local push = false

local smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2
local TARGET_ALT = 9001

local function MakeVisible()
	while true do
		for _, curUnitID in ipairs(Spring.GetAllUnits()) do
			Spring.SetUnitAlwaysVisible(curUnitID, true)
		end
		Sleep(1000)
	end
end

local SIZE_GROWTH = 25
local MAP_SIZE = Game.mapSizeX + Game.mapSizeZ

local function ShockwavesOfKillEverything()
	local _,_,_,x,y,z = Spring.GetUnitPosition(unitID, true)
	local size = 0
	while size < MAP_SIZE do
		local units = Spring.GetUnitsInSphere(x,y,z,size)
		for i = 1, #units do
			if units[i] ~= unitID then
				Spring.DestroyUnit(units[i])
			end
		end
		Sleep(250)
		size = size + SIZE_GROWTH
	end
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		if units[i] ~= unitID then
			Spring.DestroyUnit(units[i])
		end
	end
end

function script.HitByWeapon(x, z, weaponDefID, damage)
	if built then
		return 0
	end
	return damage
end


function script.Create()
	Turn(firepoint, z_axis, math.rad(0.04))
	Hide(firepoint)
	StartThread(SmokeUnit, smokePiece)
	local buildprogress = select(5, Spring.GetUnitHealth(unitID))
	while buildprogress < 1 do
		Sleep(250)
		buildprogress = select(5, Spring.GetUnitHealth(unitID))
	end
	built = true
	
	Move(firepoint, y_axis, TARGET_ALT, 30*4)
	StartThread(MakeVisible)
	StartThread(ShockwavesOfKillEverything)
end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	return true
end

function script.QueryWeapon1()
	return firepoint_test
end

function script.FireWeapon1()
	if not push then
		push = true
		Move(button, y_axis, -10, 16)
		WaitForMove(button, y_axis)
		Sleep(10)
		
		Move(button, y_axis, 0, 16)
		WaitForMove(button, y_axis)
		Sleep(10)
		push = false
	end
	
	--EmitSfx(firepoint_test,  FIRE_W2)
end

function script.AimFromWeapon1()
	return firepoint_test
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
