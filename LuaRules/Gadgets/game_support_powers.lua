if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name    = "Support Powers",
		desc    = "Implements Age of Mythology / CnC Generals style global powers",
		author  = "Sprung",
		date    = "2022",
		license = "Public domain",
		layer   = 0,
		enabled = true,
	}
end

local RULES_PARAM_VISIBILITY = { public = true } -- by design, though many are global so you could keep track anyway

local PowerDefs = VFS.Include("LuaRules/Configs/support_power_defs.lua", nil, VFS.GAME)

local sp = Spring

local function CheckFeatureValidity(featureID, teamID)
	if not featureID or not sp.ValidFeatureID(featureID) then
		return false
	end

	--[[ visibility check; there is no explicit callout.
	     Note that some features such as trees are globally
	     visible even if their position has no LoS (so
	     while there's IsPosInLos, a check that acts on the
	     feature itself is necessary), but features also
	     aren't subject to radar (so anything that requires
	     visibility is sufficient). ]]
	if not CallAsTeam(teamID, sp.GetFeatureDefID, featureID) then
		return false
	end

	return true
end

local untargetable = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.customParams.support_power_untargetable then
		untargetable[unitDefID] = true
	end
end
local function CheckUnitValidity(unitID, allyTeamID)
	if not unitID
	or not sp.ValidUnitID(unitID)
	or untargetable[sp.GetUnitDefID(unitID)] then
		return false
	end

	--[[ Note that radar-only targets are not allowed.
	     This simplifies things UI-side (variable mana
	     costs are always known) and is probably good
	     balance-wise (can't just pwn crap on the other
	     side of the map with advanced radar). If a mod
	     wants radar-targetable units they can use the
	     "unit or position" targeting mode and snap to
	     the closest unit when cast into a position in
	     the fog of war (like Dota Zeus W). ]]
	local los_state = sp.GetUnitLosState(unitID, allyTeamID, true)
	return los_state % 2 == 1
end

local function CheckPosValidity(x, z)
	--[[ Note: visibility checks up to the power,
	     since position-based powers may want to
	     be cast into the fog of war (eg. scan sweep) ]]
	return Spring.Utilities.IsValidPosition(x, z)
	   and GG.map_AllowPositionTerraform(x, z) -- not actually terraform: circular map border
end

local function CheckArgsValidity(teamID, allyTeamID, targetType, arg1, arg2, arg3, arg4)
	if     targetType == "unit"
	or     targetType == "unit_or_position" and not arg2 then
		return CheckUnitValidity(arg1, allyTeamID)

	elseif targetType == "feature"
	or     targetType == "feature_or_position" and not arg2 then
		return CheckFeatureValidity(arg1, teamID)

	elseif targetType == "position"
	or     targetType == "unit_or_position" -- unit variant already handled above
	or     targetType == "feature_or_position" then
		return CheckPosValidity(arg1, arg2)

	elseif targetType == "unit_and_position" then
		return CheckUnitValidity(arg1, allyTeamId)
		   and CheckPosValidity(arg2, arg3)

	elseif targetType == "feature_and_position" then
		return CheckFeatureValidity(arg1, teamID)
		   and CheckPosValidity(arg2, arg3)

	elseif targetType == "position_and_position" then
		return CheckPosValidity(arg1, arg2)
		   and CheckPosValidity(arg3, arg4)

	else
		return targetType == "freestyle" -- łaka maka fą!
	end
end

local function InvokePower(teamID, powerDefName, arg1, arg2, arg3, arg4)
	local powerDef = PowerDefs[powerDefName]
	if not powerDef then
		return
	end

	if not sp.GetTeamRulesParam(teamID, "support_available_" .. powerDefName) then
		return
	end

	local currentFrame = sp.GetGameFrame()
	local cooldown_param_name = "support_ready_" .. powerDefName
	local readyFrame = sp.GetTeamRulesParam(teamID, cooldown_param_name)
	if currentFrame < readyFrame then
		-- Script.LuaUI.PowerUseFailed("cooldown")
		Spring.Echo("power failed: cooldown", currentFrame, readyFrame)
		return
	end

	local targetType = powerDef.TargetType
	local _, _, _, _, _, allyTeamID = sp.GetTeamInfo(teamID)
	if not CheckArgsValidity(teamID, allyTeamID, targetType, arg1, arg2, arg3, arg4) then
		Spring.Echo("power failed: args invalid (1st step)")
		return
	end

	local cost = powerDef:Cost(teamID, arg1, arg2, arg3, arg4)
	if not cost then
		-- Script.LuaUI.PowerUseFailed("invalid")
		Spring.Echo("power failed: args invalid (2nd step)")
		return
	end

	-- FIXME: turn into a regular resource once that exists in engine
	if not GG.Support.UseTeamMana(teamID, cost) then
		-- Script.LuaUI.PowerUseFailed("mana")
		Spring.Echo("power failed: mana")
		-- return -- FIXME nothing grants mana yet
	end

	powerDef:Apply(teamID, arg1, arg2, arg3, arg4)

	local nextReadyFrame = currentFrame + Game.gameSpeed * powerDef:Cooldown(teamID, arg1, arg2, arg3, arg4)
	sp.SetTeamRulesParam(teamID, cooldown_param_name, nextReadyFrame)
end

local function handleMessage (teamID, msg)
	if not msg or type(msg) == "number" then
		return
	end
	--[[ NB: Lua patterns are not proper regexes, so the matching is
	     not ideal. In particular, you can't apply ? to capture groups,
	     only piece-meal, so strings can satisfy some of the optional
	     captures in an inconvenient way. That is acceptable since the
	     UI won't produce them and the code which interprets the parsed
	     params is robust, but it's worth keeping in mind when working
	     with the pattern. ]]
	local powerDefName, a1, a2, a3, a4 = msg:match("^support ([^ ]+) *([0-9]*) *([0-9]*) *([0-9]*) *([0-9]*)")
	if not powerDefName then
		return
	end

	local arg1 = tonumber(a1)
	local arg2 = tonumber(a2)
	local arg3 = tonumber(a3)
	local arg4 = tonumber(a4)

	return InvokePower(teamID, powerDefName, arg1, arg2, arg3, arg4)
end


local function InitializeAvailabilityForTeam(teamID, availablePowers)
	for powerDefName in pairs(availablePowers) do
		sp.SetTeamRulesParam(teamID, "support_available_" .. powerDefName, true, RULES_PARAM_VISIBILITY)
	end
end

local function InitializeAvailability()

	-- FIXME: figure out a good modding interface for this mapping
	local function GetAvailablePowersByTeam(teamID)
		local ret = {}
		if tonumber(Spring.GetModOptions().all_support_powers) == 1 then
			for powerDefName in pairs(PowerDefs) do
				ret[powerDefName] = true
			end
		end
		return ret
	end

	local teamList = sp.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		InitializeAvailabilityForTeam(teamID, GetAvailablePowersByTeam(teamID))
	end
end

local function InitializePowers()
	local teamList = sp.GetTeamList()
	for powerDefName, powerDef in pairs(PowerDefs) do

		-- start everything off cooldown by default; Initialize below can modify that
		for i = 1, #teamList do
			sp.SetTeamRulesParam(teamList[i], "support_ready_" .. powerDefName, 0)
		end

		if powerDef.Initialize then
			powerDef:Initialize()
		end

		powerDef.GUI = nil -- don't waste memory for widget-specific crap
	end
end

function gadget:Initialize()
	InitializePowers()
	InitializeAvailability()

	GG.Support = GG.Support or {}
	GG.Support.InvokePower = InvokePower
end

function gadget:RecvLuaMsg (msg, playerID)
	local _, _, spec, teamID = sp.GetPlayerInfo(playerID, false)
	if spec then
		return
	end

	return handleMessage(teamID, msg)
end

-- already passes the correct params
gadget.RecvSkirmishAIMessage = handleMessage

-- Mostly for debugging. "/luarules support powerDefName 1200 3400"
gadget.GotChatMsg = gadget.RecvLuaMsg
