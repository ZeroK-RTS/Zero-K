local body = piece 'body' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 
local wake3 = piece 'wake3' 
local wake4 = piece 'wake4' 
local radar = piece 'radar' 
local landpad1 = piece 'landpad1' 
local landpad2 = piece 'landpad2' 
local landpad3 = piece 'landpad3' 
local landpad4 = piece 'landpad4' 
local landpad5 = piece 'landpad5' 
local landpad6 = piece 'landpad6' 
local landpad7 = piece 'landpad7' 
local landpad8 = piece 'landpad8' 
local landpad9 = piece 'landpad9' 
local hatch1 = piece 'hatch1' 
local hatch2 = piece 'hatch2' 
local hatch3 = piece 'hatch3' 
local hatch4 = piece 'hatch4' 
local hatch5 = piece 'hatch5' 
local hole1 = piece 'hole1' 
local hole2 = piece 'hole2' 
local hole3 = piece 'hole3' 
local hole4 = piece 'hole4' 
local hole5 = piece 'hole5' 
local muzzle1 = piece 'muzzle1' 
local muzzle2 = piece 'muzzle2' 
local muzzle3 = piece 'muzzle3' 
local muzzle4 = piece 'muzzle4' 
local muzzle5 = piece 'muzzle5' 

include "constants.lua"

smokePiece = {body,landpad1,landpad2,landpad3,landpad4,landpad5,landpad6,landpad7,landpad8,landpad9}
--local nanoPieces = {}

local missileSpots = {
	{hole = hole1, hatch = hatch2, muzzle = muzzle1},
	{hole = hole2, hatch = hatch3, muzzle = muzzle2},
	{hole = hole3, hatch = hatch4, muzzle = muzzle3},
	{hole = hole4, hatch = hatch1, muzzle = muzzle4},
}
local missileGun = 1

local SIG_MOVE = 1
local SIG_RESTORE = 2

function script.Create()
	Hide( muzzle1)
	Hide( muzzle2)
	Hide( muzzle3)
	Hide( muzzle4)
	Hide( muzzle5)
	Hide( wake1)
	Hide( wake2)
	StartThread(SmokeUnit)
	
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
		Sleep(1000)
	end
	Spin( radar , y_axis, rad(60) )
end

local function StartMoving()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	while  true  do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep(150)
	end
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	Signal( SIG_MOVE)
end

local function RestoreAfterDelay()
	Signal( SIG_RESTORE)
	SetSignalMask( SIG_RESTORE)
	Sleep(3000)
	Turn( hatch1 , x_axis, 0, rad(35) )
	Turn( hatch2 , x_axis, 0, rad(35) )
	Turn( hatch3 , x_axis, 0, rad(35) )
	Turn( hatch4 , x_axis, 0, rad(35) )
	Turn( hatch5 , x_axis, 0, rad(35) )
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		return true
	elseif num == 2 then
		Turn( missileSpots[missileGun].hatch , x_axis, rad(-90), rad(180) )
		WaitForTurn(missileSpots[missileGun].hatch, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 3 then
		Turn( hatch5 , x_axis, rad(-90), rad(180) )
		WaitForTurn(hatch5, x_axis)
		return true
	end
end

function script.FireWeapon(num)
	if num == 1 then
		
	elseif num == 2 then
		Turn( hatch1 , x_axis, 0, rad(35) )
		Turn( hatch2 , x_axis, 0, rad(35) )
		Turn( hatch3 , x_axis, 0, rad(35) )
		Turn( hatch4 , x_axis, 0, rad(35) )
		missileGun = (missileGun%4) + 1
	elseif num == 3 then
		Sleep(1300)
		Turn( hatch5 , x_axis, 0, rad(35) )
		Sleep(3000)
	end
end

function script.AimFromWeapon(num)
	if num == 1 then
		return radar
	elseif num == 2 then
		return missileSpots[missileGun].hole
	elseif num == 3 then
		return hole5
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		return radar
	elseif num == 2 then
		return missileSpots[missileGun].hole
	elseif num == 3 then
		return hole5
	end
end


function script.QueryLandingPads()
	return {landpad1,landpad2,landpad3,landpad4,landpad5,landpad6,landpad7,landpad8,landpad9}
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		return 1
	elseif severity <= 0.50 then
		return 1
	else
		return 2
	end
end
