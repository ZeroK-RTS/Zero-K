function gadget:GetInfo() return {
	name      = "Rezz Hp changer + effect",
	desc      = "Sets rezzed units to full hp",
	author    = "Google Frog, modified by Rafal & Meep",
	date      = "Nov 30, 2008",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true
} end

if (not gadgetHandler:IsSyncedCode()) then

	local spSetUnitHealth = Spring.SetUnitHealth
	local spGetUnitHealth = Spring.GetUnitHealth
	local CMD_RESURRECT   = CMD.RESURRECT

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

				-- award calculation
				if GG.Awards then
					GG.Awards.UnitResurrected(unitDefID, teamID)
				end

				-- add CEG and play sound
				local ud = Spring.GetUnitDefID(unitID)
				ud = ud and UnitDefs[ud]
				if ud then
					local size = ud.xsize
					local ux, uy, uz = Spring.GetUnitPosition(unitID)
					Spring.SpawnCEG("resurrect", ux, uy, uz, 0, 0, 0, size)
					--Spring.PlaySoundFile("sounds/misc/resurrect.wav", 15, ux, uy, uz)
					SendToUnsynced("rez_sound", ux, uy, uz)
				end
			end
		end
	end

	function gadget:GameFrame(n)
		-- apply pending unit health changes
		if (unitsCount ~= 0) then
			for i = 1, unitsCount do
			local health, maxHealth = spGetUnitHealth(units[i])
				if maxHealth then
					spSetUnitHealth(units[i], maxHealth)
				end

				units[i] = nil
			end
			unitsCount = 0
		end
	end

else -- UNSYNCED

	local function rez_sound(_, x, y, z)
		local spec = select(2, Spring.GetSpectatingState())
		local myAllyTeam = Spring.GetLocalAllyTeamID()
		if (spec or Spring.IsPosInLos(x, y, z, myAllyTeam)) then
			Spring.PlaySoundFile("sounds/misc/resurrect.wav", 15, x, y, z)
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("rez_sound", rez_sound)
	end

end