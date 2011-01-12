--by Chris Mackey

local wake = piece "wake"
local base = piece "base"
local firepoint = piece "firepoint"

local SIG_MOVE = 1

local function Rise()
	Move( base, y_axis, 20 )
	Sleep( 1000 )
	Move( base, y_axis, 0, 5 )
end

--[[
local function Swim()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while( TRUE )
	while true do
		Sleep(250)
	end
end

function script.StartMoving()
	StartThread(Swim)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end
--]]
function script.Create()
	--StartThread( Rise )
end

function script.QueryWeapon(num) 
--	return base
	return firepoint
end

function script.AimFromWeapon(num) return base end

function script.AimWeapon( num, heading, pitch )
	return num == 2
end

function script.FireWeapon(num)
-- FX goes here
end

--[[
function script.BlockShot(num)
	local targID = GetUnitValue(COB.TARGET_ID, 1)
	if targID < 0 then return false end	--attacking ground
	local ux,uy,uz = Spring.GetUnitBasePosition(targID)
	local y = Spring.GetGroundHeight(ux, uz)
	return (y > -3)		--bit of leeway for just being toe deep
end
--]]

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)
		return 1 -- corpsetype
	else	
		Explode(base, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
