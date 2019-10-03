include "constants.lua"

local base = piece 'base'
local torso = piece 'torso'
local turret = piece 'turret'
local lbarrel = piece 'lbarrel'
local lflare = piece 'lflare'
local rbarrel = piece 'rbarrel'
local rflare = piece 'rflare'
local larm = piece 'larm'
local rarm = piece 'rarm'

local lfrontleg = piece 'lfrontleg'
local lfrontleg1 = piece 'lfrontleg1'

local rfrontleg = piece 'rfrontleg'
local rfrontleg1 = piece 'rfrontleg1'

local laftleg = piece 'laftleg'
local laftleg1 = piece 'laftleg1'

local raftleg = piece 'raftleg'
local raftleg1 = piece 'raftleg1'

local PACE = 1.4

local SIG_Walk = 1
local SIG_Aim = 2

--constants
local PI = math.pi
local sa = math.rad(-10)
local ma = math.rad(40)
local la = math.rad(100)
local pause = 440

local forward = 2.2
local backward = 2
local up = 1

local gun = false

local smokePiece = {base, barrel}

function script.Create()
	Turn(lfrontleg, y_axis, math.rad(45))
	Turn(rfrontleg, y_axis, math.rad(-45))
	Turn(laftleg, y_axis, math.rad(-45))
	Turn(raftleg, y_axis, math.rad(45))

	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end


local function RestoreAfterDelay()
	Sleep(2750)
	Turn(turret, y_axis, 0, math.rad(90))
	WaitForTurn(turret, y_axis)
	Turn(torso, x_axis, 0, math.rad(90))
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	while (true) do

		-- Move(base, y_axis, 1.5, 2*up)
		Turn(lfrontleg, y_axis, 1.5*ma, forward) -- right front forward
		Turn(lfrontleg, z_axis, -ma/2, up)		-- right front up
		Turn(lfrontleg1, z_axis, -ma/3, up)

		Turn(laftleg, y_axis, -1.5*ma, backward) -- right back backward
		Turn(laftleg, z_axis, 0, 6*up)			-- right back down
		Turn(laftleg1, z_axis, 0, up)

		Turn(rfrontleg, y_axis, sa, backward)	 -- left front backward
		Turn(rfrontleg, z_axis, 0, 6*up)		 -- left front down
		Turn(rfrontleg1, z_axis, 0, up)

		Turn(raftleg, y_axis, -sa, forward)	 -- left back forward
		Turn(raftleg, z_axis, ma/2, up)		 -- left back up
		Turn(raftleg1, z_axis, ma/3, up)

		Sleep(pause)

		-- Move(base, y_axis, 0, 4*up)
		Turn(lfrontleg, y_axis, -sa, backward)	-- right front backward
		Turn(lfrontleg, z_axis, 0, 6*up)		 -- right front down
		Turn(lfrontleg1, z_axis, 0, up)

		Turn(laftleg, y_axis, sa, forward)		-- right back forward
		Turn(laftleg, z_axis, -ma/2, up)		 -- right back up
		Turn(laftleg1, z_axis, -ma/3, up)

		Turn(rfrontleg, y_axis, -1.5*ma, forward) -- left front forward
		Turn(rfrontleg, z_axis, ma/2, up)		 -- left front up
		Turn(rfrontleg1, z_axis, ma/3, up)

		Turn(raftleg, y_axis, 1.5*ma, backward) -- left back backward
		Turn(raftleg, z_axis, 0, 6*up)			-- left back down
		Turn(raftleg1, z_axis, 0, up)

		Sleep(pause)
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	Move(base, y_axis, 0, 4*up)
	Turn(lfrontleg, y_axis, 0) 	-- right front forward
	Turn(lfrontleg, z_axis, 0, up)
	Turn(lfrontleg1, z_axis, 0, up)

	Turn(laftleg, y_axis, 0) 	-- right back backward
	Turn(laftleg, z_axis, 0, up)
	Turn(laftleg1, z_axis, 0, up)

	Turn(rfrontleg, y_axis, 0) 	-- left front backward
	Turn(rfrontleg, z_axis, 0, up)
	Turn(rfrontleg1, z_axis, 0, up)

	Turn(raftleg, y_axis, 0) 	-- left back forward
	Turn(raftleg, z_axis, 0, up)
	Turn(raftleg1, z_axis, 0, up)

	Turn(lfrontleg, y_axis, math.rad(45), forward)
	Turn(rfrontleg, y_axis, math.rad(-45), forward)
	Turn(laftleg, y_axis, math.rad(-45), forward)
	Turn(raftleg, y_axis, math.rad(45), forward)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.QueryWeapon(num)
	if gun then
		return lflare
	else
		return rflare
	end
end

function script.AimFromWeapon(num)
	return turret
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(turret, y_axis, heading, math.rad(180)) -- left-right
	Turn(torso, x_axis, -pitch, math.rad(270)) --up-down
	WaitForTurn(turret, y_axis)
	WaitForTurn(torso, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

local function recoil()
	if gun then
		EmitSfx(lflare, 1024)
		EmitSfx(lflare, 1025)

		Move(lbarrel, z_axis, -6)
		Move(larm, z_axis, -2)

		Move(lbarrel, z_axis, 0, 3)
		Move(larm, z_axis, 0, 1)
	else
		EmitSfx(rflare, 1024)
		EmitSfx(rflare, 1025)

		Move(rbarrel, z_axis, -6)
		Move(rarm, z_axis, -2)

		Move(rbarrel, z_axis, 0, 3)
		Move(rarm, z_axis, 0, 1)
	end
end

function script.FireWeapon(num)
	StartThread(recoil)
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/350
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 141.1, 30 * distMult, false, false, true)
	end
	return false
end

function script.EndBurst()
	gun = not gun
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(base, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(base, SFX.NONE)
		Explode(lbarrel, SFX.FALL + SFX.SMOKE)
		Explode(rbarrel, SFX.FALL + SFX.SMOKE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(lbarrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rbarrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
