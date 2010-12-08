--by Chris Mackey

local wake = piece "wake"
local base = piece "base"
local tube1 = piece "tube1"
local tube2 = piece "tube2"

local tube = false
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
	StartThread( Rise )
end

function script.QueryWeapon1() 
--	return base
	if tube then return tube1
	else return tube2 end
end

function script.AimFromWeapon1() return base end

function script.AimWeapon1( heading, pitch )
	return true
end

function script.FireWeapon1()
	tube = not tube
end

function script.BlockShot1()
	local targID = GetUnitValue(COB.TARGET_ID, 1)
	if targID < 0 then return false end	--attacking ground
	local ux,uy,uz = Spring.GetUnitBasePosition(targID)
	local y = Spring.GetGroundHeight(ux, uz)
	return (y > -3)		--bit of leeway for just being toe deep
end

function script.Killed(recentDamage, maxHealth)
	Explode( base, SFX.SHATTER )
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		return 1 -- corpsetype

	elseif (severity <= .5) then
		return 2 -- corpsetype

	else		
		return 3 -- corpsetype
	end
end
