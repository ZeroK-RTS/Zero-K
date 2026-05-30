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

local eggDefID = UnitDefNames["commander_egg"] and UnitDefNames["commander_egg"].id
if not eggDefID then
	return -- no commander egg unit defined, nothing to do
end

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local eggs = IterableMap.New()
local commanders = IterableMap.New()

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function CountCommandersByTeam(excludeUnitID, includeMorphingEggs)
	local commsByTeam = {}
	local commsByAllyTeam = {}
	for unitID, _ in IterableMap.Iterator(commanders) do
		if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) and unitID ~= excludeUnitID then
			local ownerTeam = Spring.GetUnitRulesParam(unitID, "commander_owner_team")
			if ownerTeam then
				commsByTeam[ownerTeam] = (commsByTeam[ownerTeam] or 0) + 1
				local allyTeamID = select(6, Spring.GetTeamInfo(ownerTeam, false))
				commsByAllyTeam[allyTeamID] = (commsByAllyTeam[allyTeamID] or 0) + 1
			end
		end
	end
	if includeMorphingEggs then
		for unitID, _ in IterableMap.Iterator(eggs) do
			if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) and unitID ~= excludeUnitID then
				local morphOwnerTeam = Spring.GetUnitRulesParam(unitID, "egg_morph_owner_team")
				if morphOwnerTeam then
					commsByTeam[morphOwnerTeam] = (commsByTeam[morphOwnerTeam] or 0) + 1
					local allyTeamID = select(6, Spring.GetTeamInfo(morphOwnerTeam, false))
					commsByAllyTeam[allyTeamID] = (commsByAllyTeam[allyTeamID] or 0) + 1
				end
			end
		end
	end
	return commsByTeam, commsByAllyTeam
end

local function CanTeamSpawnCommander(teamID, commsByTeam, commsByAllyTeam)
	local allyTeamID = select(6, Spring.GetTeamInfo(teamID, false))
	local allyTeamLimit = Spring.GetAllyTeamRulesParam(allyTeamID, "initial_commanders")
	local myShare, totalTeamShare = GG.Lagmonitor.GetTeamCommanderShare(teamID)
	if not myShare then
		return false
	end
	myShare = myShare * allyTeamLimit / totalTeamShare
	-- myShare can be fractional if there are resigns, so it is first-come first served
	--Spring.Echo("myShare", myShare, (commsByAllyTeam[allyTeamID] or 0), "allyTeamLimit", allyTeamLimit)
	if (commsByAllyTeam[allyTeamID] or 0) >= allyTeamLimit then
		return false
	end
	return (commsByTeam[teamID] or 0) < myShare
end

--------------------------------------------------------------------------------
-- Button greying
--------------------------------------------------------------------------------

local SUC = Spring.Utilities.CMD
local CMD_MORPH = SUC.MORPH
local MAX_MORPH = GG.MorphInfo and GG.MorphInfo["MAX_MORPH"] or 100

local function UpdateMorphButton(unitID, eggData, index, commsByTeam, commsByAllyTeam)
	if Spring.GetUnitRulesParam(unitID, "morphing") == 1 then
		return
	end
	local teamID = Spring.GetUnitTeam(unitID)
	if not teamID then
		return true -- Remove egg
	end
	local canHatch = CanTeamSpawnCommander(teamID, commsByTeam, commsByAllyTeam)

	-- update all morph cmd descriptions on this egg
	for morphNum = 1, MAX_MORPH do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_MORPH + morphNum)
		if cmdDescID then
			Spring.EditUnitCmdDesc(unitID, cmdDescID, {disabled = not canHatch})
		end
	end
end

local function UpdateEggMorphButtons()
	local commsByTeam, commsByAllyTeam = CountCommandersByTeam(false, true)
	IterableMap.Apply(eggs, UpdateMorphButton, commsByTeam, commsByAllyTeam)
end

--------------------------------------------------------------------------------
-- GG Morph hooks (called by unit_morph.lua)
--------------------------------------------------------------------------------

local function IsEggMorph(unitID, targetDefID)
	if not Spring.Utilities.isComm(targetDefID) then
		return false
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	return unitDefID == eggDefID
end

function GG.MorphPreCheck(unitID, targetDefID, teamID)
	if not IsEggMorph(unitID, targetDefID) then
		return true
	end
	local commsByTeam, commsByAllyTeam = CountCommandersByTeam(unitID, true)
	if not CanTeamSpawnCommander(teamID, commsByTeam, commsByAllyTeam) then
		return false, true -- blocked, hard reject
	end
	return true
end

function GG.MorphStarted(unitID, targetDefID, teamID)
	local targetDef = UnitDefs[targetDefID]
	if not IsEggMorph(unitID, targetDefID) then
		return
	end
	local commsByTeam, commsByAllyTeam = CountCommandersByTeam()
	if not CanTeamSpawnCommander(teamID, commsByTeam, commsByAllyTeam) then
		return
	end
	Spring.SetUnitRulesParam(unitID, "egg_morph_owner_team", teamID)
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
	local ownerTeam = Spring.GetUnitRulesParam(oldUnitID, "egg_morph_owner_team") or Spring.GetUnitRulesParam(oldUnitID, "commander_owner_team")
	-- tag the new commander
	Spring.SetUnitRulesParam(newUnitID, "commander_owner_team", ownerTeam, {inlos = true})
	if GG.ShareMode_RegisterUnit then
		GG.ShareMode_RegisterUnit(newUnitID, ownerTeam)
	end
	
	if not hatchForTeam then
		return true -- not from an egg, allow
	end

	-- final check: verify this team still needs a commander
	local commsByTeam, commsByAllyTeam = CountCommandersByTeam(newUnitID)
	if not CanTeamSpawnCommander(teamID, commsByTeam, commsByAllyTeam) then
		return false
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
local cmdsToRemove = {CMD.MOVE, CMD.PATROL, CMD.FIGHT, CMD.GUARD, CMD.MOVE_STATE, CMD.FIRE_STATE, Spring.Utilities.CMD.RAW_MOVE}

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if unitDefID == eggDefID then
		IterableMap.Add(eggs, unitID)
		pendingEggUpdate = true
	end
	if Spring.Utilities.isComm(unitDefID) then
		IterableMap.Add(commanders, unitID)
		if not Spring.GetUnitRulesParam(unitID, "commander_owner_team") then
			-- Set here because this gadget handles commander_owner_team, but will be overriden in MorphCompleted for morphed commanders
			Spring.SetUnitRulesParam(unitID, "commander_owner_team", teamID, {inlos = true})
		end
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
	IterableMap.Remove(eggs, unitID)
	IterableMap.Remove(commanders, unitID)
	if GG.MorphDestroy ~= unitID and Spring.Utilities.isComm(unitDefID) then
		UpdateEggMorphButtons(unitID)
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	if Spring.Utilities.isComm(unitDefID) then
		UpdateEggMorphButtons()
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
