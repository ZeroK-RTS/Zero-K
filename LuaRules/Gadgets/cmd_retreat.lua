--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Retreat Command",
    desc      = "Handle retreats",
    author    = "CarRepairer",
    date      = "2014-04-10",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local Tooltips = {
	'Orders: Never retreat.',
	'Orders: Retreat at less than 30% health (right-click to cancel).',
	'Orders: Retreat at less than 65% health (right-click to cancel).',
	'Orders: Retreat at less than 99% health (right-click to cancel).',
}

local DefaultState = 0

local CommandOrder = 123456
local CommandDesc = {
	id          = CMD_RETREAT,
	type        = CMDTYPE.ICON_MODE,
	name        = 'Retreat',
	action      = 'retreat',
	tooltip 	= Tooltips[DefaultState + 1],
	params  = { 'Retreat Off', 'Retreat Off', 'Retreat 30%', 'Retreat 65%', 'Retreat 99%' }, 
}
local StateCount = #CommandDesc.params-1

local thresholdMap = {
	0.3,
	0.65,
	0.99,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetUnitTeam 		= Spring.GetUnitTeam
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGiveOrderToUnit 	= Spring.GiveOrderToUnit
local spInsertUnitCmdDesc 	= Spring.InsertUnitCmdDesc
local spEditUnitCmdDesc 	= Spring.EditUnitCmdDesc
local spGetUnitHealth 		= Spring.GetUnitHealth
local spGetUnitRulesParam 	= Spring.GetUnitRulesParam
local spSetUnitRulesParam 	= Spring.SetUnitRulesParam
local spFindUnitCmdDesc 	= Spring.FindUnitCmdDesc
local spGetUnitIsStunned 	= Spring.GetUnitIsStunned

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local getMovetype = Spring.Utilities.getMovetype

local rand 		= math.random

local alliedTrueTable = {allied = true}

local interruptedRetreaters = {} -- unit was retreating but got manual orders
local wantRetreat = {} -- unit wants to retreat, may or may not be retreating
local isRetreating = {} -- unit has retreat orders (move and wait)
local retreaterTagsMove = {}
local retreaterTagsWait = {}
local retreaterHasRearm = {}
local retreatState = {} -- stores the the current state of the retreat command for the unit
local retreatables = {} -- unit has the ability to retreat (so it should have a retreat state command available)
local isPlane = {}
local havens = {}
local RADIUS = 160 --retreat zone radius
local DIAM = RADIUS * 2
local RADSQ = RADIUS * RADIUS 

local ignoreAllowCommand = false

local gunshipDefs = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	local movetype = Spring.Utilities.getMovetype(unitDef)
	if movetype == 1 and not Spring.Utilities.tobool(unitDef.customParams.cantuseairpads) then
		gunshipDefs[unitDefID] = true
	end
end

----------------------------
----- Haven Handling
----------------------------

local function FindClosestHaven(teamID, sx, sz)
	local closestDistSqr = math.huge
	local cx, cz  --  closest coordinates
	local cHavenID
	local havensTeam = havens[teamID]
	if not havensTeam then
		return -1, -1, -1 
	end
	for havenID = 1, havensTeam.count do
		local hx, hz = havensTeam.data[havenID].x, havensTeam.data[havenID].z
		if hx then 
			local dSquared = (hx - sx)^2 + (hz - sz)^2
			if (dSquared < closestDistSqr) then
				closestDistSqr = dSquared
				cx = hx
				cz = hz
				cHavenID = havenID
			end
		end
	end
	if (not cx) then 
		return -1, -1, -1 
	end
	return cx, cz, closestDistSqr, cHavenID
end

local function FindClosestHavenToUnit(unitID)
	local ux, _, uz = spGetUnitPosition(unitID)
	local teamID = spGetUnitTeam(unitID)
	return FindClosestHaven(teamID, ux, uz)
end

local function WriteHavenToTeamRulesParam(teamID, havenID)
	if havens[teamID] and havenID <= havens[teamID].count then
		local data = havens[teamID].data[havenID]
		Spring.SetTeamRulesParam(teamID, "haven_x" .. havenID, data.x, alliedTrueTable)
		Spring.SetTeamRulesParam(teamID, "haven_z" .. havenID, data.z, alliedTrueTable)
	end
end

local function AddHaven(teamID, x, z)
	if not teamID then
		return
	end
	if not havens[teamID] then
		havens[teamID] = {count = 0, data = {}}
	end
	local teamHavens = havens[teamID]
	teamHavens.count = teamHavens.count + 1
	teamHavens.data[teamHavens.count] = {x = x, z = z}
	Spring.SetTeamRulesParam(teamID, "haven_count", havens[teamID].count, alliedTrueTable)
	WriteHavenToTeamRulesParam(teamID, teamHavens.count)
end


local function RemoveHaven(teamID, havenID)
	if havens[teamID] and havenID <= havens[teamID].count then
		havens[teamID].data[havenID] = havens[teamID].data[havens[teamID].count]
		havens[teamID].data[havens[teamID].count] = nil
		havens[teamID].count = havens[teamID].count - 1
		Spring.SetTeamRulesParam(teamID, "haven_count", havens[teamID].count, alliedTrueTable)
		WriteHavenToTeamRulesParam(teamID, havenID)
	end
end

local function ToggleHaven(teamID, x,z)
	local _, _, dSquared, closestHavenID = FindClosestHaven(teamID, x,z)
	if dSquared ~= -1 and dSquared < RADSQ then
		RemoveHaven(teamID, closestHavenID)
	else
		AddHaven(teamID, x,z)
	end
	SendToUnsynced("HavenUpdate", teamID)
end

GG.Retreat_ToggleHaven = ToggleHaven

----------------------------
----- Retreat Handling
----------------------------


local function ResetRetreatData(unitID)
	isRetreating[unitID] = nil
	retreaterTagsMove[unitID] = nil
	retreaterTagsWait[unitID] = nil
	retreaterHasRearm[unitID] = nil
	interruptedRetreaters[unitID] = nil
end

local function StopRetreating(unitID)
	SendToUnsynced("StopRetreat", unitID)
	local cmds = Spring.GetUnitCommands(unitID, -1)
	if retreaterHasRearm[unitID] then
		for _,cmd in ipairs(cmds) do
			if cmd.id == CMD_REARM then
				spGiveOrderToUnit(unitID, CMD.REMOVE, { cmd.tag }, {})
			end
		end
	end

	if retreaterTagsMove[unitID] or retreaterTagsWait[unitID] then
		local first = true
		for _,cmd in ipairs(cmds) do
			if cmd.tag == retreaterTagsMove[unitID] or cmd.tag == retreaterTagsWait[unitID] then
				spGiveOrderToUnit(unitID, CMD.REMOVE, { cmd.tag }, {})
			elseif first and cmd.id == CMD.WAIT then
				spGiveOrderToUnit(unitID, CMD.WAIT, {}, {})
			end
			first = false
		end
	end
	
	ResetRetreatData(unitID)
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env and env.StopRetreatFunction then
		Spring.UnitScript.CallAsUnit(unitID,env.StopRetreatFunction, hx, hy, hz)
	end
end


local function IsUnitIdle(unitID)
	local cQueue = spGetCommandQueue(unitID, 1)
	local moving = cQueue and #cQueue > 0
	return not moving
end

local function GiveRearmOrders(unitID)
	local unitIsIdle = IsUnitIdle(unitID) 
	local insertIndex = 0
	
	ignoreAllowCommand = true
	local success = GG.RequestRearm(unitID, nil, true)
	ignoreAllowCommand = false

	if success then 
		isRetreating[unitID] = true
		retreaterHasRearm[unitID] = true
		
		if unitIsIdle then
			local ux, uy, uz = spGetUnitPosition(unitID)
			GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE, {ux, uy, uz}, {"shift"})
		end
		
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env.RetreatFunction then
			Spring.UnitScript.CallAsUnit(unitID,env.RetreatFunction, hx, hy, hz)
		end

		SendToUnsynced("StartRetreat", unitID)
		return true
	end
	return false
end

local function GiveRetreatOrders(unitID, hx,hz)
	local unitIsIdle = IsUnitIdle(unitID) 
	local insertIndex = 0
	local hy = Spring.GetGroundHeight(hx, hz)
	
	spGiveOrderToUnit(unitID, CMD.INSERT, { insertIndex, CMD.WAIT, CMD.OPT_SHIFT}, {"alt"}) --SHIFT W
	GiveClampedOrderToUnit(unitID, CMD.INSERT, { insertIndex, CMD_RAW_MOVE, CMD.OPT_INTERNAL, hx, hy, hz}, {"alt"}) -- ALT makes the 0 positional
	
	local cmds = Spring.GetUnitCommands(unitID,2)
	local tag1, tag2 = cmds[1].tag, cmds[2] and cmds[2].tag
	
	isRetreating[unitID] = true
	retreaterTagsMove[unitID] = tag1
	retreaterTagsWait[unitID] = tag2
	
	if unitIsIdle then
		local ux, uy, uz = spGetUnitPosition(unitID)
		GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE, {ux, uy, uz}, {"shift"})
	end
	
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env and env.RetreatFunction then
		Spring.UnitScript.CallAsUnit(unitID,env.RetreatFunction, hx, hy, hz)
	end
end

local function MaybeLandGunshipAtAirpad(unitID, x, z, r)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not gunshipDefs[unitDefID] then
		return
	end

	local padID = GG.FindBestAirpadAt(unitID, x, z, r)
	if not padID then
		return
	end

	spGiveOrderToUnit(unitID, CMD.INSERT, {0, CMD_REARM, CMD.OPT_SHIFT + CMD.OPT_INTERNAL, padID}, CMD.OPT_ALT)
	retreaterHasRearm[unitID] = true

	-- there's some room for improvement, for example check if there's a second pad in the zone if the first is dead or slacking
end

local function StartRetreat(unitID)
	if isPlane[unitID] and GiveRearmOrders(unitID) then
		return
	end

	local hx, hz, dSquared = FindClosestHavenToUnit(unitID)
	if dSquared < RADSQ then
		return
	end

	GiveRetreatOrders(unitID,
		hx + RADIUS - rand(10, DIAM),
		hz + RADIUS - rand(10, DIAM))
	MaybeLandGunshipAtAirpad(unitID, hx, hz, RADIUS)
	SendToUnsynced("StartRetreat", unitID)
end

local function CheckRetreat(unitID)
	local want = wantRetreat[unitID]
	if want and not isRetreating[unitID] then
		StartRetreat(unitID)
	elseif not want and isRetreating[unitID] then
		StopRetreating(unitID)
	end
end

local function SetWantRetreat(unitID, want)
	if wantRetreat[unitID] ~= want then
		Spring.SetUnitRulesParam(unitID, "retreat", want and 1 or 0, alliedTrueTable)
		if not want then
			local env = Spring.UnitScript.GetScriptEnv(unitID)
			if env and env.StopRetreatFunction then
				Spring.UnitScript.CallAsUnit(unitID,env.StopRetreatFunction)
			end
		end
	end
	wantRetreat[unitID] = want
end

local function CheckSetWantRetreat(unitID)
	local health, maxHealth = spGetUnitHealth(unitID)
	if not health then 
		ResetRetreatData(unitID)
		retreatables[unitID] = nil
		return
	end
	
	if not retreatState[unitID] or retreatState[unitID] == 0 then 
		return 
	end
	
	local healthRatio = health / maxHealth
	local threshold = thresholdMap[retreatState[unitID]]
	local _,_,inBuild = spGetUnitIsStunned(unitID)

	if healthRatio < threshold and (not inBuild) then
		SetWantRetreat(unitID, true)
	elseif healthRatio >= 1 then
		SetWantRetreat(unitID, nil)
	end
end

--------------------------------------------------------------------------------
-- Command Handling
--------------------------------------------------------------------------------

local function SetRetreatState(unitID, state, retID) 
	local cmdDescID = spFindUnitCmdDesc(unitID, retID)
	if (cmdDescID) then
		CommandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, {
			params = CommandDesc.params,
			tooltip = Tooltips[state]
		})
		spSetUnitRulesParam(unitID, 'retreatState', state, alliedTrueTable)
		retreatState[unitID] = state
		SetWantRetreat(unitID, nil)
	end
end 

function RetreatCommand(unitID, cmdID, cmdParams, cmdOptions)
	local state = cmdParams[1]
	if cmdOptions.right then 
		state = 0
	elseif state == 0 then  --note: this means that to set "Retreat Off" (state = 0) you need to use the "right" modifier, whether the command is given by the player using an ui button or by Lua
		state = 1
	end
	retreatables[unitID] = state ~= 0 or wantRetreat[unitID] or isRetreating[unitID]
	state = state % StateCount
	SetRetreatState(unitID, state, cmdID)
end

local function PeriodicUnitCheck(unitID)
	CheckSetWantRetreat(unitID)
	CheckRetreat(unitID)
	if retreatState[unitID] == 0 and not (wantRetreat[unitID] or isRetreating[unitID]) then
		retreatables[unitID] = nil
	end
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID, _, _)
	local ud = UnitDefs[unitDefID]
	--add inherit or is this handled by unit states?
	if ud.canMove then
		CommandDesc.params[1] = DefaultState
		spInsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
		if getMovetype(UnitDefs[unitDefID]) == 0 then
			isPlane[unitID] = true
		else
			isPlane[unitID] = nil
		end
	end	
end

function gadget:UnitDestroyed(unitID)
	ResetRetreatData(unitID)
	retreatables[unitID] = nil
end

function gadget:RecvSkirmishAIMessage(aiTeam, dataStr)
	-- perhaps this should be a global relay mode somewhere instead
	if(string.sub(dataStr,1,string.len('sethaven'))=='sethaven') then
		CallAsTeam(aiTeam, function()
			Spring.SendLuaRulesMsg(dataStr.."|"..aiTeam)
		end)
	end
end	

function gadget:RecvLuaMsg(msg, playerID)
	local msg_table = Spring.Utilities.ExplodeString('|', msg)
	if msg_table[1] ~= 'sethaven' then
		return
	end
	
	local t = msg_table[5];
	
	local spec, teamID, allianceID;
	
	if(t) then
		t = tonumber(t);
		local _,_,_,isAI = Spring.GetTeamInfo(t)
		if(isAI) then
			local aiid, ainame, aihost = Spring.GetAIInfo(t);
			if (aihost == playerID) then
				teamID,_,_,_,_,allianceID = Spring.GetTeamInfo(t);
			end
		end
	end
	
	if not teamID then
		_,_, spec, teamID, allianceID = Spring.GetPlayerInfo(playerID)
	end
	
	if spec then return end
	
	local unitID = msg_table[2]+0
	local x = msg_table[2]+0
	local y = msg_table[3]+0
	local z = msg_table[4]+0
	
	if not z then
		return
		--fixme, yell at players
	end 
	ToggleHaven( teamID, x, z )
end

local interruptingCommands = { -- fixme: some common header should probably contain those?
	[CMD.STOP]       = true,
	[CMD_RAW_MOVE]   = true,
	[CMD_RAW_BUILD]  = true,
	[CMD.MOVE]       = true,
	[CMD.FIGHT]      = true,
	[CMD.ATTACK]     = true,
	[CMD.MANUALFIRE] = true,
	[CMD.GUARD]      = true,
	[CMD_ORBIT]      = true,
	[CMD.PATROL]     = true,
}

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	
	if cmdID == CMD_RETREAT then
		RetreatCommand(unitID, cmdID, cmdParams, cmdOptions)  
		return false  -- command was used
	end

	if isRetreating[unitID] and not ignoreAllowCommand and not cmdOptions.shift and interruptingCommands[cmdID] then
		interruptedRetreaters[unitID] = true
	end

	return true
end

function gadget:UnitIdle(unitID)
	if not interruptedRetreaters[unitID] then
		return
	end

	ResetRetreatData(unitID)
end

function gadget:GameFrame(gameFrame)
	local frame20 = gameFrame % 20 == 10 -- ~1 second
	--local frame160 = gameFrame % 160 == 0 -- ~5 second
	
	if frame20 then
		for unitID, _ in pairs(retreatables) do
			if retreatables[unitID] then
				PeriodicUnitCheck(unitID)
			end
		end -- for
	end
end
	
function gadget:Initialize()
	for _,unitID in pairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID);
		gadget:UnitCreated(unitID, unitDefID, nil, 1, _, _)
	end
	
	Spring.SetGameRulesParam('retreatZoneRadius', RADIUS)
	
	local teams = Spring.GetTeamList()
	for i = 0, #teams-1 do
		Spring.SetTeamRulesParam(i, "haven_count", 0, alliedTrueTable)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------

local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID

local function WrapToLuaUI_Haven(_,teamID)
	local spectating = Spring.GetSpectatingState()
	if not spectating then
		local allyTeamID = select(6, Spring.GetTeamInfo(teamID))
		if (allyTeamID ~= spGetLocalAllyTeamID()) then 
			return 
		end
	end
	if (Script.LuaUI('HavenUpdate')) then
		Script.LuaUI.HavenUpdate(teamID, allyTeamID)
	end
end

local function IsUnitWidgetspaceVisible (unitID)
	local spec = Spring.GetSpectatingState()
	if spec then
		return true
	end

	local localAllyTeamID = Spring.GetLocalAllyTeamID()
	local unitAllyTeamID = Spring.GetUnitAllyTeam(unitID)
	if localAllyTeamID == unitAllyTeamID then
		return true
	end

	return false
end

local function WrapToLuaUI_Retreat (cmd, unitID)
	local vis = IsUnitWidgetspaceVisible(unitID)
	if not vis then
		return
	end

	if not Script.LuaUI(cmd) then
		return
	end

	local unitDefID = Spring.GetUnitDefID(unitID)
	local teamID = Spring.GetUnitTeam(unitID)
	Script.LuaUI[cmd](unitID, unitDefID, teamID)
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction('HavenUpdate',WrapToLuaUI_Haven)
	gadgetHandler:AddSyncAction('StartRetreat',WrapToLuaUI_Retreat)
	gadgetHandler:AddSyncAction('StopRetreat',WrapToLuaUI_Retreat)
end

-------------------------------------------------------------------------------------

end
