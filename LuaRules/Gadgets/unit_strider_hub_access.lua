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

-- hubDefData[hubDefID] = {range = <hub build area>, rangeSq = <same, squared>}
local hubDefData = {}
-- builderDefData[builderDefID] = {
--   isMobile     = bool,                          -- mobile builders are gated by placement only
--   eligRangeSq  = (hubRange + builderRange)^2,    -- static builders: proximity to grey the buttons
--   striderCmds  = { -striderDefID, ... },         -- build cmdIDs to grey/enable
--   striderCmdSet = { [-striderDefID] = true },    -- fast lookup for AllowCommand
-- }
-- Only the striders newly GRANTED to a builder (customParams.strider_gated, set
-- in gamedata/unitdefs_post.lua) are gated, so a builder's native builds — e.g.
-- Athena's own striderantiheavy — keep their normal behaviour.
local builderDefData = {}

local wantedStriderCmd = {}   -- union of all gated strider build cmdIDs, for AllowCommand
local wantedBuilderDef = {}   -- union of all builder unitDefIDs, for AllowCommand

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.strider_hub then
		hubDefData[i] = {
			range = ud.buildDistance,
			rangeSq = ud.buildDistance * ud.buildDistance,
		}
	end
end

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local gatedStr = ud.customParams.strider_gated
	if gatedStr and gatedStr ~= "" then
		local striderCmds = {}
		local striderCmdSet = {}
		for name in gatedStr:gmatch("%S+") do
			local sd = UnitDefNames[name]
			if sd then
				local cmdID = -sd.id
				striderCmds[#striderCmds + 1] = cmdID
				striderCmdSet[cmdID] = true
				wantedStriderCmd[cmdID] = true
			end
		end
		if #striderCmds > 0 then
			local isMobile = (ud.speed or 0) > 0
			local eligRangeSq
			if not isMobile then
				local hubDef = UnitDefNames[ud.customParams.strider_builder]
				local hubData = hubDef and hubDefData[hubDef.id]
				local eligRange = (hubData and hubData.range or 0) + ud.buildDistance
				eligRangeSq = eligRange * eligRange
			end
			builderDefData[i] = {
				isMobile = isMobile,
				eligRangeSq = eligRangeSq,
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

-- Does this allyTeam have any powered hub at all? Used to grey the buttons of
-- mobile builders, which can drive to a hub so their own position doesn't matter.
local function AnyPoweredHub(allyTeamID)
	for hubID, hub in IterableMap.Iterator(hubs) do
		if hub.powered and hub.allyTeamID == allyTeamID then
			return true
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
	local access
	if builder.info.isMobile then
		-- Mobile builder: enabled whenever the allyTeam owns a powered hub;
		-- placement (AllowCommand) still confines the build to a hub's area.
		access = AnyPoweredHub(builder.allyTeamID)
	else
		access = HubInRange(builder.x, builder.z, builder.allyTeamID, builder.info.eligRangeSq)
	end
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
