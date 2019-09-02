include "constants.lua"
include "utility.lua"

local beacon, holder, sphere = piece('beacon', 'holder', 'sphere')

local SIG_CEG_EFFECTS = 1

local smokePiece = {sphere}

local spinmodes = {
	[1] = {holder = 30, sphere = 25},
	[2] = {holder = 50, sphere = 45},
	[3] = {holder = 100, sphere = 130},
}

local holderDirection = plusOrMinusOne()
local mode
local soundIndex = 9

function activity_mode(n)
	if (not mode) or mode ~= n then
	
		if n < 2 then
			SetUnitValue(COB.ACTIVATION, 0)
		elseif mode < 2 then
			SetUnitValue(COB.ACTIVATION, 1)
		end
		
		if n == 3 then
			soundIndex = 9
		end
		
		Spin(holder, y_axis, math.rad(spinmodes[n].holder*holderDirection))
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
		local _,_,_,x, y, z = Spring.GetUnitPosition(teleportiee, true)
		local _,_,_,lx, ly, lz = Spring.GetUnitPosition(teleporter, true)
		local teleportieeValid = Spring.ValidUnitID(teleportiee)
		local teleporterValid = Spring.ValidUnitID(teleporter)
		if teleportieeValid then
			Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
			GG.PokeDecloakUnit(teleportiee)
		end
		if teleporterValid then
			GG.PokeDecloakUnit(teleporter)
		end
		GG.PokeDecloakUnit(unitID)
		soundIndex = soundIndex + 1
		if soundIndex > 8 then
			if teleportieeValid then
				GG.PlayFogHiddenSound("sounds/misc/teleport_loop.wav", 2.5, x, y, z)
			end
			if teleporterValid then
				GG.PlayFogHiddenSound("sounds/misc/teleport_loop.wav", 2.5, lx, ly, lz)
			end
			soundIndex = 0
		end
		Sleep(200)
	end
end

function startTeleOutLoop(teleportiee, teleporter)
	StartThread(startTeleOutLoop_Thread, teleportiee, teleporter)
end

function endTeleOutLoop()
	Signal(SIG_CEG_EFFECTS)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	--StartThread(Walk)
	activity_mode(1)
end

function script.Killed(recentDamage, maxHealth)
	Explode(holder, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(sphere, SFX.FALL)
	return 0
end
