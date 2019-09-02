
-- by Chris Mackey
include "constants.lua"

--pieces
local base = piece "base"
local toroid = piece "toroid"
local energyball = piece "energyball"
local nexus = piece "nexus"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local arm3 = piece "arm3"

local smokePiece = { piece "base", piece "arm1", piece "arm2", piece "arm3" }

local function StartAnim()
	Show(energyball)

	Spin(toroid, y_axis, 1)
	Spin(arm1, y_axis, -2)
	Spin(arm2, y_axis, -2)
	Spin(arm3, y_axis, -2)
	Spin(nexus, y_axis, -2)
	
	Spin(energyball, x_axis, 1)
	Spin(energyball, y_axis, -0.7)
end

local function StopAnim()
	Hide(energyball)

	StopSpin(toroid, y_axis)
	StopSpin(arm1, y_axis)
	StopSpin(arm2, y_axis)
	StopSpin(arm3, y_axis)
	StopSpin(nexus, y_axis)
	
	StopSpin(energyball, x_axis)
	StopSpin(energyball, y_axis)
end


local function Anim()
	local last_inbuilt = true
	while (true) do
		local inbuilt = select(5,Spring.GetUnitHealth(unitID)) < 1
		if (inbuilt ~= last_inbuilt) then
			last_inbuilt = inbuilt
			if (inbuilt) then
				StopAnim()
			else
				StartAnim()
			end
		end
		Sleep(1000)
	end
end


function script.Create()
	Hide(energyball)

	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(Anim)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.EXPLODE)
	Explode(toroid, SFX.EXPLODE)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
