--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Strider Hub Access",
		desc      = "Lets Caretakers build Striders inside a powered Strider Hub's build area.",
		author    = "GoogleFrog", -- adapted from Factory Plate
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/constants.lua")

local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spValidUnitID       = Spring.ValidUnitID
local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc

local ALLY_ACCESS = {allied = true}
local DISABLED_TOOLTIP = "Requires a powered Strider Hub in range"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Static def data

-- hubDefData[hubDefID] = {rangeSq = <hub build area, squared>, buildOptions = {striderDefID, ...}}
local hubDefData = {}
-- builderDefData[builderDefID] = {
--   eligRangeSq  = (hubRange + builderRange)^2,  -- how close to a hub the builder must be to build any strider
--   striderCmds  = { -striderDefID, ... },       -- build cmdIDs to grey/enable
--   striderCmdSet = { [-striderDefID] = true },  -- fast lookup for AllowCommand
-- }
local builderDefData = {}

local wantedStriderCmd = {}   -- union of all gated strider build cmdIDs, for AllowCommand
local wantedBuilderDef = {}   -- union of all builder unitDefIDs, for AllowCommand

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.strider_hub then
		hubDefData[i] = {
			rangeSq = ud.buildDistance * ud.buildDistance,
			buildOptions = ud.buildOptions,
		}
	end
end

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local hubName = ud.customParams.strider_builder
	if hubName then
		local hubDef = UnitDefNames[hubName]
		local hubData = hubDef and hubDefData[hubDef.id]
		if hubData then
			local striderCmds = {}
			local striderCmdSet = {}
			for j = 1, #hubData.buildOptions do
				local cmdID = -hubData.buildOptions[j]
				striderCmds[#striderCmds + 1] = cmdID
				striderCmdSet[cmdID] = true
				wantedStriderCmd[cmdID] = true
			end
			local eligRange = UnitDefs[hubDef.id].buildDistance + ud.buildDistance
			builderDefData[i] = {
				eligRangeSq = eligRange * eligRange,
				striderCmds = striderCmds,
				striderCmdSet = striderCmdSet,
			}
			wantedBuilderDef[i] = true
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local hubs     = IterableMap.New() -- unitID -> {x, z, allyTeamID, powered, rangeSq}
local builders = IterableMap.New() -- unitID -> {info, x, z, allyTeamID, access}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsHubPowered(unitID)
	-- Powered = built, not EMPed/paralysed (spGetUnitIsStunned), not disarmed or
	-- morph-disabled, AND its energy grid can supply its neededlink. The last one
	-- is the "lowpower" param set by unit_mex_overdrive.lua; without it an
	-- unpowered (but un-EMPed) Hub would wrongly count as operational.
	return not (spGetUnitIsStunned(unitID)
		or (spGetUnitRulesParam(unitID, "disarmed") == 1)
		or (spGetUnitRulesParam(unitID, "morphDisable") == 1)
		or (spGetUnitRulesParam(unitID, "lowpower") == 1))
end

-- Is there a powered, same-allyTeam hub near (x, z)?
-- rangeSq nil -> test against each hub's own build area (strider placement);
-- rangeSq set -> test against that fixed radius (button eligibility).
local function HubInRange(x, z, allyTeamID, rangeSq)
	for hubID, hub in IterableMap.Iterator(hubs) do
		if hub.powered and hub.allyTeamID == allyTeamID then
			local dx, dz = x - hub.x, z - hub.z
			if dx*dx + dz*dz <= (rangeSq or hub.rangeSq) then
				return true
			end
		end
	end
	return false
end

local function SetBuilderAccess(unitID, builder, access)
	if builder.access == access then
		return
	end
	builder.access = access
	spSetUnitRulesParam(unitID, "strider_access", (access and 1) or 0, ALLY_ACCESS)

	local cmds = builder.info.striderCmds
	for i = 1, #cmds do
		local cmdIndex = spFindUnitCmdDesc(unitID, cmds[i])
		if cmdIndex then
			spEditUnitCmdDesc(unitID, cmdIndex, {disabled = not access, tooltip = (not access) and DISABLED_TOOLTIP or ""})
		end
	end
end

local function UpdateBuilder(unitID, builder)
	local access = HubInRange(builder.x, builder.z, builder.allyTeamID, builder.info.eligRangeSq)
	SetBuilderAccess(unitID, builder, access)
end

local function UpdateAllBuilders()
	for unitID, builder in IterableMap.Iterator(builders) do
		UpdateBuilder(unitID, builder)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if n % TEAM_SLOWUPDATE_RATE ~= 16 then
		return
	end
	local changed = false
	for hubID, hub in IterableMap.Iterator(hubs) do
		local powered = IsHubPowered(hubID)
		if powered ~= hub.powered then
			hub.powered = powered
			changed = true
		end
	end
	if changed then
		UpdateAllBuilders()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand_GetWantedCommand()
	return wantedStriderCmd
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return wantedBuilderDef
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	local info = builderDefData[unitDefID]
	if not (info and info.striderCmdSet[cmdID]) then
		return true
	end
	-- Gated strider build: only allowed inside a powered same-allyTeam Hub's build area.
	local bx, bz = cmdParams[1], cmdParams[3]
	if not bz then
		return true -- not a positional build order
	end
	return HubInRange(bx, bz, spGetUnitAllyTeam(unitID))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if hubDefData[unitDefID] then
		local x, _, z = spGetUnitPosition(unitID)
		IterableMap.Add(hubs, unitID, {
			x = x,
			z = z,
			allyTeamID = spGetUnitAllyTeam(unitID),
			powered = IsHubPowered(unitID),
			rangeSq = hubDefData[unitDefID].rangeSq,
		})
		UpdateAllBuilders()
	end

	if builderDefData[unitDefID] then
		local x, _, z = spGetUnitPosition(unitID)
		IterableMap.Add(builders, unitID, {
			info = builderDefData[unitDefID],
			x = x,
			z = z,
			allyTeamID = spGetUnitAllyTeam(unitID),
			access = nil,
		})
		UpdateBuilder(unitID, IterableMap.Get(builders, unitID))
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if hubDefData[unitDefID] then
		IterableMap.Remove(hubs, unitID)
		UpdateAllBuilders()
		return
	end
	if builderDefData[unitDefID] then
		IterableMap.Remove(builders, unitID)
		return
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	gadget:UnitCreated(unitID, unitDefID, newTeamID)
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	gadget:UnitDestroyed(unitID, unitDefID, oldTeamID)
end

function gadget:Initialize()
	IterableMap.Clear(hubs)
	IterableMap.Clear(builders)

	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
