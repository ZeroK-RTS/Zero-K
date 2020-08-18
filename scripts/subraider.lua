--by Chris Mackey

local wake = piece "wake"
local base = piece "base"
local firepoint = piece "firepoint"
local smokePiece = {base}
local moving = false
local criticalHeight = 0

local function MoveScript()
	while true do
		if moving and not Spring.GetUnitIsCloaked(unitID) then
			local x,y,z = Spring.GetUnitPosition(unitID);
			if y > criticalHeight then
				EmitSfx(wake, 3)
				EmitSfx(firepoint, 3)
			end
		end
		Sleep(150)
	end
end

function script.QueryWeapon(num)
	return firepoint
end
function script.AimFromWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return num == 2
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 240, 25, 0.5) -- Leeway for amph regen
end

function script.StopMoving()
	moving = false
end

function script.StartMoving()
	moving = true
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(MoveScript)
	criticalHeight = -1 * Spring.GetUnitHeight(unitID) + 10
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
