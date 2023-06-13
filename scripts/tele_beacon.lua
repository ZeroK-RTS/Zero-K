include "constants.lua"
include "utility.lua"

local holder, sphere = piece('holder', 'sphere')
-- unused piece: 'beacon'

local SIG_CEG_EFFECTS = 1

local smokePiece = {sphere}

local spinmodes = {
	[1] = {holder = math.rad(30), sphere = math.rad(25)},
	[2] = {holder = math.rad(50), sphere = math.rad(45)},
	[3] = {holder = math.rad(100), sphere = math.rad(130)},
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

		local spinData = spinmodes[n]
		local spinSphere = spinData.sphere
		local rand = math.random
		Spin(holder, y_axis, spinData.holder*holderDirection)
		Spin(sphere, x_axis, spinSphere*(1 + rand())*plusOrMinusOne())
		Spin(sphere, y_axis, spinSphere*(1 + rand())*plusOrMinusOne())
		Spin(sphere, z_axis, spinSphere*(1 + rand())*plusOrMinusOne())
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
			GG.teleport_lastUnitFrame[teleportiee] = Spring.GetGameFrame()
		end
		if teleporterValid then
			GG.PokeDecloakUnit(teleporter)
		end
		GG.PokeDecloakUnit(unitID, unitDefID)
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
