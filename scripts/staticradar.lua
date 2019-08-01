include "constants.lua"

local base = piece 'base' 
local ground = piece 'ground' 
local head = piece 'head' 

local smokePiece = {head}

local SCANNER_PERIOD = 1000

local on = false

--[[
local function TargetingLaser()
	while on do
		Turn(emit1, x_axis, math.rad(-50))
		Turn(emit2, x_axis, math.rad(-40))
		Turn(emit3, x_axis, math.rad(-20))
		Turn(emit4, x_axis, math.rad(-5))
		
		EmitSfx(emit1, 2048)
		EmitSfx(emit2, 2048)
		EmitSfx(emit3, 2048)
		EmitSfx(emit4, 2048)
		
		Sleep(20)

		Turn(emit1, x_axis, math.rad(-30))
		Turn(emit2, x_axis, math.rad(-10))
		Turn(emit3, x_axis, math.rad(10))
		Turn(emit4, x_axis, math.rad(30))
		
		EmitSfx(emit1, 2048)
		EmitSfx(emit2, 2048)
		EmitSfx(emit3, 2048)
		EmitSfx(emit4, 2048)
		
		Sleep(20)
		
		Turn(emit1, x_axis, math.rad(5))
		Turn(emit2, x_axis, math.rad(20))
		Turn(emit3, x_axis, math.rad(40))
		Turn(emit4, x_axis, math.rad(50))
		
		EmitSfx(emit1, 2048)
		EmitSfx(emit2, 2048)
		EmitSfx(emit3, 2048)
		EmitSfx(emit4, 2048)
		
		Sleep(20)
	end
end
]]
local index = 0
local function ScannerLoop()
	while true do
	while (not on) or Spring.GetUnitIsStunned(unitID) do
		Sleep(300)
	end
	EmitSfx(head, 4096)
	index = index + 1
	if index == 5 then
		index = 0
		EmitSfx(head, 1024)
	end
	Sleep(SCANNER_PERIOD)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	--StartThread(ScannerLoop)
	local cmd = Spring.FindUnitCmdDesc(unitID, CMD.ATTACK)
	if cmd then 
		Spring.RemoveUnitCmdDesc(unitID, cmd) 
	end
end

function script.Activate()
	Spin(head, y_axis, math.rad(60))
	on = true
end

function script.Deactivate()
	StopSpin(head, y_axis)
	on = false
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(ground, SFX.NONE)
		Explode(head, SFX.FALL + SFX.EXPLODE)
		return 1
	elseif severity <= .50 then
		Explode(ground, SFX.NONE)
		Explode(head, SFX.FALL + SFX.EXPLODE)
		return 1
	elseif severity <= .99 then
		corpsetype = 2
		Explode(ground, SFX.NONE)
		Explode(head, SFX.FALL + SFX.EXPLODE)
		return 2
	else
		Explode(ground, SFX.NONE)
		Explode(head, SFX.FALL + SFX.EXPLODE)
		return 2
	end
end
