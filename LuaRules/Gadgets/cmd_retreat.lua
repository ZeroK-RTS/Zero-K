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
	'Orders: Retreat at less than 60% health (right-click to cancel).',
	'Orders: Retreat at less than 90% health (right-click to cancel).',
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

--------------------------------------------------------------------------------
-- functions

local function explode(div,str)
	if (div=='') then return 
		false 
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end
----------------------------
----- Haven Handling
----------------------------

local function FindClosestHaven(teamID, sx, sz)
	local closestDistSqr = math.huge
	local cx, cz  --  closest coordinates
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
end

local function StopRetreating(unitID)
	local cmds = Spring.GetUnitCommands(unitID)
	if retreaterHasRearm[unitID] then
		for _,cmd in ipairs(cmds) do
			if retreaterHasRearm[unitID] and cmd.id == CMD_REARM then
				spGiveOrderToUnit(unitID, CMD.REMOVE, { cmd.tag }, {})
			end
		end
	else
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
			GiveClampedOrderToUnit(unitID, CMD.MOVE, {ux, uy, uz}, {"shift"})
		end
		
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env.RetreatFunction then
			Spring.UnitScript.CallAsUnit(unitID,env.RetreatFunction, hx, hy, hz)
		end
		return true
	end
	return false
end

local function GiveRetreatOrders(unitID, hx,hz)
	local unitIsIdle = IsUnitIdle(unitID) 
	local insertIndex = 0
	local hy = Spring.GetGroundHeight(hx, hz)
	
	spGiveOrderToUnit(unitID, CMD.INSERT, { insertIndex, CMD.WAIT, CMD.OPT_SHIFT}, {"alt"}) --SHIFT W
	GiveClampedOrderToUnit(unitID, CMD.INSERT, { insertIndex, CMD.MOVE, CMD.OPT_INTERNAL, hx, hy, hz}, {"alt"}) -- ALT makes the 0 positional
	
	local cmds = Spring.GetUnitCommands(unitID,2)
	local tag1, tag2 = cmds[1].tag, cmds[2] and cmds[2].tag
	
	isRetreating[unitID] = true
	retreaterTagsMove[unitID] = tag1
	retreaterTagsWait[unitID] = tag2
	
	if unitIsIdle then
		local ux, uy, uz = spGetUnitPosition(unitID)
		GiveClampedOrderToUnit(unitID, CMD.MOVE, {ux, uy, uz}, {"shift"})
	end
	
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env and env.RetreatFunction then
		Spring.UnitScript.CallAsUnit(unitID,env.RetreatFunction, hx, hy, hz)
	end
end


local function StartRetreat(unitID)
	if not (isPlane[unitID] and GiveRearmOrders(unitID)) then
		local hx, hz, dSquared = FindClosestHavenToUnit(unitID)
		hx = hx + RADIUS - rand(10, DIAM)
		hz = hz + RADIUS- rand(10, DIAM)
		if dSquared > RADSQ then
			local insertIndex = 0
			GiveRetreatOrders(unitID, hx, hz)
		end
	end
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

function gadget:RecvLuaMsg(msg, playerID)
	local _,_, spec, teamID, allianceID = Spring.GetPlayerInfo(playerID)
	HandleLuaMessage(msg, teamID);
end

function gadget:RecvSkirmishAIMessage(aiTeam, dataStr)
	HandleLuaMessage(dataStr, aiTeam);
end

function HandleLuaMessage(msg, teamID)
	local msg_table = explode('|', msg)
	if msg_table[1] ~= 'sethaven' then
		return
	end
	
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


function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	
	if cmdID == CMD_RETREAT then
		RetreatCommand(unitID, cmdID, cmdParams, cmdOptions)  
		return false  -- command was used
	end
	
    if isRetreating[unitID] and not ignoreAllowCommand and not cmdOptions.shift
		--need checks here because of random commands like maxwantedspeed, find better way
		and ( cmdID == CMD.MOVE or cmdID == CMD.FIGHT or cmdID == CMD.STOP or cmdID == CMD.ATTACK or cmdID == CMD.GUARD or cmdID == CMD.PATROL )
		then
		ResetRetreatData(unitID)
		if not CheckUnitNextFrame then
			CheckUnitNextFrame = {}
		end
		CheckUnitNextFrame[unitID] = true
    end
	
	return true
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
	if CheckUnitNextFrame then
		for unitID, _ in pairs(CheckUnitNextFrame) do
			PeriodicUnitCheck(unitID)
		end
		CheckUnitNextFrame = nil
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

function WrapToLuaUI(_,teamID)
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

function gadget:Initialize()
	gadgetHandler:AddSyncAction('HavenUpdate',WrapToLuaUI)
end

-------------------------------------------------------------------------------------

end
