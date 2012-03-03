include "constants.lua"
include "utility.lua"

local beacon, holder, sphere = piece('beacon', 'holder', 'sphere') 

local SIG_CEG_EFFECTS = 1

smokePiece = {sphere}

local spinmodes = {
	[1] = {holder = 30, sphere = 25},
	[2] = {holder = 50, sphere = 45},
	[3] = {holder = 100, sphere = 130},
}

local holderDirection = plusOrMinusOne()
local mode
local soundIndex = 6

function activity_mode(n)
	if (not mode) or mode ~= n then
	
		if n < 2 then
			SetUnitValue(COB.ACTIVATION, 0)
		elseif mode < 2 then
			SetUnitValue(COB.ACTIVATION, 1)
		end
		
		if n == 3 then
			soundIndex = 6
		end
		
		Spin(holder, y_axis, math.rad(spinmodes[n].holder*holderDirection) )
		Spin(sphere, x_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		Spin(sphere, y_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		Spin(sphere, z_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		mode = n
	end
end

function startTeleOutLoop_Thread(teleportiee, teleporter)
	Signal(SIG_CEG_EFFECTS)
	SetSignalMask(SIG_CEG_EFFECTS)
	
	while true do
		if Spring.ValidUnitID(teleportiee) then
			local x, y, z = Spring.GetUnitPosition(teleportiee)
			Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
			GG.PokeDecloakUnit(teleportiee)
		end
		if Spring.ValidUnitID(teleporter) then
			GG.PokeDecloakUnit(teleporter)
		end
		GG.PokeDecloakUnit(unitID)
		soundIndex = soundIndex + 1
		if soundIndex > 5 then
			Spring.PlaySoundFile("sounds/misc/teleport_loop.wav", 0.3, x, y, z)
			soundIndex = 0
		end
		Sleep(300)
	end
end

function startTeleOutLoop(teleportiee, teleporter)
	StartThread(startTeleOutLoop_Thread, teleportiee, teleporter)
end
	
function endTeleOutLoop()
	Signal(SIG_CEG_EFFECTS)
end

function script.Create()
	StartThread(SmokeUnit)
	--StartThread(Walk)
	activity_mode(1)
end

function script.Killed(recentDamage, maxHealth)
	Explode(holder, sfxSmoke  + sfxFire  + sfxExplode)
	Explode(sphere, sfxFall)
	return 0
end