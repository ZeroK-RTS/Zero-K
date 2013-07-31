include "constants.lua"

local base = piece 'base' 
--local imma_chargin = piece 'imma_chargin' 
local firepoint_test = piece 'firepoint' 
local firepoint = piece 'firepoint' 
local button  = piece 'button' 

local on = false

smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2
local TARGET_ALT = 9001

local function MakeVisible()
    while true do
        for _, curUnitID in ipairs( Spring.GetAllUnits() ) do
            Spring.SetUnitAlwaysVisible(curUnitID , true)
        end
        Sleep(1000)
    end
end

function script.HitByWeapon( x, z, weaponDefID, damage )
	return 0
end

function script.Activate()
	Move( firepoint , y_axis, TARGET_ALT , 30*4)
	on = true
end

function script.Deactivate()
	Move( firepoint , y_axis, 0 , 250*4)
	on = false
	Signal( SIG_AIM)
end

function script.Create()
	Turn( firepoint , z_axis, math.rad(0.04) )
	Hide( firepoint)
	StartThread(SmokeUnit)
    local buildprogress = select(5, Spring.GetUnitHealth(unitID))
	while buildprogress < 1 do
	    Sleep(250)
	    buildprogress = select(5, Spring.GetUnitHealth(unitID))
	end
    StartThread(MakeVisible)
    
end

function script.AimWeapon(num, heading, pitch)
	if on then
		Signal( SIG_AIM)
		SetSignalMask( SIG_AIM)
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return firepoint_test
end

function script.FireWeapon(num)
    Move( button , y_axis, -10 , 16)
    WaitForMove(button, y_axis)
    Sleep(1)
    Move( button , y_axis, 0 , 16)
    WaitForMove(button, y_axis)
    Sleep(1)
    
	EmitSfx( firepoint_test,  FIRE_W2 )
end

function script.AimFromWeapon(num)
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
