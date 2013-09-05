function gadget:GetInfo() return {
	name      = "Rezz Hp changer + effect",
	desc      = "Sets rezzed units to full hp",
	author    = "Google Frog, modified by Rafal & Meep",
	date      = "Nov 30, 2008",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true
} end

if (gadgetHandler:IsSyncedCode()) then

	local spGetUnitHealth   = Spring.GetUnitHealth
	local spGetUnitPosition = Spring.GetUnitPosition
	local spSetUnitHealth   = Spring.SetUnitHealth
	local spSpawnCEG        = Spring.SpawnCEG

	local SendToUnsync      = SendToUnsynced
	local CMD_RESURRECT     = CMD.RESURRECT

	local units = {}
	local unitsCount = 0

	-- Engine multiplies rezzed unit HP by 0.05 just after UnitCreated so their HP has to be changed 1 frame later
	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
		if (builderID) then
			local command = Spring.GetCommandQueue(builderID, 1)[1]
			if (command and command.id == CMD_RESURRECT) then
				--spSetUnitHealth(unitID, maxHealth)  -- does nothing, hp overwritten by engine

				-- queue resurrected unit
				unitsCount = unitsCount + 1
				units[unitsCount] = unitID

				local unitDef = unitDefID and UnitDefs[unitDefID]

				-- award calculation
				if GG.Awards and GG.Awards.AddAwardPoints then
					GG.Awards.AddAwardPoints( 'rezz', teamID, (unitDef and unitDef.metalCost or 0) )
				end

				-- add CEG and play sound
				if unitDef then
					local size = unitDef.xsize
					local ux, uy, uz = spGetUnitPosition(unitID)
					spSpawnCEG("resurrect", ux, uy, uz, 0, 0, 0, size)
					--Spring.PlaySoundFile("sounds/misc/resurrect.wav", 15, ux, uy, uz)
					SendToUnsync("rez_sound", ux, uy, uz)
				end
			end
		end
	end

	function gadget:GameFrame(n)
		-- apply pending unit health changes
		if (unitsCount ~= 0) then
			for i = 1, unitsCount do
			local maxHealth = select(2, spGetUnitHealth(units[i]))
				if maxHealth then
					spSetUnitHealth(units[i], maxHealth)
				end

				units[i] = nil
			end
			unitsCount = 0
		end
	end

else -- UNSYNCED

	local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
	local spGetSpectatingState = Spring.GetSpectatingState
	local spIsPosInLos         = Spring.IsPosInLos
	local spPlaySoundFile      = Spring.PlaySoundFile

	local function rez_sound(_, x, y, z)
		local spec = select(2, spGetSpectatingState())
		local myAllyTeam = spGetLocalAllyTeamID()
		if (spec or spIsPosInLos(x, y, z, myAllyTeam)) then
			spPlaySoundFile("sounds/misc/resurrect.wav", 15, x, y, z)
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("rez_sound", rez_sound)
	end

end