include "constants.lua"

local base, float, body, head, ball = piece ("base", "float", "body", "head", "ball")
local wings = {}
for i = 1, 4 do
	wings[i] = piece ("wing"..i)
end

local explodables1 = {ball, wings[1], wings[2]}
local explodables2 = {float, head, wings[3], wings[4]}
local smokePiece = { base }

function script.Activate()
	Spin (float, y_axis, math.rad(30))
	Spin (head, y_axis, math.rad(-90))
	Turn (wings[1], x_axis, math.rad(-50), math.rad(20))
	Turn (wings[2], z_axis, math.rad(50), math.rad(20))
	Turn (wings[3], x_axis, math.rad(50), math.rad(20))
	Turn (wings[4], z_axis, math.rad(-50), math.rad(20))
end

function script.Deactivate()
	StopSpin (float, y_axis, math.rad(2))
	StopSpin (head, y_axis, math.rad(4))
	Turn (wings[1], x_axis, 0, math.rad(20))
	Turn (wings[2], z_axis, 0, math.rad(20))
	Turn (wings[3], x_axis, 0, math.rad(20))
	Turn (wings[4], z_axis, 0, math.rad(20))
end

local function Bobbing ()
	Spin (base, y_axis, math.rad(2))
	local dir = 1
	while true do
		Move (base, y_axis, 1.5*dir, 0.6)
		Turn (base, x_axis, math.rad(5*dir), math.rad(2))
		WaitForTurn (base, x_axis)
		Sleep (800)
		dir = -dir
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(Bobbing)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables1 do
		if (math.random() < severity) then
			Explode (explodables1[i], SFX.SMOKE + SFX.FIRE)
		end
	end

	if (severity <= .5) then
		return 1
	else
		Explode(body, SFX.SHATTER)
		for i = 1, #explodables2 do
			if (math.random() < severity) then
				Explode (explodables2[i], SFX.SMOKE + SFX.FIRE)
			end
		end
		return 2
	end
end
