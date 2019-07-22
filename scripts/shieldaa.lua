-- This is very much wip. There are lots of parts broken, so be warned. 
--by Chris Mackey

include "constants.lua"

-- pieces
local base = piece "base"
local head = piece "head"
local axle = piece "axle"
local podpist = piece "podpist"

-- missile rack
local pod = piece "pod"
local l_poddoor = piece "l_poddoor"
local r_poddoor = piece "r_poddoor"
local m_1 = piece "m_1"
local m_2 = piece "m_2"
local m_3 = piece "m_3"
local ex_1 = piece "ex_1"
local ex_2 = piece "ex_2"
local ex_3 = piece "ex_3"
local d_1 = piece "d_1"
local d_2 = piece "d_2"
local d_3 = piece "d_3"

--left leg
local l_thigh = piece "l_thigh"
local l_leg = piece "l_leg"
local l_pist = piece "l_pist"
local l_ankle = piece "l_ankle"
local l_foot = piece "r_foot"
local l_footie = piece "l_footie"
local l_toe = piece "l_toe"
local lf_toe = piece "lf_toe"
local lb_toe = piece "lb_toe"

--right leg
local r_thigh = piece "r_thigh"
local r_leg = piece "r_leg"
local r_pist = piece "r_pist"
local r_ankle = piece "r_ankle"
local r_foot = piece "l_foot"
local r_footie = piece "r_footie"
local r_toe = piece "r_toe"
local rf_toe = piece "rf_toe"
local rb_toe = piece "rb_toe"

local smokePiece = {head, pod}

local points = {
	{missile = m_1, exhaust = ex_1},
	{missile = m_2, exhaust = ex_2},
	{missile = m_3, exhaust = ex_3},
}

local missile = 1

--constants
local missilespeed = 850 --fixme
local mfront = 10 --fixme
local pause = 600

--effects
local smokeblast = 1024

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim = 4

function script.Create()
	Turn(ex_1, x_axis, math.rad(170))
	Turn(ex_2, x_axis, math.rad(170))
	Turn(ex_3, x_axis, math.rad(170))
	Turn(axle, x_axis, math.rad(-30))
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while (true) do -- needs major fixing. 
		Move(base, y_axis, 3.6, 12)
		
		Turn(l_thigh, x_axis, 0.6, 4)
		Turn(l_leg, x_axis, 0.6, 3.5)
		
		Turn(r_thigh, x_axis, -1, 5)
		Turn(r_leg, x_axis, -0.4, 6)
		Turn(r_foot, x_axis, -0.8, 4)
		
		Sleep(190)
		Move(base, y_axis, 0, 10)
		
		Turn(r_thigh, x_axis, -1, 2)
		Turn(r_leg, x_axis, 0.4, 6)
		Turn(r_foot, x_axis, 0, 3.5)
		
		Sleep(190)
		
		Move(base, y_axis, 3.6, 12)
		
		Turn(l_thigh, x_axis, -1, 5)
		Turn(l_leg, x_axis, -0.4, 6)
		Turn(l_foot, x_axis, -0.8, 4)
		
		Turn(r_thigh, x_axis, 0.6, 4)
		Turn(r_leg, x_axis, 0.6, 3.5)
		
		Sleep(190)
		
		Move(base, y_axis, 0, 10)
		
		Turn(l_thigh, x_axis, -1, 2)
		Turn(l_leg, x_axis, 0.4, 6)
		Turn(l_foot, x_axis, 0, 3.5)
		
		Sleep(190)
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	Move(base, y_axis, 0, 12)
	
	Turn(l_thigh, x_axis, 0, 2)
	Turn(l_leg, x_axis, 0, 2)
	Turn(l_foot, x_axis, 0, 2)
	
	Turn(r_thigh, x_axis, 0, 2)
	Turn(r_leg, x_axis, 0, 2)
	Turn(r_foot, x_axis, 0, 2)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(2000)
	Turn(head, y_axis, 0, 3)
	Turn(pod, x_axis, 0, 3)
	Move(podpist, y_axis, 0, 3)
end

----[[
function script.QueryWeapon1() return points[missile].missile end

function script.AimFromWeapon1() return pod end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	pitch = math.max(pitch, math.rad(20))	-- results in a minimum pod angle of 20° above horizontal
	Turn(head, y_axis, heading, 6)
	Turn(pod, x_axis, -pitch, 6)
	Move(podpist, y_axis, pitch*2.5, 3)
	WaitForTurn(head, y_axis)
	WaitForTurn(pod, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	EmitSfx(points[missile].exhaust, smokeblast)
	missile = missile + 1
	if missile > 3 then missile = 1 end
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/880
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 71, 30 * distMult)
	end
	return false
end

--]]

--[[ why are there two weapons???
function script.QueryWeapon2() return pod end

function script.AimFromWeapon2() return pod end

function script.AimWeapon2(heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(head, y_axis, heading, 5)
	Turn(pod, x_axis, -pitch, 5)
	--WaitForTurn(head, y_axis)
	--WaitForTurn(pod, x_axis)
	return true
end

function script.FireWeapon2()
	--effects
end
--]]

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(pod, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(pod, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		Explode(head, SFX.SMOKE + SFX.FIRE)
		Explode(pod, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
