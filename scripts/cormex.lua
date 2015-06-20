
local  base, bottom, tamper, furnace, door_l, door_r, drill1, drill2, drill3, posts = piece ('base', 'bottom', 'tamper', 'furnace', 'door_l', 'door_r', 'drill1', 'drill2', 'drill3', 'posts')

include "pieceControl.lua"
include "constants.lua"

local smokePiece = {tamper}

local function Open()
	Turn (door_r, z_axis, math.rad(-120), math.rad(120))
	Turn (door_l, z_axis, math.rad(120), math.rad(120))
	WaitForTurn (door_l, z_axis)
	Move (tamper, y_axis, 15, 10)
	WaitForMove (tamper, y_axis)

	local height = 40

	while true do
		local income = Spring.GetUnitRulesParam(unitID, "mex_income") or 0
		if income > 0 then
			Spin (furnace, y_axis, income, math.rad(1))
			Spin (drill1,  y_axis, income, math.rad(1))
			Move (tamper, y_axis, height, income*10)
			WaitForMove (tamper, y_axis)
			height = 60 - height
		else
			StopSpin (furnace, y_axis, math.rad(5))
			StopSpin (drill1,  y_axis, math.rad(5))
			Sleep (200)
		end
	end
end

function script.Activate()
	StartThread(Open)
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

local explodables = {door_l, door_r, furnace}

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], sfxFall + sfxSmoke)
		end
	end
	if severity < .5 then
		return 1
	else
		Explode (bottom, sfxShatter)
		return 2
	end
end
