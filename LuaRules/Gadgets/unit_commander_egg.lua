--------------------------------------------------------------------------------
-- Commander Egg - hatching logic, button greying, and morph hooks
-- Uses generic GG.Morph* hooks defined in unit_morph.lua
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Commander Egg",
		desc      = "Manages commander egg hatching limits and morph button state",
		author    = "Orlicek, Licho",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local eggDefID = UnitDefNames["commander_egg"] and UnitDefNames["commander_egg"].id
if not eggDefID then
	return -- no commander egg unit defined, nothing to do
end

local function GetOrigTeams(teamID)
	local origTeams = {}
	local isAI = select(4, Spring.GetTeamInfo(teamID, false))
	if isAI then
		origTeams[1] = teamID
	else
		local playerList = Spring.GetPlayerList(teamID)
		local seen = {}
		for _, pid in ipairs(playerList) do
			local _, _, isSpec = Spring.GetPlayerInfo(pid, false)
			if not isSpec then
				local origTeamID = Spring.GetPlayerRulesParam(pid, "commshare_orig_teamid") or teamID
				if not seen[origTeamID] then
					seen[origTeamID] = true
					origTeams[#origTeams + 1] = origTeamID
				end
			end
		end
	end
	return origTeams
end

local function CountCommandersByTeam(excludeUnitID)
	local commsByTeam = {}
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local uid = allUnits[i]
		if uid ~= excludeUnitID then
			local ownerTeam = Spring.GetUnitRulesParam(uid, "commander_owner_team")
			if ownerTeam and Spring.GetUnitRulesParam(uid, "comm_level") then
				commsByTeam[ownerTeam] = (commsByTeam[ownerTeam] or 0) + 1
			end
			local morphOwnerTeam = Spring.GetUnitRulesParam(uid, "egg_morph_owner_team")
			if morphOwnerTeam then
				commsByTeam[morphOwnerTeam] = (commsByTeam[morphOwnerTeam] or 0) + 1
			end
		end
	end
	return commsByTeam
end

local function FindTeamNeedingCommander(teamID, excludeUnitID)
	local origTeams = GetOrigTeams(teamID)
	local commsByTeam = CountCommandersByTeam(excludeUnitID)
	for _, origTeamID in ipairs(origTeams) do
		local maxComms = Spring.GetTeamRulesParam(origTeamID, "start_comm_count") or 1
		local current = commsByTeam[origTeamID] or 0
		if current < maxComms then
			return origTeamID
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Button greying
--------------------------------------------------------------------------------

local SUC = Spring.Utilities.CMD
local CMD_MORPH = SUC.MORPH
local MAX_MORPH = GG.MorphInfo and GG.MorphInfo["MAX_MORPH"] or 100

local destroyedUnitID = nil -- set during UnitDestroyed to exclude from count

local function UpdateEggMorphButtons()
	local commsByTeam = CountCommandersByTeam(destroyedUnitID)
	local allUnits = Spring.GetAllUnits()

	for i = 1, #allUnits do
		local uid = allUnits[i]
		if Spring.GetUnitDefID(uid) == eggDefID and Spring.GetUnitRulesParam(uid, "morphing") ~= 1 then
			local teamID = Spring.GetUnitTeam(uid)
			local canHatch = false

			local origTeams = GetOrigTeams(teamID)
			for _, origTeamID in ipairs(origTeams) do
				local maxComms = Spring.GetTeamRulesParam(origTeamID, "start_comm_count") or 1
				if (commsByTeam[origTeamID] or 0) < maxComms then
					canHatch = true
					break
				end
			end

			-- update all morph cmd descriptions on this egg
			for morphNum = 1, MAX_MORPH do
				local cmdDescID = Spring.FindUnitCmdDesc(uid, CMD_MORPH + morphNum)
				if cmdDescID then
					Spring.EditUnitCmdDesc(uid, cmdDescID, {disabled = not canHatch})
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- GG Morph hooks (called by unit_morph.lua)
--------------------------------------------------------------------------------

function GG.MorphPreCheck(unitID, targetDefID, teamID)
	local targetDef = UnitDefs[targetDefID]
	if not (targetDef and targetDef.customParams and targetDef.customParams.dynamic_comm) then
		return true -- not a commander morph, allow
	end

	local hatchForTeam = FindTeamNeedingCommander(teamID, unitID)
	if not hatchForTeam then
		Spring.SendMessageToTeam(teamID, "game_message: Cannot hatch: all commanders are still alive.")
		return false, true -- blocked, hard reject
	end

	return true
end

function GG.MorphStarted(unitID, targetDefID, teamID)
	local targetDef = UnitDefs[targetDefID]
	if not (targetDef and targetDef.customParams and targetDef.customParams.dynamic_comm) then
		return
	end

	local hatchForTeam = FindTeamNeedingCommander(teamID, unitID)
	if hatchForTeam then
		Spring.SetUnitRulesParam(unitID, "egg_morph_owner_team", hatchForTeam)
	end
	UpdateEggMorphButtons()
end

function GG.MorphCancelled(unitID)
	local had = Spring.GetUnitRulesParam(unitID, "egg_morph_owner_team")
	Spring.SetUnitRulesParam(unitID, "egg_morph_owner_team", nil)
	if had then
		UpdateEggMorphButtons()
	end
end

function GG.MorphCompleted(oldUnitID, newUnitID, teamID)
	local newUnitDef = UnitDefs[Spring.GetUnitDefID(newUnitID)]
	if not (newUnitDef and newUnitDef.customParams and newUnitDef.customParams.dynamic_comm) then
		return true -- not a commander, allow
	end

	local hatchForTeam = Spring.GetUnitRulesParam(oldUnitID, "egg_morph_owner_team")
	if not hatchForTeam then
		return true -- not from an egg, allow
	end

	-- final check: verify this team still needs a commander
	local maxComms = Spring.GetTeamRulesParam(hatchForTeam, "start_comm_count") or 1
	local current = 0
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		if allUnits[i] ~= oldUnitID and allUnits[i] ~= newUnitID then
			if Spring.GetUnitRulesParam(allUnits[i], "commander_owner_team") == hatchForTeam
			   and Spring.GetUnitRulesParam(allUnits[i], "comm_level") then
				current = current + 1
			end
		end
	end
	if current >= maxComms then
		return false -- abort morph, too many commanders
	end

	-- tag the new commander
	Spring.SetUnitRulesParam(newUnitID, "commander_owner_team", hatchForTeam, {inlos = true})
	if GG.ShareMode_RegisterUnit then
		GG.ShareMode_RegisterUnit(newUnitID, hatchForTeam)
	end

	UpdateEggMorphButtons()
	return true
end

--------------------------------------------------------------------------------
-- Block move commands on eggs (egg has speed for blocking but should not move)
--------------------------------------------------------------------------------

local blockedCmds = {
	[CMD.MOVE] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD.GUARD] = true,
	[SUC.RAW_MOVE] = true,
}

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if unitDefID == eggDefID and blockedCmds[cmdID] then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- Event handlers for button greying
--------------------------------------------------------------------------------

local pendingEggUpdate = false
local cmdsToRemove = {CMD.MOVE, CMD.PATROL, CMD.FIGHT, CMD.GUARD, CMD.MOVE_STATE, CMD.FIRE_STATE}

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if unitDefID == eggDefID then
		pendingEggUpdate = true
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if unitDefID == eggDefID then
		-- remove movement-related command buttons
		for _, cmdID in ipairs(cmdsToRemove) do
			local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmdID)
			if cmdDescID then
				Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
			end
		end
		Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, 0)
		UpdateEggMorphButtons()
	end
end

function gadget:GameFrame(n)
	if pendingEggUpdate then
		pendingEggUpdate = false
		UpdateEggMorphButtons()
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if Spring.GetUnitRulesParam(unitID, "comm_level") then
		destroyedUnitID = unitID
		UpdateEggMorphButtons()
		destroyedUnitID = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	if Spring.GetUnitRulesParam(unitID, "comm_level") then
		UpdateEggMorphButtons()
	end
end
