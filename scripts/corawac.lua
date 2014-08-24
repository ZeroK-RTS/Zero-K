include 'constants.lua'

--------------------------------------------------------------------
-- constants/vars
--------------------------------------------------------------------
local base, nozzle, thrust = piece("base", "nozzle", "thrust")
local smokePiece = {base}

local SIG_CLOAK = 1
local CLOAK_TIME = 5000
--------------------------------------------------------------------
-- functions
--------------------------------------------------------------------
local function Decloak()
    Signal(SIG_CLOAK)
    SetSignalMask(SIG_CLOAK)
    Sleep(CLOAK_TIME)
    Spring.SetUnitCloak(unitID, false)
end

function Cloak()
    Spring.SetUnitCloak(unitID, 2)
    StartThread(Decloak)
end

function script.Create()
    StartThread(SmokeUnit, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(nozzle, sfxFall)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(nozzle, sfxFall + sfxSmoke)
		return 2
	end
end
