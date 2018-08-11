function gadget:GetInfo() return {
	name      = "Fog Hidden Effects API",
	desc      = "API for playing sounds only for players with vision",
	author    = "Google Frog",
	date      = "17 Jan 2016",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true,
} end

if gadgetHandler:IsSyncedCode() then
	local SendToUnsync = SendToUnsynced

	function GG.PlayFogHiddenSound(sound, volume, x, y, z)
		SendToUnsync("playSound", sound, volume, x, y, z)
	end
else
	local spIsPosInLos    = Spring.IsPosInLos
	local spPlaySoundFile = Spring.PlaySoundFile

	local myAllyTeam = Spring.GetLocalAllyTeamID()
	local fullView = select(2, Spring.GetSpectatingState())

	local function playSound(_, sound, volume, x, y, z)
		if not fullView and not spIsPosInLos(x, y, z, myAllyTeam) then
			return
		end
		spPlaySoundFile(sound, volume, x, y, z)
	end

	local myPlayerID = Spring.GetLocalPlayerID()
	function gadget:PlayerChanged(playerID)
		if playerID ~= myPlayerID then
			return
		end

		fullView = select(2, Spring.GetSpectatingState())
		myAllyTeam = Spring.GetLocalAllyTeamID()
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("playSound", playSound)
	end
end
