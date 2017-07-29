function gadget:GetInfo() return {
	name      = "Fog Hidden Effects API",
	desc      = "API for playing sounds only for players with vision",
	author    = "Google Frog",
	date      = "17 Jan 2016",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true,
} end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals because I hear SendToUnsynced is really slow so copying strings
-- needlessly is bad.

local soundList = {
	"sounds/misc/teleport.wav",
	"sounds/misc/teleport2.wav",
	"sounds/misc/teleport_loop.wav",
}

local soundMap = {}
for i = 1, #soundList do
	soundMap[soundList[i]] = i
end

--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- Synced ---------------------------------
--------------------------------------------------------------------------------

function GG.PlayFogHiddenSound(sound, volume, x, y, z)
	soundIndex = soundMap[sound]
	if soundIndex then
		if x then
			SendToUnsynced("playSound", soundIndex, volume, x, y, z)
		else
			Spring.Echo("Sound position not found", sound, volume, x, y, z)
		end
	else
		Spring.Echo("Sound not found in gadget-side sound list", sound)
	end
end

--------------------------------------------------------------------------------
else ----------------------------------Unsynced --------------------------------
--------------------------------------------------------------------------------

local function playSound(_, sound, volume, x, y, z)
	local _, fullView = select(2, Spring.GetSpectatingState())
	local myAllyTeam = Spring.GetLocalAllyTeamID()
	if (fullView or Spring.IsPosInLos(x, y, z, myAllyTeam)) then
		Spring.PlaySoundFile(soundList[sound], volume, x, y, z)
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("playSound", playSound)
end

--------------------------------------------------------------------------------
end -------------------------------- End Unsynced ------------------------------
--------------------------------------------------------------------------------